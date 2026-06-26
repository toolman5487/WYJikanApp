//
//  UserInterfacePlatform.swift
//  WYJikanApp
//
//

import Foundation
import UIKit

// MARK: - UserInterfacePlatform

nonisolated enum UserInterfacePlatform: Sendable {
    case phone
    case pad
}

// MARK: - Resolution

nonisolated extension UserInterfacePlatform {
    init(userInterfaceIdiom: UIUserInterfaceIdiom) {
        self = userInterfaceIdiom == .pad ? .pad : .phone
    }
    
    var isPhone: Bool {
        self == .phone
    }
    
    var isPad: Bool {
        self == .pad
    }
}

extension UserInterfacePlatform {
    @MainActor
    static var current: UserInterfacePlatform {
        UserInterfacePlatform(userInterfaceIdiom: UIDevice.current.userInterfaceIdiom)
    }
}

// MARK: - MainCategoryList

nonisolated extension UserInterfacePlatform {
    var categoryGenreInitialBatchCount: Int {
        isPad ? 3 : 3
    }
    
    var categoryGenreLoadMoreBatchCount: Int {
        isPad ? 3 : 5
    }
    
    var categoryGenreItemRequestLimit: Int {
        isPad ? 8 : 5
    }
    
    var categoryGenreConcurrentFetchCount: Int {
        isPad ? 1 : 2
    }
    
    var categoryGenreInitialRequestDelay: Duration {
        .milliseconds(500)
    }
    
    var categoryGenreRequestInterval: Duration {
        isPad ? .seconds(1) : .zero
    }
}

// MARK: - MainHome

nonisolated extension UserInterfacePlatform {
    var loadsHomeDeferredSectionsWhenVisible: Bool {
        isPhone
    }
    
    var shouldPreloadHomeDeferredSections: Bool {
        isPad
    }
    
    var homeDeferredSectionLoadDelay: Duration {
        isPad ? .milliseconds(500) : .zero
    }
}

// MARK: - MainMyList

nonisolated extension UserInterfacePlatform {
    var prefersSideBySideStatisticsCharts: Bool {
        isPad
    }
    
    var statisticsChartCardMinHeight: CGFloat {
        isPad ? 336 : 280
    }
    
    var statisticsChartContentMinHeight: CGFloat {
        isPad ? 232 : 208
    }
}
