//
//  MainCategoryListView.swift
//  WYJikanApp
//
//  Created by Willy Hsu on 2026/4/8.
//

import SwiftUI

struct MainCategoryListView: View {
    
    // MARK: - Properties
    
    @StateObject private var viewModel = MainCategoryListViewModel()
    
    private let topAnchorId = "MainCategoryListTopAnchor"
    
    // MARK: - Body
    
    var body: some View {
        NavigationStack {
            scrollView
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button {
                            viewModel.reloadSelectedKind()
                        } label: {
                            Image(systemName: "arrow.trianglehead.counterclockwise")
                                .font(.body.weight(.bold))
                        }
                    }
                }
                .onDisappear {
                    viewModel.stopLoading()
                }
        }
    }
    
    // MARK: - Scroll View
    
    private var scrollView: some View {
        ScrollViewReader { proxy in
            ScrollView {
                Color.clear
                    .frame(height: 0)
                    .id(topAnchorId)
                
                selectedContentView
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal)
                    .padding(.bottom, 16)
                    .id(viewModel.selectedKind)
            }
            .safeAreaInset(edge: .top, spacing: 0) {
                HStack(alignment: .center, spacing: 12) {
                    CapsuleFilterBarView(
                        tags: MainListKind.categoryTags,
                        title: { $0.title },
                        selection: $viewModel.selectedKind
                    )
                    .frame(maxWidth: .infinity, alignment: .leading)
                    
                    topFilterMenu
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(.ultraThinMaterial)
            }
            .onChange(of: viewModel.selectedKind) { _, _ in
                proxy.scrollTo(topAnchorId, anchor: .top)
            }
            .onChange(of: viewModel.activeTopFilterSelectionIdentifier) { _, _ in
                guard viewModel.activeTopFilterSelectionIdentifier != nil else { return }
                withAnimation(.easeInOut(duration: 0.2)) {
                    proxy.scrollTo(topAnchorId, anchor: .top)
                }
            }
        }
    }
    
    // MARK: - Selected Content
    
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
    
    // MARK: - Top Filter Menu
    
    @ViewBuilder
    private var topFilterMenu: some View {
        switch viewModel.topFilterState {
        case .hidden:
            EmptyView()
            
        case .menu(let menu):
            Menu {
                ForEach(menu.options) { option in
                    Button {
                        viewModel.selectTopFilterOption(option)
                    } label: {
                        Label(
                            option.title,
                            systemImage: option.systemImageName
                        )
                    }
                }
            } label: {
                Image(systemName: "slider.horizontal.3")
                    .font(.title3.weight(.bold))
                    .foregroundStyle(ThemeColor.textPrimary)
                    .frame(width: 40, height: 40)
            }
            .accessibilityValue(menu.accessibilityValue)
        }
    }
}

// MARK: - Preview

#Preview {
    MainCategoryListView()
}
