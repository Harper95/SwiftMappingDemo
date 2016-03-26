//
//  DataStore.swift
//  Mapper
//
//  Created by hollarab on 2/24/16.
//  Copyright © 2016 a. brooks hollar. All rights reserved.
//

import Foundation
import Alamofire
import SwiftyJSON
import MapKit
import AddressBook
import Contacts

let kDateString = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
let kLoadedNotification = "com.ctharper.mapper.loaded"
let kLoadingNotification = "com.ctharper.mapper.loading"

let smallQuakeListURL = NSURL(string: "https://aqueous-depths-77407.herokuapp.com/earthquakes.json")      // 100 Earthquakes
let largeQuakeListURL = NSURL(string: "https://earthquake-grapher.herokuapp.com/earthquakes.json")        // 10000 Earthquakes

struct Earthquake {
    var id:Int
    var long:Double
    var lat:Double
    var mag:Float
    var date:NSDate
    var place:String
}

class EarthquakeAnotation: NSObject, MKAnnotation {
	var earthquake: Earthquake
	var coordinate: CLLocationCoordinate2D
	
	init(earthquake: Earthquake) {
		self.earthquake = earthquake
		self.coordinate = CLLocationCoordinate2D(latitude: earthquake.lat, longitude: earthquake.long)
	}
	
	var title: String? {	// Calculated Parameter
		return "Mag: \(earthquake.mag.format("0.2"))"
	}
	
	var subtitle: String? {
		return earthquake.place
	}
	
	func mapItem() -> MKMapItem {
		let addressDictionary:[String:AnyObject]? = [CNPostalAddressStreetKey: subtitle ?? "no info"]
		let placemark = MKPlacemark(coordinate: coordinate, addressDictionary: addressDictionary)
		
		let mapItem = MKMapItem(placemark: placemark)
		mapItem.name = title
		
		return mapItem
	}
	
	func pinTintColor() -> UIColor {
		switch earthquake.mag {
		case 0..<0.5:
			return UIColor.greenColor()
		case 0.5..<1:
			return UIColor.blueColor()
		case 1..<1.5:
			return UIColor.yellowColor()
		case 1.5..<2:
			return UIColor.magentaColor()
		case 2..<3:
			return UIColor.orangeColor()
		default:
			return UIColor.redColor()
		}
	}
}

class DataStore {
    static var sharedInstance = DataStore()
    var earthquakes = [Earthquake]()
    
    private var currentURL = smallQuakeListURL
	
	private init() {}
	
	func setUserLargeList(useLarge: Bool) {
		if useLarge {
			currentURL = largeQuakeListURL
		} else {
			currentURL = smallQuakeListURL
		}
		loadData()
	}
	
	func usingLargeSet() -> Bool {
		return currentURL === largeQuakeListURL
	}
	
    func loadData() {
		NSNotificationCenter.defaultCenter().postNotificationName(kLoadingNotification, object: nil)
        earthquakes = [Earthquake]()
        Alamofire.request(.GET, currentURL!).validate().responseJSON { response in
            switch response.result {
            case .Success:
                if let value = response.result.value {
                    let json = JSON(value)
                    for item in json.arrayValue {
                        let id = item["id"].intValue
                        let long = item["longitude"].doubleValue
                        let lat = item["latitude"].doubleValue
                        let mag = item["mag"].floatValue
                        let dateString = item["time"].stringValue
                        let place = item["place"].stringValue
                        
                        let date = self.dateFromString(dateString) ?? NSDate()
                        
                        self.earthquakes.append(Earthquake(id: id, long: long, lat: lat, mag: mag, date: date, place: place))
                    }
                }
				
				NSNotificationCenter.defaultCenter().postNotificationName(kLoadedNotification, object: nil)

            case .Failure(let error):
                print(error)
            }
        }
    }

    
    func dateFromString(string:String) -> NSDate? {
        let formatter = NSDateFormatter()
        formatter.dateFormat = kDateString
        return formatter.dateFromString(string)
    }
    
}