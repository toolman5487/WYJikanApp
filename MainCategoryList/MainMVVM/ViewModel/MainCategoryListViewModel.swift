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

    private let kindLoadControllers: [MainListKind: any PaginatedListLoadControlling]
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
        self.kindLoadControllers = [
            .anime: animeListViewModel,
            .manga: mangaListViewModel,
            .people: peopleListViewModel,
            .character: characterListViewModel
        ]
        self.requestLifecycleController = RequestScreenLifecycleController(
            scope: .mainCategoryList,
            requestLifecycleController: requestLifecycleController
        )

        bindSelectedKind()
        makeParentChromeStateCancellable()
            .store(in: &cancellables)
    }

    func screenDidDisappear() {
        kindLoadControllers.values.forEach { $0.stop() }
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
        kindLoadController(for: selectedKind)?.canLoadMore ?? false
    }

    var shouldShowLoadMoreFooter: Bool {
        canLoadMoreSelectedKind || isLoadingMoreSelectedKind
    }

    var isLoadingMoreSelectedKind: Bool {
        kindLoadController(for: selectedKind)?.isLoadingMore ?? false
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
    func kindLoadController(
        for kind: MainListKind
    ) -> (any PaginatedListLoadControlling)? {
        kindLoadControllers[kind]
    }

    func activateKind(_ kind: MainListKind) {
        stopInactiveKinds(except: kind)
        kindLoadController(for: kind)?.loadIfNeeded()
    }

    func stopInactiveKinds(except activeKind: MainListKind) {
        for kind in MainListKind.allCases where kind != activeKind {
            kindLoadController(for: kind)?.stop()
        }
    }

    func configureGenreBatch(platform: UserInterfacePlatform) {
        let configuration = MainCategoryGenreBatchConfiguration.platformAdaptive(platform)
        animeListViewModel.configureGenreBatchIfNeeded(configuration)
        mangaListViewModel.configureGenreBatchIfNeeded(configuration)
    }

    func reload(for kind: MainListKind) {
        kindLoadController(for: kind)?.reload()
    }

    func loadMore(for kind: MainListKind) {
        kindLoadController(for: kind)?.loadMore()
    }
}
