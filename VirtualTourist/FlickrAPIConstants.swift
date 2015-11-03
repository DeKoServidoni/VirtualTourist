//
//  FlickrAPIConstants.swift
//  VirtualTourist
//
//  Created by André Servidoni on 10/29/15.
//  Copyright © 2015 Udacity. All rights reserved.
//

// Extension responsible to hold all the constants values
// required for the Flicker API
//
extension FlickrAPI {
 
    struct Flickr {
        // url
        static let BaseUrl: String = "https://api.flickr.com/services/rest/"
        static let Method: String = "flickr.photos.search"
        static let ApiKey: String = "7f402bc8f5775181bea39c7fc69187fd"
        
        // parameters
        static let Extras: String = "url_c"
        static let SafeSearch: String = "1"
        static let DataFormat: String = "json"
        static let NoJsonCallback: String = "1"
        static let PerPage: String = "100"
        
        // json tags
        static let TagId: String = "id"
        static let TagUrlM: String = "url_c"
        static let TagPhotos: String = "photos"
        static let TagPhoto: String = "photo"
        static let TagStat: String = "stat"
        
        // expected values
        static let StatOk: String = "ok"
    }
}