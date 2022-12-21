//
//  PlaceFinderViewController.swift
//  QueroConhecer
//
//  Created by Arthur Silva on 21/12/22.
//

import UIKit
import MapKit

protocol PlacefinderDelegate: class{
    func addPlace(_ place: Place)
}
class PlaceFinderViewController: UIViewController {
    
    enum PlacefindMessageType{
        case error(String)
        case confirmation(String)
    }
    
    
    @IBOutlet weak var tfCity: UITextField!
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var aiLoading: UIActivityIndicatorView!
    @IBOutlet weak var viLoading: UIView!
    

    
    var place: Place!
    weak var delegate: (PlacefinderDelegate)?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let gesture = UILongPressGestureRecognizer(target: self, action: #selector(getLocation(_:)))
        mapView.addGestureRecognizer(gesture)
        
    }
    
    @objc func getLocation(_ gesture: UILongPressGestureRecognizer){
        if gesture.state == .began{
            load(show: true)
            let point = gesture.location(in: mapView)
            let coordinate = mapView.convert(point, toCoordinateFrom: mapView)
            let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
            CLGeocoder().reverseGeocodeLocation(location) { (placemarks, error) in
                self.load(show: false)
                if error == nil {
                    if !self.savePlace(with: placemarks?.first){
                        self.showMessgae(type: .error("Não foi possível encontrar nenhum local com esse nome"))
                                         
                        }
                    }else {
                        self.showMessgae(type: .error("Erro desconhecido"))
                }
            }
        }
    }
    

    @IBAction func findCity(_ sender: Any) {
        tfCity.resignFirstResponder()
        let address =  tfCity.text!
        load(show: true)

        let geoCoder = CLGeocoder()
        geoCoder.geocodeAddressString(address) { placemarks, error in
            self.load(show: false)
            if error == nil {
                if !self.savePlace(with: placemarks?.first){
                    self.showMessgae(type: .error("Não foi possível encontrar nenhum local com esse nome"))
                                     
                    }
                }else {
                    self.showMessgae(type: .error("Erro desconhecido"))
            }
        }
    }
    
    func savePlace(with placemark: CLPlacemark?) -> Bool{
        guard let placemark = placemark, let coordinate =  placemark.location?.coordinate else {
            return false
        }
        let name = placemark.name ?? placemark.country ?? "Desconhecido"
        let address =  Place.getFomattedAddress(with: placemark)
        place = Place(name: name, latitude: coordinate.latitude, longitude: coordinate.longitude, address: address)
        
        let region = MKCoordinateRegion(center: coordinate, latitudinalMeters: 3500, longitudinalMeters: 3500)
        mapView.setRegion(region, animated: true)
        self.showMessgae(type: .confirmation(place.name))
        
        
        return true
    }
    
    func showMessgae(type: PlacefindMessageType){
        
        let title: String, message: String
        var hasConfirmation: Bool = false
        
        switch type{
        case .confirmation(let name):
            title = "Local encontrado"
            message = " Deseja Adicionar \(name)?"
            hasConfirmation = true
        case .error(let errorMessage):
            title = "Erro"
            message = errorMessage
        }
        
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let cancelAction = UIAlertAction(title: "Cancelar", style: .cancel, handler: nil)
        alert.addAction(cancelAction)
        
        if hasConfirmation {
            let confirmAction = UIAlertAction(title: "Ok", style: .default, handler: { (action) in
                self.delegate?.addPlace(self.place)
                self.dismiss(animated: true, completion: nil)
            })
            alert.addAction(confirmAction)
        }
        present(alert, animated: true, completion: nil)
    }

    func load(show: Bool){
        viLoading.isHidden = !show
        if show{
            aiLoading.startAnimating()
        }else{
            aiLoading.stopAnimating()
        }
    }
    @IBAction func close(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
    
    
}
