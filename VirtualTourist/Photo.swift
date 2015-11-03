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
    @NSManaged var url: NSString?
    @NSManaged var imgPath: NSString?
    @NSManaged var pin: Pin?
    
    var photoImage: UIImage? {
        
        get {
            return imageWithIdentifier()
        }
        
        set {
            saveImageWithIdentifier(newValue)
        }
    }
    
    override init(entity: NSEntityDescription, insertIntoManagedObjectContext context: NSManagedObjectContext?) {
        super.init(entity: entity, insertIntoManagedObjectContext: context)
    }
    
    init(content: [String:AnyObject], context: NSManagedObjectContext) {
        let entity = NSEntityDescription.entityForName("Photo", inManagedObjectContext: context)
        super.init(entity: entity!, insertIntoManagedObjectContext: context)

        id = Int(content[FlickrAPI.Flickr.TagId] as? String ?? "") ?? 0
        url = content[FlickrAPI.Flickr.TagUrlM] as? NSString ?? ""
    }
    
    // MARK: Private functions
    
    // get the image from file
    private func imageWithIdentifier() -> UIImage? {
        let path = getPath()
        
        if path != nil {
            if let data = NSData(contentsOfFile: path!) {
                return UIImage(data: data)
            }
        }
        
        return nil
    }
    
    // save the image in the path
    private func saveImageWithIdentifier(value: UIImage!) {
        
        let path = getPath()
        
        if path != nil {
            imgPath = path
            
            let data = UIImageJPEGRepresentation(value, 0.0)!
            data.writeToFile(imgPath! as String, atomically: true)
        }
    }
    
    // get image path
    private func getPath() -> String? {

        if url != "" {
            let identifier = NSURL(string: url as! String)?.lastPathComponent!
            
            let documentsDirectoryURL: NSURL = NSFileManager.defaultManager().URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask).first!
            
            return documentsDirectoryURL.URLByAppendingPathComponent(identifier!).path
        }
        
        return nil
    }
}