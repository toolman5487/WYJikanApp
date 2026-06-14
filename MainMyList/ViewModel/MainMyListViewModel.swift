//
//  MainMyListViewModel.swift
//  WYJikanApp
//
//  Created by Willy Hsu on 2026/4/25.
//

import Combine
import Foundation
import OSLog

@MainActor
final class MainMyListViewModel: ObservableObject {

    // MARK: - Published State

    @Published private(set) var presentation: MyListPresentation
    @Published var selectedFilter: MyListFilter = .all {
        didSet {
            guard selectedFilter != oldValue else { return }
            rebuildPresentationFromCachedItems()
        }
    }

    // MARK: - Dependencies

    private let favoriteRepository: any FavoriteRepository
    private let presentationBuilder: MainMyListPresentationBuilder
    private var cachedItems: [MyListCollectionItem] = []
    private var myListCancellable: AnyCancellable?

    // MARK: - Lifecycle

    init(
        favoriteRepository: any FavoriteRepository,
        presentationBuilder: MainMyListPresentationBuilder = MainMyListPresentationBuilder()
    ) {
        self.favoriteRepository = favoriteRepository
        self.presentationBuilder = presentationBuilder
        self.presentation = presentationBuilder.emptyPresentation(selectedFilter: .all)
        connectToRepository()
    }

    // MARK: - Actions

    func remove(_ item: MyListCollectionItem) {
        do {
            try favoriteRepository.remove(item)
        } catch {
            AppLogger.persistence.error("MyList delete failed: \(error.localizedDescription, privacy: .public)")
        }
    }

    // MARK: - Empty State

    func emptyTitle(for filter: MyListFilter) -> String {
        filter == .all ? "還沒有收藏" : "還沒有收藏\(filter.title)"
    }

    func emptyState() -> MyListEmptyState {
        let title = emptyTitle(for: selectedFilter)
        let message = "在作品詳情頁點右上角的愛心，就會加入收藏。"

        guard let selectedMediaKind = selectedFilter.mediaKind else {
            return .emptyCollection(title: title, message: message)
        }

        let hasOtherMedia = cachedItems.contains { $0.mediaKind != selectedMediaKind }
        if hasOtherMedia {
            return .filteredEmpty(title: title, message: message)
        }
        return .emptyCollection(title: title, message: message)
    }

    // MARK: - Repository

    private func connectToRepository() {
        guard myListCancellable == nil else { return }

        myListCancellable = favoriteRepository.myListPublisher
            .sink { [weak self] items in
                self?.applyItems(items)
            }

        do {
            try favoriteRepository.reloadFavorites()
        } catch {
            AppLogger.persistence.error(
                "MyList reload failed: \(error.localizedDescription, privacy: .public)"
            )
        }
    }

    private func applyItems(_ items: [MyListCollectionItem]) {
        cachedItems = items
        rebuildPresentationFromCachedItems()
    }

    // MARK: - Presentation

    private func rebuildPresentationFromCachedItems() {
        presentation = presentationBuilder.makePresentation(
            from: cachedItems,
            selectedFilter: selectedFilter
        )
    }
}
