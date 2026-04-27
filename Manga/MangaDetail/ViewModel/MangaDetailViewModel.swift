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
    enum ScreenState {
        case loading
        case loaded(MangaDetailDTO)
        case error(String)
    }

    @Published private(set) var detail: MangaDetailDTO?
    @Published private(set) var errorMessage: String?
    @Published private(set) var isLoading = false

    private let malId: Int
    private let service: MangaDetailServicing

    init(malId: Int, service: MangaDetailServicing = MangaDetailService()) {
        self.malId = malId
        self.service = service
    }

    var screenState: ScreenState {
        if let detail {
            return .loaded(detail)
        }
        if let errorMessage, !errorMessage.isEmpty {
            return .error(errorMessage)
        }
        return .loading
    }

    // MARK: - Load

    func load(forceRefresh: Bool = false) async {
        guard forceRefresh || detail == nil else { return }
        guard !isLoading else { return }

        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            let response = try await service.fetchMangaDetail(malId: malId)
            detail = response.data
        } catch is CancellationError {
            return
        } catch {
            errorMessage = error.localizedDescription
            if !forceRefresh {
                detail = nil
            }
        }
    }
}
