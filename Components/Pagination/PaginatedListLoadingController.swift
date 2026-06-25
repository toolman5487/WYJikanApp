//
//  PaginatedListLoadingController.swift
//  WYJikanApp
//
//  Created by Codex on 2026/6/15.
//

import Foundation

// MARK: - PaginatedListLoadControlling

@MainActor
protocol PaginatedListLoadControlling: AnyObject {
    var canLoadMore: Bool { get }
    var isLoadingMore: Bool { get }
    func loadIfNeeded()
    func loadMore()
    func reload()
    func stop()
}

// MARK: - PaginatedListLoadingController

@MainActor
final class PaginatedListLoadingController<Item: Identifiable & Sendable> where Item.ID: Hashable & Sendable {

    // MARK: - Typealiases

    typealias PageFetcher = (_ page: Int) async throws -> PaginatedPage<Item>
    typealias PresentationApplier = (_ items: [Item], _ footerState: PaginationFooterState) -> Void
    typealias LoadingApplier = (_ footerState: PaginationFooterState) -> Void
    typealias ErrorApplier = (_ failure: FeatureLoadFailure, _ footerState: PaginationFooterState) -> Void

    // MARK: - Properties

    private var pagination = PaginatedListState<Item>()
    private var activeTask: Task<Void, Never>?

    // MARK: - State

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

    var isPaused: Bool {
        pagination.isPaused
    }

    // MARK: - Task Control

    func run(_ operation: @escaping () async -> Void) {
        activeTask?.cancel()
        activeTask = Task(priority: .userInitiated) {
            await operation()
        }
    }

    func stopLoading() {
        activeTask?.cancel()
        activeTask = nil
        pagination.stopLoading()
    }

    // MARK: - Initial Load

    func loadIfNeeded(
        showSkeleton: Bool = true,
        setLoading: LoadingApplier,
        fetchPage: PageFetcher,
        applyPresentation: PresentationApplier,
        applyError: ErrorApplier
    ) async {
        if let intent = pagination.consumePausedIntent() {
            await resumePausedLoad(
                intent: intent,
                showSkeleton: showSkeleton,
                setLoading: setLoading,
                fetchPage: fetchPage,
                applyPresentation: applyPresentation,
                applyError: applyError
            )
            return
        }

        guard !pagination.hasLoaded else { return }

        await reload(
            showSkeleton: showSkeleton,
            setLoading: setLoading,
            fetchPage: fetchPage,
            applyPresentation: applyPresentation,
            applyError: applyError
        )
    }

    // MARK: - Reload

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
            guard pagination.failReload(generation: generation) else { return }
            applyError(FeatureLoadFailure(error), pagination.footerState)
        }
    }

    // MARK: - Load More

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

    // MARK: - Private Methods

    private func resumePausedLoad(
        intent: PaginatedPausedLoadIntent,
        showSkeleton: Bool,
        setLoading: LoadingApplier,
        fetchPage: PageFetcher,
        applyPresentation: PresentationApplier,
        applyError: ErrorApplier
    ) async {
        switch intent {
        case .initial:
            await reload(
                showSkeleton: showSkeleton && pagination.items.isEmpty,
                setLoading: setLoading,
                fetchPage: fetchPage,
                applyPresentation: applyPresentation,
                applyError: applyError
            )
        case .loadMore:
            await loadMore(
                fetchPage: fetchPage,
                setFooterState: setLoading,
                applyPresentation: applyPresentation
            )
        }
    }
}
