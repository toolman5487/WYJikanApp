//
//  SettingView.swift
//  WYJikanApp
//
//  Created by Willy Hsu on 2026/6/17.
//

import SwiftUI

struct SettingView: View {

    // MARK: - Body

    var body: some View {
        List {
            Section {
                Text("設定功能即將推出。")
                    .foregroundStyle(ThemeColor.textSecondary)
            }
        }
        .navigationTitle("設定")
        .navigationBarTitleDisplayMode(.inline)
        .background(Color(.systemBackground))
    }
}

#Preview {
    NavigationStack {
        SettingView()
    }
}
