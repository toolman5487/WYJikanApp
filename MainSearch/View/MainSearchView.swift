//
//  MainSearchView.swift
//  WYJikanApp
//
//  Created by Willy Hsu on 2026/4/2.
//

import SwiftUI

struct MainSearchView: View {

    enum Kind: String, CaseIterable {
        case anime = "動畫"
        case manga = "漫畫"
    }

    @State private var selectedKind: Kind = .anime

    var body: some View {
        VStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 16) {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(Kind.allCases, id: \.self) { kind in
                            Button {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    selectedKind = kind
                                }
                            } label: {
                                Text(kind.rawValue)
                                    .font(.subheadline.weight(.medium))
                                    .foregroundStyle(selectedKind == kind ? ThemeColor.textPrimary : ThemeColor.textSecondary)
                                    .lineLimit(1)
                                    .padding(.vertical, 8)
                                    .padding(.horizontal, 16)
                                    .frame(minHeight: 44)
                                    .background(selectedKind == kind ? ThemeColor.sakura : Color(.systemGray5))
                                    .clipShape(Capsule())
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 16)
            .padding(.vertical, 12)

            Spacer(minLength: 0)
        }
    }
}

#Preview {
    MainSearchView()
}
