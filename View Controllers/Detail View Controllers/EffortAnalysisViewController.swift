//
//  EffortAnalysisViewController.swift
//  RideViewer
//
//  Created by West Hill Lodge on 20/05/2019.
//  Copyright © 2019 Home. All rights reserved.
//

import UIKit

class EffortAnalysisViewController: UIViewController, RVEffortTableDelegate, RouteProfileDelegate {

    @IBOutlet weak var topInfoLabel: UILabel!
    @IBOutlet weak var bottomInfoLabel: UILabel!
    
    @IBOutlet weak var profileSegmentedControl: UISegmentedControl!
    @IBOutlet weak var profileDetailStackView: UIStackView!
    
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
    /// Segment for analysis
    var segment : RVSegment! {
        didSet {
            effortTableViewController?.ride = segment
        }
    }
    
    /// Selected effort - will normally be set on segue
    var selectedEffort : RVEffort? = nil
    
    // MARK: Model for effort table
    private lazy var dataManager = DataManager<RVEffort>()
    private var effortFilters : [EffortFilter] = []
    private var effortSort : EffortSort = .elapsedTime
    private var popupController : UIViewController?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        profileViewController.delegate = self
        
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

        // Get the effort data for the shortest ride on this segment
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
 
        // Show selected effort if selected
        if selectedEffort != nil  {
            effortTableViewController.highlightEffort(selectedEffort!)
            if selectedEffort! != shortestEffort {
                displayStreamsForEffort(selectedEffort!, displayType: .secondary)
           }
        }

        // Show text detail
        profileDetailStackView.addArrangedSubview(detailLabel(effort: shortestEffort))
    }
    
    func detailLabel(effort : RVEffort) -> UILabel {
        let label = UILabel(frame: CGRect(x: 0, y: 0, width: 20, height: 10))
        label.font = UIFont.preferredFont(forTextStyle: .body)
        label.text = "No selection"
        return label
    }
    
    // Profile view delegate
    func profileTouch(at: Int) {
        guard let shortestTimeData = profileViewController.dataSetOfType(.time, forStreamOwner: segment.shortestElapsedEffort())?.dataPoints  else {
            appLog.debug("No time stream for shortest")
            return
        }
        var shortestTimeString = ((shortestTimeData[at].dataValue - shortestTimeData[0].dataValue) as Duration).shortDurationDisplayString
        var shortestSpeedString = (profileViewController.primaryDataSet.dataPoints[at].dataValue as Speed).speedDisplayString

        if let selectedTimeData = profileViewController.dataSetOfType(.time, forStreamOwner: selectedEffort)?.dataPoints {
            shortestTimeString += " (" + ((selectedTimeData[at].dataValue - selectedTimeData[0].dataValue) as Duration).shortDurationDisplayString + ")"
        }
        if let selectedSpeedData = profileViewController.dataSetOfType(.speed, forStreamOwner: selectedEffort)?.dataPoints {
            shortestSpeedString += " (" + (selectedSpeedData[at].dataValue as Speed).speedDisplayString + ")"
        }
        
        let labelString = "Time: \(shortestTimeString), Speed: \(shortestSpeedString)"
        (profileDetailStackView.arrangedSubviews[0] as! UILabel).text = labelString
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
        selectedEffort = effort
        displayStreamsForEffort(effort, displayType: .secondary)
    }
    
    func didDeselectEffort(effort: RVEffort) {
        selectedEffort = nil
        profileViewController.removeProfileForOwner(effort)
    }
    
    // MARK: Effort profile setup
    private func displayStreamsForEffort(_ effort: RVEffort, displayType: ViewProfileDisplayType) {
        effort.streams(completionHandler: ({ [weak self] streams in
            guard let `self` = self else { return }
            if displayType == .primary {
                self.setAvailableStreamsInSegmentedControlForEffort(effort)
                self.profileViewController.setPrimaryProfile(streamOwner: effort, profileType: self.selectedStreamType, seriesType: .distance)
                effort.segment.streams(completionHandler: ({ [weak self] streams in
                    self?.profileViewController.addProfile(streamOwner: effort.segment, profileType: .altitude, displayType: .background, withRange: nil)
                }))
            } else {            // Secondary
                self.profileViewController.addProfile(streamOwner: effort, profileType: self.selectedStreamType, displayType: .secondary, withRange: nil)
            }
            // Retrieve the time stream for all types but it is not displayed
            self.profileViewController.addProfile(streamOwner: effort, profileType: .time, displayType: .notShown, withRange: nil)
        }))
    }
    
    private func setAvailableStreamsInSegmentedControlForEffort(_ effort : RVEffort) {
        effort.streamTypes.forEach { (streamType) in
            if let index = streamDataTypes.firstIndex(of: streamType) {
                profileSegmentedControl.setEnabled(true, forSegmentAt: index)
            }
        }
    }
}
