//
//  DataManager.swift
//  FlightLog2
//
//  Created by Phil Diggens on 08/12/2017.
//  Copyright © 2017 Phil Diggens. All rights reserved.
//

import Foundation
import CoreData
import UIKit

class DataManager<Entity: NSManagedObject & TableViewCompatibleEntity> : NSObject,  UITableViewDataSource, NSFetchedResultsControllerDelegate {

    private var fetchedResultsController : NSFetchedResultsController<Entity>!
    private var fetchRequest : NSFetchRequest<Entity>!
	var tableView : UITableView!
    
    // Public properties for sort and filter
    public var filterPredicate : NSCompoundPredicate?
    public var sortDescriptor : NSSortDescriptor?

	// MARK: General instance functions
	func fetchObjects() -> [Entity] {
        // This is UI so need to use view context
		let moc = CoreDataManager.sharedManager().viewContext
		
		fetchRequest = Entity.fetchRequest() as? NSFetchRequest<Entity>
		if let fp = filterPredicate  {
			fetchRequest.predicate = fp
		}
		
		guard sortDescriptor != nil else {			// Fetch request must have  sort descriptor
			appLog.debug("No sort descriptor for fetch")
			return []
		}
		
		fetchRequest.sortDescriptors = [sortDescriptor!]

        fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest,
                                                              managedObjectContext: moc,
                                                              sectionNameKeyPath: nil, cacheName: nil)
        self.fetchedResultsController.delegate = self
    
        do {
            try fetchedResultsController.performFetch()
        } catch {
            appLog.error("Failed to fetch: \(error)")
            return [Entity]()                       // Return empty array
        }

		appLog.verbose("Retrieved \(fetchedResultsController.fetchedObjects?.count ?? -1) objects")
		
        return fetchedResultsController.fetchedObjects ?? [Entity]()
    }
	
    func objectAtIndexPath(_ indexPath : IndexPath) -> Entity? {
        return fetchedResultsController?.sections?[indexPath.section].objects?[indexPath.row] as? Entity
    }
    
    var numberOfObjects : Int? {
        return fetchedResultsController?.fetchedObjects?.count
    }
    
    func indexPathForObject(_ object : Entity) -> IndexPath? {
        return fetchedResultsController.indexPath(forObject: object)
    }
	
	// MARK: Fetched results controller delegate functions
	func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
		tableView?.beginUpdates()
	}
	
	func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
		tableView?.endUpdates()
	}
	
	func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
		switch (type) {
		case .insert:
			if let indexPath = newIndexPath {
				tableView?.insertRows(at: [indexPath], with: .fade)
			}
			break
		case .delete:
			if let indexPath = indexPath {
				tableView?.deleteRows(at: [indexPath], with: .fade)
			}
			break
        case .update:
            if let indexPath = indexPath, let object = anObject as? Entity {
                _ = (tableView?.cellForRow(at: indexPath) as? TableViewCompatibleCell)?.configure(withModel: object)
            }
		default:
			appLog.debug("Unprocessed type is \(type)")
			break
		}
	}
	
	// MARK: Table view data source delegate functions
    func numberOfSections(in tableView: UITableView) -> Int {
        return fetchedResultsController?.sections?.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return fetchedResultsController?.sections?[section].numberOfObjects ?? 0
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        guard let sectionInfo = fetchedResultsController?.sections?[section] else {
            appLog.severe("Invalid section")
			return nil
        }
        return sectionInfo.name
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if let entity = fetchedResultsController.sections?[indexPath.section].objects?[indexPath.row] as? TableViewCompatibleEntity {
            return entity.cellForTableView(tableView: tableView, atIndexPath: indexPath) as! UITableViewCell 
        } else {
            appLog.error("Unable to retrieve table view compatible entity")
            return UITableViewCell()
        }
    }
}

