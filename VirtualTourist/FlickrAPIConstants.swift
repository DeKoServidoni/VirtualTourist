//
//  FlickrAPIConstants.swift
//  VirtualTourist
//
//  Created by DeKo Servidoni on 10/29/15.
//  Copyright © 2015 Udacity. All rights reserved.
//

extension FlickrAPI {
 
    struct Flickr {
        // url
        static let BaseUrl: String = "https://api.flickr.com/services/rest/"
        static let Method: String = "flickr.photos.search"
        static let ApiKey: String = "7f402bc8f5775181bea39c7fc69187fd"
        
        // parameters
        static let Extras: String = "url_m"
        static let SafeSearch: String = "1"
        static let DataFormat: String = "json"
        static let NoJsonCallback: String = "1"
        
        // default values
        static let BoundinBoxHalfWidth = 1.0
        static let BoundingBoxHalfHeight = 1.0
        static let LatMin = -90.0
        static let LatMax = 90.0
        static let LonMin = -180.0
        static let LonMax = 180.0
    }
}