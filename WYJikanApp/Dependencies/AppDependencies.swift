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
        let mainNewsService = MainNewsService()
        let mainCategoryListService = MainCategoryListService()
        let myListDependencies = MyListDependencies(
            favoriteRepository: favoriteRepository,
            broadcastReminderRepository: broadcastReminderRepository,
            searchHistoryRepository: mainSearchHistoryRepository,
            mainCategoryListService: mainCategoryListService,
            clearApplicationCache: {
                await JikanAPIService.shared.clearCache()
                await mainNewsService.clearCache()
                URLCache.shared.removeAllCachedResponses()
            }
        )

        return AppDependencies(
            homeLoadCoordinator: HomeLoadCoordinator(),
            mainHomeService: MainHomeService(),
            homeWatchService: HomeWatchService(),
            mainCategoryListService: mainCategoryListService,
            mainSearchService: MainSearchService(),
            mainNewsService: mainNewsService,
            animeDetailService: AnimeDetailService(),
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
            initialKind: initialKind,
            initialQuery: initialQuery,
            initialSortOption: initialSortOption
        )
    }

    func makeMainNewsViewModel() -> MainNewsViewModel {
        MainNewsViewModel(service: mainNewsService)
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
            characterListViewModel: CharacterListViewModel(service: mainCategoryListService)
        )
    }

    // MARK: - Home Factories

    func makeHomeTodayAnimeScheduleListViewModel() -> HomeTodayAnimeScheduleListViewModel {
        HomeTodayAnimeScheduleListViewModel(service: homeTodayAnimeScheduleListService)
    }

    func makeHomeTrendingAnimeListViewModel() -> HomeTrendingAnimeListViewModel {
        HomeTrendingAnimeListViewModel(service: homeTrendingAnimeListService)
    }

    func makeHomeTrendingMangaListViewModel() -> HomeTrendingMangaListViewModel {
        HomeTrendingMangaListViewModel(service: homeTrendingMangaListService)
    }

    func makeHomeWatchListViewModel(initialFeed: HomeWatchFeedKind) -> HomeWatchListViewModel {
        HomeWatchListViewModel(initialFeed: initialFeed, service: homeWatchService)
    }

    // MARK: - Detail Factories

    func makeAnimeDetailViewModel(malId: Int) -> AnimeDetailViewModel {
        AnimeDetailViewModel(
            malId: malId,
            service: animeDetailService,
            favoriteRepository: favoriteRepository,
            broadcastReminderRepository: broadcastReminderRepository
        )
    }

    func makeMangaDetailViewModel(malId: Int) -> MangaDetailViewModel {
        MangaDetailViewModel(
            malId: malId,
            service: mangaDetailService,
            favoriteRepository: favoriteRepository
        )
    }

    func makeAnimeDetailEpisodesListViewModel(malId: Int) -> AnimeDetailEpisodesListViewModel {
        AnimeDetailEpisodesListViewModel(malId: malId, service: animeDetailService)
    }

    func makeAnimeReviewViewModel(malId: Int) -> AnimeReviewViewModel {
        AnimeReviewViewModel(malId: malId, service: animeReviewService)
    }

    func makeMangaReviewViewModel(malId: Int) -> MangaReviewViewModel {
        MangaReviewViewModel(malId: malId, service: mangaReviewService)
    }

    func makePeopleDetailViewModel(malId: Int) -> PeopleDetailViewModel {
        PeopleDetailViewModel(malId: malId, service: peopleDetailService)
    }

    func makeCharacterDetailViewModel(malId: Int) -> CharacterDetailViewModel {
        CharacterDetailViewModel(malId: malId, service: characterDetailService)
    }

    func makeProducerDetailViewModel(malId: Int) -> ProducerDetailViewModel {
        ProducerDetailViewModel(malId: malId, service: producerDetailService)
    }

    func makeProducerAnimeListViewModel(
        producerId: Int,
        producerName: String
    ) -> ProducerAnimeListViewModel {
        ProducerAnimeListViewModel(
            producerId: producerId,
            producerName: producerName,
            service: producerAnimeListService
        )
    }

    func makeAnimeCategoryDetailViewModel(genre: AnimeListGenreDTO) -> AnimeCategoryDetailViewModel {
        AnimeCategoryDetailViewModel(genre: genre, service: animeCategoryDetailService)
    }

    func makeMangaCategoryDetailViewModel(genre: MangaListGenreDTO) -> MangaCategoryDetailViewModel {
        MangaCategoryDetailViewModel(genre: genre, service: mangaCategoryDetailService)
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
