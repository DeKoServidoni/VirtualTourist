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

class TravelLocationsMapViewController: UIViewController, MKMapViewDelegate, NSFetchedResultsControllerDelegate {
    
    @IBOutlet weak var mapView: MKMapView!
    
    var mapInfo: MapInfo!
    var pins: [Pin]!
    
    // MARK: Application lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // load map information (zoom and center)
        //TODO
        
        // load saved pins
        do {
            try fetchedResultsController.performFetch()
        } catch {
            showErrorAlert("Failed to load the saved pins.")
        }
        
        fetchedResultsController.delegate = self
    }
    
    // MARK: Core data
    
    lazy var sharedContext: NSManagedObjectContext = {
       return CoreDataStackManager.sharedInstance().managedObjectContext
    }()
    
    // fetched results to get the pins from the core data
    lazy var fetchedResultsController: NSFetchedResultsController = {
        
        let fetchRequest = NSFetchRequest(entityName: "Pin")
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "latitude", ascending: true)]
        
        let fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: self.sharedContext,
            sectionNameKeyPath: nil,cacheName: nil)
        
        return fetchedResultsController
        
    }()
    
    // MARK: Private functions
    
    // Save the context and handle the error if it occurrs
    private func saveContextInCoreData() {
        
        do {
            try CoreDataStackManager.sharedInstance().saveContext()
        } catch {
            showErrorAlert("Failed to save the current position.")
        }
    }
    
    // Save the region of the map every time it's update
    private func saveRegion() {
        
        let positionDictionary = [
            MapInfo.Keys.Latitude : mapView.region.center.latitude,
            MapInfo.Keys.Longitude : mapView.region.center.longitude,
            MapInfo.Keys.LatitudeDelta : mapView.region.span.latitudeDelta,
            MapInfo.Keys.LongitudeDelta : mapView.region.span.longitudeDelta
        ]
        
        // if the mapInfo object is already created we just update the values of it
        if mapInfo != nil {
            mapInfo.setValues(positionDictionary)
        } else {
            mapInfo = MapInfo(dictionary: positionDictionary, context: sharedContext)
        }
        
        saveContextInCoreData()
    }
    
    // Show the error alert to the user
    private func showErrorAlert(message: String) {
        let alert = UIAlertController(title: "Error", message: message, preferredStyle: UIAlertControllerStyle.Alert)
        alert.addAction(UIAlertAction(title: "Ok", style: UIAlertActionStyle.Default, handler:nil))
        presentViewController(alert, animated: true, completion: nil)
    }
    
    // MARK: Map view delegate
    
    func mapView(mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        saveRegion()
    }
    
    // MARK: Fetched results delegate
    
    func controller(controller: NSFetchedResultsController, didChangeSection sectionInfo: NSFetchedResultsSectionInfo, atIndex sectionIndex: Int, forChangeType type: NSFetchedResultsChangeType) {
            
            switch type {
                
                case .Insert:
                    //TODO: AQUI! - Insert the pin when 
                    break
                
                case .Update:
                    break
                
                case .Move:
                    break
                
                default:
                    return
            }
    }
}