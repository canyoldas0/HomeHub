//
//  EventManager.swift
//  HomeHub
//
//  Created by Can Yoldas on 06/11/2023.
//

import EventKit
import SwiftUI


enum EventStoreError: Error {
    case denied
    case restricted
    case unknown
    case upgrade
}

/// documentation: https://developer.apple.com/documentation/eventkit/accessing_calendar_using_eventkit_and_eventkitui
extension EventStoreError: LocalizedError {
    var errorDescription: String? {
        switch self {
        case .denied:
            return NSLocalizedString("The app doesn't have permission to Calendar in Settings.", comment: "Access denied")
         case .restricted:
            return NSLocalizedString("This device doesn't allow access to Calendar.", comment: "Access restricted")
        case .unknown:
            return NSLocalizedString("An unknown error occured.", comment: "Unknown error")
        case .upgrade:
            let access = "The app has write-only access to Calendar in Settings."
            let update = "Please grant it full access so the app can fetch and delete your events."
            return NSLocalizedString("\(access) \(update)", comment: "Upgrade to full access")
        }
    }
}


extension EventDataStore {
    
    var isFullAccessAuthorized: Bool {
        if #available(iOS 17.0, *) {
            EKEventStore.authorizationStatus(for: .event) == .fullAccess
        } else {
            // Fall back on earlier versions.
            EKEventStore.authorizationStatus(for: .event) == .authorized
        }
    }

    /// Prompts the user for full-access authorization to Calendar.
    private func requestFullAccess() async throws -> Bool {
        if #available(iOS 17.0, *) {
            return try await eventStore.requestFullAccessToEvents()
        } else {
            // Fall back on earlier versions.
            return try await eventStore.requestAccess(to: .event)
        }
    }
    
    /// Verifies the authorization status for the app.
    func verifyAuthorizationStatus() async throws -> Bool {
        let status = EKEventStore.authorizationStatus(for: .event)
        switch status {
        case .notDetermined:
            return try await requestFullAccess()
        case .restricted:
            throw EventStoreError.restricted
        case .denied:
            throw EventStoreError.denied
        case .fullAccess:
            return true
        case .writeOnly:
            throw EventStoreError.upgrade
        @unknown default:
            throw EventStoreError.unknown
        }
    }
    
    /// Fetches all events occuring within a month in all the user's calendars.
    func fetchEvents() -> [EKEvent] {
        guard isFullAccessAuthorized else { return [] }
        let start = Date.now
        let end = start.tomorrow
        let predicate = eventStore.predicateForEvents(withStart: start, end: end, calendars: nil)
        return eventStore.events(matching: predicate).sortedEventByAscendingDate()
    }
    
    /// Removes an event.
    private func removeEvent(_ event: EKEvent) throws {
        try self.eventStore.remove(event, span: .thisEvent, commit: false)
    }
    
    /// Batches all the remove operations.
    func removeEvents(_ events: [EKEvent]) throws {
        do {
            try events.forEach { event in
                try removeEvent(event)
            }
            try eventStore.commit()
         } catch {
             eventStore.reset()
             throw error
         }
    }
}


actor EventDataStore {
    let eventStore: EKEventStore
            
    init() {
        self.eventStore = EKEventStore()
    }
}

extension EventStoreManager {
    /*
        Listens for event store changes, which are always posted on the main thread. When the app receives a full access authorization status, it
        fetches all events occuring within a month in all the user's calendars.
    */
    func listenForCalendarChanges() async {
        let center = NotificationCenter.default
        let notifications = center.notifications(named: .EKEventStoreChanged).map({ (notification: Notification) in notification.name })
        
        for await _ in notifications {
            guard await dataStore.isFullAccessAuthorized else { return }
            await self.fetchLatestEvents()
        }
    }
    
    func setupEventStore() async throws {
        let response = try await dataStore.verifyAuthorizationStatus()
        authorizationStatus = EKEventStore.authorizationStatus(for: .event)
        if response {
            await fetchLatestEvents()
        }
    }
    
  func fetchLatestEvents() async {
        let latestEvents = await dataStore.fetchEvents()
        self.events = latestEvents
   }
    
    func removeEvents(_ events: [EKEvent]) async throws {
        try await dataStore.removeEvents(events)
    }
}


@MainActor
class EventStoreManager: ObservableObject {
    /// Contains fetched events when the app receives a full-access authorization status.
    @Published var events: [EKEvent]
    
    /// Specifies the authorization status for the app.
    @Published var authorizationStatus: EKAuthorizationStatus
    
    let dataStore: EventDataStore
    
    init(store: EventDataStore = EventDataStore()) {
        self.dataStore = store
        self.events = []
        self.authorizationStatus = EKEventStore.authorizationStatus(for: .event)
    }
    
    var isWriteOnlyOrFullAccessAuthorized: Bool {
        if #available(iOS 17.0, *) {
            return ((authorizationStatus == .writeOnly) || (authorizationStatus == .fullAccess))
        } else {
            // Fall back on earlier versions.
            return authorizationStatus == .authorized
        }
    }
}
