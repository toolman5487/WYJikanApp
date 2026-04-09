//
//  AnimeListView.swift
//  WYJikanApp
//
//  Created by Willy Hsu on 2026/4/8.
//

import SwiftUI

struct AnimeListView: View {
    // MARK: - Types

    enum Section: Identifiable {
        case randomHero

        var id: String {
            switch self {
            case .randomHero: return "randomHero"
            }
        }
    }

    // MARK: - Properties

    @StateObject private var viewModel = AnimeListViewModel()

    private let sections: [Section] = [
        .randomHero
    ]

    // MARK: - Private Methods

    @ViewBuilder
    private func sectionView(_ section: Section) -> some View {
        switch section {
        case .randomHero:
            RandomHeroSectionView(
                viewModel: viewModel.randomHeroViewModel
            )
        }
    }

    // MARK: - View

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
