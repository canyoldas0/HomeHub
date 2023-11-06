//
//  Array+Extensions.swift
//  HomeHub
//
//  Created by Can Yoldas on 06/11/2023.
//

import Foundation
import class EventKit.EKEvent

extension Array {
    /// An array of events sorted by start date in ascending order.
    func sortedEventByAscendingDate() -> [EKEvent] {
        guard let self = self as? [EKEvent] else { return [] }
        
        return self.sorted(by: { (first: EKEvent, second: EKEvent) in
            return first.compareStartDate(with: second) == .orderedAscending
        })
    }
}
