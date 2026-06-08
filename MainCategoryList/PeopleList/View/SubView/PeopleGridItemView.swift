//
//  PeopleGridItemView.swift
//  WYJikanApp
//
//  Created by Willy Hsu on 2026/4/19.
//

import SwiftUI

struct PeopleGridItemView: View {

    // MARK: - Properties

    let row: PeopleListRow

    // MARK: - Body

    var body: some View {
        HStack(spacing: 12) {
            poster
                .frame(width: 72, height: 96)
                .clipShape(imageShape)

            VStack(alignment: .leading, spacing: 8) {
                Text(row.name)
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(ThemeColor.textPrimary)
                    .multilineTextAlignment(.leading)
                    .lineLimit(2)

                if let favoritesText {
                    Label(favoritesText, systemImage: "heart.fill")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Image(systemName: "chevron.right")
                .font(.footnote.weight(.semibold))
                .foregroundStyle(.tertiary)
        }
        .padding(12)
        .background(Color(.secondarySystemBackground))
        .clipShape(cardShape)
        .contentShape(cardShape)
        .accessibilityElement(children: .combine)
    }

    // MARK: - Private Methods

    @ViewBuilder
    private var poster: some View {
        if let imageURL = row.imageURL {
            RemotePosterImageView(
                url: imageURL,
                contentMode: .fill
            )
        } else {
            Color(.secondarySystemBackground)
                .overlay {
                    Image(systemName: "person.crop.square")
                        .font(.title2.weight(.semibold))
                        .foregroundStyle(.secondary)
                }
        }
    }

    private var cardShape: RoundedRectangle {
        RoundedRectangle(cornerRadius: 16, style: .continuous)
    }

    private var imageShape: RoundedRectangle {
        RoundedRectangle(cornerRadius: 12, style: .continuous)
    }

    private var favoritesText: String? {
        guard let favorites = row.favorites, favorites > 0 else { return nil }
        return favorites.formatted(.number.notation(.compactName))
    }
}
