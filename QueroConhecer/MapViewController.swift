//
//  MapViewController.swift
//  QueroConhecer
//
//  Created by Arthur Silva on 21/12/22.
//

import UIKit
import MapKit

class MapViewController: UIViewController {

    @IBOutlet weak var searchBar: UISearchBar!
    
    @IBOutlet weak var viInfo: UIView!
    @IBOutlet weak var mapView: MKMapView!
    
    @IBOutlet weak var lbName: UILabel!
    
    @IBOutlet weak var lbAddress: UILabel!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    
    @IBAction func showRoute(_ sender: Any) {
    }
    

    @IBAction func showSearchBar(_ sender: Any) {
    }
}
