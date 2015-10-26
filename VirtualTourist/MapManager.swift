//
//  MapManager.swift
//  VirtualTourist
//
//  Created by André Servidoni on 10/25/15.
//  Copyright © 2015 Udacity. All rights reserved.
//

import Foundation
import MapKit
import CoreData

// Protocol responsible to comunicate with the caller of this manager
//
protocol MapManagerDelegate {
    func pinInserted()
    func operationFinishedWithError(andMessage message: String)
}

// Class responsible to manage all the operations with the map view from the view controller
//
class MapManager: NSObject, MKMapViewDelegate {
    
    var mapInfo: MapInfo!
    var mapView: MKMapView!
    var sharedContext: NSManagedObjectContext!
    var delegate: MapManagerDelegate?
    
    // MARK: Initializer function
    
    init(mapView: MKMapView!, sharedContext: NSManagedObjectContext!, delegate: MapManagerDelegate?) {
        super.init()
        
        self.mapView = mapView
        self.sharedContext = sharedContext
        self.delegate = delegate
        
        // set the long press on the map
        let longPress = UILongPressGestureRecognizer(target: self, action: "handleLongPressGesture:")
        longPress.minimumPressDuration = 2.0;
        
        self.mapView.addGestureRecognizer(longPress)
    }
    
    // MARK: Public functions
    
    func prepareMap() {
        
        mapInfo = fetchMapInfo()
        
        if mapInfo != nil {
            restoreMapRegion(true)
        }
    }
    
    func handleLongPressGesture(sender: UIGestureRecognizer) {
        print("LONG PRESS")
    }
    
    // MARK: Private functions
    
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
    
    // Restore the map previous region
    private func restoreMapRegion(animated: Bool) {

        let longitude = mapInfo.longitude as CLLocationDegrees
        let latitude = mapInfo.latitude as CLLocationDegrees
        let center = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        
        let longitudeDelta = mapInfo.longitudeDelta as CLLocationDegrees
        let latitudeDelta = mapInfo.latitudeDelta as CLLocationDegrees
        let span = MKCoordinateSpan(latitudeDelta: latitudeDelta, longitudeDelta: longitudeDelta)
        
        let savedRegion = MKCoordinateRegion(center: center, span: span)
        
        mapView.setRegion(savedRegion, animated: animated)
    }
    
    // MARK: Core data functions
    
    // Save the context and handle the error if it occurrs
    private func saveContextInCoreData() {
        do {
            try CoreDataStackManager.sharedInstance().saveContext()
        } catch {
            delegate?.operationFinishedWithError(andMessage: "Failed to save map current position and zoom!")
        }
    }
    
    // Fetch the saved map information (Zoom and Center)
    private func fetchMapInfo() -> MapInfo? {
        let mapInfo: MapInfo?
        let request = NSFetchRequest(entityName: "MapInfo")
        
        do {
            
            let result = try sharedContext.executeFetchRequest(request) as! [MapInfo]
            mapInfo = (result.count > 0) ? result[0] : nil
            
        } catch {
            delegate?.operationFinishedWithError(andMessage: "Failed to load map previous position and zoom!")
            mapInfo = nil
        }
        
        return mapInfo
    }
    
    // MARK: Map view delegate
    
    func mapView(mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        saveRegion()
    }

}
