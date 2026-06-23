//
//  SettingNotificationSectionView.swift
//  WYJikanApp
//

import SwiftUI

struct SettingNotificationSectionView: View {
    let presentation: SettingNotificationPresentation
    let onAction: (SettingNotificationAction) -> Void

    var body: some View {
        Section {
            authorizationStatusRow
            reminderCountRow
            primaryAuthorizationButton
            refreshButton
        } header: {
            Text("通知")
                .foregroundStyle(ThemeColor.sakura)
        } footer: {
            Text("播出提醒會依你在動畫詳情頁訂閱的作品安排通知。")
                .foregroundStyle(ThemeColor.textSecondary)
        }
    }

    private var reminderCountRow: some View {
        LabeledContent {
            SettingValueAccessory(
                text: "\(presentation.reminderCount) 部"
            )
        } label: {
            Label("已訂閱提醒", systemImage: "calendar.badge.clock")
                .foregroundStyle(ThemeColor.textPrimary)
        }
    }

    private var authorizationStatusRow: some View {
        LabeledContent {
            authorizationStatusAccessory
        } label: {
            Label("通知權限", systemImage: "bell.badge")
                .foregroundStyle(ThemeColor.textPrimary)
        }
    }

    @ViewBuilder
    private var primaryAuthorizationButton: some View {
        switch presentation.authorizationStatus.primaryAction {
        case .some(.requestAuthorization):
            actionButton(
                title: "允許通知",
                systemImage: "bell.badge",
                action: .requestAuthorization
            )
            .disabled(presentation.refreshState == .processing)
        case .some(.openSystemSettings):
            actionButton(
                title: "系統通知設定",
                systemImage: "gearshape",
                action: .openSystemSettings
            )
        case .none:
            EmptyView()
        }
    }

    private var refreshButton: some View {
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
    }

    private func actionButton(
        title: String,
        systemImage: String,
        action: SettingNotificationAction
    ) -> some View {
        Button {
            onAction(action)
        } label: {
            SettingActionLabel(
                title: title,
                systemImage: systemImage,
                state: .idle
            )
        }
    }

    @ViewBuilder
    private var authorizationStatusAccessory: some View {
        switch presentation.authorizationStatus {
        case .loading:
            ProgressView()
                .controlSize(.small)
        case .notDetermined:
            SettingValueAccessory(
                text: presentation.authorizationStatus.title
            )
        case .authorized:
            SettingValueAccessory(
                text: presentation.authorizationStatus.title
            )
        case .provisional:
            SettingValueAccessory(
                text: presentation.authorizationStatus.title
            )
        case .ephemeral:
            SettingValueAccessory(
                text: presentation.authorizationStatus.title
            )
        case .denied:
            SettingValueAccessory(
                text: presentation.authorizationStatus.title
            )
        }
    }

    private var refreshButtonTitle: String {
        switch presentation.refreshState {
        case .idle:
            return presentation.reminderCount == 0
                ? "尚無可更新提醒"
                : "立即更新提醒"
        case .processing:
            return "正在更新提醒"
        }
    }

}
