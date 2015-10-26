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
    var pins: [Pin]!
    
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
    
    // MARK: Core data functions
    
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
    
    // MARK: Map manager delegate
    
    func pinInserted() {
        //TODO
    }
    
    func operationFinishedWithError(andMessage message: String) {
        showErrorAlert(message)
    }
    
    // MARK: Private functions
    
    // Show the error alert to the user
    private func showErrorAlert(message: String) {
        let alert = UIAlertController(title: "Error", message: message, preferredStyle: UIAlertControllerStyle.Alert)
        alert.addAction(UIAlertAction(title: "Ok", style: UIAlertActionStyle.Default, handler:nil))
        presentViewController(alert, animated: true, completion: nil)
    }
}