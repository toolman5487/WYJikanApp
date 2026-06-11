//
//  DetailClipboard.swift
//  WYJikanApp
//
//  Created by Willy Hsu on 2026/6/11.
//

import UIKit

enum DetailClipboard {
    @MainActor
    static func copy(_ text: String) {
        UIPasteboard.general.string = text
    }
}
