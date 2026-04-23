//
//  ImagePreviewViewer.swift
//  WYJikanApp
//
//  Created by Codex on 2026/4/23.
//

import SwiftUI
import SDWebImageSwiftUI

struct ImagePreviewItem: Identifiable, Hashable {
    let id: String
    let url: URL
}

struct ImagePreviewViewer: View {
    let items: [ImagePreviewItem]
    @Binding var selectedIndex: Int

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack(alignment: .topTrailing) {
            Color.black
                .ignoresSafeArea()

            TabView(selection: $selectedIndex) {
                ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                    previewImage(url: item.url)
                        .tag(index)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 60)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .automatic))

            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(.white)
                    .frame(width: 44, height: 44)
                    .background(.black.opacity(0.5))
                    .clipShape(Circle())
            }
            .padding(.top, 16)
            .padding(.trailing, 16)
        }
        .overlay(alignment: .bottom) {
            if !items.isEmpty {
                Text("\(selectedIndex + 1) / \(items.count)")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(.black.opacity(0.5))
                    .clipShape(Capsule())
                    .padding(.bottom, 24)
            }
        }
        .overlay {
            if items.count > 1 {
                HStack {
                    navigationButton(
                        systemName: "chevron.left",
                        isEnabled: selectedIndex > 0
                    ) {
                        selectedIndex = max(selectedIndex - 1, 0)
                    }

                    Spacer()

                    navigationButton(
                        systemName: "chevron.right",
                        isEnabled: selectedIndex < items.count - 1
                    ) {
                        selectedIndex = min(selectedIndex + 1, items.count - 1)
                    }
                }
                .padding(.horizontal, 16)
            }
        }
    }

    @ViewBuilder
    private func previewImage(url: URL) -> some View {
        ZoomableRemoteImageView(url: url)
    }

    private func navigationButton(
        systemName: String,
        isEnabled: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.title3.weight(.semibold))
                .foregroundStyle(.white)
                .frame(width: 44, height: 44)
                .background(.black.opacity(0.5))
                .clipShape(Circle())
        }
        .disabled(!isEnabled)
        .opacity(isEnabled ? 1 : 0.35)
    }
}

private struct ZoomableRemoteImageView: View {
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
