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
    @IBOutlet var spotButton: UIButton!
    @IBOutlet var centerButton: UIButton!

    var users = [User]()
    
    var userSpot: MKOverlay!
    var initialCenterUser = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
        locationManager.requestWhenInUseAuthorization()
        locationManager.distanceFilter = 10
        
        signIn()
        
        spotButton.layer.cornerRadius = 10
        
        // Create simulated users for testing
//        addTestUsers(_amount: 5)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func addTestUsers(_amount: Int) {
        print("Creating \(_amount) test users")
        let databaseRef = FIRDatabase.database().reference()
        
        for index in 1..._amount {
            let randomNumber = Double(arc4random_uniform(20))
            let secondRandomNumber = Double(arc4random_uniform(10))
            let latitude: CLLocationDegrees = 42.81850396193826 + (0.0005 * Double(index)) + (0.00025 * randomNumber) - (0.00015 * secondRandomNumber)
            let longitude: CLLocationDegrees = -75.54432160228076 + (0.0005 * Double(index)) + (0.00025 * randomNumber) - (0.00005 * secondRandomNumber)
            
            let userUpdates = ["latitude" : latitude, "longitude" : longitude, "lastUpdate": Date().timeIntervalSince1970, "username": "test_\(index)"] as [String : Any]
            databaseRef.child("locations").childByAutoId().updateChildValues(userUpdates)
        }
    }
    
    func signIn() {
        if FIRAuth.auth()?.currentUser != nil {
            print("User already signed in")
            self.locationManager.startUpdatingLocation()
            self.addObservers()
        }else {
            FIRAuth.auth()?.signInAnonymously(completion: { (user, error) in
                if error != nil {
                    print("Error signing in:", error)
                } else {
                    print("Signed in anonymously")
                    self.showUsernameAlert()
                    self.addObservers()
                }
            })
        }
    }
    
    func showUsernameAlert() {
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
                    let latitude = locationDict["latitude"] as! CLLocationDegrees
                    let longitude = locationDict["longitude"] as! CLLocationDegrees
                    
                    let location = CLLocation(latitude: latitude, longitude: longitude)
                    let name = locationDict.value(forKey: "username") as? String ?? ""
                    let lastUpdate = locationDict.value(forKey: "lastUpdate") as? TimeInterval ?? 0.0

                    let newUser = User(id: snapshot.key, name: name, location: location, lastUpdate: lastUpdate)
                    self.users.append(newUser)

                    let pin = UserAnnotation(_user: newUser)
                    self.mapView.addAnnotation(pin)
                    print("Added new pin")
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
                            print("Added new pin")
                        }
                    }
                }
            }
        })
        
        databaseRef.child("locations").observe(.childRemoved, with: { (snapshot) -> Void in
            if snapshot.key != FIRAuth.auth()?.currentUser?.uid {
                print("Child removed:", snapshot.key)
                
                for (index, _) in self.users.enumerated() {
                    for pin in self.mapView.annotations {
                        if pin is UserAnnotation {
                            if (pin as! UserAnnotation).id == snapshot.key {
                                self.users.remove(at: index)
                                self.mapView.removeAnnotation(pin)
                                print("Removed deleted pin")
                            }
                        }
                    }
                }
            }
        })
    }
    
    @IBAction func spotButtonAction(_ sender: UIButton) {
        if sender.currentTitle! == "Enable Spot" {
            sender.setTitle("Disable Spot", for: .normal)
            sender.backgroundColor = UIColor(red: 237/255, green: 106/255, blue: 94/255, alpha: 1)
            enableSpot()
        } else {
            sender.setTitle("Enable Spot", for: .normal)
            sender.backgroundColor = UIColor(red: 41/255, green: 171/255, blue: 226/255, alpha: 1)
            disableSpot()
        }
    }
    
    func enableSpot() {
        let userLocation = locationManager.location?.coordinate
        let circle = MKCircle(center: userLocation!, radius: 50)
        self.userSpot = circle
        
        self.mapView.addOverlays([circle])
    }
    
    func disableSpot() {
        self.mapView.remove(userSpot)
    }
    
    @IBAction func centerButtonAction(_ sender: UIButton) {
        centerUser(_initial: false)
    }
    
    func centerUser(_initial: Bool) {
        let userLocation = locationManager.location?.coordinate

        if _initial {
            // Set view relatively high
            let span = MKCoordinateSpanMake(0.012, 0.012)
            let region = MKCoordinateRegion(center: userLocation!, span: span)
            mapView.setRegion(region, animated: true)
        } else {
            // Maintain region span
            var region = mapView.region
            region.center = userLocation!
            mapView.setRegion(region, animated: true)
        }
    }

}

extension ViewController: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        if status == .authorizedWhenInUse {
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let location = locations.first {
            
            if !initialCenterUser {
                initialCenterUser = true
                centerUser(_initial: true)
            }
            saveLocation(location)
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location manager failed with error:", error)
    }
    
}

extension ViewController: MKMapViewDelegate {
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        if annotation is MKUserLocation {
            return nil
        }
        
        let annotationId = "userDotAnnotation"
        
        var anView = mapView.dequeueReusableAnnotationView(withIdentifier: annotationId)
        if anView == nil {
            if annotation is UserAnnotation {
                anView = MKAnnotationView(annotation: annotation, reuseIdentifier: annotationId)
                anView?.image = UIImage(named: "userDot")
            }
            // True if want to show bubble
            anView?.canShowCallout = false
        } else {
            anView?.annotation = annotation
        }
        return anView
    }
    
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        let circleRenderer = MKCircleRenderer(overlay: overlay)
        circleRenderer.fillColor = UIColor.green.withAlphaComponent(0.1)
        circleRenderer.strokeColor = UIColor.green
        circleRenderer.lineWidth = 1
        return circleRenderer
    }
}

struct User {
    var id: String!
    var name: String!
    var location: CLLocation!
    var lastUpdate: TimeInterval!
}

