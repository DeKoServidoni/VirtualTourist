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
    
    // fetched results to get the photos from the core data
    lazy var fetchedPhotosResultsController: NSFetchedResultsController = {
        
        let fetchRequest = NSFetchRequest(entityName: "Photo")
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "id", ascending: true)]
        fetchRequest.predicate = NSPredicate(format: "pin == %@", self.pin);
        
        let fetchedPhotosResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: self.sharedContext, sectionNameKeyPath: nil,cacheName: nil)
        
        return fetchedPhotosResultsController
        
        }()
    
    // MARK: Lifecycle functions
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        initializeMap()
        
        // load saved pins
        do {
            try fetchedPhotosResultsController.performFetch()
        } catch {
            showErrorAlert("Failed to load the saved photos.")
        }
        
        fetchedPhotosResultsController.delegate = self
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        if pin.photos.isEmpty {
            requestPhotosFromAPI()
        } else {
            endLoading(true)
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
        
        // let's delete all photos from the core data and disk
        let photosToDelete = fetchedPhotosResultsController.fetchedObjects
        
        for item in photosToDelete! {
            let photo = item as! Photo
            sharedContext.deleteObject(photo)
        }
        
        saveContext()
        
        // request a new sorted set of photos
        requestPhotosFromAPI()
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
                
                let photo = anObject as! Photo
                if !photo.deletePhotoAtDisk() {
                    showErrorAlert("Failed to delete image!")
                }
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
        
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("PhotoCellView", forIndexPath: indexPath) as! PhotoCell
        cell.photo.image = UIImage(named: "placeholder")
        
        if photo.url == "" {
            cell.photo.image = UIImage(named: "noImage")
            
        } else if photo.photoImage != nil {
            cell.photo.image = photo.photoImage
            
        } else {
            
            let task = FlickrAPI.sharedInstance().downloadImageOf(photo.url as? String) { (data, error) in
                
                let image: UIImage!
                
                guard error == nil else {
                    image = UIImage(named: "noImage")
                    return
                }
                
                if let data = data {
                    photo.photoImage = UIImage(data: data)
                    image = photo.photoImage
                
                } else {
                    image = UIImage(named: "noImage")
                }
                
                dispatch_async(dispatch_get_main_queue()) {
                    cell.photo.image = image
                }
            }
            
            cell.taskToCancelifCellIsReused = task
        }
        
        return cell
    }
    
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        let photo = fetchedPhotosResultsController.objectAtIndexPath(indexPath) as! Photo
        sharedContext.deleteObject(photo)
        saveContext()
    }
    
    // MARK: Private components
    
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
    
    // call the flickr API and request a new set of photos that
    // corresponds to PIN coordinate
    private func requestPhotosFromAPI() {
        
        startLoading()
        
        FlickrAPI.sharedInstance().findPhotosOf(pin.coordinate, inPages: Int(pin.pagesOfPhotos)) { (photos, pages, error) in
            
            guard error == nil else {
                dispatch_async(dispatch_get_main_queue()) {
                    self.endLoading(false)
                }
                return
            }
            
            if let response = photos as? [[String:AnyObject]] {
                
                if response.isEmpty {
                    dispatch_async(dispatch_get_main_queue()) {
                        self.endLoading(false)
                    }
                } else {
                    
                    let _ = response.map() { (item: [String : AnyObject]) -> Photo in
                        let photo = Photo(content: item, context: self.sharedContext)
                        
                        photo.pin = self.pin
                        return photo
                    }
                    
                    self.pin.pagesOfPhotos = pages
                    self.saveContext()
                    
                    dispatch_async(dispatch_get_main_queue()) {
                        self.endLoading(true)
                    }
                }
            }
        }
    }
    
    // Refresh the UI when the loading start
    private func startLoading() {
        
        newCollection.enabled = false
        activityIndicator.hidden = false
        collectionView.hidden = true
        
        activityIndicator.startAnimating()
    }
    
    // Refresh the UI when the loading end
    private func endLoading(success: Bool) {
        
        activityIndicator.stopAnimating()
        activityIndicator.hidden = true
        
        if success {
            collectionView.hidden = false
            activityIndicator.hidden = true
            newCollection.enabled = true
            
        } else {
            emptyLabel.hidden = false
            newCollection.enabled = true
        }
        
    }
}