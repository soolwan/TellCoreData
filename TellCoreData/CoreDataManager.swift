//
//  CoreDataManager.swift
//  Future Self
//
//  Created by Sean Coleman on 8/16/16.
//  Copyright © 2016 Sean Coleman. All rights reserved.
//

import Foundation
import CoreData

class CoreDataManager {

    lazy var container: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "DataModel")

        container.loadPersistentStores() { (storeDescription, error) in
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        }

        container.viewContext.automaticallyMergesChangesFromParent = true

        return container
    }()

    func saveContext() {
        let context = container.viewContext
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                let nserror = error as NSError
                fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
            }
        }
    }
}
