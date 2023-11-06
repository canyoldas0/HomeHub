//
//  Date+Extensions.swift
//  HomeHub
//
//  Created by Can Yoldas on 06/11/2023.
//

import Foundation

extension Date {
    
    /// The day of the week matching the specified date.
    var matchingDay: Int {
        Calendar.current.component(.weekday, from: self)
    }
    
    /// The next date for the given weekdays.
    func fetchNextDateFromDays(_ nextWeekDay: IndexSet) -> Date {
       var components: Int?
       let weekDay = Calendar.current.component(.weekday, from: self)
    
       if let nextWeekDay = nextWeekDay.integerGreaterThan(weekDay) {
           components = nextWeekDay
       } else {
           components = nextWeekDay.first
       }
       guard let foundWeekDay = components else { return self }
       return Calendar.current.nextDate(after: self, matching: DateComponents(weekday: foundWeekDay), matchingPolicy: .nextTime) ?? self
   }
   
    /// The formatted time of the date.
    var timeAsText: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: self)
    }
    
    /// Thirty minutes from the current time.
    var thirtyMinutesLater: Date {
        Date(timeInterval: 1800, since: self)
    }
    
    /// A month from the current date.
    var oneMonthOut: Date {
        Calendar.current.date(byAdding: .month, value: 1, to: Date.now) ?? Date()
    }
    
    var tomorrow: Date {
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: Date()) ?? Date()
        return Calendar.current.startOfDay(for: tomorrow)
    }
}
