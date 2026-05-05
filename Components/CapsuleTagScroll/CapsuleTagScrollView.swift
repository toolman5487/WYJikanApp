//
//  CapsuleTagScrollView.swift
//  WYJikanApp
//
//  Created by Willy Hsu on 2026/4/4.
//

import SwiftUI

// MARK: - CapsuleTagScrollView

struct CapsuleTagScrollView<Tag: Hashable>: View {
    @Namespace private var selectionAnimation

    let tags: [Tag]
    let title: (Tag) -> String
    var systemImageName: ((Tag) -> String?)? = nil
    var selection: Binding<Tag>? = nil
    var onTap: ((Tag) -> Void)? = nil

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(tags, id: \.self) { tag in
                    Button {
                        if let selection {
                            withAnimation(.spring(response: 0.28, dampingFraction: 0.84)) {
                                selection.wrappedValue = tag
                            }
                        }
                        onTap?(tag)
                    } label: {
                        capsuleLabel(
                            title: title(tag),
                            systemImageName: systemImageName?(tag),
                            isSelected: isSelected(tag)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.vertical, 2)
        }
    }

    // MARK: - Private

    private func isSelected(_ tag: Tag) -> Bool {
        selection.map { $0.wrappedValue == tag } ?? true
    }

    private func capsuleLabel(
        title: String,
        systemImageName: String?,
        isSelected: Bool
    ) -> some View {
        HStack(spacing: systemImageName == nil ? 0 : 8) {
            if let systemImageName {
                Image(systemName: systemImageName)
                    .font(.footnote.weight(.semibold))
            }

            Text(title)
                .font(.subheadline.weight(.semibold))
                .lineLimit(1)
        }
        .foregroundStyle(isSelected ? ThemeColor.textPrimary : ThemeColor.textSecondary)
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .frame(minHeight: 44)
        .background {
            ZStack {
                if selection != nil, isSelected {
                    Capsule()
                        .fill(ThemeColor.sakura)
                        .matchedGeometryEffect(id: "capsuleSelection", in: selectionAnimation)
                } else if isSelected {
                    Capsule()
                        .fill(ThemeColor.sakura)
                } else {
                    Capsule()
                        .fill(Color(.secondarySystemBackground))
                }
            }
        }
    }
}
