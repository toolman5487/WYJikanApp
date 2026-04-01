//
//  MangaDetailViewModel.swift
//  WYJikanApp
//
//  Created by Willy Hsu on 2026/4/1.
//

import Combine
import Foundation

@MainActor
final class MangaDetailViewModel: ObservableObject {

    @Published private(set) var detail: MangaDetailDTO?
    @Published private(set) var errorMessage: String?

    private let malId: Int
    private let service: MangaDetailServicing

    init(malId: Int, service: MangaDetailServicing = MangaDetailService()) {
        self.malId = malId
        self.service = service
    }

    // MARK: - Load

    func load() async {
        guard detail == nil else { return }

        errorMessage = nil

        do {
            let response = try await service.fetchMangaDetail(malId: malId)
            detail = response.data
        } catch is CancellationError {
            return
        } catch {
            errorMessage = error.localizedDescription
            detail = nil
        }
    }
}
