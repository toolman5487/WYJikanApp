//
//  ImagePreviewViewerChrome.swift
//  WYJikanApp
//
//  Created by Willy Hsu 2026/4/24.
//

import SwiftUI

struct ImagePreviewDismissButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: "xmark")
                .font(.headline.weight(.semibold))
                .foregroundStyle(ThemeColor.textPrimary)
                .frame(width: 44, height: 44)
                .background(.black.opacity(0.5))
                .clipShape(Circle())
        }
        .padding(.top, 16)
        .padding(.trailing, 16)
    }
}

struct ImagePreviewPageIndexLabel: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.footnote.weight(.semibold))
            .foregroundStyle(ThemeColor.textPrimary)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(.black.opacity(0.5))
            .clipShape(Capsule())
            .padding(.bottom, 24)
    }
}

struct ImagePreviewSideNavigationBar: View {
    let navigationState: ImagePreviewViewerViewModel.NavigationState
    let onStep: (ImagePreviewViewerViewModel.NavigationDirection) -> Void

    var body: some View {
        HStack {
            stepButton(
                systemName: "chevron.left",
                buttonState: navigationState.previousButtonState
            ) {
                onStep(.previous)
            }

            Spacer()

            stepButton(
                systemName: "chevron.right",
                buttonState: navigationState.nextButtonState
            ) {
                onStep(.next)
            }
        }
        .padding(.horizontal, 16)
    }

    // MARK: - Private

    private func stepButton(
        systemName: String,
        buttonState: ImagePreviewViewerViewModel.NavigationButtonState,
        action: @escaping () -> Void
    ) -> some View {
        ImagePreviewSideStepButton(
            systemName: systemName,
            buttonState: buttonState,
            action: action
        )
    }
}

private struct ImagePreviewSideStepButton: View {
    enum VisualState {
        case disabled
        case idle
        case wiggling
    }

    let systemName: String
    let buttonState: ImagePreviewViewerViewModel.NavigationButtonState
    let action: () -> Void

    @State private var isWiggling = false
    @State private var wiggleTask: Task<Void, Never>?

    var body: some View {
        Button(action: handleTap) {
            buttonImage
        }
        .disabled(!buttonState.isEnabled)
        .opacity(buttonState.isEnabled ? 1 : 0.4)
        .onDisappear {
            wiggleTask?.cancel()
        }
    }

    @ViewBuilder
    private var buttonImage: some View {
        let image = Image(systemName: systemName)
            .font(.title3.weight(.bold))
            .foregroundStyle(ThemeColor.textPrimary)
            .frame(width: 40, height: 40)
            .background(.black.opacity(0.4))
            .clipShape(Circle())

        switch visualState {
        case .disabled:
            image
        case .idle:
            image.symbolEffect(.breathe)
        case .wiggling:
            image.symbolEffect(.wiggle.byLayer, options: .repeat(.continuous))
        }
    }

    private func handleTap() {
        guard buttonState.isEnabled else { return }

        wiggleTask?.cancel()
        isWiggling = true
        action()

        wiggleTask = Task {
            try? await Task.sleep(for: .milliseconds(700))
            guard !Task.isCancelled else { return }
            await MainActor.run {
                isWiggling = false
            }
        }
    }

    private var visualState: VisualState {
        switch (buttonState, isWiggling) {
        case (.disabled, _):
            .disabled
        case (.enabled, true):
            .wiggling
        case (.enabled, false):
            .idle
        }
    }
}
