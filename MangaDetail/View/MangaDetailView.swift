//
//  MangaDetailView.swift
//  WYJikanApp
//
//  Created by Willy Hsu on 2026/3/31.
//

import SwiftUI

struct MangaDetailView: View {

    // MARK: - Properties

    let malId: Int

    @StateObject private var viewModel: MangaDetailViewModel

    // MARK: - Initialization

    init(malId: Int, service: MangaDetailServicing = MangaDetailService()) {
        self.malId = malId
        _viewModel = StateObject(wrappedValue: MangaDetailViewModel(malId: malId, service: service))
    }

    // MARK: - Nested Types

    enum Section: Identifiable {
        case header
        case highlights
        case basicInfo
        case score
        case synopsis
        case publication

        var id: String {
            switch self {
            case .header: return "header"
            case .highlights: return "highlights"
            case .basicInfo: return "basicInfo"
            case .score: return "score"
            case .synopsis: return "synopsis"
            case .publication: return "publication"
            }
        }
    }

    // MARK: - Sections

    private func sections(for manga: MangaDetailDTO) -> [Section] {
        var result: [Section] = [
            .header,
            .highlights,
            .basicInfo,
            .score
        ]
        if viewModel.hasSynopsis(for: manga) || viewModel.hasThemes(for: manga) {
            result.append(.synopsis)
        }
        if viewModel.hasPublicationInfo(for: manga) {
            result.append(.publication)
        }
        return result
    }

    @ViewBuilder
    private func sectionView(_ section: Section, viewModel: MangaDetailViewModel, manga: MangaDetailDTO) -> some View {
        switch section {
        case .header:
            MangaDetailHeaderSectionView(viewModel: viewModel, manga: manga)
        case .highlights:
            MangaDetailHighlightsSectionView(viewModel: viewModel, manga: manga)
        case .basicInfo:
            MangaDetailBasicInfoSectionView(viewModel: viewModel, manga: manga)
        case .score:
            MangaDetailScoreSectionView(viewModel: viewModel, manga: manga)
        case .synopsis:
            MangaDetailSynopsisSectionView(viewModel: viewModel, manga: manga)
        case .publication:
            MangaDetailPublicationSectionView(viewModel: viewModel, manga: manga)
        }
    }

    // MARK: - Body

    var body: some View {
        Group {
            if let manga = viewModel.detail {
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 20) {
                        ForEach(sections(for: manga)) { section in
                            sectionView(section, viewModel: viewModel, manga: manga)
                        }
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            } else if let message = viewModel.errorMessage {
                ErrorMessageView(message: message, height: 200)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 20) {
                        MangaDetailHeaderSectionSkeletonView()
                        MangaDetailHighlightsSectionSkeletonView()
                        MangaDetailBasicInfoSectionSkeletonView()
                        MangaDetailScoreSectionSkeletonView()
                        MangaDetailSynopsisSectionSkeletonView()
                        MangaDetailPublicationSectionSkeletonView()
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .task(id: malId) {
            await viewModel.load()
        }
    }
}

#Preview {
    NavigationStack {
        MangaDetailView(malId: 1)
    }
}
