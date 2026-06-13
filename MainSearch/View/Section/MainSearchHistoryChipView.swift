//
//  MainSearchHistoryChipView.swift
//  WYJikanApp
//

import SwiftUI

struct MainSearchHistoryChipView: View {

    // MARK: - Properties

    let item: MainSearchHistoryItem
    let onSelect: (MainSearchHistoryItem) -> Void
    let onRemove: (MainSearchHistoryItem) -> Void

    // MARK: - Body

    var body: some View {
        HStack(spacing: 8) {
            selectButton
            removeButton
        }
        .padding(.leading, 16)
        .padding(.trailing, 8)
        .padding(.vertical, 8)
        .frame(minHeight: 44)
        .background {
            Capsule()
                .fill(Color(.secondarySystemBackground).opacity(0.95))
        }
        .overlay {
            Capsule()
                .strokeBorder(ThemeColor.sakura.opacity(0.12), lineWidth: 1)
        }
        .clipShape(Capsule())
    }

    // MARK: - Private Views

    private var selectButton: some View {
        Button {
            onSelect(item)
        } label: {
            HStack(spacing: 8) {
                Image(systemName: item.kind.historyIconSystemName)
                    .font(.footnote.weight(.semibold))

                Text(item.query)
                    .font(.subheadline.weight(.semibold))
                    .lineLimit(1)
            }
            .foregroundStyle(ThemeColor.textPrimary)
        }
        .buttonStyle(.plain)
    }

    private var removeButton: some View {
        Button {
            onRemove(item)
        } label: {
            Image(systemName: "xmark")
                .font(.caption.weight(.bold))
                .frame(width: 24, height: 24)
                .foregroundStyle(ThemeColor.textSecondary)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("刪除 \(item.query)")
    }
}

// MARK: - MainSearchKind

private extension MainSearchKind {
    var historyIconSystemName: String {
        switch self {
        case .anime:
            "play.rectangle"
        case .manga:
            "book.closed"
        case .character:
            "person.crop.circle"
        case .people:
            "person.wave.2"
        }
    }
}
