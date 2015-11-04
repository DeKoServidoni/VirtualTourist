//
//  TravelLocationsMapViewController.swift
//  VirtualTourist
//
//  Created by André Servidoni on 10/25/15.
//  Copyright © 2015 Udacity. All rights reserved.
//

import Foundation
import UIKit
import MapKit
import CoreData

class TravelLocationsMapViewController: BaseViewController, MapManagerDelegate, NSFetchedResultsControllerDelegate {
    
    @IBOutlet weak var mapView: MKMapView!
    
    var mapManager: MapManager!
    
    // MARK: Application lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // load map information (zoom and center)
        mapManager = MapManager(mapView: mapView, sharedContext: sharedContext, delegate: self)
        mapManager.prepareMap()
        
        // set map delegate
        mapView.delegate = mapManager
        
        // load saved pins
        do {
            try fetchedPinResultsController.performFetch()
        } catch {
            showErrorAlert("Failed to load the saved pins.")
        }
        
        fetchedPinResultsController.delegate = self
        
        // initialize the map with the pins
        let pins = fetchedPinResultsController.fetchedObjects
        
        if let array = pins as? [Pin] {
            for item in array {
                let pin = item as Pin
                pin.setCoordinateTitle()
                
                mapManager.insertPin(pin)
            }
        }
    }
    
    // MARK: Fetched results delegate
    
    func controller(controller: NSFetchedResultsController, didChangeObject anObject: AnyObject, atIndexPath indexPath: NSIndexPath?, forChangeType type: NSFetchedResultsChangeType, newIndexPath: NSIndexPath?) {

        switch type {
            
            case .Insert:
                mapManager.insertPin(anObject as! Pin)
                break
                
            case .Move:
                mapManager.updatePin(anObject as! Pin)
                break
                
            default:
                // do nothing
                return
        }
    }
    
    // MARK: Map manager delegate
    
    // insert pin in the core data
    func operationInsert(coordinate: CLLocationCoordinate2D?) {
        
        guard let coordinates = coordinate as CLLocationCoordinate2D! else {
            showErrorAlert("Invalid coordinates!")
            return
        }
        
        let pin = Pin(latitude: coordinates.latitude, longitude: coordinates.longitude, context: sharedContext)
        sharedContext.insertObject(pin)
        saveContext()
    }
    
    // delete pin of the core data
    func operationDelete(coordinate: CLLocationCoordinate2D?) {
        
        guard let coordinates = coordinate as CLLocationCoordinate2D! else {
            showErrorAlert("Invalid coordinates!")
            return
        }
        
        let founded = fetchPinWith(coordinates)
        
        if let pin = founded {
            sharedContext.deleteObject(pin)
            saveContext()
        } else {
            showErrorAlert("Failed to delete pin of the map!")
        }
    }
    
    // update pin in the core data
    func operationUpdate(coordinate: CLLocationCoordinate2D?, to newCoordinate: CLLocationCoordinate2D?) {
        
        guard let coordinates = coordinate as CLLocationCoordinate2D! else {
            showErrorAlert("Invalid coordinates!")
            return
        }
        
        guard let newCoordinates = newCoordinate as CLLocationCoordinate2D! else {
            showErrorAlert("Invalid coordinates!")
            return
        }
        
        let founded = fetchPinWith(coordinates)
        
        if let pin = founded {
            
            // delete all photos from the core data of the previous coordinate
            cleanPhotosOf(pin)
            
            pin.longitude = newCoordinates.longitude
            pin.latitude = newCoordinates.latitude
            pin.setCoordinateTitle()

            saveContext()
        } else {
            showErrorAlert("Failed to update pin of the map!")
        }
    }
    
    // show the album view controller of that pin coordinates
    func operationClick(coordinate: CLLocationCoordinate2D?) {
        
        let pin = fetchPinWith(coordinate!)
        
        let photoAlbumViewController = storyboard!.instantiateViewControllerWithIdentifier("photoAlbum") as! PhotoAlbumViewController
        photoAlbumViewController.pin = pin
        
        navigationController?.pushViewController(photoAlbumViewController, animated: true)
    }

    // show the error of any operation
    func operationFinishedWithError(andMessage message: String) {
        showErrorAlert(message)
    }
    
    // MARK: Private functions
    
    // remove all photos from the pin
    func cleanPhotosOf(pin: Pin) {
        
        do {
            let fetchRequest = NSFetchRequest(entityName: "Photo")
            fetchRequest.sortDescriptors = [NSSortDescriptor(key: "id", ascending: true)]
            fetchRequest.predicate = NSPredicate(format: "pin == %@", pin);
            
            let photos = try sharedContext.executeFetchRequest(fetchRequest) as! [Photo]
            
            for item in photos {
                
                let photo = item as Photo
                photo.deletePhotoAtDisk()
                
                sharedContext.deleteObject(photo)
            }
            
            saveContext()
            
        } catch {
            showErrorAlert("Failed to clean photos after move the pin")
        }
    }

    
    // Get fetch Pin from location 
    private func fetchPinWith(coordinate: CLLocationCoordinate2D) -> Pin? {
        
        var pin: Pin? = nil
        
        let fetchRequest = NSFetchRequest(entityName: "Pin")
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "latitude", ascending: true)]
        fetchRequest.predicate = NSPredicate(format:"latitude == %lf and longitude == %lf", coordinate.latitude, coordinate.longitude)
        
        do {
            let results = try sharedContext.executeFetchRequest(fetchRequest) as? [Pin]
            
            if let pins = results {
                if pins.count > 0 {
                    pin = pins[0] as Pin
                }
            }
            
        } catch {
            pin = nil
        }

        return pin
    }
    
    // fetched results to get the pins from the core data
    lazy var fetchedPinResultsController: NSFetchedResultsController = {
        
        let fetchRequest = NSFetchRequest(entityName: "Pin")
        fetchRequest.sortDescriptors = []
        
        let fetchedPinResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: self.sharedContext,
            sectionNameKeyPath: nil,cacheName: nil)
        
        return fetchedPinResultsController
        
        }()
}