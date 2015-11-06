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
    
    var newPin: Pin?
    
    // fetched results to get the pins from the core data
    lazy var fetchedPinResultsController: NSFetchedResultsController = {
        
        let fetchRequest = NSFetchRequest(entityName: "Pin")
        fetchRequest.sortDescriptors = []
        
        let fetchedPinResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: self.sharedContext,
            sectionNameKeyPath: nil,cacheName: nil)
        
        return fetchedPinResultsController
        
        }()
    
    // MARK: Application lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.Trash, target: self, action: "cleanPins")
        
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
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        // initialize the map with the pins
        let pins = fetchedPinResultsController.fetchedObjects
        
        if let array = pins as? [Pin] {
            for item in array {
                let pin = item as Pin
                
                mapManager.insertPin(pin)
            }
        }
    }
    
    // MARK: Action functions
    
    // remove all pins from the map view
    func cleanPins() {
        
        let pins = fetchedPinResultsController.fetchedObjects as! [Pin]
        for item in pins {
            let pin = item as Pin
            sharedContext.deleteObject(pin)
        }
        
        saveContext()
    }
    
    // handle the touch and hold functionality
    @IBAction func addPinToMap(sender: UILongPressGestureRecognizer) {
     
        let tapPosition:CGPoint = sender.locationInView(self.mapView)
        let coordinates = mapView.convertPoint(tapPosition, toCoordinateFromView: mapView)
        
        switch sender.state {
        case .Began:
            newPin = Pin(latitude: coordinates.latitude, longitude: coordinates.longitude, context: sharedContext)
            break
            
        case .Changed:
            newPin!.coordinate = coordinates
            break
            
        case .Ended:
            saveContext()
            break
            
        default:
            // do nothing
            break
        }
    }
    
    // MARK: Fetched results delegate
    
    func controller(controller: NSFetchedResultsController, didChangeObject anObject: AnyObject, atIndexPath indexPath: NSIndexPath?, forChangeType type: NSFetchedResultsChangeType, newIndexPath: NSIndexPath?) {

        switch type {
            
            case .Insert:
                mapManager.insertPin(anObject as! Pin)
                break
            
            case .Delete:
                mapManager.removePin(anObject as! Pin)
                break
            
            default:
                // do nothing
                return
        }
    }
    
    // MARK: Map manager delegate
    
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
}