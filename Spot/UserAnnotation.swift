//
//  UserAnnotation.swift
//  Spot
//
//  Created by Connor Wybranowski on 10/1/16.
//  Copyright © 2016 com.Wybro. All rights reserved.
//

import MapKit

// Constants
let secondsPerDay: Double = 86400.0

class UserAnnotation: NSObject, MKAnnotation {
    let id: String
    let coordinate: CLLocationCoordinate2D
    let title: String?
    let subtitle: String?
    
    //    init(_userId: String, _userCoordinate: CLLocationCoordinate2D, _title: String, _subtitle: String) {
    init(_userId: String, _userLocation: CLLocation, _title: String, _subtitle: String) {
        self.id = _userId
        self.coordinate = CLLocationCoordinate2DMake(_userLocation.coordinate.latitude, _userLocation.coordinate.longitude)
        self.title = _title
        self.subtitle = _subtitle
        
        super.init()
    }
    
    init(_user: User) {
        self.id = _user.id
        self.coordinate = CLLocationCoordinate2DMake(_user.location.coordinate.latitude, _user.location.coordinate.longitude)
        self.title = _user.name
//        self.subtitle = TimeInterval.convertReadable(_user.lastUpdate)
        self.subtitle = _user.lastUpdate.convertReadable()
        
        super.init()
    }
    
    func convertReadable(_interval: TimeInterval) -> String {
        let trueInterval = (Date().timeIntervalSince1970 - _interval) as Double
        
        let days = trueInterval / secondsPerDay
        let hours = days * 24.0
        let minutes = hours * 60.0
        //        let seconds = (60 * minutes) % 60
        
        if days >= 1 {
            return "\(Int(days)) days ago"
        } else if hours >= 1 {
            return "\(Int(hours)) hours ago"
        } else if minutes >= 1 {
            return "\(Int(minutes)) minutes ago"
        } else {
            return "Now"
        }
    }
    
}

extension TimeInterval {
    
    func convertReadable() -> String {
//    func convertReadable(_interval: TimeInterval) -> String {
        let trueInterval = (Date().timeIntervalSince1970 - self) as Double
        
        let days = trueInterval / secondsPerDay
        let hours = days * 24.0
        let minutes = hours * 60.0
        //        let seconds = (60 * minutes) % 60
        
        if days >= 1 {
            return "\(Int(days)) days ago"
        } else if hours >= 1 {
            return "\(Int(hours)) hours ago"
        } else if minutes >= 1 {
            return "\(Int(minutes)) minutes ago"
        } else {
            return "Now"
        }
    }
}
