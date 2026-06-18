//
//  SettingView.swift
//  WYJikanApp
//
//  Created by Willy Hsu on 2026/6/17.
//

import SwiftUI
import UIKit

struct SettingView: View {

    // MARK: - Environment

    @Environment(\.openURL) private var openURL
    @Environment(\.scenePhase) private var scenePhase

    // MARK: - State

    @StateObject private var viewModel: SettingViewModel

    // MARK: - Lifecycle

    init(
        dependencies: AppDependencies,
        notificationScheduler: HomeTodayAnimeNotificationScheduler,
        broadcastReminderStatusStore: AnimeBroadcastReminderStatusStore,
        favoriteStatusStore: FavoriteStatusStore
    ) {
        _viewModel = StateObject(
            wrappedValue: dependencies.makeSettingViewModel(
                notificationScheduler: notificationScheduler,
                broadcastReminderStatusStore: broadcastReminderStatusStore,
                favoriteStatusStore: favoriteStatusStore
            )
        )
    }

    // MARK: - Body

    var body: some View {
        Form {
            ForEach(SettingSection.allCases) { section in
                sectionView(for: section)
            }
        }
        .formStyle(.grouped)
        .scrollContentBackground(.hidden)
        .background(Color(.systemGroupedBackground))
        .tint(ThemeColor.sakura)
        .navigationTitle("設定")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("設定")
                    .font(.headline)
                    .foregroundStyle(ThemeColor.sakura)
            }
        }
        .task {
            await viewModel.refresh()
        }
        .onChange(of: scenePhase) { _, phase in
            handleScenePhaseChange(phase)
        }
        .alert(item: $viewModel.presentedAlert, content: makeAlert)
    }

    // MARK: - Section Routing

    @ViewBuilder
    private func sectionView(for section: SettingSection) -> some View {
        switch section {
        case .notification:
            SettingNotificationSectionView(
                presentation: viewModel.presentation.notification,
                onAction: handleNotificationAction
            )
        case .dataManagement:
            SettingDataManagementSectionView(
                presentation: viewModel.presentation.dataManagement,
                onAction: viewModel.requestDataAction
            )
        case .appInformation:
            SettingAppInformationSectionView(
                presentation: viewModel.presentation.appInformation
            )
        }
    }

    // MARK: - Actions

    private func handleScenePhaseChange(_ phase: ScenePhase) {
        switch phase {
        case .active:
            Task(priority: .utility) {
                await viewModel.refresh()
            }
        case .inactive, .background:
            break
        @unknown default:
            break
        }
    }

    private func handleNotificationAction(_ action: SettingNotificationAction) {
        switch action {
        case .requestAuthorization, .refreshReminders:
            Task(priority: .userInitiated) {
                await viewModel.performNotificationAction(action)
            }
        case .openSystemSettings:
            openNotificationSettings()
        }
    }

    private func openNotificationSettings() {
        switch URL(string: UIApplication.openNotificationSettingsURLString) {
        case .some(let url):
            openURL(url)
        case .none:
            break
        }
    }

    // MARK: - Alert

    private func makeAlert(_ alert: SettingAlert) -> Alert {
        switch alert {
        case .confirmation(let action, let count):
            return confirmationAlert(for: action, count: count)
        case .message(let message):
            return messageAlert(for: message)
        }
    }

    private func confirmationAlert(
        for action: SettingDataAction,
        count: Int
    ) -> Alert {
        switch action {
        case .clearSearchHistory:
            return destructiveAlert(
                title: "清除搜尋紀錄？",
                message: "將刪除 \(count) 筆搜尋紀錄。"
            )
        case .clearFavorites:
            return destructiveAlert(
                title: "清除全部收藏？",
                message: "將永久刪除 \(count) 個收藏與相關觀看或閱讀進度。"
            )
        case .clearCache:
            return destructiveAlert(
                title: "清除網路快取？",
                message: "已載入的網路資料將在下次使用時重新下載。"
            )
        }
    }

    private func messageAlert(for message: SettingAlertMessage) -> Alert {
        switch message {
        case .notificationAuthorizationFailed:
            return informationAlert(
                title: "無法開啟通知",
                message: "請前往系統設定允許通知後再試。"
            )
        case .favoriteRemovalFailed(let message):
            return informationAlert(
                title: "無法清除收藏",
                message: message
            )
        case .cacheCleared:
            return informationAlert(
                title: "快取已清除",
                message: "下次載入內容時會重新取得最新資料。"
            )
        }
    }

    private func destructiveAlert(title: String, message: String) -> Alert {
        Alert(
            title: Text(title),
            message: Text(message),
            primaryButton: .destructive(
                Text("清除"),
                action: viewModel.confirmPresentedAlert
            ),
            secondaryButton: .cancel(
                Text("取消"),
                action: viewModel.dismissPresentedAlert
            )
        )
    }

    private func informationAlert(title: String, message: String) -> Alert {
        Alert(
            title: Text(title),
            message: Text(message),
            dismissButton: .default(
                Text("好"),
                action: viewModel.dismissPresentedAlert
            )
        )
    }
}

#Preview {
    let broadcastReminderStatusStore = AnimeBroadcastReminderStatusStore()
    let favoriteStatusStore = FavoriteStatusStore()
    let notificationScheduler = HomeTodayAnimeNotificationScheduler()

    NavigationStack {
        SettingView(
            dependencies: .live,
            notificationScheduler: notificationScheduler,
            broadcastReminderStatusStore: broadcastReminderStatusStore,
            favoriteStatusStore: favoriteStatusStore
        )
    }
}
