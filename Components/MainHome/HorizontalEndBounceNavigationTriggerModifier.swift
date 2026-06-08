//
//  HorizontalEndBounceNavigationTriggerModifier.swift
//  WYJikanApp
//
//  Created by Codex on 2026/6/8.
//

import SwiftUI

// MARK: - HorizontalEndBounceNavigationHintView

struct HorizontalEndBounceNavigationHintView: View {
    // MARK: - Properties

    let title: String
    let subtitle: String
    let progress: CGFloat

    // MARK: - Body

    var body: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .strokeBorder(Color(.separator).opacity(0.36), lineWidth: 2)

                Circle()
                    .trim(from: 0, to: clampedProgress)
                    .stroke(
                        ThemeColor.sakura,
                        style: StrokeStyle(lineWidth: 3, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))

                Image(systemName: "chevron.right")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(ThemeColor.textPrimary)
            }
            .frame(width: 44, height: 44)

            VStack(spacing: 4) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(ThemeColor.textPrimary)
                    .multilineTextAlignment(.center)

                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(ThemeColor.textPrimary.opacity(0.72))
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
            }
        }
        .padding(16)
        .frame(
            width: MainHomePosterCardMetrics.width,
            height: MainHomePosterCardMetrics.height
        )
        .background(Color(.secondarySystemBackground))
        .clipShape(cardShape)
        .overlay {
            cardShape
                .strokeBorder(Color(.separator).opacity(0.36))
        }
    }

    // MARK: - Private

    private var cardShape: RoundedRectangle {
        RoundedRectangle(
            cornerRadius: MainHomePosterCardMetrics.cornerRadius,
            style: .continuous
        )
    }

    private var clampedProgress: CGFloat {
        min(max(progress, 0), 1)
    }
}

// MARK: - HorizontalEndBounceNavigationTriggerModifier

struct HorizontalEndBounceNavigationTriggerModifier: ViewModifier {
    // MARK: - Properties

    let isEnabled: Bool
    let threshold: CGFloat
    let progress: Binding<CGFloat>
    let action: () -> Void

    @State private var canTrigger = true
    @State private var maximumOverscroll: CGFloat = 0

    // MARK: - Body

    func body(content: Content) -> some View {
        content
            .onScrollGeometryChange(for: CGFloat.self) { geometry in
                let maximumOffsetX = max(
                    geometry.contentSize.width - geometry.containerSize.width,
                    0
                )
                return max(geometry.contentOffset.x - maximumOffsetX, 0)
            } action: { _, overscroll in
                handleOverscrollChange(overscroll)
            }
    }

    // MARK: - Private Methods

    private func handleOverscrollChange(_ overscroll: CGFloat) {
        guard isEnabled else {
            resetTrigger()
            return
        }

        guard overscroll > 1 else {
            resetTrigger()
            return
        }

        progress.wrappedValue = min(overscroll / threshold, 1)

        guard canTrigger else { return }

        if overscroll > maximumOverscroll {
            maximumOverscroll = overscroll
            return
        }

        if maximumOverscroll >= threshold, overscroll < maximumOverscroll {
            canTrigger = false
            action()
        }
    }

    private func resetTrigger() {
        canTrigger = true
        maximumOverscroll = 0
        progress.wrappedValue = 0
    }
}

// MARK: - View

extension View {
    func onHorizontalEndBounce(
        isEnabled: Bool = true,
        threshold: CGFloat = 64,
        progress: Binding<CGFloat> = .constant(0),
        perform action: @escaping () -> Void
    ) -> some View {
        modifier(
            HorizontalEndBounceNavigationTriggerModifier(
                isEnabled: isEnabled,
                threshold: threshold,
                progress: progress,
                action: action
            )
        )
    }
}
