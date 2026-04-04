//
//  MainSearchView.swift
//  WYJikanApp
//
//  Created by Willy Hsu on 2026/4/2.
//

import SwiftUI

struct MainSearchView: View {

    @Binding var selectedKind: MainSearchKind

    var body: some View {
        VStack(spacing: 0) {
            CapsuleTagScrollView(
                tags: MainSearchKind.allCases,
                title: { $0.title },
                selection: $selectedKind
            )
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 16)
            .padding(.vertical, 12)

            Spacer(minLength: 0)
        }
    }
}

#Preview {
    @Previewable @State var kind = MainSearchKind.anime
    MainSearchView(selectedKind: $kind)
}
