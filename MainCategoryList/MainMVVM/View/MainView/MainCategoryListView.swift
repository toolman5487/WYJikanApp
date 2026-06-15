//
//  MainCategoryListView.swift
//  WYJikanApp
//
//  Created by Willy Hsu on 2026/4/8.
//

import SwiftUI

struct MainCategoryListView: View {

    // MARK: - Properties

    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @StateObject private var viewModel: MainCategoryListViewModel

    // MARK: - Lifecycle

    init(dependencies: AppDependencies) {
        _viewModel = StateObject(wrappedValue: dependencies.makeMainCategoryListViewModel())
    }
    @State private var loadMoreBounceProgress: CGFloat = 0
    
    private let topAnchorId = "MainCategoryListTopAnchor"
    
    // MARK: - Body
    
    var body: some View {
        NavigationStack {
            scrollView
                .toolbar(.hidden, for: .navigationBar)
                .task(priority: .userInitiated) {
                    viewModel.prepareSelectedKind(
                        isPadScreen: horizontalSizeClass == .regular
                    )
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

                if viewModel.shouldShowLoadMoreFooter {
                    Group {
                        if viewModel.isLoadingMoreSelectedKind {
                            ProgressView()
                                .frame(maxWidth: .infinity, minHeight: 116)
                        } else {
                            EndBounceHintView(
                                axis: .vertical,
                                title: viewModel.loadMoreFooterTitle,
                                subtitle: viewModel.loadMoreFooterSubtitle,
                                progress: loadMoreBounceProgress
                            )
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 24)
                }
            }
            .onEndBounce(
                axis: .vertical,
                isEnabled: viewModel.canLoadMoreSelectedKind,
                threshold: 36,
                revealDistance: 144,
                progress: $loadMoreBounceProgress
            ) {
                viewModel.loadMoreSelectedKind()
            }
            .safeAreaInset(edge: .top, spacing: 0) {
                topFilterHeader
            }
            .onChange(of: viewModel.selectedKind) { _, _ in
                Task(priority: .userInitiated) { @MainActor in
                    proxy.scrollTo(topAnchorId, anchor: .top)
                }
            }
            .onChange(of: viewModel.activeTopFilterSelectionIdentifier) { _, _ in
                guard viewModel.activeTopFilterSelectionIdentifier != nil else { return }
                Task(priority: .userInitiated) { @MainActor in
                    withAnimation(.easeInOut(duration: 0.2)) {
                        proxy.scrollTo(topAnchorId, anchor: .top)
                    }
                }
            }
        }
    }

    private var topFilterHeader: some View {
        HStack(alignment: .center, spacing: 12) {
            CapsuleFilterBarView(
                tags: MainListKind.categoryTags,
                title: { $0.title },
                selection: $viewModel.selectedKind
            )
            .frame(maxWidth: .infinity, alignment: .leading)

            topFilterMenu

            reloadButton
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color.clear)
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

    private var reloadButton: some View {
        Button {
            viewModel.reloadSelectedKind()
        } label: {
            Image(systemName: "arrow.trianglehead.counterclockwise")
                .font(.title3.weight(.bold))
                .foregroundStyle(ThemeColor.textPrimary)
                .frame(width: 40, height: 40)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Preview

#Preview {
    MainCategoryListView(dependencies: .live)
}
