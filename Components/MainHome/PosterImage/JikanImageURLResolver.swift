//
//  JikanImageURLResolver.swift
//  WYJikanApp
//
//  Created by Willy Hsu on 2026/6/12.
//

import Foundation

// MARK: - JikanImageDisplayTier

nonisolated enum JikanImageDisplayTier: Sendable {
    case thumbnail
    case card
    case poster
    case full
}

// MARK: - JikanImageURLResolver

nonisolated enum JikanImageURLResolver {

    // MARK: - URL

    static func url(from images: AnimeImagesDTO?, tier: JikanImageDisplayTier) -> URL? {
        urlString(from: images, tier: tier).flatMap(URL.init(string:))
    }

    static func url(from images: AnimeListImagesDTO?, tier: JikanImageDisplayTier) -> URL? {
        urlString(from: images, tier: tier).flatMap(URL.init(string:))
    }

    static func url(from images: MangaListImagesDTO?, tier: JikanImageDisplayTier) -> URL? {
        urlString(from: images, tier: tier).flatMap(URL.init(string:))
    }

    static func url(from images: AnimeCategoryImagesDTO?, tier: JikanImageDisplayTier) -> URL? {
        urlString(from: images, tier: tier).flatMap(URL.init(string:))
    }

    static func url(from images: MangaCategoryImagesDTO?, tier: JikanImageDisplayTier) -> URL? {
        urlString(from: images, tier: tier).flatMap(URL.init(string:))
    }

    // MARK: - URL String

    static func urlString(from images: AnimeImagesDTO?, tier: JikanImageDisplayTier) -> String? {
        firstURLString(from: variants(from: images), tier: tier)
    }

    static func urlString(from images: AnimeListImagesDTO?, tier: JikanImageDisplayTier) -> String? {
        firstURLString(from: variants(from: images), tier: tier)
    }

    static func urlString(from images: MangaListImagesDTO?, tier: JikanImageDisplayTier) -> String? {
        firstURLString(from: variants(from: images), tier: tier)
    }

    static func urlString(from images: AnimeCategoryImagesDTO?, tier: JikanImageDisplayTier) -> String? {
        firstURLString(from: variants(from: images), tier: tier)
    }

    static func urlString(from images: MangaCategoryImagesDTO?, tier: JikanImageDisplayTier) -> String? {
        firstURLString(from: variants(from: images), tier: tier)
    }

    // MARK: - Variants Mapping

    private static func variants(from images: AnimeImagesDTO?) -> JikanImageVariants {
        makeVariants(
            jpgImageUrl: images?.jpg?.imageUrl,
            jpgSmallImageUrl: images?.jpg?.smallImageUrl,
            jpgLargeImageUrl: images?.jpg?.largeImageUrl,
            webpImageUrl: images?.webp?.imageUrl,
            webpSmallImageUrl: images?.webp?.smallImageUrl,
            webpLargeImageUrl: images?.webp?.largeImageUrl
        )
    }

    private static func variants(from images: AnimeListImagesDTO?) -> JikanImageVariants {
        makeVariants(
            jpgImageUrl: images?.jpg?.imageUrl,
            jpgSmallImageUrl: images?.jpg?.smallImageUrl,
            jpgLargeImageUrl: images?.jpg?.largeImageUrl,
            webpImageUrl: images?.webp?.imageUrl,
            webpSmallImageUrl: images?.webp?.smallImageUrl,
            webpLargeImageUrl: images?.webp?.largeImageUrl
        )
    }

    private static func variants(from images: MangaListImagesDTO?) -> JikanImageVariants {
        makeVariants(
            jpgImageUrl: images?.jpg?.imageUrl,
            jpgSmallImageUrl: images?.jpg?.smallImageUrl,
            jpgLargeImageUrl: images?.jpg?.largeImageUrl,
            webpImageUrl: images?.webp?.imageUrl,
            webpSmallImageUrl: images?.webp?.smallImageUrl,
            webpLargeImageUrl: images?.webp?.largeImageUrl
        )
    }

    private static func variants(from images: AnimeCategoryImagesDTO?) -> JikanImageVariants {
        makeVariants(
            jpgImageUrl: images?.jpg?.imageUrl,
            jpgSmallImageUrl: images?.jpg?.smallImageUrl,
            jpgLargeImageUrl: images?.jpg?.largeImageUrl,
            webpImageUrl: images?.webp?.imageUrl,
            webpSmallImageUrl: images?.webp?.smallImageUrl,
            webpLargeImageUrl: images?.webp?.largeImageUrl
        )
    }

    private static func variants(from images: MangaCategoryImagesDTO?) -> JikanImageVariants {
        makeVariants(
            jpgImageUrl: images?.jpg?.imageUrl,
            jpgSmallImageUrl: images?.jpg?.smallImageUrl,
            jpgLargeImageUrl: images?.jpg?.largeImageUrl,
            webpImageUrl: images?.webp?.imageUrl,
            webpSmallImageUrl: images?.webp?.smallImageUrl,
            webpLargeImageUrl: images?.webp?.largeImageUrl
        )
    }

    private static func makeVariants(
        jpgImageUrl: String?,
        jpgSmallImageUrl: String?,
        jpgLargeImageUrl: String?,
        webpImageUrl: String?,
        webpSmallImageUrl: String?,
        webpLargeImageUrl: String?
    ) -> JikanImageVariants {
        JikanImageVariants(
            jpgImageUrl: jpgImageUrl,
            jpgSmallImageUrl: jpgSmallImageUrl,
            jpgLargeImageUrl: jpgLargeImageUrl,
            webpImageUrl: webpImageUrl,
            webpSmallImageUrl: webpSmallImageUrl,
            webpLargeImageUrl: webpLargeImageUrl
        )
    }

    // MARK: - URL Selection

    private static func firstURLString(
        from variants: JikanImageVariants,
        tier: JikanImageDisplayTier
    ) -> String? {
        candidateURLs(from: variants, tier: tier).compactMap(nonEmpty).first
    }

    private static func candidateURLs(
        from variants: JikanImageVariants,
        tier: JikanImageDisplayTier
    ) -> [String?] {
        switch tier {
        case .thumbnail:
            return [
                variants.jpgSmallImageUrl,
                variants.webpSmallImageUrl,
                variants.jpgImageUrl,
                variants.webpImageUrl,
                variants.jpgLargeImageUrl,
                variants.webpLargeImageUrl
            ]
        case .card:
            return [
                variants.jpgImageUrl,
                variants.webpImageUrl,
                variants.jpgSmallImageUrl,
                variants.webpSmallImageUrl,
                variants.jpgLargeImageUrl,
                variants.webpLargeImageUrl
            ]
        case .poster:
            return [
                variants.jpgImageUrl,
                variants.webpImageUrl,
                variants.jpgLargeImageUrl,
                variants.webpLargeImageUrl,
                variants.jpgSmallImageUrl,
                variants.webpSmallImageUrl
            ]
        case .full:
            return [
                variants.jpgLargeImageUrl,
                variants.webpLargeImageUrl,
                variants.jpgImageUrl,
                variants.webpImageUrl,
                variants.jpgSmallImageUrl,
                variants.webpSmallImageUrl
            ]
        }
    }

    // MARK: - Helpers

    private static func nonEmpty(_ value: String?) -> String? {
        guard let text = value?.trimmingCharacters(in: .whitespacesAndNewlines), !text.isEmpty else {
            return nil
        }
        return text
    }
}

// MARK: - JikanImageVariants

private struct JikanImageVariants: Sendable {
    let jpgImageUrl: String?
    let jpgSmallImageUrl: String?
    let jpgLargeImageUrl: String?
    let webpImageUrl: String?
    let webpSmallImageUrl: String?
    let webpLargeImageUrl: String?
}
