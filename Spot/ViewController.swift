//
//  ViewController.swift
//  Spot
//
//  Created by Connor Wybranowski on 9/30/16.
//  Copyright © 2016 com.Wybro. All rights reserved.
//

import UIKit
import MapKit
import Firebase
import FirebaseDatabase

class ViewController: UIViewController {
    
    var locationManager = CLLocationManager()
    var currentLocation: CLLocation?

    @IBOutlet var mapView: MKMapView!
    
//    var userLocations = [CLLocation]()
    var users = [User]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
        locationManager.requestWhenInUseAuthorization()
        locationManager.distanceFilter = 10
//        locationManager.requestLocation()
        
        FIRAuth.auth()?.signInAnonymously(completion: { (user, error) in
            if error != nil {
                print("Error signing in:", error)
            } else {
//                if let user = user {
////                    self.currentUserId = user.uid
//                }
                self.addObservers()
            }
        })
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func saveLocation(_ location: CLLocation) {
        guard FIRAuth.auth()?.currentUser != nil else {
            return
        }
        let databaseRef = FIRDatabase.database().reference()
        let locationCoords = ["latitude": location.coordinate.latitude, "longitude" : location.coordinate.longitude]
        databaseRef.child("locations").child((FIRAuth.auth()?.currentUser?.uid)!).setValue(locationCoords) { (error, dbRef) in
            if error != nil {
                print("Error setting value:", error)
            } else {
                print("Saved value in database")
            }
        }
    }
    
    func addObservers() {
        let databaseRef = FIRDatabase.database().reference()

        databaseRef.child("locations").observe(.childAdded, with: { (snapshot) -> Void in
            if snapshot.key != FIRAuth.auth()?.currentUser?.uid {
                if let locationDict = snapshot.value as? NSDictionary {
                    print("New child")
                    let latitude = locationDict["latitude"] as! CLLocationDegrees
                    let longitude = locationDict["longitude"] as! CLLocationDegrees
                    
                    let location = CLLocation(latitude: latitude, longitude: longitude)
                    
                    let newUser = User(id: snapshot.key, location: location)
                    
                    self.users.append(newUser)

                    let pin = UserAnnotation(_userId: newUser.id, _userLocation: newUser.location, _title: "", _subtitle: "")
                    self.mapView.addAnnotation(pin)
                    print("Added new pin -- CREATION")
                }
            }
        })
        
        databaseRef.child("locations").observe(.childChanged, with: { (snapshot) -> Void in
            if snapshot.key != FIRAuth.auth()?.currentUser?.uid {
                print("Child changed:", snapshot.key)
                for (index, user) in self.users.enumerated() {
                    if snapshot.key == user.id {
                        // Existing user - delete old pin
                        print("Found existing user in arr:", user.id)
                        for pin in self.mapView.annotations {
                            if pin is UserAnnotation {
                                if (pin as! UserAnnotation).id == user.id {
                                    self.mapView.removeAnnotation(pin)
                                    print("Removed old pin")
                                }
                            }
                        }
                        
                        if let locationDict = snapshot.value as? NSDictionary {
                            let latitude = locationDict["latitude"] as! CLLocationDegrees
                            let longitude = locationDict["longitude"] as! CLLocationDegrees
                            
                            let location = CLLocation(latitude: latitude, longitude: longitude)
                            
                            let newUser = User(id: snapshot.key, location: location)
                            
                            self.users[index] = newUser

                            let pin = UserAnnotation(_userId: newUser.id, _userLocation: newUser.location, _title: "", _subtitle: "")
                            self.mapView.addAnnotation(pin)
                            print("Added new pin -- UPDATE")
                        }
                    }
                }
            }
        })
    }

}

extension ViewController: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        if status == .authorizedWhenInUse {
//            locationManager.requestLocation()
            locationManager.startUpdatingLocation()
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let location = locations.first {
            let span = MKCoordinateSpanMake(0.002, 0.002)
            let region = MKCoordinateRegion(center: location.coordinate, span: span)
            mapView.setRegion(region, animated: true)
            
            saveLocation(location)
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location manager failed with error:", error)
    }
    
}

struct User {
    var id: String!
    var location: CLLocation!
}

