//
//  TrendingMangaViewModel.swift
//  WYJikanApp
//
//  Created by Willy Hsu on 2026/3/26.
//

import Combine
import Foundation

@MainActor
final class HomeTrendingMangaViewModel: ObservableObject {
    private static let maxCards = 10

    @Published private(set) var items: [HomeTrendingMangaCardItem] = []
    @Published private(set) var isLoading: Bool = false
    @Published private(set) var errorMessage: String?

    private let service: MainHomeServicing
    private var loadTask: Task<Void, Never>?

    init(service: MainHomeServicing = MainHomeService()) {
        self.service = service
    }

    func loadIfNeeded() {
        guard items.isEmpty, !isLoading else { return }
        load()
    }

    func load() {
        loadTask?.cancel()
        isLoading = true
        errorMessage = nil

        loadTask = Task { [weak self] in
            guard let self else { return }
            do {
                let response = try await self.service.fetchTopManga(limit: Self.maxCards)

#if DEBUG
                let summaryLines: [String] = response.data.map { dto in
                    let img = dto.imgUrl ?? "nil"
                    let ext = dto.imgUrl.flatMap { URL(string: $0)?.pathExtension.lowercased() } ?? "nil"
                    let fallbackJpg: String? = {
                        guard let imgUrlString = dto.imgUrl,
                              let imgUrl = URL(string: imgUrlString),
                              imgUrl.pathExtension.lowercased() == "webp" else {
                            return nil
                        }
                        return imgUrl.deletingPathExtension().appendingPathExtension("jpg").absoluteString
                    }()
                    if let rank = dto.rank {
                        return "malId:\(dto.malId) rank:\(rank) ext:\(ext) img:\(img) fallbackJpg:\(fallbackJpg ?? "nil")"
                    } else {
                        return "malId:\(dto.malId) rank:nil ext:\(ext) img:\(img) fallbackJpg:\(fallbackJpg ?? "nil")"
                    }
                }
                print("[Top Manga Response]\n" + summaryLines.joined(separator: "\n"))
#endif

                let mapped: [HomeTrendingMangaCardItem] = response.data.compactMap { dto -> HomeTrendingMangaCardItem? in
                    guard let urlString = dto.imgUrl,
                          let url = URL(string: urlString) else { return nil }

                    return HomeTrendingMangaCardItem(
                        id: dto.id,
                        rank: dto.rank,
                        imageURL: url
                    )
                }

#if DEBUG
                let mappedDebug = mapped.map { item in
                    let rankPart = item.rank.map(String.init) ?? "nil"
                    let imgExt = item.imageURL.pathExtension.lowercased()
                    return "id:\(item.id) rank:\(rankPart) ext:\(imgExt)"
                }
                print("[Top Manga Mapped]\n" + mappedDebug.joined(separator: ", "))
#endif

                self.items = mapped
                self.isLoading = false
            } catch {
                self.errorMessage = error.localizedDescription
                self.items = []
                self.isLoading = false
            }
        }
    }

    func stop() {
        loadTask?.cancel()
        loadTask = nil
    }
}
