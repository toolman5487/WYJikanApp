//
//  MainNewsErrorStateView.swift
//  WYJikanApp
//

import SwiftUI

struct MainNewsErrorStateView: View {
    let message: String
    let onRetry: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            ErrorMessageView(state: .network(message))

            Button("重新載入", action: onRetry)
                .buttonStyle(.borderedProminent)
                .tint(ThemeColor.sakura)
        }
        .frame(maxWidth: .infinity, minHeight: 220, alignment: .center)
        .padding(24)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}
