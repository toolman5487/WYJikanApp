//
//  HeroBannerImageView.swift
//  WYJikanApp
//
//  Created by Willy Hsu on 2026/3/26.
//

import SwiftUI

// MARK: - HeroBannerImageView

struct HeroBannerImageView: View {

    // MARK: - Properties

    let url: URL

    // MARK: - Body

    var body: some View {
        GeometryReader { proxy in
            RemotePosterImageView(
                url: url,
                contentMode: .fill,
                fixedSize: proxy.size
            )
        }
    }
}

#Preview {
    HeroBannerImageView(url: URL(string: "https://example.com/image.jpg")!)
        .frame(height: 220)
}
