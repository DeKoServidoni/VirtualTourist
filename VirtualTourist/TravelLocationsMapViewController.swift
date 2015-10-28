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

class TravelLocationsMapViewController: UIViewController, MapManagerDelegate, NSFetchedResultsControllerDelegate {
    
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
            try fetchedResultsController.performFetch()
        } catch {
            showErrorAlert("Failed to load the saved pins.")
        }
        
        fetchedResultsController.delegate = self
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        let pins = fetchedResultsController.fetchedObjects
        
        if let array = pins as? [Pin] {
            print("Pin list from CoreData: \(array.count)") //TODO: REMOVE HERE!! <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
            
            for item in array {
                mapManager.insertPin(item as Pin)
            }
        }
    }
    
    // MARK: Core data functions
    
    lazy var sharedContext: NSManagedObjectContext = {
       return CoreDataStackManager.sharedInstance().managedObjectContext
    }()
    
    // Save the context and handle the error if it occurrs
    private func saveContext() {
        do {
            try CoreDataStackManager.sharedInstance().saveContext()
        } catch {
            showErrorAlert("Failed to save the PIN on the map!")
        }
    }
    
    // fetched results to get the pins from the core data
    lazy var fetchedResultsController: NSFetchedResultsController = {
        
        let fetchRequest = NSFetchRequest(entityName: "Pin")
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "latitude", ascending: true)]
        
        let fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: self.sharedContext,
            sectionNameKeyPath: nil,cacheName: nil)

        return fetchedResultsController
        
    }()
    
    // MARK: Fetched results delegate
    
    func controller(controller: NSFetchedResultsController, didChangeObject anObject: AnyObject, atIndexPath indexPath: NSIndexPath?, forChangeType type: NSFetchedResultsChangeType, newIndexPath: NSIndexPath?) {

        switch type {
            
            case .Insert:
                mapManager.insertPin(anObject as! Pin)
                break
                
            case .Move:
                mapManager.updatePin(anObject as! Pin)
                break
                
            case .Delete:
                mapManager.deletePin(anObject as! Pin)
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
            pin.longitude = newCoordinates.longitude
            pin.latitude = newCoordinates.latitude

            saveContext()
        } else {
            showErrorAlert("Failed to update pin of the map!")
        }
    }

    func operationFinishedWithError(andMessage message: String) {
        showErrorAlert(message)
    }
    
    // MARK: Private functions
    
    // Get fetch Pin from location 
    private func fetchPinWith(coordinate: CLLocationCoordinate2D) -> Pin? {
        
        var pin: Pin? = nil
        
        let fetchRequest = NSFetchRequest(entityName: "Pin")
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "title", ascending: true)]
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
    
    // Show the error alert to the user
    private func showErrorAlert(message: String) {
        let alert = UIAlertController(title: "Error", message: message, preferredStyle: UIAlertControllerStyle.Alert)
        alert.addAction(UIAlertAction(title: "Ok", style: UIAlertActionStyle.Default, handler:nil))
        presentViewController(alert, animated: true, completion: nil)
    }
}