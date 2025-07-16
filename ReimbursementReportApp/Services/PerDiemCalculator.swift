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
        
        let calendar = Calendar.current
        // Normalize all dates to midnight
        let tripStart = calendar.startOfDay(for: tripStartDate)
        let tripEnd = calendar.startOfDay(for: tripEndDate)
        let eventStartDate = trip.eventStartDate ?? tripStartDate
        let eventEndDate = trip.eventEndDate ?? tripEndDate
        let eventStart = calendar.startOfDay(for: eventStartDate)
        let eventEnd = calendar.startOfDay(for: eventEndDate)
        
        // Validate that event dates are within trip dates
        guard eventStart >= tripStart && eventEnd <= tripEnd else {
            return nil // Invalid event dates
        }
        
        var travelDayDates: [Date] = []
        var eventDayDates: [Date] = []
        
        // Event days: all days from eventStart to eventEnd (inclusive)
        eventDayDates = generateDateRange(from: eventStart, to: eventEnd)
        
        // Travel day: trip start day if before event start
        if tripStart < eventStart {
            travelDayDates.append(tripStart)
        }
        // Travel day: trip end day if after event end
        if tripEnd > eventEnd {
            travelDayDates.append(tripEnd)
        }
        
        let dateRange = "\(tripStart.formatted()) to \(tripEnd.formatted())"
        
        return PerDiemInfo(
            destinationCity: destinationCity,
            destinationCountry: destinationCountry,
            totalDays: travelDayDates.count + eventDayDates.count,
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