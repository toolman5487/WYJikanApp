//
//  SettingAppInformationSectionView.swift
//  WYJikanApp
//

import SwiftUI

struct SettingAppInformationSectionView: View {
    let presentation: SettingAppInformationPresentation

    var body: some View {
        Section {
            valueRow(
                title: "名稱",
                systemImage: "app",
                value: presentation.appName
            )
            valueRow(
                title: "版本",
                systemImage: "number",
                value: presentation.versionText
            )
        } header: {
            Text("App 資訊")
                .foregroundStyle(ThemeColor.sakura)
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
