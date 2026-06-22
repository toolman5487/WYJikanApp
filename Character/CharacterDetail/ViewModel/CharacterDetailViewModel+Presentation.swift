import Foundation

extension CharacterDetailViewModel {

    private static let previewWorkLimit = 6
    private static let previewVoiceActorLimit = 8

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
        DisplayTextFormatting.firstNonEmpty(character.nameKanji, character.name) ?? "—"
    }

    func englishName(for character: CharacterDetailDTO) -> String? {
        guard character.name != displayName(for: character) else { return nil }
        return DisplayTextFormatting.nonEmpty(character.name)
    }

    func posterURL(for character: CharacterDetailDTO) -> URL? {
        imageURL(from: character.images)
    }

    func malPageURL(for character: CharacterDetailDTO) -> URL? {
        if let raw = DisplayTextFormatting.nonEmpty(character.url), let url = URL(string: raw) {
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
            .compactMap(DisplayTextFormatting.nonEmpty)
        guard !names.isEmpty else { return nil }
        return names.joined(separator: "、")
    }

    func aboutText(for character: CharacterDetailDTO) -> String? {
        DisplayTextFormatting.nonEmpty(character.about)
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

    func previewAnimeRoles(for character: CharacterDetailDTO) -> [CharacterAnimeRoleDTO] {
        Array(animeRoles(for: character).prefix(Self.previewWorkLimit))
    }

    func canShowFullAnimeRoleList(for character: CharacterDetailDTO) -> Bool {
        animeRoles(for: character).count > previewAnimeRoles(for: character).count
    }

    func previewMangaRoles(for character: CharacterDetailDTO) -> [CharacterMangaRoleDTO] {
        Array(mangaRoles(for: character).prefix(Self.previewWorkLimit))
    }

    func canShowFullMangaRoleList(for character: CharacterDetailDTO) -> Bool {
        mangaRoles(for: character).count > previewMangaRoles(for: character).count
    }

    func previewVoiceActors(for character: CharacterDetailDTO) -> [CharacterVoiceActorDTO] {
        Array(voiceActors(for: character).prefix(Self.previewVoiceActorLimit))
    }

    func canShowFullVoiceActorList(for character: CharacterDetailDTO) -> Bool {
        voiceActors(for: character).count > previewVoiceActors(for: character).count
    }

    func thumbnailImageURL(from images: AnimeImagesDTO?) -> URL? {
        JikanImageURLResolver.url(from: images, tier: .card)
    }

    func imageURL(from images: AnimeImagesDTO?) -> URL? {
        JikanImageURLResolver.url(from: images, tier: .full)
    }

    func workTitle(_ work: CharacterRelatedWorkDTO) -> String {
        DisplayTextFormatting.nonEmpty(work.title) ?? "—"
    }

    func roleText(_ role: String?) -> String {
        DisplayTextFormatting.nonEmpty(role) ?? "-"
    }

    func personName(_ person: CharacterPersonDTO) -> String {
        DisplayTextFormatting.nonEmpty(person.name) ?? "—"
    }

    func languageText(_ language: String?) -> String {
        DisplayTextFormatting.nonEmpty(language) ?? "-"
    }

    func formatNumber(_ value: Int) -> String {
        DisplayNumberFormatting.decimal(value)
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
        guard let value = DisplayTextFormatting.nonEmpty(value),
              value != "-" else {
            return nil
        }
        return value
    }
}
