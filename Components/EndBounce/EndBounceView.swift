//
//  EndBounceView.swift
//  WYJikanApp
//
//  Created by Codex on 2026/6/8.
//

import SwiftUI

// MARK: - EndBounceAxis

enum EndBounceAxis: Equatable, Sendable {
    case horizontal
    case vertical

    var initialSystemImageName: String {
        switch self {
        case .horizontal:
            return "chevron.left"
        case .vertical:
            return "chevron.up"
        }
    }

    var iconSize: CGFloat {
        switch self {
        case .horizontal:
            return 44
        case .vertical:
            return 44
        }
    }

    var iconFontSize: CGFloat {
        switch self {
        case .horizontal:
            return 16
        case .vertical:
            return 16
        }
    }

    var spacing: CGFloat {
        switch self {
        case .horizontal:
            return 12
        case .vertical:
            return 8
        }
    }
}

// MARK: - EndBounceHintView

struct EndBounceHintView: View {
    // MARK: - Properties

    let axis: EndBounceAxis
    let title: String
    let subtitle: String
    let progress: CGFloat
    let width: CGFloat?
    let height: CGFloat?
    let cornerRadius: CGFloat

    // MARK: - Lifecycle

    init(
        axis: EndBounceAxis,
        title: String,
        subtitle: String,
        progress: CGFloat,
        width: CGFloat? = nil,
        height: CGFloat? = nil,
        cornerRadius: CGFloat = 16
    ) {
        self.axis = axis
        self.title = title
        self.subtitle = subtitle
        self.progress = progress
        self.width = width
        self.height = height
        self.cornerRadius = cornerRadius
    }

    // MARK: - Body

    var body: some View {
        VStack(spacing: axis.spacing) {
            progressIcon

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
        .frame(width: resolvedWidth, height: resolvedHeight)
        .frame(maxWidth: axis == .vertical ? .infinity : nil)
        .background(Color(.secondarySystemBackground))
        .clipShape(cardShape)
        .overlay {
            cardShape
                .strokeBorder(Color(.separator).opacity(0.36))
        }
    }

    // MARK: - Private

    private var progressIcon: some View {
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

            Image(systemName: axis.initialSystemImageName)
                .font(.system(size: axis.iconFontSize, weight: .bold))
                .foregroundStyle(ThemeColor.textPrimary)
                .rotationEffect(.degrees(180 * clampedProgress))
        }
        .frame(width: axis.iconSize, height: axis.iconSize)
        .transaction { transaction in
            transaction.animation = nil
        }
    }

    private var cardShape: RoundedRectangle {
        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
    }

    private var clampedProgress: CGFloat {
        min(max(progress, 0), 1)
    }

    private var resolvedWidth: CGFloat? {
        switch axis {
        case .horizontal:
            return width ?? 160
        case .vertical:
            return width
        }
    }

    private var resolvedHeight: CGFloat {
        switch axis {
        case .horizontal:
            return height ?? 240
        case .vertical:
            return height ?? 116
        }
    }
}

// MARK: - EndBounceScrollSample

private struct EndBounceScrollSample: Equatable {
    let pullProgress: CGFloat
    let overscroll: CGFloat
}

// MARK: - EndBounceTriggerModifier

struct EndBounceTriggerModifier: ViewModifier {
    // MARK: - Properties

    let axis: EndBounceAxis
    let isEnabled: Bool
    let threshold: CGFloat
    let revealDistance: CGFloat?
    let progress: Binding<CGFloat>
    let action: () -> Void

    @State private var canTrigger = true
    @State private var maximumOverscroll: CGFloat = 0

    // MARK: - Body

    func body(content: Content) -> some View {
        content
            .onScrollGeometryChange(for: EndBounceScrollSample.self) { geometry in
                scrollSample(from: geometry)
            } action: { _, sample in
                DispatchQueue.main.async {
                    let transaction = Transaction(animation: nil)
                    withTransaction(transaction) {
                        handleScrollChange(sample)
                    }
                }
            }
            .onChange(of: isEnabled) { _, _ in
                DispatchQueue.main.async {
                    let transaction = Transaction(animation: nil)
                    withTransaction(transaction) {
                        resetTrigger()
                    }
                }
            }
    }

    // MARK: - Private Methods

    private func scrollSample(from geometry: ScrollGeometry) -> EndBounceScrollSample {
        switch axis {
        case .horizontal:
            let maximumOffset = max(
                geometry.contentSize.width - geometry.containerSize.width,
                0
            )
            let offset = geometry.contentOffset.x
            let overscroll = max(offset - maximumOffset, 0)
            let pullProgress = pullProgress(
                offset: offset,
                maximumOffset: maximumOffset,
                overscroll: overscroll
            )

            return EndBounceScrollSample(
                pullProgress: pullProgress,
                overscroll: overscroll
            )

        case .vertical:
            let maximumOffset = max(
                geometry.contentSize.height - geometry.containerSize.height,
                0
            )
            let offset = geometry.contentOffset.y
            let overscroll = max(offset - maximumOffset, 0)
            let pullProgress = pullProgress(
                offset: offset,
                maximumOffset: maximumOffset,
                overscroll: overscroll
            )

            return EndBounceScrollSample(
                pullProgress: pullProgress,
                overscroll: overscroll
            )
        }
    }

    private func pullProgress(
        offset: CGFloat,
        maximumOffset: CGFloat,
        overscroll: CGFloat
    ) -> CGFloat {
        if let revealDistance, revealDistance > 0 {
            let revealStart = max(maximumOffset - revealDistance, 0)
            let scrolledIntoRevealZone = max(offset - revealStart, 0)
            let revealProgress = min(scrolledIntoRevealZone / revealDistance, 1)

            guard overscroll > 0 else {
                return revealProgress
            }

            let overscrollProgress = min(overscroll / threshold, 1)
            return min(revealProgress + overscrollProgress * (1 - revealProgress), 1)
        }

        guard overscroll > 0 else { return 0 }
        return min(overscroll / threshold, 1)
    }

    private func handleScrollChange(_ sample: EndBounceScrollSample) {
        guard isEnabled else {
            resetTrigger()
            return
        }

        guard sample.pullProgress > 0 || sample.overscroll > 0 else {
            resetTrigger()
            return
        }

        progress.wrappedValue = sample.pullProgress

        guard canTrigger else { return }
        guard sample.overscroll > 0 else { return }

        if sample.overscroll > maximumOverscroll {
            maximumOverscroll = sample.overscroll
            return
        }

        if maximumOverscroll >= threshold, sample.overscroll < maximumOverscroll {
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
    func onEndBounce(
        axis: EndBounceAxis,
        isEnabled: Bool = true,
        threshold: CGFloat = 64,
        revealDistance: CGFloat? = nil,
        progress: Binding<CGFloat> = .constant(0),
        perform action: @escaping () -> Void
    ) -> some View {
        modifier(
            EndBounceTriggerModifier(
                axis: axis,
                isEnabled: isEnabled,
                threshold: threshold,
                revealDistance: revealDistance,
                progress: progress,
                action: action
            )
        )
    }
}
