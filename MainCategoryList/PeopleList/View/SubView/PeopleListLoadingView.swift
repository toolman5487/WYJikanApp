//
//  PeopleListLoadingView.swift
//  WYJikanApp
//
//  Created by Willy Hsu on 2026/4/19.
//

import SwiftUI

struct PeopleListLoadingView: View {

    // MARK: - Body

    var body: some View {
        LazyVStack(alignment: .leading, spacing: 12) {
            ForEach(0..<9, id: \.self) { _ in
                HStack(spacing: 12) {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color(.secondarySystemBackground))
                        .frame(width: 72, height: 96)

                    VStack(alignment: .leading, spacing: 8) {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color(.secondarySystemBackground))
                            .frame(height: 18)

                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color(.secondarySystemBackground))
                            .frame(width: 96, height: 14)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(12)
                .background(Color(.tertiarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            }
        }
    }
}
