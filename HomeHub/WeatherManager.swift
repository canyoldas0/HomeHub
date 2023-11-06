//
//  WeatherManager.swift
//  HomeHub
//
//  Created by Can Yoldas on 06/11/2023.
//

import WeatherKit
import SwiftUI

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

    func getWeather() async {
        do {
            weather = try await Task.detached(priority: .userInitiated) {
                return try await WeatherService.shared.weather(for: .init(latitude: 37.322998, longitude: -122.032181))  // Coordinates for Apple Park just as example coordinates
            }.value
        } catch {
            fatalError("\(error)")
        }
    }
}
