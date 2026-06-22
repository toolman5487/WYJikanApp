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
        isPad ? 4 : 3
    }

    var categoryGenreItemRequestLimit: Int {
        isPad ? 8 : 5
    }
}

// MARK: - MainHome

nonisolated extension UserInterfacePlatform {
    var loadsHomeDeferredSectionsWhenVisible: Bool {
        isPhone
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
