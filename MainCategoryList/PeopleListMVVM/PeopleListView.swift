//
//  PeopleListView.swift
//  WYJikanApp
//
//  Created by Willy Hsu on 2026/4/8.
//

import SwiftUI

struct PeopleListView: View {
    var body: some View {
        ScrollView {
            Text("People List View")
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
        }
    }
}

#Preview {
    PeopleListView()
}
