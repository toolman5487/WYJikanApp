//
//  HeroBannerSlideView.swift
//  WYJikanApp
//
//  Created by Willy Hsu on 2026/3/27.
//

import SwiftUI

struct HeroBannerSlideView: View {
    let imageURL: URL
    
    var body: some View {
        ZStack(alignment: .bottomLeading) {
            HeroBannerImageView(url: imageURL)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .clipped()
            
            LinearGradient(
                colors: [
                    .clear,
                    Color.black.opacity(0.65)
                ],
                startPoint: .center,
                endPoint: .bottom
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
