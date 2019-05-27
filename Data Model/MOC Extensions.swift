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

extension NSManagedObjectContext {
	
	// Return count of entitity instances
	func countOfObjects(_ entity: NSManagedObject.Type, withPredicate predicate: NSPredicate? = nil) -> Int?  {
		let fetchRequest = entity.fetchRequest()

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
	func fetchObject<Entity : NSManagedObject>(withKeyValue keyValue: String,forKey key: String) -> Entity? {
		let predicateFormat = "\(key) = \"\(keyValue)\""
		let predicate = NSPredicate(format: predicateFormat, argumentArray: nil)
		let results : [Entity]? = self.fetchObjects(withPredicate: predicate, withSortDescriptor: nil)
		return results?.last
	}

	// Overloaded for entities with Int key
	func fetchObject<Entity : NSManagedObject>(withKeyValue keyValue: Int,forKey key: String) -> Entity? {
		let predicateFormat = "\(key) = \(keyValue)"
		let predicate = NSPredicate(format: predicateFormat, argumentArray: nil)
		let results : [Entity]? = self.fetchObjects(withPredicate: predicate, withSortDescriptor: nil)
		return results?.last
	}
	
	// Generic retrieve function
	func fetchObjects<Entity : NSManagedObject> (withPredicate predicate: NSPredicate? = nil, withSortDescriptor sortDescriptor: NSSortDescriptor? = nil) -> [Entity]? {
		let fetchRequest = Entity.fetchRequest()

		if predicate != nil { fetchRequest.predicate = predicate! }
		if sortDescriptor != nil { fetchRequest.sortDescriptors = [sortDescriptor!] }
		
		let error: NSErrorPointer? = nil
		let results: [Entity]?
		do {
			results = try self.fetch(fetchRequest) as? [Entity]
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
	
	func deleteObjects<T : NSManagedObject>(_ objects : Set<T>) -> Bool {
		return self.deleteObjects(Array(objects))
	}
	
	func deleteObjects<T : NSManagedObject>(_ objects : [T]) -> Bool {
		objects.forEach({ object in
			self.delete(object)
		})
		return true
	}
	
//	func deleteAllObjects(_ objectType : NSManagedObject.Type) -> Bool {
//		let batchDeleteRequest = NSBatchDeleteRequest(fetchRequest: objectType.fetchRequest())
//		do {
//			try self.execute(batchDeleteRequest)
//		} catch {
//			let nserror = error as NSError
//			appLog.error("Unresolved error \(nserror), \(nserror.userInfo)")
//			return false
//		}
//        return true
//	}
	
    func saveContext () {
        if self.hasChanges {
            do {
				appLog.verbose("Saving changes: \(Thread.isMainThread ? "is" : "is not") main thread, context \(self == CoreDataManager.sharedManager().viewContext ? "is" : "is not") view context")
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

