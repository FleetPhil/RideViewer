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
	var streams: Set<RVStream> { get }      // Raw streams
    /// Get streams or retrieve from Strave, return streams in completion handler
    func streams(completionHandler : (@escaping (Set<RVStream>?)->Void))
    /// Set the StreamOwner as the owner of the stream data
	func setAsOwnerForStream(_ stream : RVStream)
}

extension StreamOwner {
	func hasStreamOfType(_ type : RVStreamDataType) -> Bool {
		return self.streams.filter({ $0.type == type }).first != nil
	}
    
    func streamOfType(_ type : RVStreamDataType) -> RVStream? {
        return self.streams.filter({ $0.type == type }).first
    }
    
    var streamTypes : [RVStreamDataType] {
        return self.streams.map({ $0.type })
    }
    
    func dataPoints(valueStreamType : RVStreamDataType, axisStreamType : RVStreamDataType) -> [DataPoint]? {
        if let valueStream = self.streamOfType(valueStreamType), let axisStream = self.streamOfType(axisStreamType)  {
            return valueStream.dataPointsWithAxis(axisStream)
        } else {
            return nil
        }
    }
    
    /**
     Get stream data for this entity as an array of DataPoints
     
     Calls completion handler with nil if stream data not available or invalid for this object
     
     - Parameters:
     - streamType: type of stream data (only .altitude valid for activities)
     - seriesType: .distance or .time
     - completionHandler: function called with the returned data points
     - dataPoints: array of DataPoint for the stream
     - Returns: none
     */
    func dataPointsForStreamType(_ streamType: RVStreamDataType, seriesType: RVStreamDataType, completionHandler : @escaping (_ dataPoints: [DataPoint]?)->Void) -> Void {
        
        appLog.verbose("Target: \(streamType.stringValue), streams are \(self.streams.map { $0.type })")
        
        guard streamType.isValidStreamForObjectType(type: self) else {
            appLog.error("Invalid stream type \(streamType) for activity")
            completionHandler(nil)
            return
        }
        
        self.streams(completionHandler: ({ streams in
            if streams == nil {
                appLog.debug("Failed to get data streams")
                completionHandler(nil)
                return
            }
            completionHandler(self.dataPoints(valueStreamType: streamType, axisStreamType: seriesType))
            
        }))
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
