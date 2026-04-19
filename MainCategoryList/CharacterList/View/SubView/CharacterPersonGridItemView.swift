//
//  CharacterPersonGridItemView.swift
//  WYJikanApp
//
//  Created by Willy Hsu on 2026/4/19.
//

import SwiftUI

struct CharacterPersonGridItemView: View {
    let row: MainSearchResultRow

    var body: some View {
        VStack(spacing: 8) {
            poster
                .aspectRatio(1, contentMode: .fit)
                .clipShape(Circle())

            Text(row.title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.primary)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .frame(maxWidth: .infinity, minHeight: 32, alignment: .top)
        }
    }

    @ViewBuilder
    private var poster: some View {
        if let imageURL = row.imageURL {
            RemotePosterImageView(url: imageURL)
        } else {
            Color(.secondarySystemBackground)
                .overlay {
                    Image(systemName: "person.crop.rectangle")
                        .foregroundStyle(.secondary)
                }
        }
    }
}
