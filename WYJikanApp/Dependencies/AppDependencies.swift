//
//  AppDependencies.swift
//  WYJikanApp
//

import SwiftData
import SwiftUI

struct AppDependencies {

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
    let animeCategoryDetailService: AnimeCategoryDetailServicing
    let mangaCategoryDetailService: MangaCategoryDetailServicing
    let homeTodayAnimeScheduleListService: HomeTodayAnimeScheduleListServicing
    let homeTrendingAnimeListService: HomeTrendingAnimeListServicing
    let homeTrendingMangaListService: HomeTrendingMangaListServicing

    // MARK: - Repositories

    let favoriteRepository: any FavoriteRepository
    let broadcastReminderRepository: any AnimeBroadcastReminderRepository
    let mainSearchHistoryRepository: any MainSearchHistoryRepository

    // MARK: - Live

    func connectRepositories(modelContext: ModelContext) {
        favoriteRepository.connect(modelContext: modelContext)
        broadcastReminderRepository.connect(modelContext: modelContext)
    }

    static let live: AppDependencies = {
        let favoriteRepository = SwiftDataFavoriteRepository()
        let broadcastReminderRepository = SwiftDataAnimeBroadcastReminderRepository()
        let mainSearchHistoryRepository = UserDefaultsMainSearchHistoryRepository()

        return AppDependencies(
            mainHomeService: MainHomeService(),
            homeWatchService: HomeWatchService(),
            mainCategoryListService: MainCategoryListService(),
            mainSearchService: MainSearchService(),
            mainNewsService: MainNewsService(),
            animeDetailService: AnimeDetailService(),
            mangaDetailService: MangaDetailService(),
            animeReviewService: AnimeReviewService(),
            mangaReviewService: MangaReviewService(),
            peopleDetailService: PeopleDetailService(),
            characterDetailService: CharacterDetailService(),
            animeCategoryDetailService: AnimeCategoryDetailService(),
            mangaCategoryDetailService: MangaCategoryDetailService(),
            homeTodayAnimeScheduleListService: HomeTodayAnimeScheduleListService(),
            homeTrendingAnimeListService: HomeTrendingAnimeListService(),
            homeTrendingMangaListService: HomeTrendingMangaListService(),
            favoriteRepository: favoriteRepository,
            broadcastReminderRepository: broadcastReminderRepository,
            mainSearchHistoryRepository: mainSearchHistoryRepository
        )
    }()

    // MARK: - Tab Factories

    func makeMainSearchViewModel(
        initialKind: MainSearchKind = .anime,
        initialQuery: String = "",
        initialSortOption: MainSearchSortOption = .default
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

    func makeMainMyListViewModel() -> MainMyListViewModel {
        MainMyListViewModel(favoriteRepository: favoriteRepository)
    }

    func makeMainCategoryListViewModel() -> MainCategoryListViewModel {
        MainCategoryListViewModel(
            animeListViewModel: AnimeListViewModel(
                randomHeroViewModel: RandomHeroViewModel(service: mainCategoryListService),
                genreAnimeViewModel: GenreAnimeViewModel(service: mainCategoryListService)
            ),
            mangaListViewModel: MangaListViewModel(
                randomHeroViewModel: RandomMangaViewModel(service: mainCategoryListService),
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
