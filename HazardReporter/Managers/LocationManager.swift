//
//  LocationManager.swift
//  HazardReporter
//
//  Created by Doug Robison on 4/10/20.
//  Copyright © 2020 Doug Robison. All rights reserved.
//

import Foundation
import CoreLocation
import Combine


class LocationManager: NSObject, CLLocationManagerDelegate {
    private let manager: CLLocationManager
    var lastKnownLocation: CLLocation?
    let locationAuthorizationNeeded = CurrentValueSubject<Bool, Never>(false)
    let isLocationAuthorized = CurrentValueSubject<Bool, Never>(false)

    init(manager: CLLocationManager = CLLocationManager()) {
        self.manager = manager
        super.init()
    }

    func startUpdating() {
        let locationAuthorizationStatus = CLLocationManager.authorizationStatus()

        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest

        switch locationAuthorizationStatus {
            case .notDetermined: manager.requestWhenInUseAuthorization()
            case .authorizedWhenInUse, .authorizedAlways:
                if CLLocationManager.locationServicesEnabled() {
                    locationServicesEnabled()
                }
            case .restricted, .denied: alertLocationAccessNeeded()
        @unknown default:
                fatalError()
        }
    }

    func locationManager(_: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        print(locations)
        lastKnownLocation = locations.last
    }

    private func locationServicesEnabled() {
        manager.startUpdatingLocation()
        locationAuthorizationNeeded.send(false)
        isLocationAuthorized.send(true)
    }

    func locationManager(_: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        print("Authorized = \(status.rawValue)")
        if status == .authorizedWhenInUse || status == .authorizedAlways {
            locationServicesEnabled()
        }
    }

    private func alertLocationAccessNeeded() {
        locationAuthorizationNeeded.send(true)
    }

    deinit {
        manager.stopUpdatingLocation()
    }
}

