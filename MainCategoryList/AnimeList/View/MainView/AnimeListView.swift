//
//  AnimeListView.swift
//  WYJikanApp
//
//  Created by Willy Hsu on 2026/4/8.
//

import SwiftUI

struct AnimeListView: View {
    @StateObject private var viewModel = AnimeListViewModel()

    enum Section: Identifiable {
        case randomHero

        var id: String {
            switch self {
            case .randomHero: return "randomHero"
            }
        }
    }

    private let sections: [Section] = [
        .randomHero
    ]

    @ViewBuilder
    private func sectionView(_ section: Section) -> some View {
        switch section {
        case .randomHero:
            RandomHeroSectionView(
                randomPick: viewModel.randomPick,
                isDrawing: viewModel.isDrawing,
                drawError: viewModel.drawError,
                cooldownRemainingSeconds: viewModel.cooldownRemainingSeconds,
                cooldownDisplayText: viewModel.cooldownDisplayText,
                onDrawTap: viewModel.drawRandomAnime
            )
        }
    }

    var body: some View {
        LazyVStack(alignment: .leading, spacing: 20) {
            ForEach(sections) { section in
                sectionView(section)
            }
        }
        .padding(.top, 8)
        .onDisappear {
            viewModel.stop()
        }
    }

}

#Preview {
    NavigationStack {
        ScrollView {
            AnimeListView()
                .padding(.horizontal)
        }
    }
}
