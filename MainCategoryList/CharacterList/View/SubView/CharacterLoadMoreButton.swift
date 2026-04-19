//
//  CharacterLoadMoreButton.swift
//  WYJikanApp
//
//  Created by Willy Hsu on 2026/4/19.
//

import SwiftUI

struct CharacterLoadMoreButton: View {
    let title: String
    let isLoading: Bool
    let isVisible: Bool
    let action: () -> Void

    var body: some View {
        if isVisible {
            Button(action: action) {
                HStack(spacing: 8) {
                    if isLoading {
                        ProgressView()
                    }

                    Text(isLoading ? "載入中..." : title)
                        .font(.headline)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
            }
            .buttonStyle(.borderedProminent)
            .disabled(isLoading)
            .padding(.top, 4)
        }
    }
}
