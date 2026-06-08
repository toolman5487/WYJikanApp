//
//  CharacterListView.swift
//  WYJikanApp
//
//  Created by Willy Hsu on 2026/4/8.
//

import SwiftUI

struct CharacterListView: View {

    // MARK: - Properties

    @ObservedObject var viewModel: CharacterListViewModel

    // MARK: - Body

    var body: some View {
        CharacterListContentView(viewModel: viewModel)
            .onDisappear {
                viewModel.stop()
            }
    }
}

// MARK: - Preview

#Preview {
    ScrollView {
        CharacterListView(viewModel: CharacterListViewModel())
            .padding(.horizontal)
    }
}
