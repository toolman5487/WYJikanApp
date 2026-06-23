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

    func makeAnimeDetailViewModel(malId: Int) -> AnimeDetailViewModel {
        let requestLifecycleScope = RequestLifecycleScope.animeDetail(malID: malId)
        return AnimeDetailViewModel(
            malId: malId,
            service: AnimeDetailService(
                apiService: jikanAPIService,
                lifecycleScope: requestLifecycleScope
            ),
            favoriteRepository: favoriteRepository,
            broadcastReminderRepository: broadcastReminderRepository,
            requestLifecycleScope: requestLifecycleScope,
            requestLifecycleController: requestLifecycleManager
        )
    }

    func makeMangaDetailViewModel(malId: Int) -> MangaDetailViewModel {
        let requestLifecycleScope = RequestLifecycleScope.mangaDetail(malID: malId)
        return MangaDetailViewModel(
            malId: malId,
            service: MangaDetailService(
                apiService: jikanAPIService,
                lifecycleScope: requestLifecycleScope
            ),
            favoriteRepository: favoriteRepository,
            requestLifecycleScope: requestLifecycleScope,
            requestLifecycleController: requestLifecycleManager
        )
    }

    func makeAnimeDetailEpisodesListViewModel(malId: Int) -> AnimeDetailEpisodesListViewModel {
        let requestLifecycleScope = RequestLifecycleScope.animeEpisodes(malID: malId)
        return AnimeDetailEpisodesListViewModel(
            malId: malId,
            service: AnimeDetailService(
                apiService: jikanAPIService,
                lifecycleScope: requestLifecycleScope
            ),
            requestLifecycleScope: requestLifecycleScope,
            requestLifecycleController: requestLifecycleManager
        )
    }

    func makeAnimeReviewViewModel(malId: Int) -> AnimeReviewViewModel {
        let requestLifecycleScope = RequestLifecycleScope.animeReview(malID: malId)
        return AnimeReviewViewModel(
            malId: malId,
            service: AnimeReviewService(
                apiService: jikanAPIService,
                lifecycleScope: requestLifecycleScope
            ),
            requestLifecycleScope: requestLifecycleScope,
            requestLifecycleController: requestLifecycleManager
        )
    }

    func makeMangaReviewViewModel(malId: Int) -> MangaReviewViewModel {
        let requestLifecycleScope = RequestLifecycleScope.mangaReview(malID: malId)
        return MangaReviewViewModel(
            malId: malId,
            service: MangaReviewService(
                apiService: jikanAPIService,
                lifecycleScope: requestLifecycleScope
            ),
            requestLifecycleScope: requestLifecycleScope,
            requestLifecycleController: requestLifecycleManager
        )
    }

    func makePeopleDetailViewModel(malId: Int) -> PeopleDetailViewModel {
        let requestLifecycleScope = RequestLifecycleScope.peopleDetail(malID: malId)
        return PeopleDetailViewModel(
            malId: malId,
            service: PeopleDetailService(
                apiService: jikanAPIService,
                lifecycleScope: requestLifecycleScope
            ),
            requestLifecycleScope: requestLifecycleScope,
            requestLifecycleController: requestLifecycleManager
        )
    }

    func makeCharacterDetailViewModel(malId: Int) -> CharacterDetailViewModel {
        let requestLifecycleScope = RequestLifecycleScope.characterDetail(malID: malId)
        return CharacterDetailViewModel(
            malId: malId,
            service: CharacterDetailService(
                apiService: jikanAPIService,
                lifecycleScope: requestLifecycleScope
            ),
            requestLifecycleScope: requestLifecycleScope,
            requestLifecycleController: requestLifecycleManager
        )
    }

    func makeProducerDetailViewModel(malId: Int) -> ProducerDetailViewModel {
        let requestLifecycleScope = RequestLifecycleScope.producerDetail(
            producerID: malId
        )
        return ProducerDetailViewModel(
            malId: malId,
            service: ProducerDetailService(
                apiService: jikanAPIService,
                lifecycleScope: requestLifecycleScope
            ),
            requestLifecycleScope: requestLifecycleScope,
            requestLifecycleController: requestLifecycleManager
        )
    }

    func makeProducerAnimeListViewModel(
        producerId: Int,
        producerName: String
    ) -> ProducerAnimeListViewModel {
        let requestLifecycleScope = RequestLifecycleScope.producerAnimeList(
            producerID: producerId
        )
        return ProducerAnimeListViewModel(
            producerId: producerId,
            producerName: producerName,
            service: ProducerAnimeListService(
                apiService: jikanAPIService,
                lifecycleScope: requestLifecycleScope
            ),
            requestLifecycleScope: requestLifecycleScope,
            requestLifecycleController: requestLifecycleManager
        )
    }

    func makeAnimeCategoryDetailViewModel(genre: AnimeListGenreDTO) -> AnimeCategoryDetailViewModel {
        let requestLifecycleScope = RequestLifecycleScope.animeCategoryDetail(
            genreID: genre.id
        )
        return AnimeCategoryDetailViewModel(
            genre: genre,
            service: AnimeCategoryDetailService(
                apiService: jikanAPIService,
                lifecycleScope: requestLifecycleScope
            ),
            requestLifecycleScope: requestLifecycleScope,
            requestLifecycleController: requestLifecycleManager
        )
    }

    func makeMangaCategoryDetailViewModel(genre: MangaListGenreDTO) -> MangaCategoryDetailViewModel {
        let requestLifecycleScope = RequestLifecycleScope.mangaCategoryDetail(
            genreID: genre.id
        )
        return MangaCategoryDetailViewModel(
            genre: genre,
            service: MangaCategoryDetailService(
                apiService: jikanAPIService,
                lifecycleScope: requestLifecycleScope
            ),
            requestLifecycleScope: requestLifecycleScope,
            requestLifecycleController: requestLifecycleManager
        )
    }
}

// MARK: - Live Dependencies

private extension AppDependencies {

    static func makeLiveDependencies() -> AppDependencies {
        let requestLifecycleManager = RequestLifecycleManager()
        let jikanAPIService = JikanAPIService(
            requestLifecycleExecutor: requestLifecycleManager
        )
        let favoriteRepository = SwiftDataFavoriteRepository()
        let broadcastReminderRepository = SwiftDataAnimeBroadcastReminderRepository()
        let mainSearchHistoryRepository = UserDefaultsMainSearchHistoryRepository()
        let mainNewsService = MainNewsService(
            lifecycleScope: .mainNews,
            requestLifecycleExecutor: requestLifecycleManager
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
