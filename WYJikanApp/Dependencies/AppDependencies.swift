//
//  AppDependencies.swift
//  WYJikanApp
//

import SwiftData
import SwiftUI

struct AppDependencies {

    // MARK: - Coordination

    let homeLoadCoordinator: any HomeLoadCoordinating
    let requestLifecycleManager: any RequestLifecycleManaging

    // MARK: - Networking

    private let jikanAPIService: JikanAPIServicing

    // MARK: - Services

    let mainHomeService: MainHomeServicing
    let homeWatchService: HomeWatchServicing
    let homeWatchListService: HomeWatchServicing
    let mainCategoryListService: MainCategoryListServicing
    let mainSearchService: MainSearchServicing
    let mainNewsService: MainNewsServicing
    let backgroundAnimeDetailService: AnimeDetailServicing
    let homeTodayAnimeScheduleListService: HomeTodayAnimeScheduleListServicing
    let homeTrendingAnimeListService: HomeTrendingAnimeListServicing
    let homeTrendingMangaListService: HomeTrendingMangaListServicing

    // MARK: - Repositories

    let favoriteRepository: any FavoriteRepository
    let broadcastReminderRepository: any AnimeBroadcastReminderRepository
    let mainSearchHistoryRepository: any MainSearchHistoryRepository

    // MARK: - Feature Dependencies

    let myList: MyListDependencies

    // MARK: - Live

    func connectRepositories(modelContext: ModelContext) {
        favoriteRepository.connect(modelContext: modelContext)
        broadcastReminderRepository.connect(modelContext: modelContext)
    }

    static let live = makeLiveDependencies()

    // MARK: - Tab Factories

    func makeMainSearchViewModel(
        initialKind: MainSearchKind = .anime,
        initialQuery: String = "",
        initialSortOption: MainSearchSortOption = .defaultOption
    ) -> MainSearchViewModel {
        MainSearchViewModel(
            service: mainSearchService,
            historyRepository: mainSearchHistoryRepository,
            requestLifecycleController: requestLifecycleManager,
            initialKind: initialKind,
            initialQuery: initialQuery,
            initialSortOption: initialSortOption
        )
    }

    func makeMainNewsViewModel() -> MainNewsViewModel {
        MainNewsViewModel(
            service: mainNewsService,
            requestLifecycleController: requestLifecycleManager
        )
    }

    func makeMainCategoryListViewModel() -> MainCategoryListViewModel {
        MainCategoryListViewModel(
            animeListViewModel: AnimeListViewModel(
                genreAnimeViewModel: GenreAnimeViewModel(service: mainCategoryListService)
            ),
            mangaListViewModel: MangaListViewModel(
                genreMangaViewModel: GenreMangaViewModel(service: mainCategoryListService)
            ),
            peopleListViewModel: PeopleListViewModel(service: mainCategoryListService),
            characterListViewModel: CharacterListViewModel(service: mainCategoryListService),
            requestLifecycleController: requestLifecycleManager
        )
    }

    // MARK: - Home Factories

    func makeHomeTodayAnimeScheduleListViewModel() -> HomeTodayAnimeScheduleListViewModel {
        HomeTodayAnimeScheduleListViewModel(
            service: homeTodayAnimeScheduleListService,
            requestLifecycleController: requestLifecycleManager
        )
    }

    func makeHomeTrendingAnimeListViewModel() -> HomeTrendingAnimeListViewModel {
        HomeTrendingAnimeListViewModel(
            service: homeTrendingAnimeListService,
            requestLifecycleController: requestLifecycleManager
        )
    }

    func makeHomeTrendingMangaListViewModel() -> HomeTrendingMangaListViewModel {
        HomeTrendingMangaListViewModel(
            service: homeTrendingMangaListService,
            requestLifecycleController: requestLifecycleManager
        )
    }

    func makeHomeWatchListViewModel(initialFeed: HomeWatchFeedKind) -> HomeWatchListViewModel {
        HomeWatchListViewModel(
            initialFeed: initialFeed,
            service: homeWatchListService,
            requestLifecycleController: requestLifecycleManager
        )
    }

    // MARK: - Detail Factories

    func makeAnimeDetailViewModel(
        malId: Int,
        parentTab: JikanAPIRequestScope
    ) -> AnimeDetailViewModel {
        let requestLifecycleScope = RequestLifecycleScope.animeDetail(
            malID: malId,
            parentTab: parentTab
        )
        return AnimeDetailViewModel(
            malId: malId,
            service: AnimeDetailService(
                apiService: jikanAPIService,
                lifecycleScope: requestLifecycleScope
            ),
            favoriteRepository: favoriteRepository,
            broadcastReminderRepository: broadcastReminderRepository,
            parentTab: parentTab,
            requestLifecycleScope: requestLifecycleScope,
            requestLifecycleController: requestLifecycleManager
        )
    }

    func makeMangaDetailViewModel(
        malId: Int,
        parentTab: JikanAPIRequestScope
    ) -> MangaDetailViewModel {
        let requestLifecycleScope = RequestLifecycleScope.mangaDetail(
            malID: malId,
            parentTab: parentTab
        )
        return MangaDetailViewModel(
            malId: malId,
            service: MangaDetailService(
                apiService: jikanAPIService,
                lifecycleScope: requestLifecycleScope
            ),
            favoriteRepository: favoriteRepository,
            parentTab: parentTab,
            requestLifecycleScope: requestLifecycleScope,
            requestLifecycleController: requestLifecycleManager
        )
    }

    func makeAnimeDetailEpisodesListViewModel(
        malId: Int,
        parentTab: JikanAPIRequestScope
    ) -> AnimeDetailEpisodesListViewModel {
        let requestLifecycleScope = RequestLifecycleScope.animeEpisodes(
            malID: malId,
            parentTab: parentTab
        )
        return AnimeDetailEpisodesListViewModel(
            malId: malId,
            service: AnimeDetailService(
                apiService: jikanAPIService,
                lifecycleScope: requestLifecycleScope
            ),
            parentTab: parentTab,
            requestLifecycleScope: requestLifecycleScope,
            requestLifecycleController: requestLifecycleManager
        )
    }

    func makeAnimeReviewViewModel(
        malId: Int,
        parentTab: JikanAPIRequestScope
    ) -> AnimeReviewViewModel {
        let requestLifecycleScope = RequestLifecycleScope.animeReview(
            malID: malId,
            parentTab: parentTab
        )
        return AnimeReviewViewModel(
            malId: malId,
            service: AnimeReviewService(
                apiService: jikanAPIService,
                lifecycleScope: requestLifecycleScope
            ),
            parentTab: parentTab,
            requestLifecycleScope: requestLifecycleScope,
            requestLifecycleController: requestLifecycleManager
        )
    }

    func makeMangaReviewViewModel(
        malId: Int,
        parentTab: JikanAPIRequestScope
    ) -> MangaReviewViewModel {
        let requestLifecycleScope = RequestLifecycleScope.mangaReview(
            malID: malId,
            parentTab: parentTab
        )
        return MangaReviewViewModel(
            malId: malId,
            service: MangaReviewService(
                apiService: jikanAPIService,
                lifecycleScope: requestLifecycleScope
            ),
            parentTab: parentTab,
            requestLifecycleScope: requestLifecycleScope,
            requestLifecycleController: requestLifecycleManager
        )
    }

    func makePeopleDetailViewModel(
        malId: Int,
        parentTab: JikanAPIRequestScope
    ) -> PeopleDetailViewModel {
        let requestLifecycleScope = RequestLifecycleScope.peopleDetail(
            malID: malId,
            parentTab: parentTab
        )
        return PeopleDetailViewModel(
            malId: malId,
            service: PeopleDetailService(
                apiService: jikanAPIService,
                lifecycleScope: requestLifecycleScope
            ),
            parentTab: parentTab,
            requestLifecycleScope: requestLifecycleScope,
            requestLifecycleController: requestLifecycleManager
        )
    }

    func makeCharacterDetailViewModel(
        malId: Int,
        parentTab: JikanAPIRequestScope
    ) -> CharacterDetailViewModel {
        let requestLifecycleScope = RequestLifecycleScope.characterDetail(
            malID: malId,
            parentTab: parentTab
        )
        return CharacterDetailViewModel(
            malId: malId,
            service: CharacterDetailService(
                apiService: jikanAPIService,
                lifecycleScope: requestLifecycleScope
            ),
            parentTab: parentTab,
            requestLifecycleScope: requestLifecycleScope,
            requestLifecycleController: requestLifecycleManager
        )
    }

    func makeProducerDetailViewModel(
        malId: Int,
        parentTab: JikanAPIRequestScope
    ) -> ProducerDetailViewModel {
        let requestLifecycleScope = RequestLifecycleScope.producerDetail(
            producerID: malId,
            parentTab: parentTab
        )
        return ProducerDetailViewModel(
            malId: malId,
            service: ProducerDetailService(
                apiService: jikanAPIService,
                lifecycleScope: requestLifecycleScope
            ),
            parentTab: parentTab,
            requestLifecycleScope: requestLifecycleScope,
            requestLifecycleController: requestLifecycleManager
        )
    }

    func makeProducerAnimeListViewModel(
        producerId: Int,
        producerName: String,
        parentTab: JikanAPIRequestScope
    ) -> ProducerAnimeListViewModel {
        let requestLifecycleScope = RequestLifecycleScope.producerAnimeList(
            producerID: producerId,
            parentTab: parentTab
        )
        return ProducerAnimeListViewModel(
            producerId: producerId,
            producerName: producerName,
            service: ProducerAnimeListService(
                apiService: jikanAPIService,
                lifecycleScope: requestLifecycleScope
            ),
            parentTab: parentTab,
            requestLifecycleScope: requestLifecycleScope,
            requestLifecycleController: requestLifecycleManager
        )
    }

    func makeAnimeCategoryDetailViewModel(
        genre: AnimeListGenreDTO,
        parentTab: JikanAPIRequestScope
    ) -> AnimeCategoryDetailViewModel {
        let requestLifecycleScope = RequestLifecycleScope.animeCategoryDetail(
            genreID: genre.id,
            parentTab: parentTab
        )
        return AnimeCategoryDetailViewModel(
            genre: genre,
            service: AnimeCategoryDetailService(
                apiService: jikanAPIService,
                lifecycleScope: requestLifecycleScope
            ),
            parentTab: parentTab,
            requestLifecycleScope: requestLifecycleScope,
            requestLifecycleController: requestLifecycleManager
        )
    }

    func makeMangaCategoryDetailViewModel(
        genre: MangaListGenreDTO,
        parentTab: JikanAPIRequestScope
    ) -> MangaCategoryDetailViewModel {
        let requestLifecycleScope = RequestLifecycleScope.mangaCategoryDetail(
            genreID: genre.id,
            parentTab: parentTab
        )
        return MangaCategoryDetailViewModel(
            genre: genre,
            service: MangaCategoryDetailService(
                apiService: jikanAPIService,
                lifecycleScope: requestLifecycleScope
            ),
            parentTab: parentTab,
            requestLifecycleScope: requestLifecycleScope,
            requestLifecycleController: requestLifecycleManager
        )
    }
}

// MARK: - Live Dependencies

private extension AppDependencies {

    static func makeLiveDependencies() -> AppDependencies {
        let requestLifecycleManager = RequestLifecycleManager()
        let networkRequestExecutor = NetworkRequestExecutor(
            requestLifecycleExecutor: requestLifecycleManager
        )
        let jikanAPIService = JikanAPIService(
            requestLifecycleExecutor: requestLifecycleManager
        )
        let favoriteRepository = SwiftDataFavoriteRepository()
        let broadcastReminderRepository = SwiftDataAnimeBroadcastReminderRepository()
        let mainSearchHistoryRepository = UserDefaultsMainSearchHistoryRepository()
        let mainNewsService = MainNewsService(
            lifecycleScope: .mainNews,
            networkRequestExecutor: networkRequestExecutor
        )
        let mainCategoryListService = MainCategoryListService(
            apiService: jikanAPIService
        )
        let randomPickService = RandomPickService(
            apiService: jikanAPIService
        )
        let myListDependencies = MyListDependencies(
            favoriteRepository: favoriteRepository,
            broadcastReminderRepository: broadcastReminderRepository,
            searchHistoryRepository: mainSearchHistoryRepository,
            randomPickService: randomPickService,
            requestLifecycleController: requestLifecycleManager,
            clearApplicationCache: {
                await jikanAPIService.clearCache()
                await mainNewsService.clearCache()
                URLCache.shared.removeAllCachedResponses()
            }
        )

        return AppDependencies(
            homeLoadCoordinator: HomeLoadCoordinator(),
            requestLifecycleManager: requestLifecycleManager,
            jikanAPIService: jikanAPIService,
            mainHomeService: MainHomeService(
                apiService: jikanAPIService,
                lifecycleScope: .mainHome
            ),
            homeWatchService: HomeWatchService(
                apiService: jikanAPIService,
                lifecycleScope: .mainHome
            ),
            homeWatchListService: HomeWatchService(
                apiService: jikanAPIService,
                lifecycleScope: .homeWatchList
            ),
            mainCategoryListService: mainCategoryListService,
            mainSearchService: MainSearchService(apiService: jikanAPIService),
            mainNewsService: mainNewsService,
            backgroundAnimeDetailService: AnimeDetailService(
                apiService: jikanAPIService,
                lifecycleScope: .background
            ),
            homeTodayAnimeScheduleListService: HomeTodayAnimeScheduleListService(
                apiService: jikanAPIService
            ),
            homeTrendingAnimeListService: HomeTrendingAnimeListService(
                apiService: jikanAPIService
            ),
            homeTrendingMangaListService: HomeTrendingMangaListService(
                apiService: jikanAPIService
            ),
            favoriteRepository: favoriteRepository,
            broadcastReminderRepository: broadcastReminderRepository,
            mainSearchHistoryRepository: mainSearchHistoryRepository,
            myList: myListDependencies
        )
    }
}

// MARK: - Environment

private struct AppDependenciesKey: EnvironmentKey {
    static let defaultValue = AppDependencies.live
}

extension EnvironmentValues {
    var appDependencies: AppDependencies {
        get { self[AppDependenciesKey.self] }
        set { self[AppDependenciesKey.self] = newValue }
    }
}
