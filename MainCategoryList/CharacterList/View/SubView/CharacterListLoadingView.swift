//
//  CharacterListLoadingView.swift
//  WYJikanApp
//
//  Created by Willy Hsu on 2026/4/19.
//

import SwiftUI

struct CharacterListLoadingView: View {
    var body: some View {
        LazyVGrid(columns: CharacterListGridMetrics.columns, spacing: 16) {
            ForEach(0..<9, id: \.self) { _ in
                VStack(spacing: 8) {
                    RoundedRectangle(cornerRadius: 14)
                        .fill(Color(.secondarySystemBackground))
                        .aspectRatio(1, contentMode: .fit)
                        .clipShape(Circle())

                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color(.secondarySystemBackground))
                        .frame(height: 14)
                }
            }
        }
    }
}
