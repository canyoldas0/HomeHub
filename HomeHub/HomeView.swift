//
//  ContentView.swift
//  HomeHub
//
//  Created by Can Yoldas on 06/11/2023.
//

import SwiftUI
import EventKitUI

struct HomeView: View {
    
    @State var date = Date()
    @StateObject var weatherManager = WeatherManager()
    @StateObject var storeManager = EventStoreManager()
    @StateObject var locationManager = LocationManager()
    
    var timeFormat: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "hh:mm:ss a"
        return formatter
    }
    
    func timeString(date: Date) -> String {
         let time = timeFormat.string(from: date)
         return time
    }
    
    var updateTimer: Timer {
        Timer.scheduledTimer(withTimeInterval: 1, repeats: true,
                             block: { _ in
            self.date = Date()
        })
    }
    
    var body: some View {
        VStack(alignment: .leading) {
//            List(storeManager.events, id: \.eventIdentifier) { event in
//                HStack {
//                    Text(event.title)
//                }
//            }
     
            Label(weatherManager.temp, systemImage: weatherManager.symbol)
            if let location = locationManager.lastLocation {
                HStack {
                   Image(systemName: "house")
                    // TODO: Get address
                    Text("\(location.coordinate.latitude), \(location.coordinate.longitude)")
                    Button (action: {
                        Task {
                            let location = try await locationManager.requestLocation()
                            await weatherManager.getWeather(location)
                        }
                    }, label: {
                        Image(systemName: "arrow.clockwise.circle.fill")
                    })
                }
            }
            Text("\(timeString(date: date))")
                .fontWeight(.semibold)
                .font(.largeTitle)
                .onAppear(perform: {let _ = self.updateTimer})
        }
        .task {
            try? await storeManager.setupEventStore()
        }
        .task {
            await storeManager.listenForCalendarChanges()
        }
        .task {
            do {
                let location = try await locationManager.requestLocation()
                await weatherManager.getWeather(location)
            } catch {
                dump(error)
            }
        }
        .environmentObject(storeManager)
        .padding()
    }
}

#Preview {
    HomeView()
}
