//
//  ImagePreviewViewer.swift
//  WYJikanApp
//
//  Created by Willy Hsu 2026/4/24.
//

import SwiftUI

struct ImagePreviewViewer: View {
    @Binding private var selectedIndex: Int

    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel: ImagePreviewViewerViewModel

    init(items: [ImagePreviewItem], selectedIndex: Binding<Int>) {
        _selectedIndex = selectedIndex
        _viewModel = StateObject(
            wrappedValue: ImagePreviewViewerViewModel(
                items: items,
                selectedIndex: selectedIndex.wrappedValue
            )
        )
    }

    var body: some View {
        ZStack(alignment: .topTrailing) {
            Color.black
                .ignoresSafeArea()

            contentView

            ImagePreviewDismissButton {
                dismiss()
            }
        }
        .overlay(alignment: .bottom, content: pageIndexOverlay)
        .overlay(content: sideNavigationOverlay)
        .onAppear {
            selectedIndex = viewModel.selectedIndex
        }
        .onChange(of: selectedIndex) { _, newValue in
            viewModel.syncSelectedIndex(newValue)
        }
        .onChange(of: viewModel.selectedIndex) { _, newValue in
            guard selectedIndex != newValue else { return }
            selectedIndex = newValue
        }
    }

    @ViewBuilder
    private var contentView: some View {
        switch viewModel.viewState {
        case .empty:
            EmptyView()
        case .single(let item, _):
            ImagePreviewPagerView(items: [item], selectedIndex: selectionBinding)
        case .multiple(let items, _, _, _):
            ImagePreviewPagerView(items: items, selectedIndex: selectionBinding)
        }
    }

    @ViewBuilder
    private func pageIndexOverlay() -> some View {
        switch viewModel.viewState {
        case .empty:
            EmptyView()
        case .single(_, let currentIndexText):
            ImagePreviewPageIndexLabel(text: currentIndexText)
        case .multiple(_, _, let currentIndexText, _):
            ImagePreviewPageIndexLabel(text: currentIndexText)
        }
    }

    @ViewBuilder
    private func sideNavigationOverlay() -> some View {
        switch viewModel.viewState {
        case .empty, .single:
            EmptyView()
        case .multiple(_, _, _, let navigationState):
            ImagePreviewSideNavigationBar(
                navigationState: navigationState,
                onStep: viewModel.move(_:)
            )
        }
    }

    private var selectionBinding: Binding<Int> {
        Binding(
            get: { viewModel.selectedIndex },
            set: { newValue in
                viewModel.syncSelectedIndex(newValue)
            }
        )
    }
}
