//
//  DetailCopySuccessIndicator.swift
//  WYJikanApp
//
//  Created by Willy Hsu on 2026/6/11.
//

import SwiftUI

struct DetailCopySuccessIndicator: View {
    var body: some View {
        Image(systemName: "doc.on.doc.fill")
            .font(.title3.weight(.semibold))
            .foregroundStyle(ThemeColor.sakura)
            .padding(10)
            .background(.ultraThinMaterial, in: Circle())
            .shadow(color: .black.opacity(0.12), radius: 8, y: 2)
    }
}
