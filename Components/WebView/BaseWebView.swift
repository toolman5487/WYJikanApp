//
//  BaseWebView.swift
//  WYJikanApp
//
//  Created by Codex on 2026/6/9.
//

import SwiftUI

// MARK: - BaseWebPage

nonisolated struct BaseWebPage: Hashable, Sendable {
    let title: String
    let url: URL

    static func watchPromo(url: URL) -> BaseWebPage {
        BaseWebPage(title: "觀看預告", url: url)
    }

    static func watchEpisode(url: URL) -> BaseWebPage {
        BaseWebPage(title: "觀看集數", url: url)
    }
}

// MARK: - BaseWebView

struct BaseWebView: View {

    // MARK: - Properties

    @Environment(\.openURL) private var openURL

    let page: BaseWebPage

    // MARK: - Body

    var body: some View {
        PageWebView(url: page.url)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(.systemBackground))
            .ignoresSafeArea(edges: .bottom)
            .navigationTitle(page.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        openURL(page.url)
                    } label: {
                        Image(systemName: "safari")
                            .font(.body.weight(.semibold))
                            .foregroundStyle(ThemeColor.sakura)
                            .frame(width: 44, height: 44)
                    }
                }
            }
    }
}

#Preview {
    NavigationStack {
        if let url = URL(string: "https://www.youtube.com/") {
            BaseWebView(
                page: BaseWebPage(
                    title: "觀看預告",
                    url: url
                )
            )
        }
    }
}
