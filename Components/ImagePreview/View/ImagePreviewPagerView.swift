//
//  ImagePreviewPagerView.swift
//  WYJikanApp
//
//  Created by Willy Hsu 2026/4/24.
//

import SwiftUI

struct ImagePreviewPagerView: View {
    let items: [ImagePreviewItem]
    @Binding var selectedIndex: Int

    var body: some View {
        TabView(selection: $selectedIndex) {
            ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                ZoomableRemoteImageView(url: item.url)
                    .tag(index)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 60)
            }
        }
        .tabViewStyle(.page(indexDisplayMode: .automatic))
    }
}
