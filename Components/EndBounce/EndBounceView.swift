//
//  EndBounceView.swift
//  WYJikanApp
//
//  Created by Codex on 2026/6/8.
//

import SwiftUI
import Dispatch

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
        .animation(.snappy(duration: 0.16), value: clampedProgress)
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

// MARK: - EndBounceTriggerModifier

struct EndBounceTriggerModifier: ViewModifier {
    // MARK: - Properties

    let axis: EndBounceAxis
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
                overscroll(from: geometry)
            } action: { _, overscroll in
                DispatchQueue.main.async {
                    handleOverscrollChange(overscroll)
                }
            }
    }

    // MARK: - Private Methods

    private func overscroll(from geometry: ScrollGeometry) -> CGFloat {
        switch axis {
        case .horizontal:
            let maximumOffsetX = max(
                geometry.contentSize.width - geometry.containerSize.width,
                0
            )
            return max(geometry.contentOffset.x - maximumOffsetX, 0)
        case .vertical:
            let maximumOffsetY = max(
                geometry.contentSize.height - geometry.containerSize.height,
                0
            )
            return max(geometry.contentOffset.y - maximumOffsetY, 0)
        }
    }

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
    func onEndBounce(
        axis: EndBounceAxis,
        isEnabled: Bool = true,
        threshold: CGFloat = 64,
        progress: Binding<CGFloat> = .constant(0),
        perform action: @escaping () -> Void
    ) -> some View {
        modifier(
            EndBounceTriggerModifier(
                axis: axis,
                isEnabled: isEnabled,
                threshold: threshold,
                progress: progress,
                action: action
            )
        )
    }
}
