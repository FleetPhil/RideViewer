//
//  RVRouteProfileViewController.swift
//  RideViewer
//
//  Created by Home on 01/03/2019.
//  Copyright © 2019 Home. All rights reserved.
//


///  This controller manages an RVRouteProfileView

import UIKit
import CoreData
import Charts

protocol RouteProfileDelegate {
    func profileTouch(at : Int )
}

class RVRouteProfileViewController: UIViewController, ChartViewDelegate {
	// Model
	
	/// Struct with the data to be shown
	private var profileData : ViewProfileData?
	private var countOfPointsToDisplay : Int = 0
	
	/// View that is managed by this controller
	@IBOutlet weak var profileChartView: RVRouteProfileView!
    
    /// Delegate
    var delegate : RouteProfileDelegate?
    
    override func viewDidLoad() {
        profileChartView.delegate = self
    }
	
	// Public interface
	/**
	Set the main profile for this view - determines the type of data that is shown, the number of data points and the formatting of the left axis
	
	- Parameters:
		- streamOwner: NSManagedObject owner of the stream conforming to the StreamOwner protocol
		- profileType: type of data to be shown in the profile
		- range: unused?

	- Returns: Bool indicating success (TODO: should throw if error)
	*/
    func setPrimaryProfile<S> (streamOwner: S, profileType: RVStreamDataType, seriesType: RVStreamDataType) where S : StreamOwner {
        // TODO: use .distance or .time as appropriate
        streamOwner.dataPointsForStreamType(profileType, seriesType: seriesType, completionHandler: { [weak self] dataPoints in
            guard let `self` = self else { return }     // Out of scope
            
            guard let dataPoints = dataPoints else {
                appLog.error("Failed to get data points of type \(profileType)")
                self.profileChartView.noDataText = "Unable to get data of type \(profileType.stringValue)"
                self.profileData = nil
                return
            }
            
            // Create the data set with the required stream
            let dataSet = ViewProfileDataSet(streamOwner: streamOwner,
                                             profileDataType: profileType,
                                             profileDisplayType: .primary,      // TODO: should be a parameter
                                             dataPoints: dataPoints)
            
            self.profileData    = ViewProfileData(primaryDataSet: dataSet, seriesType: seriesType)
            
            self.profileChartView.setProfileData(self.profileData!)
        })
	}
	
	
	/**
	Add an additional profile for this view
	
	- Parameters:
		- streamOwner: NSManagedObject owner of the stream conforming to the StreamOwner protocol
		- profileType: type of data to be shown in the profile
		- displayType: how the data should be displayed
	
	- Returns: None
	*/
    func addProfile<S>(streamOwner : S, profileType: RVStreamDataType, displayType : ViewProfileDisplayType, withRange : RouteIndexRange?) where S : StreamOwner {
		guard profileData != nil else {
			appLog.error("No profile to add to")
			return
		}
        
        streamOwner.dataPointsForStreamType(profileType, seriesType: profileData!.profileSeriesType, completionHandler: { [weak self] dataPoints in
            guard let `self` = self else { return }     // Out of scope
            
            guard let dataPoints = dataPoints else {
                appLog.error("Failed to add data points of type \(profileType)")
                return
            }

            self.profileData!.addDataSet(ViewProfileDataSet(streamOwner: streamOwner, profileDataType: profileType, profileDisplayType: displayType, dataPoints: dataPoints))
            
            self.profileChartView.setProfileData(self.profileData!)
        })
	}
	
	/**
	Remove secondary profile
	*/
    func removeProfileForOwner(_ owner : StreamOwner) {
        if profileData == nil { return }
        profileData!.removeDataSetForOwner(owner)
        profileChartView.setProfileData(profileData!)
    }
    
    // Data access
    var primaryDataSet : ViewProfileDataSet {
        return profileData!.primaryDataSet          // Primary set must exist
    }
    
    func dataSetOfType(_ type : RVStreamDataType, forStreamOwner : StreamOwner?) -> ViewProfileDataSet? {
        if let owner = forStreamOwner {
            return profileData?.profileDataSets.filter({ $0.profileDataType == type && $0.streamOwner == owner }).first
        } else {
            return  nil
        }
    }
    
    // Chart view delegate
    func chartValueSelected(_ chartView: ChartViewBase, entry: ChartDataEntry, highlight: Highlight) {
        appLog.verbose("Touch at \(entry.x),\(entry.y)")
        
        delegate?.profileTouch(at: Int(entry.x / DisplayConstants.ProfileDistanceIncrement))
    }
    
    private func matchingDataPoint(_ dataPoint : DataPoint) -> (ViewProfileDataSet, Int)? {
        if let matchingPoint = profileData!.profileDataSets.map({ (dataSet) in (dataSet, dataSet.dataPoints.firstIndex { $0 == dataPoint })  })
            .filter({ matching in matching.1 != nil }).first {
            return (matchingPoint.0, matchingPoint.1!)
        } else {
            return nil
        }
    }
}




