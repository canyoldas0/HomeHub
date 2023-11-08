//
//  LocationManager.swift
//  HomeHub
//
//  Created by Can Yoldas on 06/11/2023.
//

import Foundation
import CoreLocation

enum LocationResponse {
    case error(Error)
    case granted(DeviceLocation)
}

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
    @Published var lastLocation: DeviceLocation? = nil
    public var locationManager: CLLocationManager
    private var locationCompletionHandler: ((LocationResponse) -> Void)?

    
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
    
    private func updateAuthorization(
        status: CLAuthorizationStatus,
        ifNotDetermined: () -> Void,
        ifAuthorized: () -> Void
    ) {
        switch status {
        case .restricted:
            return
        case .denied:
            locationCompletionHandler?(.error(LocationError.genericError))
            locationCompletionHandler = nil

        case .notDetermined:
            ifNotDetermined()

        default:
            ifAuthorized()
        }
    }
    
    public func requestLocation(
        completion: @escaping (LocationResponse) -> Void
    ) {
        self.locationCompletionHandler = completion
        
        let status = locationManager.authorizationStatus
        self.authStatus = status
        
        switch status {
        case .notDetermined:
            self.locationManager.requestWhenInUseAuthorization()
        case .restricted:
            return
        case .denied:
            return
        case .authorizedAlways, .authorizedWhenInUse, .authorized:
            locationManager.requestLocation()
        @unknown default:
            return
        }
    }
    
  
    func requestLocation() async throws -> DeviceLocation {
        try await withCheckedThrowingContinuation({ continuation in
            self.requestLocation { location in
                
                switch location {
                case .error(let error):
                    continuation.resume(throwing: error)
                case .granted(let location):
                    continuation.resume(with: .success(location))
                }
                
            }
        })
    }
}

extension LocationManager: CLLocationManagerDelegate {
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        self.authStatus = manager.authorizationStatus
        
//        requestLocation { loc in
//            self.locationCompletionHandler?(loc)
//        }
    }
    
    public func locationManager(
        _: CLLocationManager,
        didUpdateLocations locations: [CLLocation]
    ) {

        guard let location = locations.first else {
            locationCompletionHandler = nil
            return
        }
        let loc: DeviceLocation = .init(lat: location.coordinate.latitude, long: location.coordinate.longitude)
        lastLocation = loc

        locationCompletionHandler?(.granted(loc))
        locationCompletionHandler = nil
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        debugPrint(error.localizedDescription)
    }
    
}
