//
//  Photo.swift
//  VirtualTourist
//
//  Created by André Servidoni on 10/25/15.
//  Copyright © 2015 Udacity. All rights reserved.
//

import Foundation
import CoreData
import UIKit

// Class responsible to represent a PHOTO in the core data model
class Photo: NSManagedObject {
    
    @NSManaged var id: NSNumber
    @NSManaged var url: NSString
    @NSManaged var imgPath: NSString?
    @NSManaged var pin: Pin?
    
    var photoImage: UIImage?
    
    override init(entity: NSEntityDescription, insertIntoManagedObjectContext context: NSManagedObjectContext?) {
        super.init(entity: entity, insertIntoManagedObjectContext: context)
    }
    
    init(id: NSNumber, url: NSString, imgPath: NSString?, context: NSManagedObjectContext) {
        
        let entity = NSEntityDescription.entityForName("Photo", inManagedObjectContext: context)
        super.init(entity: entity!, insertIntoManagedObjectContext: context)
        
        self.id = id
        self.url = url
        self.imgPath = imgPath
        
        photoImage = imageWithIdentifier("\(id)");
    }
    
    func imageWithIdentifier(identifier: String?) -> UIImage? {
        
        // If the identifier is nil, or empty, return nil
        if identifier == nil || identifier! == "" {
            return nil
        }
        
        let documentsDirectoryURL: NSURL = NSFileManager.defaultManager().URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask).first!
        let fullURL = documentsDirectoryURL.URLByAppendingPathComponent(identifier!)
        let path = fullURL.path!
        
        // Next Try the hard drive
        if let data = NSData(contentsOfFile: path) {
            return UIImage(data: data)
        }
        
        return nil
    }
}