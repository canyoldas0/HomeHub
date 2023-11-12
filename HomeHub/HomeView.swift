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
    
    @ViewBuilder
    var weatherInfoStack: some View {
        VStack(alignment: .leading) {
            Text("\(timeString(date: date))")
                .fontWeight(.semibold)
                .font(Font.largeTitle.monospacedDigit())
                .onAppear(perform: {let _ = self.updateTimer})
            Label(weatherManager.temp, systemImage: weatherManager.symbol)
            if let location = locationManager.lastLocation {
                HStack(alignment: .lastTextBaseline) {
                    Image(systemName: "mappin.and.ellipse")
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
                    Spacer()
                }
            }
        }
    }
    
    var body: some View {
        NavigationStack {
            VStack {
                weatherInfoStack
                    .frame(alignment: .leading)
                Spacer()
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
            .navigationTitle("Hello 👋")
        }
    }
}

#Preview {
    HomeView()
}
