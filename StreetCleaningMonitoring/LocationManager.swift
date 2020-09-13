//
//  LocationManager.swift
//  GPSTestApplication
//
//  Created by Igor Shukyurov on 27.08.2020.
//  Copyright © 2020 Igor Shukyurov. All rights reserved.
//

import CoreLocation

// MARK: - NotificationCenter
extension Notification.Name {
    static let didReceivedLocation = Notification.Name("didReceivedLocation")
}

final class LocationManager: NSObject, CLLocationManagerDelegate {
    static let shared = LocationManager()
    private let locationManager = CLLocationManager()
    
    var isRunning = false
    
    var distanceFilter: Double {
        set {
            locationManager.distanceFilter = newValue
        }
        get {
            return locationManager.distanceFilter
        }
    }
    
    var speedMS: Double = 0
    var speedKMH: Double {
        get {
            return round(speedMS * 3.6 * 100) / 100
        }
    }
    var startLocation: CLLocation!
    var previousLocation: CLLocation!
    var heading: CLHeading! {
        get {
            return locationManager.heading
        }
    }
    var totalTravelledDistance: Double = 0
    var distanceBetweenStartAndLastLocations: Double = 0
    var didUpdateLocationsCount = 0
    var errorSum: Double = 0
    var averageError: Double = 0

    // MARK: - Initialization
    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.requestWhenInUseAuthorization()
//        locationManager.requestAlwaysAuthorization()
        locationManager.allowsBackgroundLocationUpdates = false
        locationManager.pausesLocationUpdatesAutomatically = false
        locationManager.desiredAccuracy = kCLLocationAccuracyBestForNavigation
        distanceFilter = 20
        print("-=- LocationManager -=- Init")
    }
    
    func start() {
        isRunning = true
        locationManager.startUpdatingLocation()
        locationManager.startMonitoringSignificantLocationChanges()
        print("-=- LocationManager -=- Start")
    }
    
    func stop() {
        isRunning = false
        locationManager.stopUpdatingLocation()
        locationManager.stopMonitoringSignificantLocationChanges()
        startLocation = nil
        previousLocation = nil
        totalTravelledDistance = 0
        didUpdateLocationsCount = 0
        print("-=- LocationManager -=- Stop")
    }
    
    // MARK: - CLLocationManagerDelegate
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        print("-=- LocationManager -=- didUpdateLocations")

        var df: CLLocationDistance = 0
        guard let location = locations.last else { return }
        
        didUpdateLocationsCount += 1
        errorSum += location.horizontalAccuracy
        
        if startLocation == nil {
            startLocation = location
        }
        
        if previousLocation != nil {
            df = location.distance(from: previousLocation)
        }
        totalTravelledDistance += df
        previousLocation = location
        
        speedMS = round(location.speed * 100) / 100
        averageError = round((errorSum / Double(didUpdateLocationsCount)) * 100) / 100
        distanceBetweenStartAndLastLocations = startLocation.distance(from: location)
        
        NotificationCenter.default.post(name: .didReceivedLocation, object: nil)
    }
}
