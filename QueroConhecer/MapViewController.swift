//
//  MapViewController.swift
//  QueroConhecer
//
//  Created by Arthur Silva on 21/12/22.
//

import UIKit
import MapKit

class MapViewController: UIViewController {
    
    
    enum MapMessageType{
        case routeError
        case authorizationwarning
    }

    //MARK: - IBOutlets

    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var viInfo: UIView!
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var lbName: UILabel!
    @IBOutlet weak var lbAddress: UILabel!
    @IBOutlet weak var loading: UIActivityIndicatorView!
    
    lazy var locationManager = CLLocationManager()
    var btUserLocation: MKUserTrackingButton!
    var selectedAnnotation: PlaceAnnotation?
    
    //MARK: - Propeties

    var places: [Place]!
    var poi: [MKAnnotation] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        searchBar.isHidden = true
        viInfo.isHidden = true
        mapView.mapType = .mutedStandard
        mapView.delegate = self
        locationManager.delegate = self

        
        if places.count == 1 {
            title = places[0].name
        }else{
            title = "Meus Lugares"
        }

        for place in places{
            addToMap(place)
        }
        
        configureLocationButton()
        
        showPlaces()
        requesteUserLocationAuthorization()
        
        
    }
    
    func configureLocationButton(){
        btUserLocation = MKUserTrackingButton(mapView: mapView)
        btUserLocation.backgroundColor = .white
        btUserLocation.frame.origin.x = 10
        btUserLocation.frame.origin.y = 10
        btUserLocation.layer.cornerRadius = 5
        btUserLocation.layer.borderWidth = 1
        btUserLocation.layer.borderColor = UIColor(named: "main")?.cgColor
        
    }
    
    func requesteUserLocationAuthorization(){
        if CLLocationManager.locationServicesEnabled(){
            switch CLLocationManager.authorizationStatus() {
                case .authorizedAlways, .authorizedWhenInUse:
                mapView.addSubview(btUserLocation)
                case .denied:
                    showMessgae(type: .authorizationwarning)
                case .notDetermined:
                    locationManager.requestWhenInUseAuthorization()
                case .restricted:
                    break
            }
            
        }
        
    }
    
    func showPlaces(){
        mapView.showAnnotations(mapView.annotations, animated: true)
    }
    
    func showInfo(){
        lbName.text = selectedAnnotation?.title
        lbAddress.text = selectedAnnotation?.address
        viInfo.isHidden = false
    }
    func addToMap(_ place: Place){
        
        let annotation = PlaceAnnotation(coordinate: place.coordinate, type: .place)
        annotation.title = place.name
        annotation.address = place.address
        annotation.coordinate = place.coordinate
        annotation.title = place.name
        mapView.addAnnotation(annotation)
        
    }
    
    @IBAction func showRoute(_ sender: Any) {
        if CLLocationManager.authorizationStatus() != .authorizedWhenInUse{
            showMessgae(type: .authorizationwarning)
            return
        }
        let request = MKDirections.Request()
        request.destination = MKMapItem(placemark: MKPlacemark(coordinate:selectedAnnotation!.coordinate) )
        request.destination = MKMapItem(placemark: MKPlacemark(coordinate:locationManager.location!.coordinate) )
        
        let directions = MKDirections(request: request)
        directions.calculate { response, error in
            if error == nil{
                if let response = response {
                    self.mapView.removeOverlay(self.mapView.overlays as! MKOverlay)
                    
                    let route = response.routes.first!
                    
                    print("Nome:", route.name)
                    print("distance:", route.distance)
                    print("duração:", route.expectedTravelTime)
                    print("=================:")
                    for step in route.steps{
                        print("Em \(step.distance) metro(s), \(step.instructions)")
                    }
                    self.mapView.addOverlay(route.polyline, level: .aboveRoads)
                    var annotations = self.mapView.annotations.filter({!($0 is PlaceAnnotation)})
                    annotations.append((self.selectedAnnotation!))
                    self.mapView.showAnnotations(annotations, animated: true)
                }
            }else {
                self.showMessgae(type: .routeError)
            }
            
        }
    }
       

    @IBAction func showSearchBar(_ sender: Any) {
        searchBar.resignFirstResponder()
        searchBar.isHidden = !searchBar.isHidden
    }
    
    func showMessgae(type: MapMessageType){
        
        let title = type == .authorizationwarning ? "Aviso" : "Erro"
        
        let message = type == .authorizationwarning ? " para usar os recursos de localização de App, você precisa permitir o usa na tela de Ajustes" : "Não foi possível encontrar essa rota"
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let cancelAction = UIAlertAction(title: "Cancelar", style: .cancel, handler: nil)
        alert.addAction(cancelAction)
        if type == .authorizationwarning {
            let confirmAction = UIAlertAction(title: "ir para Ajustes", style: .default, handler: { (action) in
                if #available(iOS 15.4, *) {
                    if let appSettings = URL(string: UIApplicationOpenNotificationSettingsURLString){
                        UIApplication.shared.open(appSettings, options: [:], completionHandler: nil)
                    }
                } else {
                    // Fallback on earlier versions
                }
            })
            alert.addAction(confirmAction)
        }
        present(alert, animated: true, completion: nil)
    }

    
}

extension MapViewController: MKMapViewDelegate{
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        if !(annotation is PlaceAnnotation){
            return nil
        }
        let type = (annotation as! PlaceAnnotation).type

        let identifier = "\(annotation)"
        var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier) as? MKMarkerAnnotationView
        if annotationView == nil{
            annotationView = MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: identifier)
        }
        annotationView?.annotation = annotation
        annotationView?.canShowCallout = true
        annotationView?.markerTintColor = type == .place ? UIColor(named:  "main") : UIColor(named: "poi")
        annotationView?.glyphImage = type == .place ? UIImage(named: "placeGlyph") : UIImage(named: "poiGlyph")
        annotationView?.displayPriority = type == .place ? .required : .defaultHigh
        
        return annotationView
    }
}

//MARK: - MKMapViewDelegate
extension MapViewController: UISearchBarDelegate{
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.isHidden = true
        searchBar.resignFirstResponder()
        loading.startAnimating()
        
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = searchBar.text
        request.region = mapView.region
        let search = MKLocalSearch(request: request)
        search.start{ [self](response,error) in
            if error == nil {
                guard let response = response else {
                    self.loading.stopAnimating()
                    return
                }
                self.mapView.removeAnnotation(self.poi as! MKAnnotation)
                self.poi.removeAll()
                for item in response.mapItems {
                    let annotation = PlaceAnnotation(coordinate: item.placemark.coordinate, type: .poi)
                    annotation.title = item.name
                    annotation.subtitle = item.phoneNumber
                    annotation.address = Place.getFomattedAddress(with: item.placemark)
                    self.poi.append(annotation)
                }
                self.mapView.addAnnotation(self.poi as! MKAnnotation )
                self.mapView.showAnnotations(self.poi, animated: true)
                
            }
            loading.stopAnimating()
        }
    }
    
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        let camera = MKMapCamera()
        camera.centerCoordinate =  view.annotation!.coordinate
        camera.pitch = 80
        camera.altitude = 100
        mapView.setCamera(camera, animated: true)
        selectedAnnotation = (view.annotation as? PlaceAnnotation)
        showInfo()
    }
    
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        if overlay is MKPolyline{
            let renderer = MKPolylineRenderer(overlay: overlay)
            renderer.strokeColor = UIColor(named: "main")?.withAlphaComponent(0.0)
            renderer.lineWidth = 5.0
            return renderer
        }
        return MKOverlayRenderer(overlay: overlay)
    }
}

extension MapViewController:CLLocationManagerDelegate{
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        switch status {
        case .authorizedAlways, .authorizedWhenInUse:
            mapView.showsUserLocation = true
            mapView.addSubview(btUserLocation)
            locationManager.startUpdatingLocation()
        default:
            break
            
        }
    }
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let location = locations.last{
            print("Velocidade.", location.speed)
            let region = MKCoordinateRegion(center: location.coordinate, latitudinalMeters: 500, longitudinalMeters: 500)
            mapView.setRegion(region, animated: true)
        }
    }
}
