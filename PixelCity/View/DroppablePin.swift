//
//  DroppablePin.swift
//  PixelCity
//
//  Created by Mahesh on 28/10/20.
//

import Foundation
import MapKit

class DroppablePin: NSObject, MKAnnotation {
    dynamic var coordinate: CLLocationCoordinate2D
    var identifier : String
    
    init(coordinate : CLLocationCoordinate2D, identifier : String) {
        self.coordinate = coordinate
        self.identifier = identifier
        super.init()
    }
}
