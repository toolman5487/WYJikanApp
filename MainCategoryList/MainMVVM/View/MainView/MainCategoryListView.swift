//
//  MainCategoryListView.swift
//  WYJikanApp
//
//  Created by Willy Hsu on 2026/4/8.
//

import SwiftUI

struct MainCategoryListView: View {
    
    @StateObject private var viewModel = MainCategoryListViewModel()
    private let topAnchorId = "MainCategoryListTopAnchor"
    
    var body: some View {
        NavigationStack {
            ScrollViewReader { proxy in
                ScrollView {
                    Color.clear
                        .frame(height: 0)
                        .id(topAnchorId)

                    LazyVStack(spacing: 0, pinnedViews: [.sectionHeaders]) {
                        Section {
                            selectedContentView
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.horizontal)
                                .padding(.bottom, 16)
                                .id(viewModel.selectedKind)
                        } header: {
                            CapsuleTagScrollView(
                                tags: MainListKind.categoryTags,
                                title: { $0.title },
                                selection: $viewModel.selectedKind
                            )
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal)
                            .padding(.vertical, 12)
                        }
                    }
                }
                .onChange(of: viewModel.selectedKind) { _, _ in
                    proxy.scrollTo(topAnchorId, anchor: .top)
                }
            }
            .navigationTitle("分類")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        viewModel.reloadSelectedKind()
                    } label: {
                        Image(systemName: "arrow.trianglehead.counterclockwise")
                    }
                    .accessibilityLabel("重新整理")
                }
            }
            .onDisappear {
                viewModel.stopLoading()
            }
        }
    }
    
    // MARK: - Private Views
    
    @ViewBuilder
    private var selectedContentView: some View {
        switch viewModel.selectedKind {
        case .anime:
            AnimeListView(viewModel: viewModel.animeListViewModel)
        case .manga:
            MangaListView(viewModel: viewModel.mangaListViewModel)
        case .people:
            PeopleListView(viewModel: viewModel.peopleListViewModel)
        case .character:
            CharacterListView(viewModel: viewModel.characterListViewModel)
        }
    }
}

#Preview {
    MainCategoryListView()
}
