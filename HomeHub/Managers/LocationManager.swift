//
//  LocationManager.swift
//  HomeHub
//
//  Created by Can Yoldas on 06/11/2023.
//

import Foundation
import CoreLocation

struct DeviceLocation {
    let lat: Double
    let long: Double
}

@MainActor
final class LocationManager: NSObject, ObservableObject {
    enum LocationError: String, CustomNSError {
        case genericError = "Something went wrong."
    }
    
    @Published var currentLocation: CLLocation? = nil
    @Published var authStatus: CLAuthorizationStatus
    private var locationManager: CLLocationManager
    private var locationCompletionHandler: ((DeviceLocation) -> Void)?

    
    init(locationManager: CLLocationManager = defaultLocationManager) {
        self.locationManager = locationManager
        self.authStatus = locationManager.authorizationStatus
        super.init()
        self.locationManager.delegate = self
    }
    
    public static let defaultLocationManager: CLLocationManager = {
        let manager = CLLocationManager()
        manager.activityType = .other
        manager.allowsBackgroundLocationUpdates = false
        manager.desiredAccuracy = kCLLocationAccuracyThreeKilometers
        return manager
    }()
    
    public func requestLocation(
        completion: @escaping (DeviceLocation?) -> Void
    ) {
        self.locationCompletionHandler = completion
    }
    
    func updateAuthStatus() {
        locationManager.requestWhenInUseAuthorization()
    }
    
    func requestLocation(shouldLookInUserDefaults: Bool) async throws -> DeviceLocation {
        try await withCheckedThrowingContinuation({ continuation in
            self.requestLocation { location in
                guard let location = location else {
                    continuation.resume(throwing: LocationError.genericError)
                    return
                }
                continuation.resume(with: .success(location))
            }
        })
    }


}

extension LocationManager: CLLocationManagerDelegate {
    
   
    
}
