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
    enum ViewState {
        case loading
        case content(AnimeDetailDTO)
        case error(String)
    }

    @Published private(set) var detail: AnimeDetailDTO?
    @Published private(set) var pictureItems: [AnimeDetailPictureItem] = []
    @Published private(set) var errorMessage: String?
    @Published private(set) var isLoading = false

    private let malId: Int
    private let service: AnimeDetailServicing

    init(malId: Int, service: AnimeDetailServicing = AnimeDetailService()) {
        self.malId = malId
        self.service = service
    }

    var viewState: ViewState {
        if let detail {
            return .content(detail)
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
        if !forceRefresh {
            pictureItems = []
        }
        defer { isLoading = false }

        do {
            let resolvedDetail = try await service.fetchAnimeDetail(malId: malId)
            detail = resolvedDetail.data
            do {
                let resolvedPictures = try await service.fetchAnimePictures(malId: malId)
                pictureItems = AnimeDetailPictureMapping.items(from: resolvedPictures)
            } catch is CancellationError {
                return
            } catch {
                if !forceRefresh {
                    pictureItems = []
                }
            }
        } catch is CancellationError {
            return
        } catch {
            errorMessage = error.localizedDescription
            if !forceRefresh {
                detail = nil
                pictureItems = []
            }
        }
    }
}
