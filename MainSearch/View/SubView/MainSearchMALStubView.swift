//
//  MainSearchMALStubView.swift
//  WYJikanApp
//
//  Created by Willy Hsu on 2026/4/4.
//

import SwiftUI

struct MainSearchMALStubView: View {
    let title: String
    let malPageURL: URL?

    var body: some View {
        Group {
            if let malPageURL {
                PageWebView(url: malPageURL)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .ignoresSafeArea(edges: .bottom)
            } else {
                ContentUnavailableView {
                    Label("No Link", systemImage: "link.badge.plus")
                } description: {
                    Text("暫無可用的 MyAnimeList 連結。")
                }
            }
        }
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
    }
}
