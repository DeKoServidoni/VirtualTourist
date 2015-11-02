//
//  FlickrAPI.swift
//  VirtualTourist
//
//  Created by André Servidoni on 10/29/15.
//  Copyright © 2015 Udacity. All rights reserved.
//

import Foundation
import MapKit
import CoreData

// Class responsible to hold all necessary methods to get the 
// photos from the Flickr web service
//
class FlickrAPI: NSObject {
    
    // singleton instance
    class func sharedInstance() -> FlickrAPI {
        
        struct Static {
            static var sharedInstance = FlickrAPI()
        }
        
        return Static.sharedInstance
    }
    
    // shared session
    lazy var sharedSession = {
        return NSURLSession.sharedSession()
    }()
    
    // MARK: Public functions
    
    // find the photos from the parameted coordinate
    func findPhotosOf(coordinate: CLLocationCoordinate2D, completionHandler: (result: AnyObject!, error: String!) -> Void) {
        
        let methodArguments = [
            "method": Flickr.Method,
            "api_key": Flickr.ApiKey,
            "lat": "\(coordinate.latitude)",
            "lon": "\(coordinate.longitude)",
            "safe_search": Flickr.SafeSearch,
            "extras": Flickr.Extras,
            "format": Flickr.DataFormat,
            "nojsoncallback": Flickr.NoJsonCallback,
            "page": "1"
        ]
        
        let urlString = FlickrAPI.Flickr.BaseUrl + formatParameters(methodArguments)
        let url = NSURL(string: urlString)
        let request = NSURLRequest(URL: url!)
        
        sharedSession.dataTaskWithRequest(request) { (data, result, error) in
        
            guard error == nil else {
                completionHandler(result: nil, error: error?.localizedDescription)
                return
            }
            
            guard let statusCode = (result as? NSHTTPURLResponse)?.statusCode where statusCode == 200 else {
                completionHandler(result: nil, error: "Invalid status code for the response!")
                return
            }
            
            guard let data = data else {
                completionHandler(result: nil, error: "empty")
                return
            }
            
            let response: AnyObject!
            
            do {
                response = try NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions.AllowFragments)
            } catch {
                completionHandler(result: nil, error: "Failed to parse the photos")
                return
            }
            
            let parsedResponse = self.parseResponseFromAPI(response)
            
            // send the response back to the view controller
            if parsedResponse != nil {
                completionHandler(result: parsedResponse, error: nil)
            } else {
                completionHandler(result: nil, error: "empty")
            }
            
        }.resume()
    }
    
    // MARK: Private functions
    
    // parse the JSON from the API
    private func parseResponseFromAPI(response: AnyObject!) -> [[String:AnyObject]]? {
        
        guard let stat = response[Flickr.TagStat] as? String where stat == Flickr.StatOk else {
            return nil
        }
        
        guard let photos = response[Flickr.TagPhotos] as? [String:AnyObject] else {
            return nil
        }
        
        guard let array = photos[Flickr.TagPhoto] as? [[String:AnyObject]] else {
            return nil
        }
        
        return array
    }
    
    // format the parameters to the format of URL
    private func formatParameters(parameters: [String : AnyObject]) -> String {
        
        var urlVars = [String]()
        
        for (key, value) in parameters {
            
            let stringValue = "\(value)"
            let escapedValue = stringValue.stringByAddingPercentEncodingWithAllowedCharacters(NSCharacterSet.URLQueryAllowedCharacterSet())

            urlVars += [key + "=" + "\(escapedValue!)"]
        }
        
        return (!urlVars.isEmpty ? "?" : "") + urlVars.joinWithSeparator("&")
    }
}
