//
//  SettingStorageSectionView.swift
//  WYJikanApp
//

import SwiftUI

struct SettingStorageSectionView: View {
    let presentation: SettingStoragePresentation
    let userInformation: SettingUserInformationPresentation
    let onClearCache: () -> Void
    let onDeleteLocalData: (SettingLocalDataTarget) -> Void

    var body: some View {
        Section {
            cacheSizeRow
            clearCacheButton

            ForEach(deletionRows) { row in
                deletionButton(row)
            }
        } header: {
            Text("儲存空間與資料")
                .foregroundStyle(ThemeColor.sakura)
        } footer: {
            Text("快取可以重新下載；收藏、進度、提醒與搜尋紀錄刪除後無法復原。")
                .foregroundStyle(ThemeColor.textSecondary)
        }
    }

    private var cacheSizeRow: some View {
        LabeledContent {
            cacheSizeAccessory
        } label: {
            Label("快取資料", systemImage: "internaldrive")
                .foregroundStyle(ThemeColor.textPrimary)
        }
    }

    private var clearCacheButton: some View {
        Button(action: onClearCache) {
            SettingActionLabel(
                title: cacheActionTitle,
                systemImage: "trash",
                state: cacheActionState
            )
        }
        .disabled(
            !presentation.cacheState.canClear
                || presentation.isOperationInProgress
        )
    }

    private func deletionButton(
        _ row: SettingStorageDeletionRow
    ) -> some View {
        Button {
            onDeleteLocalData(row.target)
        } label: {
            SettingActionLabel(
                title: row.title,
                systemImage: row.systemImage,
                state: deletionActionState(for: row.target)
            )
        }
        .disabled(
            row.itemCount == 0
                || presentation.isOperationInProgress
        )
    }

    @ViewBuilder
    private var cacheSizeAccessory: some View {
        switch presentation.cacheState {
        case .loading:
            ProgressView()
                .controlSize(.small)
                .accessibilityLabel("正在計算快取大小")
        case .available, .clearing:
            SettingValueAccessory(
                text: presentation.cacheState.sizeText
            )
        }
    }

    private var cacheActionTitle: String {
        switch presentation.cacheState {
        case .loading, .available:
            return "清除快取"
        case .clearing:
            return "正在清除快取"
        }
    }

    private var cacheActionState: SettingActionState {
        switch presentation.cacheState {
        case .loading, .available:
            return .idle
        case .clearing:
            return .processing
        }
    }

    private func deletionActionState(
        for target: SettingLocalDataTarget
    ) -> SettingActionState {
        presentation.localDataOperationState.activeTarget == target
            ? .processing
            : .idle
    }

    private var deletionRows: [SettingStorageDeletionRow] {
        [
            SettingStorageDeletionRow(
                target: .searchHistory,
                title: "清除搜尋紀錄",
                systemImage: "clock.arrow.circlepath",
                itemCount: userInformation.searchHistoryCount
            ),
            SettingStorageDeletionRow(
                target: .broadcastReminders,
                title: "刪除播出提醒",
                systemImage: "calendar.badge.minus",
                itemCount: userInformation.reminderCount
            ),
            SettingStorageDeletionRow(
                target: .favoritesAndProgress,
                title: "刪除收藏與進度",
                systemImage: "heart.slash",
                itemCount: favoriteCount
            ),
            SettingStorageDeletionRow(
                target: .all,
                title: "刪除所有本機資料",
                systemImage: "trash",
                itemCount: localDataCount
            )
        ]
    }

    private var favoriteCount: Int {
        userInformation.animeFavoriteCount
            + userInformation.mangaFavoriteCount
    }

    private var localDataCount: Int {
        favoriteCount
            + userInformation.reminderCount
            + userInformation.searchHistoryCount
    }
}

private struct SettingStorageDeletionRow: Identifiable {
    let target: SettingLocalDataTarget
    let title: String
    let systemImage: String
    let itemCount: Int

    var id: SettingLocalDataTarget { target }
}
