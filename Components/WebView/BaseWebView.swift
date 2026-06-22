//
//  BaseWebView.swift
//  WYJikanApp
//
//  Created by Codex on 2026/6/9.
//

import SwiftUI
import UIKit

// MARK: - BaseWebPageContent

nonisolated enum BaseWebPageContent: Hashable, Sendable {
    case web(URL)
    case youtube(videoID: String, fallbackURL: URL)
}

// MARK: - BaseWebPage

nonisolated struct BaseWebPage: Hashable, Sendable {
    let title: String
    let content: BaseWebPageContent

    static func watchPromo(url: URL) -> BaseWebPage {
        BaseWebPage(title: "觀看預告", content: content(for: url))
    }

    static func watchEpisode(url: URL) -> BaseWebPage {
        BaseWebPage(title: "觀看集數", content: content(for: url))
    }

    static func newsArticle(sourceName: String, url: URL) -> BaseWebPage {
        BaseWebPage(title: sourceName, content: .web(url))
    }

    var fallbackURL: URL {
        switch content {
        case .web(let url):
            return url
        case .youtube(let videoID, let fallbackURL):
            return YouTubeVideoURLResolver.watchURL(videoID: videoID) ?? fallbackURL
        }
    }

    var externalURLCandidates: [URL] {
        switch content {
        case .web(let url):
            return [url]
        case .youtube(let videoID, let fallbackURL):
            let watchURL = YouTubeVideoURLResolver.watchURL(videoID: videoID)
            return Self.uniqueURLs([watchURL, fallbackURL].compactMap { $0 })
        }
    }

    var opensExternally: Bool {
        switch content {
        case .web:
            return false
        case .youtube:
            return true
        }
    }

    private static func content(for url: URL) -> BaseWebPageContent {
        if let videoID = YouTubeVideoURLResolver.videoID(from: url) {
            return .youtube(videoID: videoID, fallbackURL: url)
        }

        return .web(url)
    }

    private static func uniqueURLs(_ urls: [URL]) -> [URL] {
        var seenURLs = Set<URL>()
        return urls.filter { seenURLs.insert($0).inserted }
    }
}

// MARK: - BaseWebView

struct BaseWebView: View {

    // MARK: - Properties

    let page: BaseWebPage

    // MARK: - Body

    var body: some View {
        contentView
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(backgroundColor)
            .ignoresSafeArea(edges: .bottom)
            .navigationTitle(page.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        ExternalURLOpener.open(page.externalURLCandidates)
                    } label: {
                        Image(systemName: "safari")
                            .font(.body.weight(.semibold))
                            .foregroundStyle(ThemeColor.sakura)
                            .frame(width: 44, height: 44)
                    }
                }
            }
    }

    // MARK: - Private Methods

    @ViewBuilder
    private var contentView: some View {
        switch page.content {
        case .web(let url):
            PageWebView(url: url)

        case .youtube(let videoID, let fallbackURL):
            if let embedURL = YouTubeVideoURLResolver.embedURL(videoID: videoID) {
                YouTubeEmbedWebView(url: embedURL)
            } else {
                PageWebView(url: fallbackURL)
            }
        }
    }

    private var backgroundColor: Color {
        switch page.content {
        case .web:
            return Color(.systemBackground)
        case .youtube:
            return .black
        }
    }
}

// MARK: - ExternalURLOpener

@MainActor
enum ExternalURLOpener {
    static func open(_ candidates: [URL]) {
        open(candidates[...])
    }

    private static func open(_ candidates: ArraySlice<URL>) {
        guard let url = candidates.first else { return }

        UIApplication.shared.open(url, options: [:]) { accepted in
            guard !accepted else { return }
            Task(priority: .userInitiated) { @MainActor in
                open(candidates.dropFirst())
            }
        }
    }
}

// MARK: - YouTubeVideoURLResolver

nonisolated enum YouTubeVideoURLResolver {
    static func videoID(from url: URL) -> String? {
        guard let host = url.host(percentEncoded: false)?.lowercased() else {
            return nil
        }

        guard isYouTubeHost(host) else {
            return nil
        }

        if host == "youtu.be" || host.hasSuffix(".youtu.be") {
            return firstPathComponent(from: url)
        }

        if let videoID = queryItem(named: "v", from: url) {
            return videoID
        }

        let pathComponents = url.pathComponents.filter { $0 != "/" }
        guard let markerIndex = pathComponents.firstIndex(where: { $0 == "embed" || $0 == "shorts" }),
              pathComponents.indices.contains(pathComponents.index(after: markerIndex)) else {
            return nil
        }

        return normalizedText(pathComponents[pathComponents.index(after: markerIndex)])
    }

    static func embedURL(videoID: String) -> URL? {
        guard var components = URLComponents(string: "https://www.youtube.com/embed/\(videoID)") else {
            return nil
        }

        components.queryItems = [
            URLQueryItem(name: "playsinline", value: "1"),
            URLQueryItem(name: "rel", value: "0"),
            URLQueryItem(name: "modestbranding", value: "1"),
            URLQueryItem(name: "autoplay", value: "0"),
            URLQueryItem(name: "origin", value: "https://www.youtube.com")
        ]
        return components.url
    }

    static func watchURL(videoID: String) -> URL? {
        URL(string: "https://www.youtube.com/watch?v=\(videoID)")
    }

    static func isYouTubeURL(_ url: URL) -> Bool {
        guard let host = url.host(percentEncoded: false)?.lowercased() else {
            return false
        }

        return isYouTubeHost(host)
    }

    private static func isYouTubeHost(_ host: String) -> Bool {
        host == "youtu.be" ||
        host.hasSuffix(".youtu.be") ||
        host == "youtube.com" ||
        host.hasSuffix(".youtube.com") ||
        host == "youtube-nocookie.com" ||
        host.hasSuffix(".youtube-nocookie.com")
    }

    private static func firstPathComponent(from url: URL) -> String? {
        normalizedText(url.pathComponents.first { $0 != "/" })
    }

    private static func queryItem(named name: String, from url: URL) -> String? {
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
            return nil
        }

        return components.queryItems?
            .first(where: { $0.name == name })
            .flatMap { normalizedText($0.value) }
    }

    private static func normalizedText(_ value: String?) -> String? {
        DisplayTextFormatting.nonEmpty(value)
    }
}

#Preview {
    NavigationStack {
        if let url = URL(string: "https://www.youtube.com/") {
            BaseWebView(
                page: .watchPromo(url: url)
            )
        }
    }
}
