//
//  PinProtocol.swift
//  VirtualTourist
//
//  Created by André Servidoni on 10/27/15.
//  Copyright © 2015 Udacity. All rights reserved.
//

import Foundation
import MapKit

// Protocol responsible to implement the contract of MKAnnotation
// with this our core data object (Pin) can be added directly to the
// Map view
protocol PinProtocol: MKAnnotation {
    
    var title: String? { get }
    var subtitle: String? { get }
}