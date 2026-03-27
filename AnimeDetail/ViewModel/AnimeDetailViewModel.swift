//
//  AnimeDetailViewModel.swift
//  WYJikanApp
//
//  Created by Willy Hsu on 2026/3/27.
//

import Combine
import Foundation

@MainActor
final class AnimeDetailViewModel: ObservableObject {

    @Published private(set) var detail: AnimeDetailDTO?
    @Published private(set) var errorMessage: String?

    private let malId: Int
    private let service: AnimeDetailServicing

    init(malId: Int, service: AnimeDetailServicing = AnimeDetailService()) {
        self.malId = malId
        self.service = service
    }

    func load() async {
        guard detail == nil else { return }

        errorMessage = nil

        do {
            let response = try await service.fetchAnimeDetail(malId: malId)
            detail = response.data
        } catch is CancellationError {
            return
        } catch {
            errorMessage = error.localizedDescription
            detail = nil
        }
    }
}
