//
//  ErrorMessageView.swift
//  WYJikanApp
//
//  Created by Willy Hsu on 2026/3/26.
//

import SwiftUI

struct ErrorMessageView: View {
    let message: String
    var height: CGFloat?

    var body: some View {
        Group {
            if let height {
                content.frame(height: height)
            } else {
                content
            }
        }
    }

    private var content: some View {
        VStack(spacing: 8) {
            Image(systemName: "exclamationmark.triangle.fill")
                .imageScale(.large)
                .accessibilityHidden(true)
            Text(message)
                .font(.subheadline)
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
        }
        .accessibilityElement(children: .combine)
        .accessibilityValue(message)
    }
}

#Preview {
    ErrorMessageView(message: "Failed to load data.", height: 200)
}
