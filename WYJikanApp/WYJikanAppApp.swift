//
//  WYJikanAppApp.swift
//  WYJikanApp
//
//  Created by Willy Hsu on 2026/3/24.
//

import SwiftUI
import SwiftData

@main
struct WYJikanAppApp: App {
    var body: some Scene {
        WindowGroup {
            MainTabBarView()
                .preferredColorScheme(.dark)
                .dynamicTypeSize(.medium)
        }
        .modelContainer(for: [MyListCollectionItem.self])
    }
}
