//
//  ProducerDetailViewModel+Presentation.swift
//  WYJikanApp
//

import Foundation

extension ProducerDetailViewModel {

    // MARK: - Section

    enum Section: Identifiable {
        case header
        case info
        case about
        case links
        case anime

        var id: String {
            switch self {
            case .header: return "header"
            case .info: return "info"
            case .about: return "about"
            case .links: return "links"
            case .anime: return "anime"
            }
        }
    }

    func sections(for producer: ProducerDetailDTO) -> [Section] {
        var sections: [Section] = [.header, .info]
        if aboutText(for: producer) != nil {
            sections.append(.about)
        }
        if !externalLinks(for: producer).isEmpty {
            sections.append(.links)
        }
        sections.append(.anime)
        return sections
    }

    // MARK: - Names

    func displayName(for producer: ProducerDetailDTO) -> String {
        title(for: producer, matching: "Default")
            ?? producer.titles?.compactMap(\.title).compactMap(DisplayTextFormatting.nonEmpty).first
            ?? "未命名製作公司"
    }

    func japaneseName(for producer: ProducerDetailDTO) -> String? {
        guard let japaneseName = title(for: producer, matching: "Japanese"),
              japaneseName != displayName(for: producer) else {
            return nil
        }
        return japaneseName
    }

    func alternateNamesText(for producer: ProducerDetailDTO) -> String? {
        let primaryNames = Set(
            [displayName(for: producer), japaneseName(for: producer)]
                .compactMap { $0 }
        )
        let names = (producer.titles ?? [])
            .filter { $0.type?.localizedCaseInsensitiveCompare("Synonym") == .orderedSame }
            .compactMap(\.title)
            .compactMap(DisplayTextFormatting.nonEmpty)
            .filter { !primaryNames.contains($0) }

        guard !names.isEmpty else { return nil }
        return names.joined(separator: "、")
    }

    func logoURL(for producer: ProducerDetailDTO) -> URL? {
        DisplayTextFormatting.nonEmpty(producer.images?.jpg?.imageUrl)
            .flatMap(URL.init(string:))
    }

    // MARK: - Metrics

    func favoritesText(for producer: ProducerDetailDTO) -> String {
        producer.favorites.map(DisplayNumberFormatting.decimal) ?? "—"
    }

    func animeCountText(for producer: ProducerDetailDTO) -> String {
        guard let count = producer.count else { return "—" }
        return "\(DisplayNumberFormatting.decimal(count)) 部"
    }

    func establishedText(for producer: ProducerDetailDTO) -> String {
        DisplayDateFormatting.displayDateString(
            fromISO8601: producer.established
        ) ?? "—"
    }

    // MARK: - About

    func aboutText(for producer: ProducerDetailDTO) -> String? {
        DisplayTextFormatting.nonEmpty(producer.about)
    }

    func externalLinks(
        for producer: ProducerDetailDTO
    ) -> [ProducerExternalLinkItem] {
        var seenURLs: Set<String> = []

        return (producer.external ?? []).compactMap { link in
            guard let rawURL = DisplayTextFormatting.nonEmpty(link.url),
                  let url = URL(string: rawURL),
                  let scheme = url.scheme?.lowercased(),
                  scheme == "https" || scheme == "http",
                  seenURLs.insert(url.absoluteString).inserted else {
                return nil
            }

            return ProducerExternalLinkItem(
                title: externalLinkTitle(link.name, url: url),
                url: url,
                kind: externalLinkKind(name: link.name, url: url)
            )
        }
        .sorted {
            externalLinkSortOrder($0.kind) < externalLinkSortOrder($1.kind)
        }
    }

    func externalLinkSystemImage(
        for link: ProducerExternalLinkItem
    ) -> String {
        switch link.kind {
        case .official:
            return "globe"
        case .youtube:
            return "play.rectangle.fill"
        case .social:
            return "person.2.fill"
        case .reference:
            return "book.closed.fill"
        case .other:
            return "link"
        }
    }

    func malPageURL(for producer: ProducerDetailDTO) -> URL? {
        if let rawValue = DisplayTextFormatting.nonEmpty(producer.url),
           let url = URL(string: rawValue) {
            return url
        }
        return URL(string: "https://myanimelist.net/anime/producer/\(producer.malId)")
    }

    // MARK: - Navigation & Share

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

    func shareMessageText(for producer: ProducerDetailDTO) -> String {
        let title = displayName(for: producer)
        let details = [
            shareLine(title: "成立", value: establishedText(for: producer)),
            shareLine(title: "收錄動畫", value: animeCountText(for: producer)),
            shareLine(title: "收藏", value: favoritesText(for: producer))
        ]
        .compactMap { $0 }
        .joined(separator: "\n")

        guard !details.isEmpty else { return title }
        return "\(title)\n\n\(details)"
    }

    // MARK: - Private Methods

    private func title(
        for producer: ProducerDetailDTO,
        matching type: String
    ) -> String? {
        producer.titles?
            .first {
                $0.type?.localizedCaseInsensitiveCompare(type) == .orderedSame
            }
            .flatMap(\.title)
            .flatMap(DisplayTextFormatting.nonEmpty)
    }

    private func shareLine(title: String, value: String?) -> String? {
        guard let value = DisplayTextFormatting.nonEmpty(value),
              value != "—" else {
            return nil
        }
        return "\(title)：\(value)"
    }

    private func externalLinkTitle(_ name: String?, url: URL) -> String {
        let normalizedName = DisplayTextFormatting.nonEmpty(name)
        let host = url.host?.lowercased() ?? ""

        if YouTubeVideoURLResolver.isYouTubeURL(url) {
            return "YouTube"
        }
        if host.contains("twitter.com") || host.contains("x.com") {
            return normalizedName?.hasPrefix("@") == true
                ? normalizedName ?? "X"
                : "X"
        }
        if host.contains("facebook.com") {
            return "Facebook"
        }
        if host.contains("instagram.com") {
            return "Instagram"
        }
        if host.contains("wikipedia.org") || host.contains("wikiwand.com") {
            return normalizedName ?? "百科資料"
        }
        return normalizedName ?? url.host ?? "外部連結"
    }

    private func externalLinkKind(
        name: String?,
        url: URL
    ) -> ProducerExternalLinkItem.Kind {
        let host = url.host?.lowercased() ?? ""
        let normalizedName = DisplayTextFormatting.nonEmpty(name)?.lowercased() ?? ""

        if YouTubeVideoURLResolver.isYouTubeURL(url) {
            return .youtube
        }
        if host.contains("twitter.com")
            || host.contains("x.com")
            || host.contains("facebook.com")
            || host.contains("instagram.com") {
            return .social
        }
        if host.contains("wikipedia.org")
            || host.contains("wikiwand.com")
            || host.contains("bangumi.tv")
            || host.contains("anisearch.com") {
            return .reference
        }
        if normalizedName.contains("official")
            || host.hasSuffix(".jp")
            || host.hasSuffix(".com")
            || host.hasSuffix(".co.jp") {
            return .official
        }
        return .other
    }

    private func externalLinkSortOrder(
        _ kind: ProducerExternalLinkItem.Kind
    ) -> Int {
        switch kind {
        case .official: return 0
        case .youtube: return 1
        case .social: return 2
        case .reference: return 3
        case .other: return 4
        }
    }
}
