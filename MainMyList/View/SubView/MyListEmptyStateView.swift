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
        ErrorMessageView(
            state: ErrorMessageView.State(
                kind: emptyState.kind,
                message: emptyState.message
            )
        )
            .frame(maxWidth: .infinity)
            .padding(.vertical, 44)
            .padding(.horizontal, 20)
            .background(Color(.secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}
