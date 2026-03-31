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
    @Published private(set) var pictureItems: [AnimeDetailPictureItem] = []
    @Published private(set) var errorMessage: String?

    private let malId: Int
    private let service: AnimeDetailServicing

    init(malId: Int, service: AnimeDetailServicing = AnimeDetailService()) {
        self.malId = malId
        self.service = service
    }

    // MARK: - Load

    func load() async {
        guard detail == nil else { return }

        errorMessage = nil
        pictureItems = []

        do {
            let resolvedDetail = try await service.fetchAnimeDetail(malId: malId)
            detail = resolvedDetail.data
            do {
                let resolvedPictures = try await service.fetchAnimePictures(malId: malId)
                pictureItems = AnimeDetailPictureMapping.items(from: resolvedPictures)
            } catch is CancellationError {
                return
            } catch {
                pictureItems = []
            }
        } catch is CancellationError {
            return
        } catch {
            errorMessage = error.localizedDescription
            detail = nil
            pictureItems = []
        }
    }
}
