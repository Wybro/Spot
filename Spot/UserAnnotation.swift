//
//  UserAnnotation.swift
//  Spot
//
//  Created by Connor Wybranowski on 10/1/16.
//  Copyright © 2016 com.Wybro. All rights reserved.
//

import MapKit

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

}
