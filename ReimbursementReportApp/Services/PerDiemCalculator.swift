//
//  PerDiemCalculator.swift
//  ReimbursementReportApp
//
//  Created by Xuyang Zheng on 7/12/25.
//

import Foundation

struct PerDiemCalculator {
    
    struct PerDiemInfo {
        let destinationCity: String
        let destinationCountry: String
        let totalDays: Int
        let travelDays: Int
        let eventDays: Int
        let dateRange: String
        let travelDayDates: [Date]
        let eventDayDates: [Date]
        
        var summary: String {
            var lines: [String] = []
            lines.append("Per Diem Summary")
            lines.append("Destination: \(destinationCity), \(destinationCountry)")
            lines.append("Total Days: \(totalDays)")
            if travelDays > 0 {
                let travelDateStrings = travelDayDates.map { $0.formatted(date: .numeric, time: .omitted) }
                lines.append("Travel Days: \(travelDays) (\(travelDateStrings.joined(separator: ", ")))" )
            }
            if let eventStart = eventDayDates.first, let eventEnd = eventDayDates.last {
                lines.append("Event Days: \(eventDays) (\(eventStart.formatted(date: .numeric, time: .omitted)) to \(eventEnd.formatted(date: .numeric, time: .omitted)))")
            }
            return lines.joined(separator: "\n")
        }
    }
    
    static func calculatePerDiem(for trip: Trip) -> PerDiemInfo? {
        guard let tripStartDate = trip.startDate,
              let tripEndDate = trip.endDate,
              let destinationCity = trip.destinationCity,
              let destinationCountry = trip.destinationCountry else {
            return nil
        }
        
        let eventStartDate = trip.eventStartDate ?? tripStartDate
        let eventEndDate = trip.eventEndDate ?? tripEndDate
        
        // Validate that event dates are within trip dates
        guard eventStartDate >= tripStartDate && eventEndDate <= tripEndDate else {
            return nil // Invalid event dates
        }
        
        var travelDayDates: [Date] = []
        var eventDayDates: [Date] = []
        let calendar = Calendar.current
        
        // Event days: all days from eventStartDate to eventEndDate (inclusive)
        eventDayDates = generateDateRange(from: eventStartDate, to: eventEndDate)
        
        // Travel day: trip start day if before event start
        if tripStartDate < eventStartDate {
            travelDayDates.append(tripStartDate)
        }
        // Travel day: trip end day if after event end
        if tripEndDate > eventEndDate {
            travelDayDates.append(tripEndDate)
        }
        
        let dateRange = "\(tripStartDate.formatted()) to \(tripEndDate.formatted())"
        let totalDays = calendar.dateComponents([.day], from: tripStartDate, to: tripEndDate).day ?? 0 + 1
        
        return PerDiemInfo(
            destinationCity: destinationCity,
            destinationCountry: destinationCountry,
            totalDays: totalDays,
            travelDays: travelDayDates.count,
            eventDays: eventDayDates.count,
            dateRange: dateRange,
            travelDayDates: travelDayDates,
            eventDayDates: eventDayDates
        )
    }
    
    private static func generateDateRange(from startDate: Date, to endDate: Date) -> [Date] {
        var dates: [Date] = []
        var currentDate = startDate
        let calendar = Calendar.current
        
        while currentDate <= endDate {
            dates.append(currentDate)
            currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate) ?? currentDate
        }
        
        return dates
    }
} 