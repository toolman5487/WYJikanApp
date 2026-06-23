//
//  AppDependencies.swift
//  WYJikanApp
//

import SwiftData
import SwiftUI

struct AppDependencies {

    // MARK: - Coordination

    let homeLoadCoordinator: any HomeLoadCoordinating

    // MARK: - Services

    let mainHomeService: MainHomeServicing
    let homeWatchService: HomeWatchServicing
    let homeWatchListService: HomeWatchServicing
    let mainCategoryListService: MainCategoryListServicing
    let mainSearchService: MainSearchServicing
    let mainNewsService: MainNewsServicing
    let animeDetailService: AnimeDetailServicing
    let mangaDetailService: MangaDetailServicing
    let animeReviewService: AnimeReviewServicing
    let mangaReviewService: MangaReviewServicing
    let peopleDetailService: PeopleDetailServicing
    let characterDetailService: CharacterDetailServicing
    let producerDetailService: ProducerDetailServicing
    let producerAnimeListService: ProducerAnimeListServicing
    let animeCategoryDetailService: AnimeCategoryDetailServicing
    let mangaCategoryDetailService: MangaCategoryDetailServicing
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

    static let live: AppDependencies = {
        let favoriteRepository = SwiftDataFavoriteRepository()
        let broadcastReminderRepository = SwiftDataAnimeBroadcastReminderRepository()
        let mainSearchHistoryRepository = UserDefaultsMainSearchHistoryRepository()
        let mainNewsService = MainNewsService(
            lifecycleScope: .mainNews,
            requestLifecycleManager: RequestLifecycleManager.shared
        )
        let mainCategoryListService = MainCategoryListService()
        let randomPickService = RandomPickService()
        let myListDependencies = MyListDependencies(
            favoriteRepository: favoriteRepository,
            broadcastReminderRepository: broadcastReminderRepository,
            searchHistoryRepository: mainSearchHistoryRepository,
            randomPickService: randomPickService,
            requestLifecycleManager: RequestLifecycleManager.shared,
            clearApplicationCache: {
                await JikanAPIService.shared.clearCache()
                await mainNewsService.clearCache()
                URLCache.shared.removeAllCachedResponses()
            }
        )

        return AppDependencies(
            homeLoadCoordinator: HomeLoadCoordinator(),
            mainHomeService: MainHomeService(lifecycleScope: .mainHome),
            homeWatchService: HomeWatchService(lifecycleScope: .mainHome),
            homeWatchListService: HomeWatchService(lifecycleScope: .homeWatchList),
            mainCategoryListService: mainCategoryListService,
            mainSearchService: MainSearchService(),
            mainNewsService: mainNewsService,
            animeDetailService: AnimeDetailService(lifecycleScope: .background),
            mangaDetailService: MangaDetailService(),
            animeReviewService: AnimeReviewService(),
            mangaReviewService: MangaReviewService(),
            peopleDetailService: PeopleDetailService(),
            characterDetailService: CharacterDetailService(),
            producerDetailService: ProducerDetailService(),
            producerAnimeListService: ProducerAnimeListService(),
            animeCategoryDetailService: AnimeCategoryDetailService(),
            mangaCategoryDetailService: MangaCategoryDetailService(),
            homeTodayAnimeScheduleListService: HomeTodayAnimeScheduleListService(),
            homeTrendingAnimeListService: HomeTrendingAnimeListService(),
            homeTrendingMangaListService: HomeTrendingMangaListService(),
            favoriteRepository: favoriteRepository,
            broadcastReminderRepository: broadcastReminderRepository,
            mainSearchHistoryRepository: mainSearchHistoryRepository,
            myList: myListDependencies
        )
    }()

    // MARK: - Tab Factories

    func makeMainSearchViewModel(
        initialKind: MainSearchKind = .anime,
        initialQuery: String = "",
        initialSortOption: MainSearchSortOption = .defaultOption
    ) -> MainSearchViewModel {
        MainSearchViewModel(
            service: mainSearchService,
            historyRepository: mainSearchHistoryRepository,
            requestLifecycleManager: RequestLifecycleManager.shared,
            initialKind: initialKind,
            initialQuery: initialQuery,
            initialSortOption: initialSortOption
        )
    }

    func makeMainNewsViewModel() -> MainNewsViewModel {
        MainNewsViewModel(
            service: mainNewsService,
            requestLifecycleManager: RequestLifecycleManager.shared
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
            requestLifecycleManager: RequestLifecycleManager.shared
        )
    }

    // MARK: - Home Factories

    func makeHomeTodayAnimeScheduleListViewModel() -> HomeTodayAnimeScheduleListViewModel {
        HomeTodayAnimeScheduleListViewModel(
            service: homeTodayAnimeScheduleListService,
            requestLifecycleManager: RequestLifecycleManager.shared
        )
    }

    func makeHomeTrendingAnimeListViewModel() -> HomeTrendingAnimeListViewModel {
        HomeTrendingAnimeListViewModel(
            service: homeTrendingAnimeListService,
            requestLifecycleManager: RequestLifecycleManager.shared
        )
    }

    func makeHomeTrendingMangaListViewModel() -> HomeTrendingMangaListViewModel {
        HomeTrendingMangaListViewModel(
            service: homeTrendingMangaListService,
            requestLifecycleManager: RequestLifecycleManager.shared
        )
    }

    func makeHomeWatchListViewModel(initialFeed: HomeWatchFeedKind) -> HomeWatchListViewModel {
        HomeWatchListViewModel(
            initialFeed: initialFeed,
            service: homeWatchListService,
            requestLifecycleManager: RequestLifecycleManager.shared
        )
    }

    // MARK: - Detail Factories

    func makeAnimeDetailViewModel(malId: Int) -> AnimeDetailViewModel {
        let requestLifecycleScope = RequestLifecycleScope.animeDetail(malID: malId)
        return AnimeDetailViewModel(
            malId: malId,
            service: AnimeDetailService(lifecycleScope: requestLifecycleScope),
            favoriteRepository: favoriteRepository,
            broadcastReminderRepository: broadcastReminderRepository,
            requestLifecycleScope: requestLifecycleScope,
            requestLifecycleManager: RequestLifecycleManager.shared
        )
    }

    func makeMangaDetailViewModel(malId: Int) -> MangaDetailViewModel {
        let requestLifecycleScope = RequestLifecycleScope.mangaDetail(malID: malId)
        return MangaDetailViewModel(
            malId: malId,
            service: MangaDetailService(lifecycleScope: requestLifecycleScope),
            favoriteRepository: favoriteRepository,
            requestLifecycleScope: requestLifecycleScope,
            requestLifecycleManager: RequestLifecycleManager.shared
        )
    }

    func makeAnimeDetailEpisodesListViewModel(malId: Int) -> AnimeDetailEpisodesListViewModel {
        let requestLifecycleScope = RequestLifecycleScope.animeEpisodes(malID: malId)
        return AnimeDetailEpisodesListViewModel(
            malId: malId,
            service: AnimeDetailService(lifecycleScope: requestLifecycleScope),
            requestLifecycleScope: requestLifecycleScope,
            requestLifecycleManager: RequestLifecycleManager.shared
        )
    }

    func makeAnimeReviewViewModel(malId: Int) -> AnimeReviewViewModel {
        let requestLifecycleScope = RequestLifecycleScope.animeReview(malID: malId)
        return AnimeReviewViewModel(
            malId: malId,
            service: AnimeReviewService(lifecycleScope: requestLifecycleScope),
            requestLifecycleScope: requestLifecycleScope,
            requestLifecycleManager: RequestLifecycleManager.shared
        )
    }

    func makeMangaReviewViewModel(malId: Int) -> MangaReviewViewModel {
        let requestLifecycleScope = RequestLifecycleScope.mangaReview(malID: malId)
        return MangaReviewViewModel(
            malId: malId,
            service: MangaReviewService(lifecycleScope: requestLifecycleScope),
            requestLifecycleScope: requestLifecycleScope,
            requestLifecycleManager: RequestLifecycleManager.shared
        )
    }

    func makePeopleDetailViewModel(malId: Int) -> PeopleDetailViewModel {
        let requestLifecycleScope = RequestLifecycleScope.peopleDetail(malID: malId)
        return PeopleDetailViewModel(
            malId: malId,
            service: PeopleDetailService(lifecycleScope: requestLifecycleScope),
            requestLifecycleScope: requestLifecycleScope,
            requestLifecycleManager: RequestLifecycleManager.shared
        )
    }

    func makeCharacterDetailViewModel(malId: Int) -> CharacterDetailViewModel {
        let requestLifecycleScope = RequestLifecycleScope.characterDetail(malID: malId)
        return CharacterDetailViewModel(
            malId: malId,
            service: CharacterDetailService(lifecycleScope: requestLifecycleScope),
            requestLifecycleScope: requestLifecycleScope,
            requestLifecycleManager: RequestLifecycleManager.shared
        )
    }

    func makeProducerDetailViewModel(malId: Int) -> ProducerDetailViewModel {
        let requestLifecycleScope = RequestLifecycleScope.producerDetail(
            producerID: malId
        )
        return ProducerDetailViewModel(
            malId: malId,
            service: ProducerDetailService(lifecycleScope: requestLifecycleScope),
            requestLifecycleScope: requestLifecycleScope,
            requestLifecycleManager: RequestLifecycleManager.shared
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
            service: ProducerAnimeListService(lifecycleScope: requestLifecycleScope),
            requestLifecycleScope: requestLifecycleScope,
            requestLifecycleManager: RequestLifecycleManager.shared
        )
    }

    func makeAnimeCategoryDetailViewModel(genre: AnimeListGenreDTO) -> AnimeCategoryDetailViewModel {
        let requestLifecycleScope = RequestLifecycleScope.animeCategoryDetail(
            genreID: genre.id
        )
        return AnimeCategoryDetailViewModel(
            genre: genre,
            service: AnimeCategoryDetailService(lifecycleScope: requestLifecycleScope),
            requestLifecycleScope: requestLifecycleScope,
            requestLifecycleManager: RequestLifecycleManager.shared
        )
    }

    func makeMangaCategoryDetailViewModel(genre: MangaListGenreDTO) -> MangaCategoryDetailViewModel {
        let requestLifecycleScope = RequestLifecycleScope.mangaCategoryDetail(
            genreID: genre.id
        )
        return MangaCategoryDetailViewModel(
            genre: genre,
            service: MangaCategoryDetailService(lifecycleScope: requestLifecycleScope),
            requestLifecycleScope: requestLifecycleScope,
            requestLifecycleManager: RequestLifecycleManager.shared
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
