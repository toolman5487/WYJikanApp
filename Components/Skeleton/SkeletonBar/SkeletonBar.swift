//
//  SkeletonBar.swift
//  WYJikanApp
//
//  Created by Willy Hsu on 2026/3/28.
//

import SwiftUI

struct SkeletonBar: View {
    var width: CGFloat?
    let height: CGFloat
    var cornerRadius: CGFloat = 6

    var body: some View {
        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            .fill(Color.gray.opacity(0.22))
            .frame(width: width, height: height)
            .frame(maxWidth: width == nil ? .infinity : nil, alignment: .leading)
    }
}
