//
//  MainListView.swift
//  WYJikanApp
//
//  Created by Willy Hsu on 2026/4/5.
//

import SwiftUI

struct MainListView: View {
    
    @State private var selectedKind: MainListKind = .anime
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                CapsuleTagScrollView(
                    tags: MainListKind.allCases,
                    title: { $0.title },
                    selection: $selectedKind
                )
                .padding(.horizontal)
                .padding(.vertical, 8)
                
                List {
                }
            }
        }
    }
}

#Preview {
    MainListView()
}
