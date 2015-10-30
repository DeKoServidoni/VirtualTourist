//
//  FlickrAPI.swift
//  VirtualTourist
//
//  Created by DeKo Servidoni on 10/29/15.
//  Copyright © 2015 Udacity. All rights reserved.
//

import Foundation
import MapKit

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
    
    // find the photos from the parameted coordinate
    func findPhotosOf(coordinate: CLLocationCoordinate2D, completionHandler: (result: AnyObject!, error: String!) -> Void) {
        
        let methodArguments = [
            "method": Flickr.Method,
            "api_key": Flickr.ApiKey,
            "bbox": createBoundingBoxStringWith(coordinate.latitude, andLongitude: coordinate.longitude),
            "safe_search": Flickr.SafeSearch,
            "extras": Flickr.Extras,
            "format": Flickr.DataFormat,
            "nojsoncallback": Flickr.NoJsonCallback
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
            
            print("\(response)")
            
            let parsedResponse = self.parseResponseFromAPI(response)
            
            // send the response back to the view controller
            if parsedResponse != nil {
                completionHandler(result: parsedResponse, error: nil)
            } else {
                completionHandler(result: nil, error: "empty")
            }
            
        }.resume()
    }
    
    // parse the JSON from the API
    private func parseResponseFromAPI(response: AnyObject!) -> [Photo]? {
        
        
        guard let photos = response["photos"] as? [String:AnyObject] else {
            return nil
        }
        
        guard let array = photos["photo"] as? [[String:AnyObject]] else {
            return nil
        }
        
        var photoArray = [Photo]()
        
        for item in array {
            //TODO: parse the photo
            let title = item["title"] as! String
            print("Foto: \(title)")
        }
        
        return photoArray
    }
    
    // format the coordinates to the bbox standard
    private func createBoundingBoxStringWith(latitude: Double, andLongitude longitude: Double) -> String {
        
        /* Fix added to ensure box is bounded by minimum and maximums */
        let bottom_left_lon = max(longitude - Flickr.BoundinBoxHalfWidth, Flickr.LonMin)
        let bottom_left_lat = max(latitude - Flickr.BoundingBoxHalfHeight, Flickr.LatMin)
        let top_right_lon = min(longitude + Flickr.BoundingBoxHalfHeight, Flickr.LonMax)
        let top_right_lat = min(latitude + Flickr.BoundingBoxHalfHeight, Flickr.LatMax)
        
        return "\(bottom_left_lon),\(bottom_left_lat),\(top_right_lon),\(top_right_lat)"
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
