//
//  PlaceholderView.swift
//  WYJikanApp
//
//  Created by Willy Hsu on 2026/3/24.
//

import SwiftUI

struct PlaceholderView: View {
    
    let placeholderName:String
    
    var body: some View {
        Text(placeholderName)
    }
}

#Preview {
    PlaceholderView(placeholderName: "Placeholder")
}
