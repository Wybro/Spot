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
                let alertController = UIAlertController(title: "Enter your name", message: "", preferredStyle: .alert)
                var nameTextField = UITextField()
                nameTextField.placeholder = "Name"
                let confirmAction = UIAlertAction(title: "Confirm", style: .default, handler: { (action) in
                    if !nameTextField.text!.isEmpty {
                        self.setUsername(_name: nameTextField.text!)
                    }
                })
                
                alertController.addTextField(configurationHandler: { (textfield) in
                    textfield.placeholder = "Name"
                    textfield.autocapitalizationType = .words
                    nameTextField = textfield
                })
                alertController.addAction(confirmAction)
                self.present(alertController, animated: true, completion: nil)
                
                self.addObservers()
            }
        })
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func setUsername(_name: String) {
        let databaseRef = FIRDatabase.database().reference()

        databaseRef.child("locations").child((FIRAuth.auth()?.currentUser?.uid)!).updateChildValues(["username" : _name]) { (error, ref) in
            if error != nil {
                print("Error saving name", error)
            } else {
                print("Saved name")
                self.locationManager.startUpdatingLocation()
            }
        }
    }
    
    func saveLocation(_ location: CLLocation) {
        guard FIRAuth.auth()?.currentUser != nil else {
            return
        }
        let databaseRef = FIRDatabase.database().reference()
        let userUpdates = ["latitude": location.coordinate.latitude, "longitude" : location.coordinate.longitude, "lastUpdate" : Date().timeIntervalSince1970]
        databaseRef.child("locations").child((FIRAuth.auth()?.currentUser?.uid)!).updateChildValues(userUpdates) { (error, dbRef) in
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
                    let name = locationDict.value(forKey: "username") as? String ?? ""
                    let lastUpdate = locationDict.value(forKey: "lastUpdate") as? TimeInterval ?? 0.0

                    let newUser = User(id: snapshot.key, name: name, location: location, lastUpdate: lastUpdate)
                    self.users.append(newUser)

                    let pin = UserAnnotation(_user: newUser)
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
                            let name = locationDict.value(forKey: "username") as? String ?? ""
                            let lastUpdate = locationDict.value(forKey: "lastUpdate") as? TimeInterval ?? 0.0
                            
                            let newUser = User(id: snapshot.key, name: name, location: location, lastUpdate: lastUpdate)
                            self.users[index] = newUser

                            let pin = UserAnnotation(_user: newUser)
                            self.mapView.addAnnotation(pin)
                            print("Added new pin -- UPDATE")
                        }
                    }
                }
            }
        })
        
        databaseRef.child("locations").observe(.childRemoved, with: { (snapshot) -> Void in
            if snapshot.key != FIRAuth.auth()?.currentUser?.uid {
                print("Child removed:", snapshot.key)
                
                for (index, user) in self.users.enumerated() {
                    for pin in self.mapView.annotations {
                        if pin is UserAnnotation {
                            if (pin as! UserAnnotation).id == user.id {
                                self.mapView.removeAnnotation(pin)
                                self.users.remove(at: index)
                                print("Removed deleted pin")
                            }
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
//            locationManager.startUpdatingLocation()
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
    var name: String!
    var location: CLLocation!
    var lastUpdate: TimeInterval!
}

