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
        cacheSection
        localDataSection
        resetSection
    }

    private var cacheSection: some View {
        Section {
            cacheSizeRow
            clearCacheButton
        } header: {
            Text("快取")
                .foregroundStyle(ThemeColor.sakura)
        } footer: {
            Text("清除後會在需要時重新下載圖片與網路資料，不會影響你的收藏與紀錄。")
                .foregroundStyle(ThemeColor.textSecondary)
        }
    }

    private var localDataSection: some View {
        Section {
            ForEach(deletionRows) { row in
                deletionButton(row)
            }
        } header: {
            Text("本機資料")
                .foregroundStyle(ThemeColor.sakura)
        } footer: {
            Text("各項資料只儲存在此裝置，刪除後無法復原。")
                .foregroundStyle(ThemeColor.textSecondary)
        }
    }

    private var resetSection: some View {
        Section {
            deletionButton(resetRow)
        } header: {
            Text("重設資料")
                .foregroundStyle(ThemeColor.sakura)
        } footer: {
            Text("一次移除收藏與進度、播出提醒、系統通知及搜尋紀錄。")
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
                state: deletionActionState(for: row.target),
                value: row.valueText
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
                itemCount: userInformation.searchHistoryCount,
                valueText: "\(userInformation.searchHistoryCount) 筆"
            ),
            SettingStorageDeletionRow(
                target: .broadcastReminders,
                title: "刪除播出提醒",
                systemImage: "calendar.badge.minus",
                itemCount: userInformation.reminderCount,
                valueText: "\(userInformation.reminderCount) 部"
            ),
            SettingStorageDeletionRow(
                target: .favoritesAndProgress,
                title: "刪除收藏與進度",
                systemImage: "heart.slash",
                itemCount: favoriteCount,
                valueText: "\(favoriteCount) 部"
            )
        ]
    }

    private var resetRow: SettingStorageDeletionRow {
        SettingStorageDeletionRow(
            target: .all,
            title: "刪除所有本機資料",
            systemImage: "trash",
            itemCount: localDataCount,
            valueText: "\(localDataCount) 項"
        )
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
    let valueText: String

    var id: SettingLocalDataTarget { target }
}
