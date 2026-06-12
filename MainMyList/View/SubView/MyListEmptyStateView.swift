//
//  MyListEmptyStateView.swift
//  WYJikanApp
//
//  Created by Willy Hsu on 2026/4/25.
//

import SwiftUI

struct MyListEmptyStateView: View {

    // MARK: - Properties

    let emptyState: MyListEmptyState

    // MARK: - Body

    var body: some View {
        FeatureEmptyStateCardView(
            emptyState: emptyState,
            minHeight: 0,
            alignment: .center
        )
        .padding(.vertical, 20)
    }
}
