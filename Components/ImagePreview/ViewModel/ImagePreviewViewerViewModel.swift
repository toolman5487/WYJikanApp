//
//  ImagePreviewViewerViewModel.swift
//  WYJikanApp
//
//  Created by Willy Hsu on 2026/4/24.
//

import Foundation
import Combine

struct ImagePreviewItem: Identifiable, Hashable {
    let id: String
    let url: URL
}

@MainActor
final class ImagePreviewViewerViewModel: ObservableObject {
    enum ViewState {
        case empty
        case single(item: ImagePreviewItem, currentIndexText: String)
        case multiple(
            items: [ImagePreviewItem],
            selectedIndex: Int,
            currentIndexText: String,
            navigationState: NavigationState
        )
    }

    enum NavigationDirection {
        case previous
        case next
    }

    struct NavigationState {
        let previousButtonState: NavigationButtonState
        let nextButtonState: NavigationButtonState
    }

    enum NavigationButtonState {
        case enabled
        case disabled

        var isEnabled: Bool {
            switch self {
            case .enabled:
                true
            case .disabled:
                false
            }
        }
    }

    let items: [ImagePreviewItem]

    @Published private(set) var selectedIndex: Int

    init(items: [ImagePreviewItem], selectedIndex: Int) {
        self.items = items
        self.selectedIndex = Self.clampedIndex(selectedIndex, itemCount: items.count)
    }

    var viewState: ViewState {
        switch items.count {
        case 0:
            .empty
        case 1:
            .single(item: items[0], currentIndexText: pageIndexText(for: 0))
        default:
            .multiple(
                items: items,
                selectedIndex: selectedIndex,
                currentIndexText: pageIndexText(for: selectedIndex),
                navigationState: navigationState(for: selectedIndex)
            )
        }
    }

    func syncSelectedIndex(_ newValue: Int) {
        let clamped = Self.clampedIndex(newValue, itemCount: items.count)
        guard selectedIndex != clamped else { return }
        selectedIndex = clamped
    }

    func move(_ direction: NavigationDirection) {
        switch direction {
        case .previous:
            syncSelectedIndex(selectedIndex - 1)
        case .next:
            syncSelectedIndex(selectedIndex + 1)
        }
    }

    private func navigationState(for index: Int) -> NavigationState {
        NavigationState(
            previousButtonState: index > 0 ? .enabled : .disabled,
            nextButtonState: index < items.count - 1 ? .enabled : .disabled
        )
    }

    private func pageIndexText(for index: Int) -> String {
        "\(index + 1) / \(items.count)"
    }

    private static func clampedIndex(_ index: Int, itemCount: Int) -> Int {
        guard itemCount > 0 else { return 0 }
        return min(max(index, 0), itemCount - 1)
    }
}
