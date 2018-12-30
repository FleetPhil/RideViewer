//
//  Display Extensions.swift
//  RideViewer
//
//  Created by Home on 24/12/2018.
//  Copyright © 2018 Home. All rights reserved.
//

import Foundation

// Date formats for display
enum timeDateContent {
	case dateTime
	case yearOnly
	case monthOnly
	case dateOnly
	case timeOnly
	case timeWithTZ
	case dateTimeWithTZ
	
	var formatString : String {
		switch self {
		case .dateOnly: return "dd-MMM-yy"
		case .dateTime: return "dd-MMM-yy HH:mm"
		case .timeOnly: return "HH:mm"
		case .timeWithTZ: return "HH:mm"
		case .dateTimeWithTZ: return "dd-MMM-yy HH:mm"
		case .yearOnly: return "yyyy"
		case .monthOnly: return "MMM yy"
		}
	}
}

extension Date {
	func displayString(displayType : timeDateContent = .dateTime,
					   timeZone : TimeZone = TimeZone(identifier: "UTC")!) -> String {
		let dateFormatter        = DateFormatter()
		let timeZoneSuffix        : String!
		
		// Work out the timezone for the date
		dateFormatter.timeZone = timeZone
		timeZoneSuffix = timeZone.abbreviation()
		
		dateFormatter.dateFormat = displayType.formatString
		if displayType == .timeWithTZ || displayType == .dateTimeWithTZ {
			return(dateFormatter.string(from: self)) + " " + timeZoneSuffix
		} else {
			return(dateFormatter.string(from: self))
		}
		
	}
}

