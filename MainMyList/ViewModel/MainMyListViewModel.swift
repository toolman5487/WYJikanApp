//
//  MainMyListViewModel.swift
//  WYJikanApp
//
//  Created by Willy Hsu on 2026/4/25.
//

import Combine
import Foundation

@MainActor
final class MainMyListViewModel: ObservableObject {

    // MARK: - Published State

    @Published private(set) var presentation: MyListPresentation
    @Published private(set) var persistenceMutationState: PersistenceMutationState = .idle
    @Published var selectedFilter: MyListFilter = .all {
        didSet {
            guard selectedFilter != oldValue else { return }
            rebuildPresentationFromCachedItems()
        }
    }

    // MARK: - Dependencies

    private let favoriteRepository: any FavoriteRepository
    private let presentationBuilder: MainMyListPresentationBuilder
    private let persistenceMutationController = PersistenceMutationController()
    private var cachedItems: [MyListItemSnapshot] = []
    private var myListCancellable: AnyCancellable?
    private var presentationTask: Task<Void, Never>?
    private var presentationGeneration = 0

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

    isolated deinit {
        presentationTask?.cancel()
    }

    // MARK: - Actions

    func remove(_ item: MyListItemSnapshot) {
        guard !persistenceMutationState.isProcessing else { return }
        persistenceMutationState = .processing

        persistenceMutationState = persistenceMutationController.perform(
            failureMessage: "無法移除收藏，請稍後再試。",
            logPrefix: "MyList delete failed"
        ) {
            try favoriteRepository.remove(
                malId: item.malId,
                mediaKind: item.mediaKind
            )
        }
    }

    func dismissPersistenceMutationFailure() {
        guard case .failed = persistenceMutationState else { return }
        persistenceMutationState = .idle
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
    }

    private func applyItems(_ items: [MyListItemSnapshot]) {
        cachedItems = items
        rebuildPresentationFromCachedItems()
    }

    // MARK: - Presentation

    private func rebuildPresentationFromCachedItems() {
        presentationTask?.cancel()
        presentationGeneration += 1

        let generation = presentationGeneration
        let items = cachedItems
        let filter = selectedFilter
        let builder = presentationBuilder
        let computation = Task.detached(priority: .utility) {
            builder.makePresentation(
                from: items,
                selectedFilter: filter
            )
        }

        presentationTask = Task(priority: .utility) { [weak self] in
            let updatedPresentation = await withTaskCancellationHandler {
                await computation.value
            } onCancel: {
                computation.cancel()
            }

            guard !Task.isCancelled, let self else { return }
            guard presentationGeneration == generation else { return }
            presentation = updatedPresentation
        }
    }
}
