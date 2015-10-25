//
//  MapInfo.swift
//  VirtualTourist
//
//  Created by André Servidoni on 10/25/15.
//  Copyright © 2015 Udacity. All rights reserved.
//

import Foundation
import CoreData

// Class responsible to represent the current location of the user, in the map, in the core data model
class MapInfo: NSManagedObject {
    
    struct Keys {
        static let Longitude = "longitude"
        static let Latitude = "latitude"
        static let LatitudeDelta = "latitudeDelta"
        static let LongitudeDelta = "longitudeDelta"
    }
    
    @NSManaged var latitude: NSNumber
    @NSManaged var longitude: NSNumber
    @NSManaged var latitudeDelta: NSNumber
    @NSManaged var longitudeDelta: NSNumber
    
    override init(entity: NSEntityDescription, insertIntoManagedObjectContext context: NSManagedObjectContext?) {
        super.init(entity: entity, insertIntoManagedObjectContext: context)
    }
    
    init(dictionary: [String : AnyObject], context: NSManagedObjectContext) {
        
        let entity = NSEntityDescription.entityForName("MapInfo", inManagedObjectContext: context)
        super.init(entity: entity!, insertIntoManagedObjectContext: context)
        
        setValues(dictionary)
    }
    
    func setValues(dictionary: [String : AnyObject]) {
        self.latitude = dictionary[Keys.Latitude] as! NSNumber
        self.longitude = dictionary[Keys.Longitude] as! NSNumber
        self.latitudeDelta = dictionary[Keys.LatitudeDelta] as! NSNumber
        self.longitudeDelta = dictionary[Keys.LongitudeDelta] as! NSNumber
    }
}
