//
//  CoreDataStack.swift
//  Erudit AI
//
//  Created by Benedikt Bachmetjev on 18/10/2025.
//

import Foundation
import CoreData
import Combine

class CoreDataStack: ObservableObject {
    static let shared = CoreDataStack()
    
    lazy var persistentContainer: NSPersistentContainer = {
        // Try to load the model from the bundle
        guard let modelURL = Bundle.main.url(forResource: "BookModel", withExtension: "momd") else {
            print("❌ Core Data: Could not find BookModel.momd in bundle")
            // Create a minimal container as fallback
            let container = NSPersistentContainer(name: "BookModel")
            return container
        }
        
        guard let model = NSManagedObjectModel(contentsOf: modelURL) else {
            print("❌ Core Data: Could not load model from \(modelURL)")
            let container = NSPersistentContainer(name: "BookModel")
            return container
        }
        
        let container = NSPersistentContainer(name: "BookModel", managedObjectModel: model)
        container.loadPersistentStores { storeDescription, error in
            if let error = error {
                print("❌ Core Data error: \(error)")
                print("Store description: \(storeDescription)")
            } else {
                print("✅ Core Data loaded successfully")
            }
        }
        return container
    }()
    
    // Fallback context for when CoreData is not available
    lazy var fallbackContext: NSManagedObjectContext = {
        let context = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
        return context
    }()
    
    var context: NSManagedObjectContext {
        return persistentContainer.viewContext
    }
    
    func save() {
        let context = persistentContainer.viewContext
        
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                print("Core Data save error: \(error)")
            }
        }
    }
    
    private init() {}
}
