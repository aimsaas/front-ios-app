//
//  HerApp.swift
//  Her
//
//  Created by dev on 2025/9/30.
//

//import SwiftUI
//import SwiftData
//
//@main
//struct HerApp: App {
//    var sharedModelContainer: ModelContainer = {
//        let schema = Schema([
//            Item.self,
//        ])
//        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
//
//        do {
//            return try ModelContainer(for: schema, configurations: [modelConfiguration])
//        } catch {
//            fatalError("Could not create ModelContainer: \(error)")
//        }
//    }()
//
//    var body: some Scene {
//        WindowGroup {
//            ContentView()
//        }
//        .modelContainer(sharedModelContainer)
//    }
//}


import SwiftUI
import SwiftData

enum Template: String {
    case Silver
    case Platinum
    case Diamond
    case Default
}

@main
struct HerApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Item.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    // 这里假设从存储里读到 Template 的值
    var selectedTemplate: Template = .Default

    var body: some Scene {
        WindowGroup {
            switch selectedTemplate {
            case .Silver:
                Silver()
            case .Platinum:
                Platinum()
            case .Diamond:
                Diamond()
            case .Default:
                DefaultView()
            }
        }
        .modelContainer(sharedModelContainer)
    }
}
