/*
See LICENSE folder for this sample’s licensing information.

Abstract:
A collection of utility functions used for charting and visualizations.
*/

import Foundation
import CareKitUI

// MARK: - Chart Date UI

/// Return a label describing the date range of the chart for the last week. Example: "Jun 3 - Jun 10, 2020"
func createChartWeeklyDateRangeLabel(lastDate: Date = Date()) -> String {
    let calendar: Calendar = .current
    
    let endOfWeekDate = lastDate
    let startOfWeekDate = getLastWeekStartDate(from: endOfWeekDate)
    
    let monthDayDateFormatter = DateFormatter()
    monthDayDateFormatter.dateFormat = "MMM d"
    let monthDayYearDateFormatter = DateFormatter()
    monthDayYearDateFormatter.dateFormat = "MMM d, yyyy"
    
    var startDateString = monthDayDateFormatter.string(from: startOfWeekDate)
    var endDateString = monthDayYearDateFormatter.string(from: endOfWeekDate)
    
    // If the start and end dates are in the same month.
    if calendar.isDate(startOfWeekDate, equalTo: endOfWeekDate, toGranularity: .month) {
        let dayYearDateFormatter = DateFormatter()
        
        dayYearDateFormatter.dateFormat = "d, yyyy"
        endDateString = dayYearDateFormatter.string(from: endOfWeekDate)
    }
    
    // If the start and end dates are in different years.
    if !calendar.isDate(startOfWeekDate, equalTo: endOfWeekDate, toGranularity: .year) {
        startDateString = monthDayYearDateFormatter.string(from: startOfWeekDate)
    }
    
    return String(format: "%@–%@", startDateString, endDateString)
}

private func createMonthDayDateFormatter() -> DateFormatter {
    let dateFormatter = DateFormatter()
    
    dateFormatter.dateFormat = "MM/dd"
    
    return dateFormatter
}

func createChartDateLastUpdatedLabel(_ dateLastUpdated: Date) -> String {
    let dateFormatter = DateFormatter()
    
    dateFormatter.dateStyle = .medium
    
    return "last updated on \(dateFormatter.string(from: dateLastUpdated))"
}

/// Returns an array of horizontal axis markers based on the desired time frame, where the last axis marker corresponds to `lastDate`
/// `useWeekdays` will use short day abbreviations (e.g. "Sun, "Mon", "Tue") instead.
/// Defaults to showing the current day as the last axis label of the chart and going back one week.
func createHorizontalAxisMarkers(lastDate: Date = Date(), useWeekdays: Bool = true) -> [String] {
    let calendar: Calendar = .current
    let weekdayTitles = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
    
    var titles: [String] = []
    
    if useWeekdays {
        titles = weekdayTitles
        
        let weekday = calendar.component(.weekday, from: lastDate)
        
        return Array(titles[weekday..<titles.count]) + Array(titles[0..<weekday])
    } else {
        let numberOfTitles = weekdayTitles.count
        let endDate = lastDate
        let startDate = calendar.date(byAdding: DateComponents(day: -(numberOfTitles - 1)), to: endDate)!
        
        let dateFormatter = createMonthDayDateFormatter()

        var date = startDate
        
        while date <= endDate {
            titles.append(dateFormatter.string(from: date))
            date = calendar.date(byAdding: .day, value: 1, to: date)!
        }
        
        return titles
    }
}

func createHorizontalAxisMarkers(for dates: [Date]) -> [String] {
    let dateFormatter = createMonthDayDateFormatter()
    
    return dates.map { dateFormatter.string(from: $0) }
}
