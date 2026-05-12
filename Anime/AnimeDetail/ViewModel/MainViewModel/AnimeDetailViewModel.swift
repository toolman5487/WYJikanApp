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
    enum ScreenState {
        case loading
        case refreshing(AnimeDetailDTO)
        case loaded(AnimeDetailDTO)
        case error(String)
    }

    @Published private(set) var screenState: ScreenState = .loading
    @Published private(set) var pictureItems: [AnimeDetailPictureItem] = []

    private let malId: Int
    private let service: AnimeDetailServicing

    init(malId: Int, service: AnimeDetailServicing = AnimeDetailService()) {
        self.malId = malId
        self.service = service
    }

    var detail: AnimeDetailDTO? {
        switch screenState {
        case let .refreshing(detail), let .loaded(detail):
            return detail
        case .loading, .error:
            return nil
        }
    }

    var isRefreshing: Bool {
        if case .refreshing = screenState {
            return true
        }
        return false
    }

    private var isInitialLoading: Bool {
        if case .loading = screenState {
            return true
        }
        return false
    }

    // MARK: - Load

    func load(forceRefresh: Bool = false) async {
        let existingDetail = detail
        guard forceRefresh || existingDetail == nil else { return }
        guard !isRefreshing, !(existingDetail == nil && isInitialLoading) else { return }

        if existingDetail == nil {
            screenState = .loading
            pictureItems = []
        } else if let existingDetail {
            screenState = .refreshing(existingDetail)
        }

        do {
            let resolvedDetail = try await service.fetchAnimeDetail(malId: malId)
            let detail = resolvedDetail.data
            screenState = .loaded(detail)
            do {
                let resolvedPictures = try await service.fetchAnimePictures(malId: malId)
                pictureItems = AnimeDetailPictureMapping.items(from: resolvedPictures)
            } catch is CancellationError {
                return
            } catch {
                if existingDetail == nil {
                    pictureItems = []
                }
            }
        } catch is CancellationError {
            return
        } catch {
            if let existingDetail, forceRefresh {
                screenState = .loaded(existingDetail)
            } else {
                screenState = .error(error.localizedDescription)
                pictureItems = []
            }
        }
    }
}
