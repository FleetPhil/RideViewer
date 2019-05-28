//
//  EffortAnalysisViewController.swift
//  RideViewer
//
//  Created by West Hill Lodge on 20/05/2019.
//  Copyright © 2019 Home. All rights reserved.
//

import UIKit

class EffortAnalysisViewController: UIViewController, RVEffortTableDelegate {

    @IBOutlet weak var topInfoLabel: UILabel!
    @IBOutlet weak var bottomInfoLabel: UILabel!
    
    @IBOutlet weak var profileSegmentedControl: UISegmentedControl!
    @IBOutlet weak var profileDetailView: UIView!
    
    
    // Private variables
    lazy private var streamDataTypes : [RVStreamDataType] = { RVStreamDataType.effortStreamTypes }()
    private var effortTableViewController : RVEffortListViewController!
    private var profileViewController : RVRouteProfileViewController!
    
    /// Currently selected data type
    var selectedStreamType : RVStreamDataType {
        switch profileSegmentedControl.selectedSegmentIndex {
        case UISegmentedControl.noSegment:
            appLog.error("No type selected")
            return .speed              // Should not happen
        default:
            return streamDataTypes[profileSegmentedControl.selectedSegmentIndex]
        }
    }
    
    // Model
    var segment : RVSegment! {
        didSet {
            effortTableViewController?.ride = segment
        }
    }
    
    /// Currently selected effort
    var selectedEffort : RVEffort? = nil
    
    // MARK: Model for effort table
    private lazy var dataManager = DataManager<RVEffort>()
    private var effortFilters : [EffortFilter] = []
    private var effortSort : EffortSort = .elapsedTime
    private var popupController : UIViewController?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // View title
        self.title = segment.name! + " (" + segment.distance.distanceDisplayString + ")"

        // Reset the effort stream types in the segmented control
        profileSegmentedControl.removeAllSegments()
        streamDataTypes.enumerated().forEach({
            profileSegmentedControl.insertSegment(withTitle: $0.element.shortValue, at: $0.offset, animated: false)
            profileSegmentedControl.setEnabled(false, forSegmentAt: $0.offset)
        })
        // Select the initial type
        profileSegmentedControl.selectedSegmentIndex = self.streamDataTypes.firstIndex(of: StravaStreamType.InitialAnalysisType) ?? 0

        // Get the effort data for this segment
        segment.efforts(completionHandler: ({ [weak self] (efforts) in
            if let shortestEffort = self?.segment.shortestElapsedEffort() {
                self?.updateView(shortestEffort: shortestEffort)
            }
        }))
    }

    private func updateView(shortestEffort : RVEffort) {
        topInfoLabel.text = EmojiConstants.Fastest + " " + shortestEffort.activity.name
        topInfoLabel.textColor = ViewProfileDisplayType.primary.displayColour
        bottomInfoLabel.attributedText = shortestEffort.effortDisplayText

        // Get stream data for the fastest ride on this segment and set as the primary - also sets the availbale streams in the segmented control
        displayStreamsForEffort(shortestEffort, displayType: .primary)
        
        // Show secondary effort if selected
        
        
        if selectedEffort != nil  {
            effortTableViewController.highlightEffort(selectedEffort!)
            if selectedEffort! != shortestEffort {
                displayStreamsForEffort(selectedEffort!, displayType: .secondary)
           }
        }
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let destination = segue.destination as? RVEffortListViewController {
            effortTableViewController = destination
            effortTableViewController.delegate = self
            effortTableViewController.ride = segment
        }
        if let destination = segue.destination as? RVRouteProfileViewController {
            profileViewController = destination
        }
    }
    
    @IBAction func profileTypeChanged() {
        if let shortest = segment.shortestElapsedEffort() {
            displayStreamsForEffort(shortest, displayType: .primary)
        }
        // Show secondary effort if selected
        if selectedEffort != nil {
            displayStreamsForEffort(selectedEffort!, displayType: .secondary)
        }
    }
    
    // MARK: Effort table delegate
    func didSelectEffort(effort: RVEffort) {
        displayStreamsForEffort(effort, displayType: .secondary)
    }
    
    func didDeselectEffort(effort: RVEffort) {
        profileViewController.removeSecondaryProfiles()
    }
    
    // MARK: Effort profile setup
    // TODO: Add .time as axis value
    private func displayStreamsForEffort(_ effort: RVEffort, displayType: ViewProfileDisplayType) {
        effort.streams(completionHandler: ({ [weak self] streams in
            guard let `self` = self else { return }
            if displayType == .primary {
                self.setAvailableStreamsForEffort(effort)
                self.profileViewController.setPrimaryProfile(streamOwner: effort, profileType: self.selectedStreamType, seriesType: .distance)
                effort.segment.streams(completionHandler: ({ [weak self] streams in
                    self?.profileViewController.addProfile(streamOwner: effort.segment, profileType: .altitude, displayType: .background, withRange: nil)
                }))
            } else {            // Secondary
                self.profileViewController.addProfile(streamOwner: effort, profileType: self.selectedStreamType, displayType: .secondary, withRange: nil)
            }
        }))
    }
    
    private func setAvailableStreamsForEffort(_ effort : RVEffort) {
        effort.streamTypes.forEach { (streamType) in
            if let index = streamDataTypes.firstIndex(of: streamType) {
                profileSegmentedControl.setEnabled(true, forSegmentAt: index)
            }
        }
    }
}
