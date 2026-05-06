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
        case error(String)
    }

    @Published private(set) var screenState: ScreenState = .loading

    private let malId: Int
    private let service: CharacterDetailServicing
    private var isLoading = false

    init(malId: Int, service: CharacterDetailServicing = CharacterDetailService()) {
        self.malId = malId
        self.service = service
    }

    var detail: CharacterDetailDTO? {
        switch screenState {
        case .loaded(let detail):
            return detail
        case .loading, .error:
            return nil
        }
    }

    func load() async {
        guard detail == nil, !isLoading else { return }

        isLoading = true
        screenState = .loading
        defer { isLoading = false }

        do {
            let response = try await service.fetchCharacterDetail(malId: malId)
            screenState = .loaded(response.data)
        } catch is CancellationError {
            return
        } catch {
            screenState = .error(error.localizedDescription)
        }
    }
}

extension CharacterDetailViewModel {

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
