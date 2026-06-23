//
//  ErrorMessageKind.swift
//  WYJikanApp
//
//  Created by Codex on 2026/6/12.
//

import Foundation

nonisolated enum ErrorMessageLoadContext: Sendable {
    case initial
    case loadMore
}

nonisolated enum ErrorMessageKind: Equatable, Sendable {
    case network
    case serverError
    case rateLimited
    case timeout
    case noSearchResults
    case emptyCollection
    case filteredEmpty
    case notFound
    case loadMoreFailed
    case unavailable
    case permissionDenied

    static func resolving(from error: Error) -> Self {
        if let urlError = error as? URLError {
            switch urlError.code {
            case .timedOut:
                return .timeout
            case .notConnectedToInternet:
                return .network
            case .networkConnectionLost:
                return .network
            case .cancelled:
                return .unavailable
            default:
                return .network
            }
        }

        if let jikanError = error as? JikanAPIError {
            switch jikanError {
            case .rateLimited:
                return .rateLimited
            case .serverError:
                return .serverError
            case .networkError(let underlyingError):
                return resolving(from: underlyingError)
            case .noData:
                return .emptyCollection
            case .decodingError:
                return .unavailable
            case .invalidURL:
                return .unavailable
            }
        }

        if error is HomeWatchServiceError {
            return .unavailable
        }

        return .network
    }

    static func resolving(message: String, context: ErrorMessageLoadContext = .initial) -> Self {
        if context == .loadMore || message.contains("載入更多") {
            return .loadMoreFailed
        }

        if message.contains("逾時") {
            return .timeout
        }

        if message.contains("請求太頻繁") {
            return .rateLimited
        }

        if message.contains("伺服器") {
            return .serverError
        }

        if message.contains("找不到") {
            return .notFound
        }

        if message.contains("尚無") || message.contains("沒有可顯示") {
            return .emptyCollection
        }

        if message.contains("權限") || message.contains("通知") {
            return .permissionDenied
        }

        if message.contains("暫時無法") || message.contains("暫時異常") {
            return .unavailable
        }

        return .network
    }
}
