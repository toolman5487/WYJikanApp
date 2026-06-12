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
        case error(FeatureLoadFailure)

        var detail: PeopleDetailDTO? {
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
    private let service: PeopleDetailServicing
    private var loadState: LoadState = .idle

    init(malId: Int, service: PeopleDetailServicing) {
        self.malId = malId
        self.service = service
    }

    var detail: PeopleDetailDTO? {
        screenState.detail
    }

    func load() async {
        guard detail == nil, !loadState.isLoading else { return }

        loadState = .loading
        screenState = .loading
        defer { loadState = .idle }

        do {
            let response = try await service.fetchPeopleDetail(malId: malId)
            screenState = .loaded(response.data)
        } catch is CancellationError {
            return
        } catch {
            screenState = .error(FeatureLoadFailure(error))
        }
    }
}

extension PeopleDetailViewModel {

    private static let previewVoiceRoleLimit = 8
    private static let previewWorkLimit = 6

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

    func shareMessageText(for person: PeopleDetailDTO) -> String {
        let title = displayName(for: person)
        let details = shareDetailsText(for: person)
        guard !details.isEmpty else { return title }
        return "\(title)\n\n\(details)"
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

    func voiceRolesWithCharacter(for person: PeopleDetailDTO) -> [PeopleVoiceRoleDTO] {
        voiceRoles(for: person).filter { $0.character != nil }
    }

    func previewVoiceRoles(for person: PeopleDetailDTO) -> [PeopleVoiceRoleDTO] {
        Array(voiceRolesWithCharacter(for: person).prefix(Self.previewVoiceRoleLimit))
    }

    func canShowFullVoiceRoleList(for person: PeopleDetailDTO) -> Bool {
        voiceRolesWithCharacter(for: person).count > previewVoiceRoles(for: person).count
    }

    func animeStaffPositions(for person: PeopleDetailDTO) -> [PeopleAnimeStaffPositionDTO] {
        (person.anime ?? []).filter { $0.anime != nil }
    }

    func previewAnimeStaffPositions(for person: PeopleDetailDTO) -> [PeopleAnimeStaffPositionDTO] {
        Array(animeStaffPositions(for: person).prefix(Self.previewWorkLimit))
    }

    func canShowFullAnimeStaffList(for person: PeopleDetailDTO) -> Bool {
        animeStaffPositions(for: person).count > previewAnimeStaffPositions(for: person).count
    }

    func mangaStaffPositions(for person: PeopleDetailDTO) -> [PeopleMangaStaffPositionDTO] {
        (person.manga ?? []).filter { $0.manga != nil }
    }

    func previewMangaStaffPositions(for person: PeopleDetailDTO) -> [PeopleMangaStaffPositionDTO] {
        Array(mangaStaffPositions(for: person).prefix(Self.previewWorkLimit))
    }

    func canShowFullMangaStaffList(for person: PeopleDetailDTO) -> Bool {
        mangaStaffPositions(for: person).count > previewMangaStaffPositions(for: person).count
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

    private func shareDetailsText(for person: PeopleDetailDTO) -> String {
        [
            shareLine(title: "英文名", value: englishName(for: person)),
            shareLine(title: "生日", value: birthdayText(for: person)),
            shareLine(title: "收藏", value: favoritesText(for: person)),
            shareLine(title: "配音角色", value: countText(voiceRoles(for: person).count, unit: "個")),
            shareLine(title: "動畫參與", value: countText(animeStaffPositions(for: person).count, unit: "部")),
            shareLine(title: "漫畫參與", value: countText(mangaStaffPositions(for: person).count, unit: "部"))
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
