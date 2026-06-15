//
//  DetailCopyableTextViewModel.swift
//  WYJikanApp
//
//  Created by Willy Hsu on 2026/6/11.
//

import Combine
import Foundation

@MainActor
final class DetailCopyableTextViewModel: ObservableObject {

    // MARK: - Types

    private enum FeedbackTiming {
        static let displayDuration: Duration = .seconds(1)
    }

    // MARK: - Properties

    @Published private(set) var showsCopiedFeedback = false
    @Published private(set) var sensoryFeedbackTrigger = 0

    private var dismissFeedbackTask: Task<Void, Never>?

    // MARK: - Lifecycle

    func onDisappear() {
        dismissFeedbackTask?.cancel()
    }

    // MARK: - Actions

    func copy(text: String) {
        DetailClipboard.copy(text)
        sensoryFeedbackTrigger += 1
        presentCopiedFeedback()
    }

    // MARK: - Private Methods

    private func presentCopiedFeedback() {
        dismissFeedbackTask?.cancel()
        showsCopiedFeedback = true

        dismissFeedbackTask = Task(priority: .low) {
            try? await Task.sleep(for: FeedbackTiming.displayDuration)
            guard !Task.isCancelled else { return }
            await MainActor.run {
                showsCopiedFeedback = false
            }
        }
    }
}
