//
//  RandomHeroSkeletonView.swift
//  WYJikanApp
//
//  Created by Willy Hsu on 2026/4/8.
//

import SwiftUI

struct RandomHeroSkeletonView: View {
    var body: some View {
        BannerSkeletonView()
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            .frame(height: 370)
    }
}

#Preview {
    RandomHeroSkeletonView()
}
