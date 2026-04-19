//
//  CharacterListView.swift
//  WYJikanApp
//
//  Created by Willy Hsu on 2026/4/8.
//

import SwiftUI

struct CharacterListView: View {
    @ObservedObject var viewModel: CharacterListViewModel

    var body: some View {
        CharacterListContentView(viewModel: viewModel)
            .onAppear {
                viewModel.loadIfNeeded()
            }
            .onDisappear {
                viewModel.stop()
            }
    }
}

#Preview {
    ScrollView {
        CharacterListView(viewModel: CharacterListViewModel())
            .padding(.horizontal)
    }
}
