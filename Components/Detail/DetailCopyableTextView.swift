//
//  DetailCopyableTextView.swift
//  WYJikanApp
//
//  Created by Willy Hsu on 2026/6/11.
//

import SwiftUI

struct DetailCopyableText: View {

    // MARK: - Properties

    let text: String
    var style: DetailCopyableTextStyle = .primary

    @StateObject private var viewModel = DetailCopyableTextViewModel()

    // MARK: - Body

    var body: some View {
        Text(text)
            .font(style.font)
            .foregroundStyle(style.foregroundStyle)
            .frame(maxWidth: .infinity, alignment: .leading)
            .frame(minHeight: 44, alignment: .leading)
            .contentShape(Rectangle())
            .overlay {
                if viewModel.showsCopiedFeedback {
                    DetailCopySuccessIndicator()
                        .transition(
                            .scale(scale: 0.72, anchor: .center)
                                .combined(with: .opacity)
                        )
                }
            }
            .animation(
                viewModel.showsCopiedFeedback
                    ? .spring(response: 0.32, dampingFraction: 0.72)
                    : .easeOut(duration: 0.2),
                value: viewModel.showsCopiedFeedback
            )
            .onLongPressGesture(minimumDuration: 0.35) {
                viewModel.copy(text: text)
            }
            .sensoryFeedback(.success, trigger: viewModel.sensoryFeedbackTrigger)
            .onDisappear {
                viewModel.onDisappear()
            }
    }
}
