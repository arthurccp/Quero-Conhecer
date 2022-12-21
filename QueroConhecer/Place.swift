//
//  Place.swift
//  QueroConhecer
//
//  Created by Arthur Silva on 21/12/22.
//

import Foundation
import MapKit

struct Place: Codable{
    let name: String
    let latitude: CLLocationDegrees
    let longitude: CLLocationDegrees
    let address: String

    
    var coordinate: CLLocationCoordinate2D {
        return CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
    
    
    static func getFomattedAddress(with placemark: CLPlacemark) -> String{
        var address = ""
        if let street = placemark.thoroughfare{
            address += street  // Rua
        }
        if let number = placemark.subThoroughfare{
            address += "\(number)" // Numero
        }
        if let sublocality = placemark.subLocality {
            address += ",\(sublocality)" // Bairro
        }
        if let city = placemark.locality {
            address += "\n\(city)"
        }
        if let state = placemark.administrativeArea {
            address += "-\(state)"
        }
        if let postalCode = placemark.postalCode {
            address += "\nCEP\(postalCode)"
        }
        if let country = placemark.country{
            address += "\n \(country)"
        }
        return address
    }
}

extension Place: Equatable {
    static func ==(lhs: Place, rhs: Place) -> Bool{
        return lhs.latitude == rhs.latitude && lhs.longitude == rhs.longitude
    }
}
