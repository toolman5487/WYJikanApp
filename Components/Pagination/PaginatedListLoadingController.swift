//
//  PaginatedListLoadingController.swift
//  WYJikanApp
//
//  Created by Codex on 2026/6/15.
//

import Foundation

@MainActor
final class PaginatedListLoadingController<Item: Identifiable & Sendable> where Item.ID: Hashable & Sendable {
    typealias PageFetcher = (_ page: Int) async throws -> PaginatedPage<Item>
    typealias PresentationApplier = (_ items: [Item], _ footerState: PaginationFooterState) -> Void
    typealias LoadingApplier = (_ footerState: PaginationFooterState) -> Void
    typealias ErrorApplier = (_ failure: FeatureLoadFailure, _ footerState: PaginationFooterState) -> Void

    private var pagination = PaginatedListState<Item>()

    var items: [Item] {
        pagination.items
    }

    var currentPage: Int {
        pagination.currentPage
    }

    var hasLoaded: Bool {
        pagination.hasLoaded
    }

    var canLoadMore: Bool {
        pagination.canLoadMore
    }

    var footerState: PaginationFooterState {
        pagination.footerState
    }

    func loadIfNeeded(
        showSkeleton: Bool = true,
        setLoading: LoadingApplier,
        fetchPage: PageFetcher,
        applyPresentation: PresentationApplier,
        applyError: ErrorApplier
    ) async {
        guard !pagination.hasLoaded else { return }
        await reload(
            showSkeleton: showSkeleton,
            setLoading: setLoading,
            fetchPage: fetchPage,
            applyPresentation: applyPresentation,
            applyError: applyError
        )
    }

    func reload(
        showSkeleton: Bool,
        setLoading: LoadingApplier,
        fetchPage: PageFetcher,
        applyPresentation: PresentationApplier,
        applyError: ErrorApplier
    ) async {
        let generation = pagination.beginReload(clearItems: showSkeleton)

        if showSkeleton {
            setLoading(pagination.footerState)
        }

        do {
            let page = try await fetchPage(1)
            guard pagination.finishReload(page, generation: generation) else { return }
            applyPresentation(pagination.items, pagination.footerState)
        } catch is CancellationError {
            return
        } catch {
            guard pagination.isCurrent(generation) else { return }
            applyError(FeatureLoadFailure(error), pagination.footerState)
        }
    }

    func loadMore(
        requiresNewItemsForNextPage: Bool = false,
        fetchPage: PageFetcher,
        setFooterState: LoadingApplier,
        applyPresentation: PresentationApplier
    ) async {
        guard let generation = pagination.beginLoadMore() else { return }
        setFooterState(pagination.footerState)

        do {
            let page = try await fetchPage(pagination.currentPage + 1)
            guard pagination.finishLoadMore(
                page,
                generation: generation,
                requiresNewItemsForNextPage: requiresNewItemsForNextPage
            ) else { return }
            applyPresentation(pagination.items, pagination.footerState)
        } catch is CancellationError {
            if pagination.cancelLoadMore(generation: generation) {
                setFooterState(pagination.footerState)
            }
        } catch {
            guard pagination.failLoadMore(FeatureLoadFailure.loadMore(), generation: generation) else { return }
            setFooterState(pagination.footerState)
        }
    }

    func shouldLoadMore(after item: Item, visibleItems: [Item], threshold: Int = 5) -> Bool {
        pagination.shouldLoadMore(after: item, visibleItems: visibleItems, threshold: threshold)
    }
}
