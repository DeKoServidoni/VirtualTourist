//
//  Pin.swift
//  VirtualTourist
//
//  Created by André Servidoni on 10/25/15.
//  Copyright © 2015 Udacity. All rights reserved.
//

import Foundation
import CoreData
import MapKit

// Class responsible to represent a PIN in the core data model
class Pin: NSManagedObject, MKAnnotation {
    
    @NSManaged var latitude: NSNumber
    @NSManaged var longitude: NSNumber
    @NSManaged var photos: [Photo]
    
    private var _coords: CLLocationCoordinate2D?
    var coordinate: CLLocationCoordinate2D {
        
        set (newCoordinate) { _coords = newCoordinate }
        
        get {
            if _coords == nil {
                _coords = CLLocationCoordinate2DMake(latitude as CLLocationDegrees, longitude as CLLocationDegrees)
            }
            
            return _coords!
        }
    }
    
    var title: String?
    var subtitle: String?
    
    override init(entity: NSEntityDescription, insertIntoManagedObjectContext context: NSManagedObjectContext?) {
        super.init(entity: entity, insertIntoManagedObjectContext: context)
    }
    
    init(latitude: NSNumber, longitude: NSNumber, context: NSManagedObjectContext) {
        
        let entity = NSEntityDescription.entityForName("Pin", inManagedObjectContext: context)
        super.init(entity: entity!, insertIntoManagedObjectContext: context)
        
        self.latitude = latitude
        self.longitude = longitude
        
        coordinate = CLLocationCoordinate2DMake(latitude as CLLocationDegrees, longitude as CLLocationDegrees)
    }
}
