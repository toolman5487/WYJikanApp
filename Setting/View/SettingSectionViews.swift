//
//  SettingSectionViews.swift
//  WYJikanApp
//

import SwiftUI

// MARK: - Notification

struct SettingNotificationSectionView: View {
    let presentation: SettingNotificationPresentation
    let onAction: (SettingNotificationAction) -> Void

    var body: some View {
        Section {
            LabeledContent {
                SettingValueAccessory(
                    text: presentation.authorizationStatus.title
                )
            } label: {
                Label("通知權限", systemImage: "bell.badge")
                    .foregroundStyle(ThemeColor.textPrimary)
            }

            LabeledContent {
                SettingValueAccessory(
                    text: "\(presentation.reminderCount) 部動畫"
                )
            } label: {
                Label("播出提醒", systemImage: "calendar.badge.clock")
                    .foregroundStyle(ThemeColor.textPrimary)
            }

            primaryAuthorizationButton

            Button {
                onAction(.refreshReminders)
            } label: {
                SettingActionLabel(
                    title: refreshButtonTitle,
                    systemImage: "arrow.clockwise",
                    state: presentation.refreshState
                )
            }
            .disabled(!presentation.canRefreshReminders)
        } header: {
            Text("通知")
                .foregroundStyle(ThemeColor.sakura)
        } footer: {
            Text("播出提醒會依你在動畫詳情頁訂閱的作品安排通知。")
                .foregroundStyle(ThemeColor.textSecondary)
        }
    }

    @ViewBuilder
    private var primaryAuthorizationButton: some View {
        switch presentation.authorizationStatus.primaryAction {
        case .requestAuthorization:
            Button {
                onAction(.requestAuthorization)
            } label: {
                SettingActionLabel(
                    title: "允許通知",
                    systemImage: "bell.badge",
                    state: .idle
                )
            }
            .disabled(presentation.refreshState == .processing)
        case .openSystemSettings:
            Button {
                onAction(.openSystemSettings)
            } label: {
                SettingActionLabel(
                    title: "系統通知設定",
                    systemImage: "gearshape",
                    state: .idle
                )
            }
        case .refreshReminders:
            EmptyView()
        }
    }

    private var refreshButtonTitle: String {
        switch presentation.refreshState {
        case .idle:
            return "立即更新提醒"
        case .processing:
            return "正在更新提醒"
        }
    }
}

// MARK: - Data Management

struct SettingDataManagementSectionView: View {
    let presentation: SettingDataManagementPresentation
    let onAction: (SettingDataAction) -> Void

    var body: some View {
        Section {
            LabeledContent {
                SettingValueAccessory(
                    text: "\(presentation.searchHistoryCount) 筆"
                )
            } label: {
                Label("搜尋紀錄", systemImage: "clock.arrow.circlepath")
                    .foregroundStyle(ThemeColor.textPrimary)
            }

            Button {
                onAction(.clearSearchHistory)
            } label: {
                SettingActionLabel(
                    title: "清除搜尋紀錄",
                    systemImage: "trash",
                    state: .idle
                )
            }
            .disabled(!presentation.canClearSearchHistory)

            LabeledContent {
                SettingValueAccessory(
                    text: "\(presentation.favoriteCount) 個"
                )
            } label: {
                Label("本機收藏", systemImage: "heart")
                    .foregroundStyle(ThemeColor.textPrimary)
            }

            Button {
                onAction(.clearFavorites)
            } label: {
                SettingActionLabel(
                    title: "清除全部收藏",
                    systemImage: "heart.slash",
                    state: .idle
                )
            }
            .disabled(!presentation.canClearFavorites)

            Button {
                onAction(.clearCache)
            } label: {
                SettingActionLabel(
                    title: cacheButtonTitle,
                    systemImage: "externaldrive.badge.xmark",
                    state: presentation.cacheState
                )
            }
            .disabled(presentation.cacheState == .processing)
        } header: {
            Text("資料管理")
                .foregroundStyle(ThemeColor.sakura)
        } footer: {
            Text("清除網路快取不會刪除收藏、觀看進度或播出提醒。")
                .foregroundStyle(ThemeColor.textSecondary)
        }
    }

    private var cacheButtonTitle: String {
        switch presentation.cacheState {
        case .idle:
            return "清除網路快取"
        case .processing:
            return "正在清除快取"
        }
    }
}

// MARK: - App Information

struct SettingAppInformationSectionView: View {
    let presentation: SettingAppInformationPresentation

    var body: some View {
        Section {
            LabeledContent {
                SettingValueAccessory(text: presentation.appName)
            } label: {
                Label("名稱", systemImage: "app")
                    .foregroundStyle(ThemeColor.textPrimary)
            }

            dataSourceLink

            LabeledContent {
                SettingValueAccessory(text: presentation.versionText)
            } label: {
                Label("版本", systemImage: "number")
                    .foregroundStyle(ThemeColor.textPrimary)
            }
        } header: {
            Text("App 資訊")
                .foregroundStyle(ThemeColor.sakura)
        }
    }

    @ViewBuilder
    private var dataSourceLink: some View {
        switch presentation.dataSource.url {
        case .some(let url):
            Link(destination: url) {
                HStack {
                    Label("資料來源", systemImage: "network")
                        .foregroundStyle(ThemeColor.textPrimary)
                    Spacer()
                    SettingValueAccessory(
                        text: presentation.dataSource.title,
                        systemImage: "arrow.up.right"
                    )
                }
            }
        case .none:
            LabeledContent {
                SettingValueAccessory(
                    text: presentation.dataSource.title
                )
            } label: {
                Label("資料來源", systemImage: "network")
                    .foregroundStyle(ThemeColor.textPrimary)
            }
        }
    }
}

// MARK: - Shared Action Label

private struct SettingActionLabel: View {
    let title: String
    let systemImage: String
    let state: SettingActionState

    var body: some View {
        HStack {
            Label(title, systemImage: systemImage)
                .foregroundStyle(ThemeColor.textPrimary)
            Spacer()
            activityIndicator
        }
    }

    @ViewBuilder
    private var activityIndicator: some View {
        switch state {
        case .idle:
            Image(systemName: "chevron.right")
                .font(.caption.weight(.semibold))
                .foregroundStyle(ThemeColor.textSecondary)
        case .processing:
            ProgressView()
                .controlSize(.small)
                .tint(ThemeColor.textPrimary)
        }
    }
}

// MARK: - Shared Value Accessory

private struct SettingValueAccessory: View {
    let text: String
    var systemImage: String?

    var body: some View {
        HStack(spacing: 8) {
            Text(text)
                .foregroundStyle(ThemeColor.textSecondary)

            switch systemImage {
            case .some(let systemImage):
                Image(systemName: systemImage)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(ThemeColor.textSecondary)
            case .none:
                EmptyView()
            }
        }
    }

    init(text: String, systemImage: String? = nil) {
        self.text = text
        self.systemImage = systemImage
    }
}
