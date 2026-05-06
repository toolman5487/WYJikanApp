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

    @Published private(set) var screenState: ScreenState = .loading
    @Published private(set) var isLoading = false

    private let malId: Int
    private let service: MangaDetailServicing

    init(malId: Int, service: MangaDetailServicing = MangaDetailService()) {
        self.malId = malId
        self.service = service
    }

    var detail: MangaDetailDTO? {
        switch screenState {
        case .loaded(let detail):
            return detail
        case .loading, .error:
            return nil
        }
    }

    // MARK: - Load

    func load(forceRefresh: Bool = false) async {
        let existingDetail = detail
        guard forceRefresh || existingDetail == nil else { return }
        guard !isLoading else { return }

        isLoading = true
        if existingDetail == nil {
            screenState = .loading
        }
        defer { isLoading = false }

        do {
            let response = try await service.fetchMangaDetail(malId: malId)
            screenState = .loaded(response.data)
        } catch is CancellationError {
            return
        } catch {
            if let existingDetail, forceRefresh {
                screenState = .loaded(existingDetail)
            } else {
                screenState = .error(error.localizedDescription)
            }
        }
    }
}
