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
        case .storage:
            SettingStorageSectionView(
                presentation: viewModel.presentation.storage,
                userInformation: viewModel.presentation.userInformation,
                onClearCache: viewModel.requestCacheClearConfirmation,
                onDeleteLocalData: viewModel.requestLocalDataDeletionConfirmation
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
        case .confirmCacheClear(let sizeText):
            return Alert(
                title: Text("清除快取？"),
                message: Text("將清除約 \(sizeText) 的圖片與網路快取，不會刪除收藏或其他本機資料。"),
                primaryButton: .destructive(Text("清除")) {
                    Task(priority: .userInitiated) {
                        await viewModel.clearCache()
                    }
                },
                secondaryButton: .cancel(Text("取消"))
            )
        case .cacheClearSucceeded:
            return informationAlert(
                title: "快取已清除",
                message: "圖片與網路資料會在需要時重新下載。"
            )
        case .cacheClearFailed:
            return informationAlert(
                title: "無法清除快取",
                message: "快取暫時無法清除，請稍後再試。"
            )
        case .confirmLocalDataDeletion(let target, let message):
            return Alert(
                title: Text("刪除\(target.title)？"),
                message: Text(message),
                primaryButton: .destructive(Text("刪除")) {
                    Task(priority: .userInitiated) {
                        await viewModel.deleteLocalData(target)
                    }
                },
                secondaryButton: .cancel(Text("取消"))
            )
        case .localDataDeletionSucceeded(let target):
            return informationAlert(
                title: "\(target.title)已刪除",
                message: localDataDeletionSuccessMessage(for: target)
            )
        case .localDataDeletionFailed(let target, let partiallyCompleted):
            return informationAlert(
                title: "無法刪除\(target.title)",
                message: partiallyCompleted
                    ? "部分資料已刪除，但操作未完整完成。請確認目前資料後再試。"
                    : "本機資料暫時無法刪除，請稍後再試。"
            )
        }
    }

    private func localDataDeletionSuccessMessage(
        for target: SettingLocalDataTarget
    ) -> String {
        switch target {
        case .searchHistory:
            return "搜尋紀錄已從此裝置移除。"
        case .broadcastReminders:
            return "播出提醒與 App 管理的系統通知已移除。"
        case .favoritesAndProgress:
            return "收藏、動畫觀看進度與漫畫閱讀進度已移除。"
        case .all:
            return "收藏、進度、播出提醒、系統通知與搜尋紀錄已移除。"
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
