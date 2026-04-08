//
//  JikanAPIService.swift
//  WYJikanApp
//
//

import Foundation
import OSLog

enum JikanAPIError: LocalizedError {
    case invalidURL
    case noData
    case decodingError(Error)
    case networkError(Error)
    case serverError(statusCode: Int)
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "The URL is invalid and the request could not be created."
        case .noData:
            return "The server returned no data."
        case .decodingError(let error):
            return "Failed to decode JSON: \(error.localizedDescription)"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .serverError(let statusCode):
            return "Server error (HTTP \(statusCode))."
        }
    }
}

final class JikanAPIService {
    
    static let shared = JikanAPIService()
    
    private var baseURL: String { APIConfig.jikanBaseURL }
    private let session: URLSession
    private let decoder: JSONDecoder
    
    private init(session: URLSession = .shared) {
        self.session = session
        self.decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
    }
    
    // MARK: - Request
    
    func fetch<T: Decodable>(
        endpoint: String,
        queryItems: [URLQueryItem]? = nil
    ) async throws -> T {
        guard var urlComponents = URLComponents(string: baseURL + endpoint) else {
            throw JikanAPIError.invalidURL
        }
        
        if let queryItems, !queryItems.isEmpty {
            urlComponents.queryItems = queryItems
        }
        
        guard let url = urlComponents.url else {
            throw JikanAPIError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        AppLogger.network.debug("GET \(url.absoluteString, privacy: .public)")

        do {
            let (data, response) = try await session.data(for: request)

            if let httpResponse = response as? HTTPURLResponse {
                AppLogger.network.debug(
                    "HTTP \(httpResponse.statusCode) bytes \(data.count) \(url.absoluteString, privacy: .public)"
                )
            }

            if let httpResponse = response as? HTTPURLResponse, !(200...299).contains(httpResponse.statusCode) {
                AppLogger.network.error("server error HTTP \(httpResponse.statusCode) \(url.absoluteString, privacy: .public)")
                throw JikanAPIError.serverError(statusCode: httpResponse.statusCode)
            }

            guard !data.isEmpty else {
                AppLogger.network.error("empty body \(url.absoluteString, privacy: .public)")
                throw JikanAPIError.noData
            }

            do {
                let decoded = try decoder.decode(T.self, from: data)
                return decoded
            } catch {
                AppLogger.decoding.error("decode failed \(url.absoluteString, privacy: .public) \(error.localizedDescription, privacy: .public)")
                throw JikanAPIError.decodingError(error)
            }
        } catch let apiError as JikanAPIError {
            throw apiError
        } catch {
            AppLogger.network.error("request failed \(url.absoluteString, privacy: .public) \(error.localizedDescription, privacy: .public)")
            throw JikanAPIError.networkError(error)
        }
    }

    func fetchFromURL<T: Decodable>(_ urlString: String) async throws -> T {
        guard let url = URL(string: urlString) else {
            throw JikanAPIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        AppLogger.network.debug("GET \(url.absoluteString, privacy: .public)")

        do {
            let (data, response) = try await session.data(for: request)

            if let httpResponse = response as? HTTPURLResponse {
                AppLogger.network.debug(
                    "HTTP \(httpResponse.statusCode) bytes \(data.count) \(url.absoluteString, privacy: .public)"
                )
            }

            if let httpResponse = response as? HTTPURLResponse, !(200...299).contains(httpResponse.statusCode) {
                AppLogger.network.error("server error HTTP \(httpResponse.statusCode) \(url.absoluteString, privacy: .public)")
                throw JikanAPIError.serverError(statusCode: httpResponse.statusCode)
            }

            guard !data.isEmpty else {
                AppLogger.network.error("empty body \(url.absoluteString, privacy: .public)")
                throw JikanAPIError.noData
            }

            do {
                let decoded = try decoder.decode(T.self, from: data)
                return decoded
            } catch {
                AppLogger.decoding.error("decode failed \(url.absoluteString, privacy: .public) \(error.localizedDescription, privacy: .public)")
                throw JikanAPIError.decodingError(error)
            }
        } catch let apiError as JikanAPIError {
            throw apiError
        } catch {
            AppLogger.network.error("request failed \(url.absoluteString, privacy: .public) \(error.localizedDescription, privacy: .public)")
            throw JikanAPIError.networkError(error)
        }
    }
}
