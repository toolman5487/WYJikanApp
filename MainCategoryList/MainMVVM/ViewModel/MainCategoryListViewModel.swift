//
//  MainCategoryListViewModel.swift
//  WYJikanApp
//
//  Created by Willy Hsu on 2026/4/8.
//

import Foundation
import Combine

@MainActor
final class MainCategoryListViewModel: ObservableObject {

    // MARK: - GenreBatchMetrics

    private enum GenreBatchMetrics {
        static let phoneInitialCount = 3
        static let padInitialCount = 4
        static let phoneItemRequestLimit = 5
        static let padItemRequestLimit = 8
    }

    // MARK: - Properties

    let animeListViewModel: AnimeListViewModel
    let mangaListViewModel: MangaListViewModel
    let peopleListViewModel: PeopleListViewModel
    let characterListViewModel: CharacterListViewModel

    @Published var selectedKind: MainListKind = .anime
    @Published private var childUpdateToken: Int = 0

    private var cancellables = Set<AnyCancellable>()

    // MARK: - Lifecycle

    init(
        animeListViewModel: AnimeListViewModel,
        mangaListViewModel: MangaListViewModel,
        peopleListViewModel: PeopleListViewModel,
        characterListViewModel: CharacterListViewModel
    ) {
        self.animeListViewModel = animeListViewModel
        self.mangaListViewModel = mangaListViewModel
        self.peopleListViewModel = peopleListViewModel
        self.characterListViewModel = characterListViewModel

        bindSelectedKind()
        bindChildViewModels()
    }

    func stopLoading() {
        MainListKind.allCases.forEach { stopLoading(for: $0) }
    }

    // MARK: - Preparation

    func prepareSelectedKind(isPadScreen: Bool) {
        let initialBatchSize = isPadScreen
            ? GenreBatchMetrics.padInitialCount
            : GenreBatchMetrics.phoneInitialCount
        let itemRequestLimit = isPadScreen
            ? GenreBatchMetrics.padItemRequestLimit
            : GenreBatchMetrics.phoneItemRequestLimit
        configureGenreBatch(
            initialBatchSize: initialBatchSize,
            itemRequestLimit: itemRequestLimit
        )
        activateKind(selectedKind)
    }

    // MARK: - Reload

    func reloadSelectedKind() {
        reload(for: selectedKind)
    }

    // MARK: - Load More

    var canLoadMoreSelectedKind: Bool {
        switch selectedKind {
        case .anime:
            return animeListViewModel.genreAnimeViewModel.canPullLoadMore
        case .manga:
            return mangaListViewModel.genreMangaViewModel.canPullLoadMore
        case .people:
            return peopleListViewModel.hasNextPage &&
                peopleListViewModel.paginationState == .idle
        case .character:
            return characterListViewModel.hasNextPage &&
                characterListViewModel.paginationState == .idle
        }
    }

    var shouldShowLoadMoreFooter: Bool {
        canLoadMoreSelectedKind || isLoadingMoreSelectedKind
    }

    var isLoadingMoreSelectedKind: Bool {
        switch selectedKind {
        case .anime:
            return animeListViewModel.genreAnimeViewModel.isLoadingMore
        case .manga:
            return mangaListViewModel.genreMangaViewModel.isLoadingMore
        case .people:
            return peopleListViewModel.paginationState == .loadingMore
        case .character:
            return characterListViewModel.paginationState == .loadingMore
        }
    }

    var loadMoreFooterTitle: String {
        switch selectedKind {
        case .anime, .manga:
            return "載入更多種類"
        case .people:
            return "載入更多聲優"
        case .character:
            return "載入更多角色"
        }
    }

    var loadMoreFooterSubtitle: String {
        switch selectedKind {
        case .anime:
            return "繼續往下拉探索更多動畫分類"
        case .manga:
            return "繼續往下拉探索更多漫畫分類"
        case .people:
            return "繼續往下拉探索更多聲優"
        case .character:
            return "繼續往下拉探索更多角色"
        }
    }

    func loadMoreSelectedKind() {
        loadMore(for: selectedKind)
    }

    // MARK: - Top Filter

    var topFilterState: MainCategoryTopFilterState {
        switch selectedKind {
        case .anime, .manga:
            return .hidden
        case .people:
            return .menu(
                MainCategoryTopFilterMenu(
                    accessibilityValue: peopleListViewModel.selectedSort.title,
                    selectionIdentifier: peopleListViewModel.selectedSort.rawValue,
                    options: PeopleListSort.allCases.map(MainCategoryTopFilterOption.people)
                )
            )
        case .character:
            return .menu(
                MainCategoryTopFilterMenu(
                    accessibilityValue: characterListViewModel.selectedSort.title,
                    selectionIdentifier: characterListViewModel.selectedSort.rawValue,
                    options: CharacterListSort.allCases.map(MainCategoryTopFilterOption.character)
                )
            )
        }
    }

    var activeTopFilterSelectionIdentifier: String? {
        switch topFilterState {
        case .hidden:
            return nil
        case .menu(let menu):
            return menu.selectionIdentifier
        }
    }

    func selectTopFilterOption(_ option: MainCategoryTopFilterOption) {
        switch option {
        case .people(let sort):
            peopleListViewModel.selectSort(sort)
        case .character(let sort):
            characterListViewModel.selectSort(sort)
        }
    }
}

// MARK: - Bindings

private extension MainCategoryListViewModel {
    func bindSelectedKind() {
        $selectedKind
            .dropFirst()
            .removeDuplicates()
            .sink { [weak self] kind in
                Task(priority: .userInitiated) { @MainActor in
                    self?.activateKind(kind)
                }
            }
            .store(in: &cancellables)
    }

    func bindChildViewModels() {
        Publishers.MergeMany(
            animeListViewModel.genreAnimeViewModel.objectWillChange.map { _ in },
            mangaListViewModel.genreMangaViewModel.objectWillChange.map { _ in },
            peopleListViewModel.objectWillChange.map { _ in },
            characterListViewModel.objectWillChange.map { _ in }
        )
        .receive(on: RunLoop.main)
        .sink { [weak self] _ in
            self?.childUpdateToken += 1
        }
        .store(in: &cancellables)
    }
}

// MARK: - Kind Management

private extension MainCategoryListViewModel {
    func activateKind(_ kind: MainListKind) {
        stopInactiveKinds(except: kind)
        loadIfNeeded(for: kind)
    }

    func stopInactiveKinds(except activeKind: MainListKind) {
        for kind in MainListKind.allCases where kind != activeKind {
            stopLoading(for: kind)
        }
    }

    func configureGenreBatch(initialBatchSize: Int, itemRequestLimit: Int) {
        let configuration = MainCategoryGenreBatchConfiguration.platformAdaptive(
            initialBatchSize: initialBatchSize,
            itemRequestLimit: itemRequestLimit
        )
        animeListViewModel.configureGenreBatchIfNeeded(configuration)
        mangaListViewModel.configureGenreBatchIfNeeded(configuration)
    }

    func loadIfNeeded(for kind: MainListKind) {
        switch kind {
        case .anime:
            animeListViewModel.loadIfNeeded()
        case .manga:
            mangaListViewModel.loadIfNeeded()
        case .people:
            peopleListViewModel.loadIfNeeded()
        case .character:
            characterListViewModel.loadIfNeeded()
        }
    }

    func reload(for kind: MainListKind) {
        switch kind {
        case .anime:
            animeListViewModel.reload()
        case .manga:
            mangaListViewModel.reload()
        case .people:
            peopleListViewModel.reload()
        case .character:
            characterListViewModel.reload()
        }
    }

    func loadMore(for kind: MainListKind) {
        switch kind {
        case .anime:
            animeListViewModel.genreAnimeViewModel.loadMoreSections()
        case .manga:
            mangaListViewModel.genreMangaViewModel.loadMoreSections()
        case .people:
            peopleListViewModel.loadMore()
        case .character:
            characterListViewModel.loadMore()
        }
    }

    func stopLoading(for kind: MainListKind) {
        switch kind {
        case .anime:
            animeListViewModel.stop()
        case .manga:
            mangaListViewModel.stop()
        case .people:
            peopleListViewModel.stop()
        case .character:
            characterListViewModel.stop()
        }
    }
}
