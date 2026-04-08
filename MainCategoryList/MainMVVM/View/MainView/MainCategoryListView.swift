//
//  MainCategoryListView.swift
//  WYJikanApp
//
//  Created by Willy Hsu on 2026/4/8.
//

import SwiftUI

struct MainCategoryListView: View {
    
    @StateObject private var viewModel = MainCategoryListViewModel()
    
    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: 0, pinnedViews: [.sectionHeaders]) {
                    Section {
                        selectedContentView
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal)
                            .padding(.bottom, 16)
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
            .navigationTitle("分類")
        }
    }
    
    // MARK: - Private Views
    
    @ViewBuilder
    private var selectedContentView: some View {
        switch viewModel.selectedKind {
        case .anime:
            AnimeListView()
        case .manga:
            MangaListView()
        case .people:
            PeopleListView()
        case .character:
            CharacterListView()
        }
    }
}

#Preview {
    MainCategoryListView()
}
