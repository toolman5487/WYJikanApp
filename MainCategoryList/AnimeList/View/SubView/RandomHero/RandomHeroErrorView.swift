//
//  RandomHeroErrorView.swift
//  WYJikanApp
//
//  Created by Willy Hsu on 2026/4/8.
//

import SwiftUI

struct RandomHeroErrorView: View {
    let message: String
    let onRetryTap: () -> Void

    var body: some View {
        VStack(spacing: 12) {
            ErrorMessageView(message: message)
            Button("重試", action: onRetryTap)
                .buttonStyle(.borderedProminent)
                .tint(ThemeColor.sakura)
                .frame(minHeight: 44)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
    }
}

#Preview {
    RandomHeroErrorView(message: "載入失敗") {}
}
