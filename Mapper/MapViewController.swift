//
//  ViewController.swift
//  Mapper
//
//  Created by hollarab on 2/24/16.
//  Copyright © 2016 a. brooks hollar. All rights reserved.
//

import UIKit
import MapKit

class MapViewController: UIViewController {

    @IBOutlet weak var myMapView: MKMapView!
    @IBOutlet weak var infoButton: UIButton!
    @IBOutlet var myLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
		
		myMapView.delegate = self
		centerMapOnLocation(initialLocation)
		addWestminsterQuake()
		checkLocationAuthorizationStatus()
		
		NSNotificationCenter.defaultCenter().addObserver(self, selector: "dataUpdated", name: kLoadedNotification, object: nil)
		NSNotificationCenter.defaultCenter().addObserver(self, selector: "dataWillUpdate", name: kLoadingNotification, object: nil)
        DataStore.sharedInstance.loadData()
    }

    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
    }

    
    // MARK: - Inital Location
    let regionRadius: CLLocationDistance = 5_000_000                                // 5 Million Meters - underscores are convenience
//    let initialLocation = CLLocation(latitude: 21.282778, longitude: -157.829444)   // Honalulu, CO
    let initialLocation = CLLocation(latitude: 39.8361, longitude: -105.0372)      // Westminster, CO

	func centerMapOnLocation(location: CLLocation) {
		let coordinateRegion = MKCoordinateRegionMakeWithDistance(location.coordinate, regionRadius * 2.0, regionRadius * 2.0)
		myMapView.setRegion(coordinateRegion, animated: true)
	}
	
	func addWestminsterQuake() {
		let quake = Earthquake(id: 1, long: -105.0372, lat: 39.8361, mag: 1.3, date: NSDate(), place: "DaVinci Coders")
		let annotation = EarthquakeAnotation(earthquake: quake)
		myMapView.addAnnotation(annotation)
	}
	
	// MARK: - location manager to authorize user location
	var locationManager = CLLocationManager()
	func checkLocationAuthorizationStatus() {
		locationManager.delegate = self
		if CLLocationManager.authorizationStatus() == .AuthorizedWhenInUse {
			myMapView.showsUserLocation = true
		} else {
			locationManager.requestWhenInUseAuthorization()
		}
	}
	
	// MARK: - Observers
	func dataUpdated() {
		myLabel.text = "\(DataStore.sharedInstance.earthquakes.count) events"
		for quake in DataStore.sharedInstance.earthquakes {
			let anotation = EarthquakeAnotation(earthquake: quake)
			myMapView.addAnnotation(anotation)
		}
	}
	
	func dataWillUpdate() {
		myLabel.text = "Loading..."
		myMapView.removeAnnotations(myMapView.annotations)
	}
}

// MARK: - Navigation and Unwind seques
extension MapViewController {
    
    @IBAction func infoButtonTouched(sender:AnyObject) {
        performSegueWithIdentifier("Info", sender: self)
    }
    
    @IBAction func mapInfoDismissed(segue:UIStoryboardSegue) {
        print("unwind segues reached")
    }
}

extension MapViewController: MKMapViewDelegate {
	
	func mapView(mapView: MKMapView, viewForAnnotation annotation: MKAnnotation) -> MKAnnotationView? {
		if let annotation = annotation as? EarthquakeAnotation {
			let identifier = "pin"
			var view: MKPinAnnotationView?
			if let dequeuedView = mapView.dequeueReusableAnnotationViewWithIdentifier(identifier) as? MKPinAnnotationView {
				dequeuedView.annotation = annotation
				view = dequeuedView
			} else {
				view = MKPinAnnotationView(annotation: annotation, reuseIdentifier: identifier)
				view?.canShowCallout = true
				view?.calloutOffset = CGPoint(x: -5, y: 5)
				view?.rightCalloutAccessoryView = UIButton(type: .DetailDisclosure)
			}
			
			view?.pinTintColor = annotation.pinTintColor()
			
			return view!
		}
		return nil
	}
	
	func mapView(mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
		guard let location = view.annotation as? EarthquakeAnotation else { return }
		
		let launchOptions = [MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving]
		location.mapItem().openInMapsWithLaunchOptions(launchOptions)
	}
}

extension MapViewController: CLLocationManagerDelegate {
	func locationManager(manager: CLLocationManager, didChangeAuthorizationStatus status: CLAuthorizationStatus) {
		if status == .AuthorizedWhenInUse {
			myMapView.showsUserLocation = true
		}
	}
}


