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
    func pinInserted(annotation: MKPointAnnotation)
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
        longPress.minimumPressDuration = 1.0;
        
        self.mapView.addGestureRecognizer(longPress)
    }
    
    // MARK: Public functions
    
    func prepareMap() {
        
        mapInfo = fetchMapInfo()
        
        if mapInfo != nil {
            restoreMapRegion(true)
        }
    }
    
    // handle the tap and holding action to place the pin
    func handleLongPressGesture(sender: UIGestureRecognizer) {
        
        if sender.state == UIGestureRecognizerState.Began {
            
            // convert the touch location to point
            let touchPoint = sender.locationInView(mapView)
            let coordinate = mapView.convertPoint(touchPoint, toCoordinateFromView: mapView)
            
            // create the annotation and set its coordiate
            let annotation = MKPointAnnotation()
            annotation.coordinate = coordinate
            annotation.title = "Delete this Pin?"
            
            // add the pin on the map
            mapView.addAnnotation(annotation)
            
            // send this annotation to the view controller to be processed
            //delegate?.pinInserted(annotation)
            print("ADD PIN")
        }
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
    
    func mapView(mapView: MKMapView, annotationView view: MKAnnotationView, didChangeDragState newState: MKAnnotationViewDragState, fromOldState oldState: MKAnnotationViewDragState) {
        
        // update the pin when the drag is cancelled or ended
        if newState == MKAnnotationViewDragState.Ending || newState == MKAnnotationViewDragState.Canceling {
            print("UPDATE PIN!")
        }
    }
    
    func mapView(mapView: MKMapView, viewForAnnotation annotation: MKAnnotation) -> MKAnnotationView? {
        
        // recycle the pin on the map
        var pinView = mapView.dequeueReusableAnnotationViewWithIdentifier("MapPin") as? MKPinAnnotationView
        
        if pinView == nil {
            pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: "MapPin")
            pinView!.canShowCallout = true
            pinView!.pinTintColor =  UIColor.orangeColor()
            pinView!.rightCalloutAccessoryView = UIButton(type: .DetailDisclosure)
        }
        else {
            pinView!.annotation = annotation
        }
        
        pinView?.draggable = true
        return pinView
    }
    
    func mapView(mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        // delete pin when the annotation is clicked
        print("REMOVE PIN!")
    }
}
