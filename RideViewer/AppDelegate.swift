//
//  AppDelegate.swift
//  RideViewer
//
//  Created by Home on 23/12/2018.
//  Copyright © 2018 Home. All rights reserved.
//

import UIKit
import CoreData
import StravaSwift
import XCGLogger

// Set up app logging
let appLog : XCGLogger = {
	let appDelegate = UIApplication.shared.delegate as! AppDelegate
	let log = XCGLogger.default
	log.outputLevel = .debug
	
	// Set up debug log and user log
	// TODO: debug log should not be in documents
	let debugLogPath: URL = appDelegate.documentsDirectory.appendingPathComponent("Load Log.txt")
	let debugFileDestination = FileDestination(writeToFile: debugLogPath)
	debugFileDestination.outputLevel = .verbose
	debugFileDestination.showLogIdentifier = true
	debugFileDestination.showFunctionName = true
	debugFileDestination.showThreadName = true
	debugFileDestination.showLevel = true
	debugFileDestination.showFileName = false
	debugFileDestination.showLineNumber = false
	debugFileDestination.showDate = true
	log.add(destination: debugFileDestination)
	return log
}()

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

	var window: UIWindow?
	
	func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
		// Override point for customization after application launch.
		
		// Add basic app info, version info etc, to the start of the logs
		appLog.logAppDetails()
		
		// Initialise settings
		let _ = Settings.sharedInstance

		return true
	}
	
	func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
		let strava = StravaClient.sharedInstance
		guard let code = strava.handleAuthorizationRedirect(url) else { return false }
		NotificationCenter.default.post(name: Notification.Name("code"), object: code )
		
		return true
	}

	func applicationWillResignActive(_ application: UIApplication) {
		// Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
		// Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
	}
	
	func applicationDidEnterBackground(_ application: UIApplication) {
		// Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
		// If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
		CoreDataManager.sharedManager().viewContext.saveContext()
	}
	
	func applicationWillEnterForeground(_ application: UIApplication) {
		// Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
	}
	
	func applicationDidBecomeActive(_ application: UIApplication) {
		// Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
	}
	
	func applicationWillTerminate(_ application: UIApplication) {
		// Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
		// Saves changes in the application's managed object context before the application terminates.
		CoreDataManager.sharedManager().viewContext.saveContext()
	}

	let documentsDirectory: URL = {
		let urls = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
		return urls[urls.endIndex - 1]
	}()
}
