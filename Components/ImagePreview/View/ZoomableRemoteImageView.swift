//
//  ZoomableRemoteImageView.swift
//  WYJikanApp
//
//  Created by Willy Hsu 2026/4/24.
//

import SwiftUI
import SDWebImageSwiftUI

struct ZoomableRemoteImageView: View {
    let url: URL

    @State private var scale: CGFloat = 1
    @State private var lastScale: CGFloat = 1
    @State private var offset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero

    var body: some View {
        GeometryReader { proxy in
            WebImage(url: url) { image in
                image
                    .resizable()
                    .scaledToFit()
                    .frame(width: proxy.size.width, height: proxy.size.height)
            } placeholder: {
                ProgressView()
                    .tint(.white)
                    .frame(width: proxy.size.width, height: proxy.size.height)
            }
            .indicator(.activity)
            .scaleEffect(scale)
            .offset(offset)
            .contentShape(Rectangle())
            .gesture(dragGesture)
            .simultaneousGesture(magnificationGesture)
            .simultaneousGesture(doubleTapGesture)
            .animation(.easeInOut(duration: 0.2), value: scale)
            .animation(.easeInOut(duration: 0.2), value: offset)
            .onChange(of: url) { _, _ in
                resetTransform()
            }
        }
    }

    // MARK: - Private

    private var magnificationGesture: some Gesture {
        MagnifyGesture()
            .onChanged { value in
                let nextScale = lastScale * value.magnification
                scale = min(max(nextScale, 1), 4)
                if scale <= 1 {
                    offset = .zero
                    lastOffset = .zero
                }
            }
            .onEnded { _ in
                lastScale = scale
                if scale <= 1 {
                    resetTransform()
                }
            }
    }

    private var dragGesture: some Gesture {
        DragGesture()
            .onChanged { value in
                guard scale > 1 else { return }
                offset = CGSize(
                    width: lastOffset.width + value.translation.width,
                    height: lastOffset.height + value.translation.height
                )
            }
            .onEnded { _ in
                guard scale > 1 else {
                    resetTransform()
                    return
                }
                lastOffset = offset
            }
    }

    private var doubleTapGesture: some Gesture {
        TapGesture(count: 2)
            .onEnded {
                if scale > 1 {
                    resetTransform()
                } else {
                    scale = 2
                    lastScale = 2
                }
            }
    }

    private func resetTransform() {
        scale = 1
        lastScale = 1
        offset = .zero
        lastOffset = .zero
    }
}
