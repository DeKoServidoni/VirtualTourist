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
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var emptyLabel: UILabel!
    
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
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        print("Load photos from web? \(pin.photos.isEmpty)")
        
        if pin.photos.isEmpty {
            
            activityIndicator.startAnimating()
            
            FlickrAPI.sharedInstance().findPhotosOf(pin.coordinate) { (result, error) in
                
                self.activityIndicator.stopAnimating()
                self.activityIndicator.hidden = true
                
                guard error == nil else {
                    self.emptyLabel.hidden = false
                    return
                }
                
                if let response = result as? [[String:AnyObject]] {
                    
                    if response.isEmpty {
                        self.emptyLabel.hidden = false
                    } else {
                        
                        for item in response {
                            let photo = Photo(content: item, context: self.sharedContext)
                            
                            // save to CoreData
                            photo.pin = self.pin
                        }
                        
                        self.collectionView.hidden = false
                    }
                }
            }
            
        } else {
            collectionView.hidden = false
            activityIndicator.hidden = true
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        // Layout the collection view so that cells take up 1/3 of the width,
        // with no space in between.
        let layout : UICollectionViewFlowLayout = UICollectionViewFlowLayout()
        layout.sectionInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        layout.minimumLineSpacing = 0
        layout.minimumInteritemSpacing = 0
        
        let width = floor(self.collectionView.frame.size.width/3)
        layout.itemSize = CGSize(width: width, height: width)
        collectionView.collectionViewLayout = layout
    }
    
    // MARK: IBAction functions
    
    @IBAction func newCollectionActionClick(sender: UIBarButtonItem) {
        print("RELOAD COLLECTION!")
        //TODO: RELOAD THE COLLECTION <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
    }
    
    // MARK: Fetched results functions
    
    func controllerWillChangeContent(controller: NSFetchedResultsController) {
        insertedIndexPaths = [NSIndexPath]()
        deletedIndexPaths = [NSIndexPath]()
        updatedIndexPaths = [NSIndexPath]()
    }
    
    func controller(controller: NSFetchedResultsController,
        didChangeObject anObject: AnyObject, atIndexPath indexPath: NSIndexPath?,
        forChangeType type: NSFetchedResultsChangeType, newIndexPath: NSIndexPath?) {
        
        switch type{
            
            case .Insert:
                insertedIndexPaths.append(newIndexPath!)
                break
                
            case .Delete:
                deletedIndexPaths.append(indexPath!)
                break
            
            case .Update:
                updatedIndexPaths.append(indexPath!)
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
            
            for indexPath in self.updatedIndexPaths {
                self.collectionView.reloadItemsAtIndexPaths([indexPath])
            }
            
        }, completion: nil)
    }
    
    // MARK: Collection view functions
    
    func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return fetchedPhotosResultsController.sections?.count ?? 0
    }
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return fetchedPhotosResultsController.sections![section].numberOfObjects
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
    
        let photo = fetchedPhotosResultsController.objectAtIndexPath(indexPath) as! Photo
        
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("PhotoCell", forIndexPath: indexPath) as! PhotoCell
        cell.photo.image = UIImage(named: "placeholder")
        
//        if photo.imgPath == nil || photo.imgPath == "" {
//            cell.photo.image = UIImage(named: "noImage")
//        } else
        if photo.photoImage != nil {
            cell.photo.image = photo.photoImage
        } else {
            print("DOWNLOAD IMAGE!")
            //TODO: download the image! <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
        }
        
        return cell
    }
    
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        print("DELETE IMAGE!")
        //TODO: DELETE THE PHOTO <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
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
    
    // fetched results to get the photos from the core data
    lazy var fetchedPhotosResultsController: NSFetchedResultsController = {
        
        let fetchRequest = NSFetchRequest(entityName: "Photo")
        fetchRequest.sortDescriptors = []
        fetchRequest.predicate = NSPredicate(format: "pin == %@", self.pin);
        
        let fetchedPhotosResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: self.sharedContext, sectionNameKeyPath: nil,cacheName: nil)
        
        return fetchedPhotosResultsController
        
        }()
}