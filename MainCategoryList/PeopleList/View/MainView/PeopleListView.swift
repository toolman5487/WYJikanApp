//
//  PeopleListView.swift
//  WYJikanApp
//
//  Created by Willy Hsu on 2026/4/8.
//

import SwiftUI

struct PeopleListView: View {

    // MARK: - Properties

    @ObservedObject var viewModel: PeopleListViewModel

    // MARK: - Body

    var body: some View {
        PeopleListContentView(viewModel: viewModel)
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
        PeopleListView(viewModel: PeopleListViewModel())
            .padding(.horizontal)
    }
}
