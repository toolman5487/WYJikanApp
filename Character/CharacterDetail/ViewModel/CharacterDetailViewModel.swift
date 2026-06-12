//
//  CharacterDetailViewModel.swift
//  WYJikanApp
//
//  Created by Willy Hsu on 2026/4/22.
//

import Combine
import Foundation

@MainActor
final class CharacterDetailViewModel: ObservableObject {

    enum ScreenState {
        case loading
        case loaded(CharacterDetailDTO)
        case error(FeatureLoadFailure)

        var detail: CharacterDetailDTO? {
            switch self {
            case .loaded(let detail):
                return detail
            case .loading, .error:
                return nil
            }
        }
    }

    private enum LoadState {
        case idle
        case loading

        var isLoading: Bool {
            switch self {
            case .idle:
                return false
            case .loading:
                return true
            }
        }
    }

    @Published private(set) var screenState: ScreenState = .loading

    private let malId: Int
    private let service: CharacterDetailServicing
    private var loadState: LoadState = .idle

    init(malId: Int, service: CharacterDetailServicing) {
        self.malId = malId
        self.service = service
    }

    var detail: CharacterDetailDTO? {
        screenState.detail
    }

    func load() async {
        guard detail == nil, !loadState.isLoading else { return }

        loadState = .loading
        screenState = .loading
        defer { loadState = .idle }

        do {
            let response = try await service.fetchCharacterDetail(malId: malId)
            screenState = .loaded(response.data)
        } catch is CancellationError {
            return
        } catch {
            screenState = .error(FeatureLoadFailure(error))
        }
    }
}

extension CharacterDetailViewModel {
    enum Section: Identifiable {
        case header
        case info
        case about
        case anime
        case manga
        case voices

        var id: String {
            switch self {
            case .header: return "header"
            case .info: return "info"
            case .about: return "about"
            case .anime: return "anime"
            case .manga: return "manga"
            case .voices: return "voices"
            }
        }
    }

    func sections(for character: CharacterDetailDTO) -> [Section] {
        var result: [Section] = [.header, .info]
        if aboutText(for: character) != nil {
            result.append(.about)
        }
        if !animeRoles(for: character).isEmpty {
            result.append(.anime)
        }
        if !mangaRoles(for: character).isEmpty {
            result.append(.manga)
        }
        if !voiceActors(for: character).isEmpty {
            result.append(.voices)
        }
        return result
    }

    func externalPageNavigationState() -> DetailNavigationToolbarExternalPageState {
        guard let detail,
              let url = malPageURL(for: detail) else {
            return .unavailable
        }
        return .available(title: displayName(for: detail), url: url)
    }

    func shareNavigationState() -> DetailNavigationToolbarShareState {
        guard let detail,
              let url = malPageURL(for: detail) else {
            return .loading
        }
        let title = displayName(for: detail)
        return .available(
            title: title,
            message: shareMessageText(for: detail),
            url: url
        )
    }

    func shareMessageText(for character: CharacterDetailDTO) -> String {
        let title = displayName(for: character)
        let details = shareDetailsText(for: character)
        guard !details.isEmpty else { return title }
        return "\(title)\n\n\(details)"
    }

    func displayName(for character: CharacterDetailDTO) -> String {
        firstNonEmpty(character.nameKanji, character.name) ?? "—"
    }

    func englishName(for character: CharacterDetailDTO) -> String? {
        guard character.name != displayName(for: character) else { return nil }
        return nonEmpty(character.name)
    }

    func posterURL(for character: CharacterDetailDTO) -> URL? {
        imageURL(from: character.images)
    }

    func malPageURL(for character: CharacterDetailDTO) -> URL? {
        if let raw = nonEmpty(character.url), let url = URL(string: raw) {
            return url
        }
        return URL(string: "https://myanimelist.net/character/\(character.malId)")
    }

    func favoritesText(for character: CharacterDetailDTO) -> String {
        guard let favorites = character.favorites else { return "-" }
        return formatNumber(favorites)
    }

    func nicknamesText(for character: CharacterDetailDTO) -> String? {
        let names = (character.nicknames ?? [])
            .compactMap(nonEmpty)
        guard !names.isEmpty else { return nil }
        return names.joined(separator: "、")
    }

    func aboutText(for character: CharacterDetailDTO) -> String? {
        nonEmpty(character.about)
    }

    func animeRoles(for character: CharacterDetailDTO) -> [CharacterAnimeRoleDTO] {
        (character.anime ?? []).filter { $0.anime != nil }
    }

    func mangaRoles(for character: CharacterDetailDTO) -> [CharacterMangaRoleDTO] {
        (character.manga ?? []).filter { $0.manga != nil }
    }

    func voiceActors(for character: CharacterDetailDTO) -> [CharacterVoiceActorDTO] {
        (character.voices ?? []).filter { $0.person != nil }
    }

    func imageURL(from images: AnimeImagesDTO?) -> URL? {
        let candidates: [String?] = [
            images?.webp?.largeImageUrl,
            images?.jpg?.largeImageUrl,
            images?.webp?.imageUrl,
            images?.jpg?.imageUrl,
            images?.jpg?.smallImageUrl,
            images?.webp?.smallImageUrl
        ]
        return candidates.compactMap(nonEmpty).first.flatMap { URL(string: $0) }
    }

    func workTitle(_ work: CharacterRelatedWorkDTO) -> String {
        nonEmpty(work.title) ?? "—"
    }

    func roleText(_ role: String?) -> String {
        nonEmpty(role) ?? "-"
    }

    func personName(_ person: CharacterPersonDTO) -> String {
        nonEmpty(person.name) ?? "—"
    }

    func languageText(_ language: String?) -> String {
        nonEmpty(language) ?? "-"
    }

    func formatNumber(_ value: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter.string(from: NSNumber(value: value)) ?? "\(value)"
    }

    private func shareDetailsText(for character: CharacterDetailDTO) -> String {
        [
            shareLine(title: "英文名", value: englishName(for: character)),
            shareLine(title: "收藏", value: favoritesText(for: character)),
            shareLine(title: "配音", value: countText(voiceActors(for: character).count, unit: "位")),
            shareLine(title: "動畫作品", value: countText(animeRoles(for: character).count, unit: "部")),
            shareLine(title: "漫畫作品", value: countText(mangaRoles(for: character).count, unit: "部"))
        ]
        .compactMap { $0 }
        .joined(separator: "\n")
    }

    private func countText(_ count: Int, unit: String) -> String? {
        guard count > 0 else { return nil }
        return "\(formatNumber(count)) \(unit)"
    }

    private func shareLine(title: String, value: String?) -> String? {
        guard let value = shareValue(value) else { return nil }
        return "\(title)：\(value)"
    }

    private func shareValue(_ value: String?) -> String? {
        guard let value = nonEmpty(value),
              value != "-" else {
            return nil
        }
        return value
    }

    private func firstNonEmpty(_ values: String?...) -> String? {
        values.compactMap(nonEmpty).first
    }

    private func nonEmpty(_ value: String?) -> String? {
        guard let text = value?.trimmingCharacters(in: .whitespacesAndNewlines), !text.isEmpty else {
            return nil
        }
        return text
    }
}
