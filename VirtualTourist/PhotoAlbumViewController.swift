//
//  PhotoAlbumViewController.swift
//  VirtualTourist
//
//  Created by André Servidoni on 10/29/15.
//  Copyright © 2015 Udacity. All rights reserved.
//

import Foundation
import MapKit
import CoreData

class PhotoAlbumViewController: BaseViewController, UICollectionViewDataSource, UICollectionViewDelegate, NSFetchedResultsControllerDelegate {
    
    var pin: Pin!
    
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var newCollection: UIBarButtonItem!
    @IBOutlet weak var collectionView: UICollectionView!
    
    // Keep the changes. We will keep track of insertions and deletions
    var insertedIndexPaths: [NSIndexPath]!
    var deletedIndexPaths: [NSIndexPath]!
    var updatedIndexPaths: [NSIndexPath]!
    
    // MARK: Lifecycle functions
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        initializeMap()
        
        // load saved pins
        do {
            try fetchedPhotosResultsController.performFetch()
        } catch {
            showErrorAlert("Failed to load the saved pins.")
        }
        
        fetchedPhotosResultsController.delegate = self
        
        // let's verify if exists any item on the core data
        // if exists didn't exists we need to request the Flickr service to get
        let photos = fetchedPhotosResultsController.fetchedObjects
        
        if photos?.count == 0 {
            //TODO: request
        }
    }
    
    // MARK: Fetched results functions
    
    func controllerWillChangeContent(controller: NSFetchedResultsController) {
        insertedIndexPaths = [NSIndexPath]()
        deletedIndexPaths = [NSIndexPath]()
    }
    
    func controller(controller: NSFetchedResultsController,
        didChangeObject anObject: AnyObject,
        atIndexPath indexPath: NSIndexPath?,
        forChangeType type: NSFetchedResultsChangeType,
        newIndexPath: NSIndexPath?) {
        
        switch type{
            
            case .Insert:
                insertedIndexPaths.append(newIndexPath!)
                break
                
            case .Delete:
                deletedIndexPaths.append(indexPath!)
                break
                
            default:
                break
        }

    }
    
    func controllerDidChangeContent(controller: NSFetchedResultsController) {
        
        collectionView.performBatchUpdates({() -> Void in
            
            for indexPath in self.insertedIndexPaths {
                self.collectionView.insertItemsAtIndexPaths([indexPath])
            }
            
            for indexPath in self.deletedIndexPaths {
                self.collectionView.deleteItemsAtIndexPaths([indexPath])
            }
            
            }, completion: nil)
    }
    
    // MARK: Collection view functions
    
    func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return fetchedPhotosResultsController.sections?.count ?? 0
    }
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        let section = fetchedPhotosResultsController.sections![0]
        return section.numberOfObjects
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
    
        let photo = fetchedPhotosResultsController.objectAtIndexPath(indexPath) as! Photo
        
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("PhotoCell", forIndexPath: indexPath) as! PhotoCell
        
        if photo.imgPath == nil || photo.imgPath == "" {
            cell.photo.image = UIImage(named: "noImage")
        } else if photo.photoImage != nil {
            cell.photo.image = photo.photoImage
        } else {
            print("DOWNLOAD IMAGE!")
            //TODO: download the image!
        }
        
        return cell
    }
    
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        //TODO: DELETE THE PHOTO
    }
    
    // MARK: Private functions
    
    // initialize the map: disable the user interaction and set the pin
    // in the center of the map
    private func initializeMap() {
        
        let span = MKCoordinateSpan(latitudeDelta: 0.2, longitudeDelta: 0.2)
        let centeredRegion = MKCoordinateRegion(center: pin.coordinate, span: span)
        
        mapView.zoomEnabled = false;
        mapView.scrollEnabled = false;
        mapView.userInteractionEnabled = false;
        mapView.setRegion(centeredRegion, animated: true)
        mapView.addAnnotation(pin)
    }
}