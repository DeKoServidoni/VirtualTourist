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
    func operationFinishedWithError(andMessage message: String)
    func operationClick(coordinate: CLLocationCoordinate2D?)
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
    }
    
    // MARK: Public functions
    
    // prepare the map, get previous zoom and center to initialize it
    func prepareMap() {
        mapInfo = fetchMapInfo()
        
        if let _ = mapInfo {
            restoreMapRegion()
        }
    }
    
    // insert the Pin in the Map
    func insertPin(pin: Pin) {
        mapView.addAnnotation(pin)
    }
    
    // remove the Pin from the Map
    func removePin(pin: Pin) {
        mapView.removeAnnotation(pin)
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
        
        do {
            try CoreDataStackManager.sharedInstance().saveContext()
        } catch {
            delegate?.operationFinishedWithError(andMessage: "Failed to save map current position and zoom!")
        }
    }
    
    // Restore the map previous region
    private func restoreMapRegion() {

        let longitude = mapInfo.longitude as CLLocationDegrees
        let latitude = mapInfo.latitude as CLLocationDegrees
        let center = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        
        let longitudeDelta = mapInfo.longitudeDelta as CLLocationDegrees
        let latitudeDelta = mapInfo.latitudeDelta as CLLocationDegrees
        let span = MKCoordinateSpan(latitudeDelta: (latitudeDelta), longitudeDelta: (longitudeDelta))
        let savedRegion = MKCoordinateRegionMake(center, span)
        
        // we set the region to use the saved zoom
        // and after that we set the center coordinate, 
        // with this we can parcially fix the zoom out problem
        // of map view
        mapView.setRegion(savedRegion, animated: false)
        mapView.setCenterCoordinate(center, animated: true)
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
    
    func mapView(mapView: MKMapView, viewForAnnotation annotation: MKAnnotation) -> MKAnnotationView? {
        
        // recycle the pin on the map
        var pinView = mapView.dequeueReusableAnnotationViewWithIdentifier("MapPin") as? MKPinAnnotationView
        
        if pinView == nil {
            pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: "MapPin")
            pinView!.canShowCallout = false
            pinView!.pinTintColor =  UIColor.orangeColor()
        }
        else {
            pinView!.annotation = annotation
        }
        
        pinView?.animatesDrop = true
        pinView?.draggable = true
        return pinView
    }
    
    func mapView(mapView: MKMapView, didSelectAnnotationView view: MKAnnotationView) {
        mapView.deselectAnnotation(view.annotation, animated: true)
        delegate?.operationClick(view.annotation?.coordinate)
    }
}
