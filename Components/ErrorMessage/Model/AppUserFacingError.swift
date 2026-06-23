//
//  AppUserFacingError.swift
//  WYJikanApp
//
//  Created by Willy Hsu on 2026/3/26.
//

import Foundation

nonisolated protocol AppUserFacingError: Error {
    nonisolated var userMessage: String { get }
}

extension Error {
    nonisolated var userFacingMessage: String {
        if let error = self as? any AppUserFacingError {
            return error.userMessage
        }

        if let urlError = self as? URLError {
            return urlError.userMessage
        }

        return "目前無法載入資料，請稍後再試。"
    }
}

private extension URLError {
    nonisolated var userMessage: String {
        switch code {
        case .notConnectedToInternet:
            return "網路連線不穩，請確認連線後再試。"
        case .networkConnectionLost:
            return "網路連線不穩，請確認連線後再試。"
        case .timedOut:
            return "連線逾時，請稍後再試。"
        case .cannotFindHost:
            return "目前無法連上伺服器，請稍後再試。"
        case .cannotConnectToHost:
            return "目前無法連上伺服器，請稍後再試。"
        case .dnsLookupFailed:
            return "目前無法連上伺服器，請稍後再試。"
        case .cancelled:
            return "操作已取消。"
        default:
            return "網路連線暫時異常，請稍後再試。"
        }
    }
}
