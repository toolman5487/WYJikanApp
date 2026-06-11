//
//  DetailToolbarPresentation.swift
//  WYJikanApp
//

import Foundation

enum DetailToolbarPresentation {
    static func reviewState(title: String?) -> DetailNavigationToolbarReviewState {
        guard let title else { return .loading }
        return .available(title: title)
    }

    static func shareState(
        title: String?,
        message: String?,
        url: URL?
    ) -> DetailNavigationToolbarShareState {
        guard let title, let message, let url else { return .loading }
        return .available(title: title, message: message, url: url)
    }
}
