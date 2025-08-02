//
//  ReportGenerator.swift
//  ReimbursementReportApp
//
//  Created by Xuyang Zheng on 7/12/25.
//

import Foundation
import UIKit
import ZIPFoundation

struct ReportGenerator {
    static func expenseReceiptFilename(occasion: String, date: Date, id: UUID, ext: String) -> String {
        let sanitizedOccasion = sanitize(occasion)
        let dateString = formatDate(date)
        let shortID = id.uuidString.prefix(4)
        return "\(sanitizedOccasion)_\(dateString)_\(shortID).\(ext)"
    }
    
    static func tripReceiptFilename(tripName: String, category: String, date: Date, id: UUID, ext: String) -> String {
        let sanitizedTripName = sanitize(tripName)
        let sanitizedCategory = sanitize(category)
        let dateString = formatDate(date)
        let shortID = id.uuidString.prefix(4)
        return "\(sanitizedTripName)_\(sanitizedCategory)_\(dateString)_\(shortID).\(ext)"
    }
    
    private static func sanitize(_ string: String) -> String {
        let allowed = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "-_"))
        return string
            .replacingOccurrences(of: " ", with: "_")
            .components(separatedBy: allowed.inverted)
            .joined()
    }
    
    static func convertToJPEG(data: Data, mimeType: String?, quality: CGFloat = 0.7) -> (data: Data, ext: String) {
        let imageTypes = ["image/jpeg", "image/jpg", "image/png", "image/heic"]
        if let mimeType = mimeType?.lowercased(), imageTypes.contains(mimeType),
           let image = UIImage(data: data),
           let jpegData = image.jpegData(compressionQuality: quality) {
            return (jpegData, "jpg")
        } else {
            let ext = fileExtension(for: mimeType) ?? "jpg"
            return (data, ext)
        }
    }
    
    static func generateExpenseReport(expenses: [MealItem]) -> (summary: String?, zipData: Data?, errorMessage: String?) {
        guard let minDate = expenses.compactMap({ $0.date }).min(),
              let maxDate = expenses.compactMap({ $0.date }).max() else {
            return (nil, nil, "No expenses to report.")
        }
        var summaryLines: [String] = []
        summaryLines.append("Expenses Report")
        summaryLines.append("Date Range: \(formatDate(minDate)) to \(formatDate(maxDate))\n")
        var expenseCount = 0
        // Create a temporary file for the ZIP
        let tempDir = FileManager.default.temporaryDirectory
        let zipURL = tempDir.appendingPathComponent(UUID().uuidString + ".zip")
        do {
            guard let archive = Archive(url: zipURL, accessMode: .create) else {
                print("[DEBUG] Failed to create ZIP archive at URL: \(zipURL)")
                return (nil, nil, "Failed to create ZIP archive.")
            }
            for expense in expenses {
                guard let id = expense.id, let date = expense.date else { continue }
                let occasion = expense.occasion ?? "Expense"
                let (data, ext) = convertToJPEG(data: expense.receiptData ?? Data(), mimeType: expense.receiptType)
                let filename = expenseReceiptFilename(occasion: occasion, date: date, id: id, ext: ext)
                print("[DEBUG] expense: \(occasion), data size: \(data.count), filename: \(filename)")
                // Add to ZIP if data is not empty
                if !data.isEmpty {
                    do {
                        try archive.addEntry(with: filename, type: .file, uncompressedSize: UInt32(data.count), provider: { position, size in
                            return data.subdata(in: position..<position+size)
                        })
                    } catch {
                        print("[DEBUG] Error zipping \(filename): \(error)")
                        let msg = "Failed to add receipt for '\(occasion)' on \(formatDate(date)). Please check the receipt image and try again."
                        return (nil, nil, msg)
                    }
                } else {
                    let msg = "No receipt data for '\(occasion)' on \(formatDate(date)). Please check the receipt image and try again."
                    return (nil, nil, msg)
                }
                summaryLines.append("• \(occasion) on \(formatDate(date)) — Receipt: \(filename)")
                expenseCount += 1
            }
            // Read ZIP data from file
            let zipData = try Data(contentsOf: zipURL)
            print("[DEBUG] Final ZIP size: \(zipData.count) bytes")
            // Clean up temp file
            try? FileManager.default.removeItem(at: zipURL)
            summaryLines.append("\nTotal Expenses: \(expenseCount)")
            return (summaryLines.joined(separator: "\n"), zipData, nil)
        } catch {
            print("[DEBUG] Error creating ZIP: \(error)")
            return (nil, nil, "Failed to create ZIP archive.")
        }
    }
    
    static func generateTripReport(trips: [Trip], mileage: String? = nil) -> (summary: String?, zipData: Data?, errorMessage: String?) {
        // Only support single-trip reports for now
        guard let trip = trips.first else {
            return (nil, nil, "No trip selected.")
        }
        let tripName = trip.name ?? "Trip"
        let tripReceipts = (trip.receipts as? Set<Receipt>) ?? []
        
        var summaryLines: [String] = []
        summaryLines.append("Trip Expenses Report - \(tripName)")
        
        // Add per diem information
        var perDiemSection = ""
        if let perDiemInfo = PerDiemCalculator.calculatePerDiem(for: trip) {
            // Replace summary header and destination label
            perDiemSection = perDiemInfo.summary
                .replacingOccurrences(of: "Per Diem Summary", with: "Per Diem Reimbursement Request")
                .replacingOccurrences(of: "Destination:", with: "Location:")
            summaryLines.append("\n" + perDiemSection)
        }
        
        // If drive and mileage provided, add mileage line after per diem
        if trip.transportType == "drive", let mileage = mileage, !mileage.trimmingCharacters(in: .whitespaces).isEmpty {
            summaryLines.append("Mileage reimbursement: \(mileage) miles")
        }
        
        // Add receipts section header
        summaryLines.append("\nReceipts for reimbursements")
        
        // Sort receipts by category
        let sortedReceipts = tripReceipts.sorted { (a, b) in
            let catA = a.expenseCategory ?? ""
            let catB = b.expenseCategory ?? ""
            return catA.localizedCaseInsensitiveCompare(catB) == .orderedAscending
        }
        
        var receiptCount = 0
        // Create a temporary file for the ZIP
        let tempDir = FileManager.default.temporaryDirectory
        let zipURL = tempDir.appendingPathComponent(UUID().uuidString + ".zip")
        do {
            guard let archive = Archive(url: zipURL, accessMode: .create) else {
                print("[DEBUG] Failed to create ZIP archive at URL: \(zipURL)")
                return (nil, nil, "Failed to create ZIP archive.")
            }
            for receipt in sortedReceipts {
                guard let id = receipt.id, let date = receipt.date else { continue }
                let categoryRaw = receipt.expenseCategory ?? "Receipt"
                let displayCategory = ReceiptCategory(rawValue: categoryRaw)?.displayName ?? categoryRaw
                let (data, ext) = convertToJPEG(data: receipt.data ?? Data(), mimeType: receipt.type)
                let filename = tripReceiptFilename(tripName: tripName, category: displayCategory, date: date, id: id, ext: ext)
                print("[DEBUG] trip: \(tripName), category: \(displayCategory), data size: \(data.count), filename: \(filename)")
                // Add to ZIP if data is not empty
                if !data.isEmpty {
                    do {
                        try archive.addEntry(with: filename, type: .file, uncompressedSize: UInt32(data.count), provider: { position, size in
                            return data.subdata(in: position..<position+size)
                        })
                    } catch {
                        print("[DEBUG] Error zipping \(filename): \(error)")
                        let msg = "Failed to add receipt [\(displayCategory)] on \(date.formatted(date: .numeric, time: .omitted)). Please check the receipt image and try again."
                        return (nil, nil, msg)
                    }
                } else {
                    let msg = "No receipt data for [\(displayCategory)] on \(date.formatted(date: .numeric, time: .omitted)). Please check the receipt image and try again."
                    return (nil, nil, msg)
                }
                summaryLines.append("• \(displayCategory): \(filename)")
                receiptCount += 1
            }
            // Read ZIP data from file
            let zipData = try Data(contentsOf: zipURL)
            print("[DEBUG] Final ZIP size: \(zipData.count) bytes")
            // Clean up temp file
            try? FileManager.default.removeItem(at: zipURL)
            summaryLines.append("\nTotal Receipts: \(receiptCount)")
            return (summaryLines.joined(separator: "\n"), zipData, nil)
        } catch {
            print("[DEBUG] Error creating ZIP: \(error)")
            return (nil, nil, "Failed to create ZIP archive.")
        }
    }
    
    static func fileExtension(for mimeType: String?) -> String? {
        guard let mimeType = mimeType else { return nil }
        switch mimeType.lowercased() {
        case "image/jpeg", "image/jpg": return "jpg"
        case "image/png": return "png"
        case "image/heic": return "heic"
        case "application/pdf": return "pdf"
        default:
            return nil
        }
    }
    
    private static func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }
}

