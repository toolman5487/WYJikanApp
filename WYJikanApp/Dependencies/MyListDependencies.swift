//
//  MyListDependencies.swift
//  WYJikanApp
//

import Foundation

struct MyListDependencies {

    // MARK: - Dependencies

    private let favoriteRepository: any FavoriteRepository
    private let broadcastReminderRepository: any AnimeBroadcastReminderRepository
    private let searchHistoryRepository: any MainSearchHistoryRepository
    private let mainCategoryListService: MainCategoryListServicing
    private let clearApplicationCache: () async -> Void

    // MARK: - Lifecycle

    init(
        favoriteRepository: any FavoriteRepository,
        broadcastReminderRepository: any AnimeBroadcastReminderRepository,
        searchHistoryRepository: any MainSearchHistoryRepository,
        mainCategoryListService: MainCategoryListServicing,
        clearApplicationCache: @escaping () async -> Void
    ) {
        self.favoriteRepository = favoriteRepository
        self.broadcastReminderRepository = broadcastReminderRepository
        self.searchHistoryRepository = searchHistoryRepository
        self.mainCategoryListService = mainCategoryListService
        self.clearApplicationCache = clearApplicationCache
    }

    // MARK: - ViewModel Factories

    func makeMainViewModel() -> MainMyListViewModel {
        MainMyListViewModel(favoriteRepository: favoriteRepository)
    }

    func makeRandomAnimeViewModel() -> RandomHeroViewModel {
        RandomHeroViewModel(service: mainCategoryListService)
    }

    func makeRandomMangaViewModel() -> RandomMangaViewModel {
        RandomMangaViewModel(service: mainCategoryListService)
    }

    func makeMangaReadingStatusQueryViewModel() -> MangaReadingStatusQueryViewModel {
        MangaReadingStatusQueryViewModel(favoriteRepository: favoriteRepository)
    }

    func makeAnimeWatchStatusQueryViewModel() -> AnimeWatchStatusQueryViewModel {
        AnimeWatchStatusQueryViewModel(favoriteRepository: favoriteRepository)
    }

    @MainActor
    func makeSettingViewModel(
        notificationScheduler: HomeTodayAnimeNotificationScheduler,
        broadcastReminderStatusStore: AnimeBroadcastReminderStatusStore,
        favoriteStatusStore: FavoriteStatusStore
    ) -> SettingViewModel {
        SettingViewModel(
            service: SettingService(
                historyRepository: searchHistoryRepository,
                favoriteRepository: favoriteRepository,
                broadcastReminderRepository: broadcastReminderRepository,
                notificationScheduler: notificationScheduler,
                clearApplicationCache: clearApplicationCache
            ),
            notificationScheduler: notificationScheduler,
            broadcastReminderStatusStore: broadcastReminderStatusStore,
            favoriteStatusStore: favoriteStatusStore
        )
    }
}
