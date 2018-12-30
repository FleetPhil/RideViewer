//
//  Data Extensions.swift
//  FlightLog
//
//  Created by Philip Diggens on 07/08/2014.
//  Copyright (c) 2014 Philip Diggens. All rights reserved.
//

import Foundation
import CoreData
import UIKit

// Singleton class for Core Data Stack
class CoreDataManager {
    private static var sharedCoreDataManager : CoreDataManager = {
        let coreDataManager = CoreDataManager()
        return coreDataManager
    }()

    class func sharedManager() -> CoreDataManager {
        return sharedCoreDataManager
    }
    
    var viewContext : NSManagedObjectContext {
        return persistentContainer.viewContext
    }
    
    lazy var persistentContainer: NSPersistentContainer = {
        /*
         The persistent container for the application. This implementation
         creates and returns a container, having loaded the store for the
         application to it. This property is optional since there are legitimate
         error conditions that could cause the creation of the store to fail.
         */
        let container = NSPersistentContainer(name: "RideViewer")
        
        var applicationSupportDirectory = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).last
        if applicationSupportDirectory == nil {
            fatalError("Can't find docs directory")
        }
		
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                
                /*
                 Typical reasons for an error here include:
                 * The parent directory does not exist, cannot be created, or disallows writing.
                 * The persistent store is not accessible, due to permissions or data protection when the device is locked.
                 * The device is out of space.
                 * The store could not be migrated to the current model version.
                 Check the error message to determine what the actual problem was.
                 */
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
            
            let path = container.persistentStoreDescriptions[0].url
        })
        return container
    }()
}

// Extension to return entity name
extension NSManagedObject {
    static var entityName : String {
        let fullName = self.entity().managedObjectClassName!
        if let index = fullName.index(of: ".") {
            let substring = String(fullName[(fullName.index(after: index))...])
            return substring
        } else {
            return fullName
        }
    }
}

extension NSManagedObjectContext {
	
	// Return count of entitity instances
	func countOfObjectsForEntityName (_ entityName: String, withPredicate predicate: NSPredicate? = nil) -> Int?  {
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: entityName)
		fetchRequest.entity = NSEntityDescription.entity(forEntityName: entityName, in: self)
		if predicate != nil {
			fetchRequest.predicate = predicate!
		}
		
        do {
            let count = try self.count(for: fetchRequest)
            return count
        } catch {
            print("fetchObjectsForEntityName: error: \(error)")
            return nil
        }
	}
	
	// Return one object with the specified key
	func fetchObjectForEntityName (_ entityName: String, withKeyValue keyValue: String,forKey key: String) -> AnyObject? {
		let predicateFormat = "\(key) = \"\(keyValue)\""
		let predicate = NSPredicate(format: predicateFormat, argumentArray: nil)
		let results = self.fetchObjectsForEntityName(entityName, withPredicate: predicate, withSortDescriptor: nil)
		return results?.last
	}
	// Overloaded for entities with Int key
	func fetchObjectForEntityName (_ entityName: String, withKeyValue keyValue: Int,forKey key: String) -> AnyObject? {
		let predicateFormat = "\(key) = \(keyValue)"
		let predicate = NSPredicate(format: predicateFormat, argumentArray: nil)
		let results = self.fetchObjectsForEntityName(entityName, withPredicate: predicate, withSortDescriptor: nil)
		return results?.last
	}

	// Generic retrieve function
	func fetchObjectsForEntityName (_ entityName: String, withPredicate predicate: NSPredicate? = nil, withSortDescriptor sortDescriptor: NSSortDescriptor? = nil) -> [AnyObject]? {
		
		let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: entityName)
		fetchRequest.entity = NSEntityDescription.entity(forEntityName: entityName, in: self)
		
		if predicate != nil {
			fetchRequest.predicate = predicate!
		}
		if sortDescriptor != nil {
			fetchRequest.sortDescriptors = [sortDescriptor!]
		}
		
		let error: NSErrorPointer? = nil
		let results: [AnyObject]?
		do {
			results = try self.fetch(fetchRequest)
		} catch let error1 as NSError {
			error??.pointee = error1
			results = nil
		}
		if (error != nil)
		{
			print("fetchObjectsForEntityName: error: \(String(describing: error))")
			return nil
		}

		return results
		
	}
	
	func deleteObjectsForEntityName (_ entityName: String ) -> Int {
		
		var count = 0
		
		if let items = self.fetchObjectsForEntityName(entityName) {
			for object in items {
				self.delete(object as! NSManagedObject)
				count += 1
			}
		}

        return count
	}
    
    func saveContext () {
        if self.hasChanges {
            do {
                try self.save()
            } catch {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                let nserror = error as NSError
                print("Unresolved error \(nserror), \(nserror.userInfo)")
				abort()
            }
        }
    }
}

