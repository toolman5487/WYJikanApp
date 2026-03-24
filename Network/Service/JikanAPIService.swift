//
//  JikanAPIService.swift
//  WYJikanApp
//
//

import Foundation

enum JikanAPIError: Error {
    case invalidURL
    case noData
    case decodingError(Error)
    case networkError(Error)
    case serverError(statusCode: Int)
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

            do {
                let decoded = try decoder.decode(T.self, from: data)
                return decoded
            } catch {
                throw JikanAPIError.decodingError(error)
            }
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

            do {
                let decoded = try decoder.decode(T.self, from: data)
                return decoded
            } catch {
                throw JikanAPIError.decodingError(error)
            }
        } catch {
            throw JikanAPIError.networkError(error)
        }
    }
}
