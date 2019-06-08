//
//  RefreshViewController.swift
//  RideViewer
//
//  Created by West Hill Lodge on 03/06/2019.
//  Copyright © 2019 Home. All rights reserved.
//

import UIKit
import CoreData


class RefreshViewController: UIViewController {

    @IBOutlet weak var progressLabel: UILabel!
    @IBOutlet weak var progressView: UIProgressView!
    @IBOutlet weak var doneButton: UIButton!

    var athleteActivityCount : Float = 0.0
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.doneButton.isEnabled = false
        self.progressView.isHidden = true
        
        self.progressLabel.text = StravaStatus.connecting.statusText
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        progressLabel.text = StravaStatus.connected.statusText
        
        // Get athlete stats
        StravaManager.sharedInstance.refreshAthlete(context: CoreDataManager.sharedManager().viewContext) { (stravaStatus) in
            self.progressLabel.text = stravaStatus.statusText
            if case .athleteStats(let activityCount) = stravaStatus {
                self.athleteActivityCount = Float(activityCount)
            }
            
            // Get activity updates
            self.progressView.isHidden = false
            self.getActivities(context: CoreDataManager.sharedManager().viewContext) { (stravaStatus) in
                self.progressLabel.text = stravaStatus.statusText
                switch stravaStatus {
                case .updateComplete :                      self.doneButton.isEnabled = true
                                                            self.progressView.progress = 1.0
                case .updatingActivities(let updateCount):  self.progressView.progress = Float(updateCount)/self.athleteActivityCount
                default:                                    appLog.error("Unexpected status")
                }
            }
        }
    }
    
    private func getActivities(context: NSManagedObjectContext, progressHandler : @escaping (StravaStatus)->Void) {
        var detailedActivityCount : Int = 0
        StravaManager.sharedInstance.getAthleteActivities(page: 1, context: context, progressHandler: { newActivity, finished in
            if finished {
                context.saveContext()
                progressHandler(.updateComplete)
            } else {                    // Not finished - get details for the retrieved activity
                if let activity = newActivity {
                    activity.detailedActivity(completionHandler: { (detailedActivity) in
                        detailedActivityCount += 1
                        progressHandler(.updatingActivities(detailedActivityCount))
                    })
                }
            }
        })
    }

    private func unsetAllEffortsFlags() {
        let predicate = NSPredicate(format: "allEfforts == %@", argumentArray: [NSNumber(value: true)])
        if let segments : [RVSegment] = CoreDataManager.sharedManager().viewContext.fetchObjects(withPredicate: predicate, withSortDescriptor: nil) {
            segments.forEach({ $0.allEfforts = false })
        }
    }
}
