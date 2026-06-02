//
//  MainNewsEmptyStateView.swift
//  WYJikanApp
//

import SwiftUI

struct MainNewsEmptyStateView: View {
    let filterTitle: String

    var body: some View {
        ContentUnavailableView {
            Label("目前沒有新聞", systemImage: "newspaper")
        } description: {
            Text("\(filterTitle) 暫時沒有可顯示的動漫新聞。")
        }
        .frame(maxWidth: .infinity, minHeight: 260)
        .padding(16)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}
