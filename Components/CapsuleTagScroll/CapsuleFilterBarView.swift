//
//  CapsuleFilterBarView.swift
//  WYJikanApp
//
//  Created by Codex on 2026/5/12.
//

import SwiftUI

struct CapsuleFilterBarView<Tag: Hashable>: View {
    @Namespace private var selectionAnimationNamespace

    let tags: [Tag]
    let title: (Tag) -> String
    var systemImageName: ((Tag) -> String?)? = nil
    var selection: Binding<Tag>
    var selectionAnimation: Animation? = .easeInOut(duration: 0.22)
    var onTap: ((Tag) -> Void)? = nil

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(tags, id: \.self) { tag in
                    Button {
                        if let selectionAnimation {
                            withAnimation(selectionAnimation) {
                                selection.wrappedValue = tag
                            }
                        } else {
                            selection.wrappedValue = tag
                        }
                        onTap?(tag)
                    } label: {
                        filterItem(for: tag)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.vertical, 4)
        }
    }

    private func filterItem(for tag: Tag) -> some View {
        let isSelected = selection.wrappedValue == tag

        return HStack(spacing: 12) {
            if let systemImageName = systemImageName?(tag) {
                Image(systemName: systemImageName)
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(iconStyle(isSelected: isSelected))
            }

            Text(title(tag))
                .font(.headline.weight(.black))
                .tracking(0.4)
                .lineLimit(1)
                .foregroundStyle(titleStyle(isSelected: isSelected))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .frame(minHeight: 38)
        .background {
            if isSelected {
                Capsule()
                    .fill(backgroundStyle(isSelected: true))
                    .matchedGeometryEffect(id: "capsuleFilterSelection", in: selectionAnimationNamespace)
            } else {
                Capsule()
                    .fill(backgroundStyle(isSelected: false))
            }
        }
        .overlay {
            Capsule()
                .strokeBorder(borderStyle(isSelected: isSelected), lineWidth: 1)
        }
        .clipShape(Capsule())
        .shadow(color: shadowColor(isSelected: isSelected), radius: 16, y: 8)
    }

    private func titleStyle(isSelected: Bool) -> AnyShapeStyle {
        if isSelected {
            AnyShapeStyle(
                LinearGradient(
                    colors: [
                        ThemeColor.sakura,
                        ThemeColor.sakura.opacity(0.72)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
        } else {
            AnyShapeStyle(ThemeColor.textSecondary)
        }
    }

    private func iconStyle(isSelected: Bool) -> AnyShapeStyle {
        isSelected ? titleStyle(isSelected: true) : AnyShapeStyle(ThemeColor.textSecondary)
    }

    private func backgroundStyle(isSelected: Bool) -> AnyShapeStyle {
        if isSelected {
            AnyShapeStyle(Material.ultraThinMaterial)
        } else {
            AnyShapeStyle(Color(.secondarySystemBackground).opacity(0.9))
        }
    }

    private func borderStyle(isSelected: Bool) -> LinearGradient {
        LinearGradient(
            colors: isSelected
                ? [
                    Color.white.opacity(0.85),
                    ThemeColor.sakura.opacity(0.18)
                ]
                : [
                    Color.white.opacity(0.5),
                    ThemeColor.sakura.opacity(0.08)
                ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    private func shadowColor(isSelected: Bool) -> Color {
        isSelected ? ThemeColor.sakura.opacity(0.10) : .clear
    }
}
