//
//  PeopleDetailViewModel.swift
//  WYJikanApp
//
//  Created by Willy Hsu on 2026/4/23.
//

import Combine
import Foundation

@MainActor
final class PeopleDetailViewModel: ObservableObject {

    enum ScreenState {
        case loading
        case loaded(PeopleDetailDTO)
        case error(String)
    }

    @Published private(set) var screenState: ScreenState = .loading

    private let malId: Int
    private let service: PeopleDetailServicing
    private var isLoading = false

    init(malId: Int, service: PeopleDetailServicing = PeopleDetailService()) {
        self.malId = malId
        self.service = service
    }

    var detail: PeopleDetailDTO? {
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
            let response = try await service.fetchPeopleDetail(malId: malId)
            screenState = .loaded(response.data)
        } catch is CancellationError {
            return
        } catch {
            screenState = .error(error.localizedDescription)
        }
    }
}

extension PeopleDetailViewModel {
    enum Section: Identifiable {
        case header
        case info
        case about
        case voices
        case anime
        case manga

        var id: String {
            switch self {
            case .header: return "header"
            case .info: return "info"
            case .about: return "about"
            case .voices: return "voices"
            case .anime: return "anime"
            case .manga: return "manga"
            }
        }
    }

    enum ExternalPageNavigationState: Equatable {
        case unavailable
        case available(title: String, url: URL)
    }

    func sections(for person: PeopleDetailDTO) -> [Section] {
        var result: [Section] = [.header, .info]
        if aboutText(for: person) != nil {
            result.append(.about)
        }
        if !voiceRoles(for: person).isEmpty {
            result.append(.voices)
        }
        if !animeStaffPositions(for: person).isEmpty {
            result.append(.anime)
        }
        if !mangaStaffPositions(for: person).isEmpty {
            result.append(.manga)
        }
        return result
    }

    func externalPageNavigationState() -> ExternalPageNavigationState {
        guard let detail,
              let url = malPageURL(for: detail) else {
            return .unavailable
        }
        return .available(title: displayName(for: detail), url: url)
    }

    func displayName(for person: PeopleDetailDTO) -> String {
        let localName = [person.familyName, person.givenName]
            .compactMap(nonEmpty)
            .joined(separator: " ")
        return firstNonEmpty(localName, person.name) ?? "-"
    }

    func englishName(for person: PeopleDetailDTO) -> String? {
        guard person.name != displayName(for: person) else { return nil }
        return nonEmpty(person.name)
    }

    func posterURL(for person: PeopleDetailDTO) -> URL? {
        imageURL(from: person.images)
    }

    func malPageURL(for person: PeopleDetailDTO) -> URL? {
        if let raw = nonEmpty(person.url), let url = URL(string: raw) {
            return url
        }
        return URL(string: "https://myanimelist.net/people/\(person.malId)")
    }

    func favoritesText(for person: PeopleDetailDTO) -> String {
        guard let favorites = person.favorites else { return "-" }
        return formatNumber(favorites)
    }

    func birthdayText(for person: PeopleDetailDTO) -> String? {
        guard let birthday = nonEmpty(person.birthday) else { return nil }
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

        if let date = formatter.date(from: birthday) {
            return dateFormatter.string(from: date)
        }

        formatter.formatOptions = [.withInternetDateTime]
        if let date = formatter.date(from: birthday) {
            return dateFormatter.string(from: date)
        }

        return birthday
    }

    func alternateNamesText(for person: PeopleDetailDTO) -> String? {
        let names = (person.alternateNames ?? [])
            .compactMap(nonEmpty)
        guard !names.isEmpty else { return nil }
        return names.joined(separator: "、")
    }

    func aboutText(for person: PeopleDetailDTO) -> String? {
        nonEmpty(person.about)
    }

    func voiceRoles(for person: PeopleDetailDTO) -> [PeopleVoiceRoleDTO] {
        (person.voices ?? []).filter { $0.character != nil || $0.anime != nil }
    }

    func animeStaffPositions(for person: PeopleDetailDTO) -> [PeopleAnimeStaffPositionDTO] {
        (person.anime ?? []).filter { $0.anime != nil }
    }

    func mangaStaffPositions(for person: PeopleDetailDTO) -> [PeopleMangaStaffPositionDTO] {
        (person.manga ?? []).filter { $0.manga != nil }
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

    func workTitle(_ work: PeopleRelatedWorkDTO) -> String {
        nonEmpty(work.title) ?? "-"
    }

    func characterName(_ character: PeopleRelatedCharacterDTO) -> String {
        nonEmpty(character.name) ?? "-"
    }

    func roleText(_ role: String?) -> String {
        guard var text = nonEmpty(role) else { return "-" }
        if text.lowercased().hasPrefix("add ") {
            text.removeFirst(4)
        }
        return text
    }

    func formatNumber(_ value: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter.string(from: NSNumber(value: value)) ?? "\(value)"
    }

    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_Hant_TW")
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter
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
