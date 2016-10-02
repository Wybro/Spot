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
    
    init(_user: User) {
        self.id = _user.id
        self.coordinate = CLLocationCoordinate2DMake(_user.location.coordinate.latitude, _user.location.coordinate.longitude)
        self.title = _user.name
        self.subtitle = _user.lastUpdate.convertReadable()
        
        super.init()
    }
    
}

extension TimeInterval {
    
    func convertReadable() -> String {
        let trueInterval = (Date().timeIntervalSince1970 - self) as Double
        
        let days = trueInterval / secondsPerDay
        let hours = days * 24.0
        let minutes = hours * 60.0

        if days >= 1 {
            if days < 2 {
                return "\(Int(days)) day ago"
            }
            return "\(Int(days)) days ago"
        } else if hours >= 1 {
            if hours < 2 {
                return "\(Int(hours)) hour ago"
            }
            return "\(Int(hours)) hours ago"
        } else if minutes >= 1 {
            if minutes < 2 {
                return "\(Int(minutes)) minute ago"
            }
            return "\(Int(minutes)) minutes ago"
        } else {
            return "Now"
        }
    }
}
