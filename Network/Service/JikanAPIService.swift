//
//  JikanAPIService.swift
//  WYJikanApp
//
//

import Foundation

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
        
        do {
            let (data, response) = try await session.data(for: request)
            
            if let httpResponse = response as? HTTPURLResponse, !(200...299).contains(httpResponse.statusCode) {
                throw JikanAPIError.serverError(statusCode: httpResponse.statusCode)
            }
            
            guard !data.isEmpty else {
                throw JikanAPIError.noData
            }
            
            do {
                let decoded = try decoder.decode(T.self, from: data)
                return decoded
            } catch {
                throw JikanAPIError.decodingError(error)
            }
        } catch let apiError as JikanAPIError {
            throw apiError
        } catch {
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
        
        do {
            let (data, response) = try await session.data(for: request)
            
            if let httpResponse = response as? HTTPURLResponse, !(200...299).contains(httpResponse.statusCode) {
                throw JikanAPIError.serverError(statusCode: httpResponse.statusCode)
            }
            
            guard !data.isEmpty else {
                throw JikanAPIError.noData
            }
            
            do {
                let decoded = try decoder.decode(T.self, from: data)
                return decoded
            } catch {
                throw JikanAPIError.decodingError(error)
            }
        } catch let apiError as JikanAPIError {
            throw apiError
        } catch {
            throw JikanAPIError.networkError(error)
        }
    }
}
