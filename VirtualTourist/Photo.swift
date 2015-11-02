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
    
    init(content: [String:AnyObject], context: NSManagedObjectContext) {
        
        let entity = NSEntityDescription.entityForName("Photo", inManagedObjectContext: context)
        super.init(entity: entity!, insertIntoManagedObjectContext: context)

        id = Int(content[FlickrAPI.Flickr.TagId] as? String ?? "") ?? 0
        url = content[FlickrAPI.Flickr.TagUrlM] as? NSString ?? ""
        
        photoImage = imageWithIdentifier("\(id)");
    }
    
    func saveImageWithIdentifier() {
        
        let documentsDirectoryURL: NSURL = NSFileManager.defaultManager().URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask).first!
        let fullURL = documentsDirectoryURL.URLByAppendingPathComponent("\(id)")
        let path = fullURL.path!
        
        // And in documents directory
        let data = UIImagePNGRepresentation(photoImage!)!
        data.writeToFile(path, atomically: true)
    }
    
    private func imageWithIdentifier(identifier: String?) -> UIImage? {
        
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