//
//  RVRouteProfileViewController.swift
//  RideViewer
//
//  Created by Home on 01/03/2019.
//  Copyright © 2019 Home. All rights reserved.
//


//  This controller manages an RVRouteProfileView

import UIKit
import CoreData
import StravaSwift

// Class objects that own streams adopt this protocol
protocol StreamOwner where Self : NSManagedObject {
	var streams: Set<RVStream> { get }
}

// Data structures for the view
enum ViewProfileDataType : String {
	case altitude
	case heartrate
	case watts
	case distance
	case cadence
}

struct ViewProfileDataSet {
	var profileDataType : ViewProfileDataType
	var profileDataPoints : [Double]
}

struct ViewProfileData {
	var profileDataSets: [ViewProfileDataSet]
	var highlightRange: RouteIndexRange?
	var rangeChangedHandler: ((RouteIndexRange) -> Void)?
}

class RVRouteProfileViewController: UIViewController {
	
	// View that is managed by this controller
	@IBOutlet weak var routeView: RVRouteProfileView!

	// Model - a NSManagedObject that has a 'streams' var
	var streamOwner : StreamOwner!
	var viewRange : RouteIndexRange?
	
	// Private data
	

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    
	func setProfile<S> (streamOwner: S, profileType: StravaSwift.StreamType, range: RouteIndexRange? = nil) where S : StreamOwner {
		CoreDataManager.sharedManager().persistentContainer.performBackgroundTask { (context) in
			let asyncActivity = context.object(with: streamOwner.objectID) as! S
			
			var profileData = ViewProfileData(profileDataSets: [], highlightRange: nil, rangeChangedHandler: nil)
			
			let streams = asyncActivity.streams.map { $0.type }
			appLog.debug("Streams are \(streams)")
			
			if let stream = (asyncActivity.streams.filter { $0.type == profileType.rawValue }).first {
				appLog.debug("Start sort \(stream.dataPoints.count)")
				
				let dataStream = stream.dataPoints.sorted(by: { $0.index < $1.index }).map({ $0.dataPoint })
				appLog.debug("End sort")
				profileData.profileDataSets.append(ViewProfileDataSet(profileDataType: ViewProfileDataType(rawValue: profileType.rawValue)!, profileDataPoints: dataStream ))
			}
			
			DispatchQueue.main.async {
				self.routeView.profileData = profileData
				if range != nil {
					self.routeView.viewRange = range
				}
			}
		}
	}
}
