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

    // MARK: - Properties

    let animeListViewModel: AnimeListViewModel
    let mangaListViewModel: MangaListViewModel
    let peopleListViewModel: PeopleListViewModel
    let characterListViewModel: CharacterListViewModel

    @Published var selectedKind: MainListKind = .anime

    private let requestLifecycleController: RequestScreenLifecycleController
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Lifecycle

    init(
        animeListViewModel: AnimeListViewModel,
        mangaListViewModel: MangaListViewModel,
        peopleListViewModel: PeopleListViewModel,
        characterListViewModel: CharacterListViewModel,
        requestLifecycleController: any RequestLifecycleControlling
    ) {
        self.animeListViewModel = animeListViewModel
        self.mangaListViewModel = mangaListViewModel
        self.peopleListViewModel = peopleListViewModel
        self.characterListViewModel = characterListViewModel
        self.requestLifecycleController = RequestScreenLifecycleController(
            scope: .mainCategoryList,
            requestLifecycleController: requestLifecycleController
        )

        bindSelectedKind()
        makeParentChromeStateCancellable()
            .store(in: &cancellables)
    }

    func screenDidDisappear() {
        MainListKind.allCases.forEach { stopLoading(for: $0) }
        requestLifecycleController.deactivate()
    }

    // MARK: - Preparation

    func screenDidAppear(platform: UserInterfacePlatform) async {
        guard await requestLifecycleController.activate() else { return }

        configureGenreBatch(platform: platform)
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
        case .anime:
            return "載入更多種類"
        case .manga:
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
        case .anime:
            return .hidden
        case .manga:
            return .hidden
        case .people:
            return .menu(
                MainCategoryTopFilterMenu(
                    selectionIdentifier: peopleListViewModel.selectedSort.rawValue,
                    options: PeopleListSort.allCases.map(MainCategoryTopFilterOption.people)
                )
            )
        case .character:
            return .menu(
                MainCategoryTopFilterMenu(
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

    func configureGenreBatch(platform: UserInterfacePlatform) {
        let configuration = MainCategoryGenreBatchConfiguration.platformAdaptive(platform)
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
