//
//  PeopleDetailAboutSectionView.swift
//  WYJikanApp
//
//  Created by Willy Hsu on 2026/4/23.
//

import SwiftUI

struct PeopleDetailAboutSectionView: View {
    let viewModel: PeopleDetailViewModel
    let person: PeopleDetailDTO

    var body: some View {
        if let about = viewModel.aboutText(for: person) {
            AnimeDetailSectionCard("人物簡介") {
                Text(about)
                    .font(.body)
                    .foregroundStyle(ThemeColor.textPrimary.opacity(0.9))
                    .lineSpacing(4)
                    .textSelection(.enabled)
            }
        }
    }
}
