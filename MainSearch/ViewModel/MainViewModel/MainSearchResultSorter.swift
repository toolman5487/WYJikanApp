//
//  MainSearchResultSorter.swift
//  WYJikanApp
//
//  Created by Codex on 2026/6/2.
//

import Foundation

struct MainSearchResultSorter: Sendable {

    // MARK: - Sorting

    func sortedRows(
        from rows: [MainSearchResultRow],
        using option: MainSearchSortOption
    ) -> [MainSearchResultRow] {
        switch option {
        case .default:
            return rows
        case .titleAscending:
            return rows.sorted { lhs, rhs in
                lhs.sortTitle.localizedCompare(rhs.sortTitle) == .orderedAscending
            }
        case .titleDescending:
            return rows.sorted { lhs, rhs in
                lhs.sortTitle.localizedCompare(rhs.sortTitle) == .orderedDescending
            }
        case .newest:
            return rows.sorted { lhs, rhs in
                compareOptionalDescending(
                    lhs.year,
                    rhs.year,
                    lhsTitle: lhs.sortTitle,
                    rhsTitle: rhs.sortTitle
                )
            }
        case .oldest:
            return rows.sorted { lhs, rhs in
                compareOptionalAscending(
                    lhs.year,
                    rhs.year,
                    lhsTitle: lhs.sortTitle,
                    rhsTitle: rhs.sortTitle
                )
            }
        case .popularityDescending:
            return rows.sorted { lhs, rhs in
                compareOptionalDescending(
                    lhs.popularityScore,
                    rhs.popularityScore,
                    lhsTitle: lhs.sortTitle,
                    rhsTitle: rhs.sortTitle
                )
            }
        case .popularityAscending:
            return rows.sorted { lhs, rhs in
                compareOptionalAscending(
                    lhs.popularityScore,
                    rhs.popularityScore,
                    lhsTitle: lhs.sortTitle,
                    rhsTitle: rhs.sortTitle
                )
            }
        }
    }

    // MARK: - Private Methods

    private func compareOptionalAscending<T: Comparable>(
        _ lhs: T?,
        _ rhs: T?,
        lhsTitle: String,
        rhsTitle: String
    ) -> Bool {
        switch (lhs, rhs) {
        case let (left?, right?):
            if left == right {
                return lhsTitle.localizedCompare(rhsTitle) == .orderedAscending
            }
            return left < right
        case (.some, .none):
            return true
        case (.none, .some):
            return false
        case (.none, .none):
            return lhsTitle.localizedCompare(rhsTitle) == .orderedAscending
        }
    }

    private func compareOptionalDescending<T: Comparable>(
        _ lhs: T?,
        _ rhs: T?,
        lhsTitle: String,
        rhsTitle: String
    ) -> Bool {
        switch (lhs, rhs) {
        case let (left?, right?):
            if left == right {
                return lhsTitle.localizedCompare(rhsTitle) == .orderedAscending
            }
            return left > right
        case (.some, .none):
            return true
        case (.none, .some):
            return false
        case (.none, .none):
            return lhsTitle.localizedCompare(rhsTitle) == .orderedAscending
        }
    }
}
