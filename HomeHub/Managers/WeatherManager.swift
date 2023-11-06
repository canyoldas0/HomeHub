//
//  WeatherManager.swift
//  HomeHub
//
//  Created by Can Yoldas on 06/11/2023.
//

import WeatherKit
import SwiftUI

extension DeviceLocation {
    static let haarlem = DeviceLocation(lat: 52.370495, long: 4.633083)
}

@MainActor
final class WeatherManager: ObservableObject {
    
    @Published var weather: Weather?
    
    var symbol: String {
        weather?.currentWeather.symbolName ?? "xmark"
    }
    
    var temp: String {
        let temp =
        weather?.currentWeather.temperature
        
        let convert = temp?.converted(to: .celsius).description
        return convert ?? "Loading Weather Data"
        
    }

    func getWeather(_ loc: DeviceLocation? = nil) async {
        
        do {
            weather = try await Task.detached(priority: .userInitiated) {
                return try await WeatherService.shared.weather(for: .init(latitude: loc?.lat ?? DeviceLocation.haarlem.long, longitude: loc?.long ?? DeviceLocation.haarlem.long))
            }.value
        } catch {
            fatalError("\(error)")
        }
    }
}
