//
//  StreamOwner.swift
//  RideViewer
//
//  Created by Home on 20/03/2019.
//  Copyright © 2019 Home. All rights reserved.
//

import Foundation
import CoreData
import StravaSwift

// Class objects that own streams adopt this protocol
protocol StreamOwner where Self : NSManagedObject {
	var streams: Set<RVStream> { get }
	func setAsOwnerForStream(_ stream : RVStream)
}

extension StreamOwner {
	func hasStreamOfType(_ type : RVStreamDataType) -> Bool {
		return self.streams.filter({ $0.type == type }).first != nil
	}
}
	
extension RVActivity : StreamOwner {
	func setAsOwnerForStream(_ stream: RVStream) {
		stream.activity = self
	}
}

extension RVSegment : StreamOwner {
	func setAsOwnerForStream(_ stream: RVStream) {
		stream.segment = self
	}
}

extension RVEffort : StreamOwner {
	func setAsOwnerForStream(_ stream: RVStream) {
		stream.effort = self
	}
}
