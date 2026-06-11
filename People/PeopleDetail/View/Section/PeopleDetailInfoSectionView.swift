//
//  PeopleDetailInfoSectionView.swift
//  WYJikanApp
//
//  Created by Willy Hsu on 2026/4/23.
//

import SwiftUI

struct PeopleDetailInfoSectionView: View {
    let viewModel: PeopleDetailViewModel
    let person: PeopleDetailDTO

    var body: some View {
        AnimeDetailSectionCard("人物資訊") {
            VStack(alignment: .leading, spacing: 12) {
                AnimeDetailInfoRow(
                    title: "本名",
                    value: viewModel.displayName(for: person),
                    isValueCopyable: true
                )
                AnimeDetailInfoRow(
                    title: "英文名",
                    value: person.name ?? "-",
                    isValueCopyable: true
                )
                AnimeDetailInfoRow(title: "收藏", value: viewModel.favoritesText(for: person))

                if let birthday = viewModel.birthdayText(for: person) {
                    AnimeDetailInfoRow(title: "生日", value: birthday)
                }

                if let alternateNames = viewModel.alternateNamesText(for: person) {
                    AnimeDetailInfoRow(
                        title: "別名",
                        value: alternateNames,
                        isValueCopyable: true
                    )
                }
            }
        }
    }
}
