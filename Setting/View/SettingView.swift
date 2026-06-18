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
        .alert(item: $viewModel.presentedAlert, content: messageAlert)
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
        case .userInformation:
            SettingUserInformationSectionView(
                presentation: viewModel.presentation.userInformation
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

    private func messageAlert(for message: SettingAlertMessage) -> Alert {
        switch message {
        case .notificationAuthorizationFailed:
            return informationAlert(
                title: "無法開啟通知",
                message: "請前往系統設定允許通知後再試。"
            )
        case .reminderRefreshSucceeded(let count):
            return informationAlert(
                title: "提醒已更新",
                message: "已重新安排 \(count) 則播出提醒。"
            )
        case .reminderRefreshFailed:
            return informationAlert(
                title: "無法更新提醒",
                message: "播出提醒暫時無法更新，請稍後再試。"
            )
        }
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
