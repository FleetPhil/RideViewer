//
//  Constants.swift
//  RideViewer
//
//  Created by Home on 20/03/2019.
//  Copyright © 2019 Home. All rights reserved.
//

import Foundation
import UIKit

struct StravaConstants {
	static let ClientID			= 8785
	static let ClientSecret		= "3b200baf949c02246425b3b6fb5957409a7fdb00"
	static let ItemsPerPage 	= 100
}

struct EmojiConstants {
	static let Camera			= "📷"
	static let HeartRate		= "❤️"
	static let Power			= "🔌"
	static let Fastest			= "🏆"
}

struct StravaStreamType {
	static let Activity 		= "distance,altitude"
	static let Effort			= "watts,heartrate,time,cadence,velocity_smooth,distance"
    
    static let EffortAnalysisTypes : [RVStreamDataType] = [.speed, .heartRate, .cadence, .power, .gearRatio]
    static let InitialAnalysisType : RVStreamDataType = .speed
}

struct DisplayConstants {
    static let ProfileDistanceIncrement : Double = 10.0         // Number of metres per data point
	static let ScreenPointsPerDataPoint : CGFloat = 2
	static let LimitLineColour : UIColor = UIColor.red
    static let PrimaryProfileColour = UIColor.purple
    static let SecondaryProfileColour = UIColor.blue
}

struct BikeConstants {
	static let Circumference 	= 2136
	static let InnerChainRing 	= 34
	static let OuterChainRing	= 50
	
}

struct SettingsConstants {
    static let ActivityFilterKey    = "ActivityFilter"
    static let SegmentFilterKey     = "SegmentFiltyer"
    static let EffortFilterKey      = "EffortFilter"

    static let ActivitySortKey      = "ActivitySort"
    static let SegmentSortKey       = "SegmentSort"
    static let EffortSortKey        = "EffortSort"
}



