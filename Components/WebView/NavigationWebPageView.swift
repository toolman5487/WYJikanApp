//
//  NavigationWebPageView.swift
//  WYJikanApp
//
//  Created by Willy Hsu on 2026/4/4.
//

import SwiftUI

// MARK: - NavigationWebPageView

struct NavigationWebPageView: View {

    let title: String
    let url: URL?

    var body: some View {
        Group {
            if let url {
                PageWebView(url: url)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .ignoresSafeArea()
            } else {
                ContentUnavailableView {
                    Label("No Link", systemImage: "link.badge.plus")
                } description: {
                    Text("暫無可用的連結。")
                }
            }
        }
    }
}
