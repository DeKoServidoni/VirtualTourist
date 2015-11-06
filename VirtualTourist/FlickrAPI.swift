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
    
    var totalPages: Int = 0
    
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
    func findPhotosOf(coordinate: CLLocationCoordinate2D, inPages pages: Int, completionHandler: (photos: AnyObject!, pages: Int!, error: String!) -> Void) {
        
        totalPages = pages
        
        let page = sortPage() as Int
        let uploadDate = dateRange() as [Double]
        
        print("page: \(page) - totalPages: \(totalPages)") ///<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<

        
        let methodArguments = [
            FlickrParamValue.ParamMethod: FlickrParamValue.ValueMethod,
            FlickrParamValue.ParamApiKey: FlickrParamValue.ValueApiKey,
            FlickrParamValue.ParamSafeSearch: FlickrParamValue.ValueSafeSearch,
            FlickrParamValue.ParamExtras: FlickrParamValue.ValueExtras,
            FlickrParamValue.ParamFormat: FlickrParamValue.ValueFormat,
            FlickrParamValue.ParamNoJsonCallback: FlickrParamValue.ValueNoJsonCallback,
            FlickrParamValue.ParamMedia: FlickrParamValue.ValueMedia,
            FlickrParamValue.ParamPerPage: FlickrParamValue.ValuePerPage,
            FlickrParamValue.ParamPage: "\(page)",
            FlickrParamValue.ParamMaxUploadDate: "\(uploadDate[0])",
            FlickrParamValue.ParamMinUploadDate: "\(uploadDate[1])",
            FlickrParamValue.ParamLat: "\(coordinate.latitude)",
            FlickrParamValue.ParamLon: "\(coordinate.longitude)"
        ]
        
        let urlString = "https://api.flickr.com/services/rest/" + formatParameters(methodArguments)
        let url = NSURL(string: urlString)
        let request = NSURLRequest(URL: url!)
        
        print("\(urlString)") ///<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
        
        sharedSession.dataTaskWithRequest(request) { (data, result, error) in
        
            guard error == nil else {
                completionHandler(photos: nil, pages: 0, error: error?.localizedDescription)
                return
            }
            
            guard let statusCode = (result as? NSHTTPURLResponse)?.statusCode where statusCode == 200 else {
                completionHandler(photos: nil, pages: 0, error: "Invalid status code for the response!")
                return
            }
            
            guard let data = data else {
                completionHandler(photos: nil, pages: 0, error: "empty")
                return
            }
            
            let response: AnyObject!
            
            do {
                response = try NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions.AllowFragments)
            } catch {
                completionHandler(photos: nil, pages: 0, error: "Failed to parse the photos")
                return
            }
            
            let parsedResponse = self.parseResponseFromAPI(response)
            
            // send the response back to the view controller
            if parsedResponse != nil {
                completionHandler(photos: parsedResponse, pages: self.totalPages, error: nil)
            } else {
                completionHandler(photos: nil, pages: 0, error: "empty")
            }
            
        }.resume()
    }
    
    // download the image from URL
    func downloadImageOf(path: String?, completionHandler: (imageData: NSData?, error: String?) ->  Void) -> NSURLSessionTask? {
        
        if let path = path {
            
            let url = NSURL(string: path)
            let request = NSURLRequest(URL: url!)
            
            let task = sharedSession.dataTaskWithRequest(request) { (data, result, error) in
                
                if let _ = error {
                    completionHandler(imageData: nil, error: "Failed to load image")
                } else {
                    completionHandler(imageData: data, error: nil)
                }
            }
            
            task.resume()
            
            return task
            
        } else {
            completionHandler(imageData: nil, error: "empty")
            return nil
        }
    }
    
    // MARK: Private functions
    
    // parse the JSON from the API
    private func parseResponseFromAPI(response: AnyObject!) -> [[String:AnyObject]]? {
        
        guard let stat = response[FlickrJSON.TagStat] as? String where stat == FlickrJSON.StatOk else {
            return nil
        }
        
        guard let photos = response[FlickrJSON.TagPhotos] as? [String:AnyObject] else {
            return nil
        }
        
        guard let pages = photos[FlickrJSON.TagPages] as? Int else {
            return nil
        }
        
        // get the total pages of this result
        totalPages = pages
        
        guard let array = photos[FlickrJSON.TagPhoto] as? [[String:AnyObject]] else {
            return nil
        }
        
        return array
    }
    
    // generate random page of the collection
    private func sortPage() -> Int {
        
        var randomPage = 1
        
        if totalPages > 0 {
            randomPage = Int(arc4random_uniform(UInt32(totalPages))) + 1
        }
        
        return randomPage
    }
    
    // 🚨🚨🚨
    // calculate the max and min upload range (1 year)
    // I generate the 2 parameters of the request: "min_upload_date" and "max_upload_date"
    // The flicker API return a maximum of 4000 photos. If the API return a higher number, the
    // pages parameter came wrong, so to try to limit the return quantity to 4000 I set a range
    // of 1 year to filter the request
    // More info at: 👉🏼http://stackoverflow.com/questions/1994037/flickr-api-returning-duplicate-photos
    private func dateRange() -> [Double] {
        
        var range = [Double]()
        
        let startedTime = NSDate().minUpdateDate().timeIntervalSince1970
        let currentTimme = NSDate().timeIntervalSince1970
        
        range.append(Double(currentTimme))
        range.append(Double(startedTime))
        
        return range
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

// Date extension
extension NSDate {
    func minUpdateDate() -> NSDate {
        return NSCalendar.currentCalendar().dateByAddingUnit(NSCalendarUnit.Year, value: -1, toDate: self, options: NSCalendarOptions())!
    }
}
