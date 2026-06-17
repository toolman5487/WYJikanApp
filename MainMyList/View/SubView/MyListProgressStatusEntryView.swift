//
//  MyListProgressStatusEntryView.swift
//  WYJikanApp
//

import SwiftUI

// MARK: - MyListProgressStatusEntryChip

struct MyListProgressStatusEntryChip: Identifiable {
    let title: String
    let count: Int

    var id: String { title }
}

// MARK: - MyListProgressStatusEntryView

struct MyListProgressStatusEntryView: View {

    // MARK: - Properties

    let title: String
    let subtitle: String
    let iconName: String
    let chips: [MyListProgressStatusEntryChip]
    let action: () -> Void

    // MARK: - Body

    var body: some View {
        Button(action: action) {
            HStack(alignment: .center, spacing: 16) {
                iconView

                VStack(alignment: .leading, spacing: 10) {
                    titleView
                    chipRowView
                }

                Spacer(minLength: 0)

                Image(systemName: "chevron.right")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(ThemeColor.textTertiary)
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(.secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    // MARK: - Private Views

    private var iconView: some View {
        Image(systemName: iconName)
            .font(.title3.weight(.semibold))
            .foregroundStyle(ThemeColor.sakura)
            .frame(width: 44, height: 44)
            .background(ThemeColor.sakura.opacity(0.12))
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private var titleView: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.headline)
                .foregroundStyle(ThemeColor.textPrimary)

            Text(subtitle)
                .font(.footnote)
                .foregroundStyle(ThemeColor.textSecondary)
        }
    }

    private var chipRowView: some View {
        HStack(spacing: 8) {
            ForEach(chips) { chip in
                Text("\(chip.title) \(chip.count)")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(ThemeColor.textSecondary)
                    .lineLimit(1)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color(.tertiarySystemBackground))
                    .clipShape(Capsule())
            }
        }
    }
}
