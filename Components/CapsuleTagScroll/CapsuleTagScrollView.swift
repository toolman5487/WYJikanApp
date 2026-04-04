//
//  CapsuleTagScrollView.swift
//  WYJikanApp
//
//  Created by Willy Hsu on 2026/4/4.
//

import SwiftUI

// MARK: - CapsuleTagScrollView

struct CapsuleTagScrollView<Tag: Hashable>: View {

    let tags: [Tag]
    let title: (Tag) -> String
    var selection: Binding<Tag>? = nil
    var onTap: ((Tag) -> Void)? = nil

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(tags, id: \.self) { tag in
                    let isSelected = selection.map { $0.wrappedValue == tag } ?? true
                    let background: Color = isSelected ? ThemeColor.sakura : Color(.systemGray5)
                    let foreground: Color = isSelected ? ThemeColor.textPrimary : ThemeColor.textSecondary

                    Button {
                        if let selection {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                selection.wrappedValue = tag
                            }
                        }
                        onTap?(tag)
                    } label: {
                        capsuleLabel(title(tag), background: background, foreground: foreground)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    // MARK: - Private

    @ViewBuilder
    private func capsuleLabel(_ text: String, background: Color, foreground: Color) -> some View {
        Text(text)
            .font(.subheadline.weight(.medium))
            .foregroundStyle(foreground)
            .lineLimit(1)
            .padding(.vertical, 8)
            .padding(.horizontal, 16)
            .frame(minHeight: 44)
            .background(background)
            .clipShape(Capsule())
    }
}
