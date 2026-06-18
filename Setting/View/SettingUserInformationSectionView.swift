//
//  SettingUserInformationSectionView.swift
//  WYJikanApp
//

import SwiftUI

struct SettingUserInformationSectionView: View {
    let presentation: SettingUserInformationPresentation

    var body: some View {
        Section {
            valueRow(
                title: "動畫收藏",
                systemImage: "play.rectangle",
                value: "\(presentation.animeFavoriteCount) 部"
            )
            valueRow(
                title: "漫畫收藏",
                systemImage: "books.vertical",
                value: "\(presentation.mangaFavoriteCount) 部"
            )
            valueRow(
                title: "播出提醒",
                systemImage: "calendar.badge.clock",
                value: "\(presentation.reminderCount) 部"
            )
            valueRow(
                title: "搜尋紀錄",
                systemImage: "clock.arrow.circlepath",
                value: "\(presentation.searchHistoryCount) 筆"
            )
        } header: {
            Text("用戶資訊")
                .foregroundStyle(ThemeColor.sakura)
        } footer: {
            Text("以上資料僅儲存在此裝置，不包含登入帳號或雲端個人資料。")
                .foregroundStyle(ThemeColor.textSecondary)
        }
    }

    private func valueRow(
        title: String,
        systemImage: String,
        value: String
    ) -> some View {
        LabeledContent {
            SettingValueAccessory(text: value)
        } label: {
            Label(title, systemImage: systemImage)
                .foregroundStyle(ThemeColor.textPrimary)
        }
    }
}
