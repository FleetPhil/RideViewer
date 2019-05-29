//
//  RVAllEffortViewController.swift
//  RideViewer
//
//  Created by West Hill Lodge on 28/05/2019.
//  Copyright © 2019 Home. All rights reserved.
//

import UIKit
import MapKit

class RVAllEffortViewController: UIViewController, RVEffortTableDelegate {
    @IBOutlet weak var infoButton: UIBarButtonItem!
    @IBOutlet weak var mapView: RideMapView!
    
    // MARK: Model for effort table
    private var effortTableViewController : RVEffortListViewController!
    
    // MARK: Properties
    private var popupController : UIViewController?
    private var activityIndicator : UIActivityIndicatorView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Info button disabled as no effort selected
        infoButton.isEnabled = false
    }
    
    func updateView() {
        self.title             = "All Efforts"
    }
    
    // MARK: - Navigation
    var selectedEffort : RVEffort? = nil
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let destination = segue.destination as? EffortAnalysisViewController {
            destination.segment = selectedEffort?.segment
            destination.selectedEffort = selectedEffort
        }
        if let destination = segue.destination as? EffortAnalysisViewController {
            destination.segment = selectedEffort?.segment
            destination.selectedEffort = selectedEffort
        }
        // Embed segues
        if let destination = segue.destination as? RVEffortListViewController {
            effortTableViewController = destination
            effortTableViewController.delegate = self
            effortTableViewController.ride = nil
        }
    }
    
    // MARK: Effort table delegate
    func didSelectEffort(effort: RVEffort) {
        selectedEffort = effort
        infoButton.isEnabled = true
        
        mapView.addRoute(effort, type: .highlightSegment)
        mapView.zoomToRoute(effort)
    }
    
    func didDeselectEffort(effort: RVEffort) {
        selectedEffort = nil
        mapView.setTypeForRoute(effort, type: nil)
        infoButton.isEnabled = false
    }
}
