//
//  AppDelegate.swift
//  TellCoreData
//
//  Created by Sean Coleman on 8/17/16.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    var coreDataManager: CoreDataManager?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {

        coreDataManager = CoreDataManager()

        let vc = self.window?.rootViewController as? ViewController
        vc?.colorService = ColorService(coreDataManager: coreDataManager)
        vc?.speechService = SpeechService()
        vc?.coreDataManager = coreDataManager

        return true
    }

    func applicationWillTerminate(_ application: UIApplication) {
        coreDataManager?.saveContext()
    }
}
