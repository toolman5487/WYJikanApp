//
//  HomeTodayAnimeScheduleListView.swift
//  WYJikanApp
//
//  Created by Codex on 2026/5/4.
//

import SwiftUI

struct HomeTodayAnimeScheduleListView: View {
    @StateObject private var viewModel: HomeTodayAnimeScheduleListViewModel
    @EnvironmentObject private var router: MainHomeRouter

    init(viewModel: HomeTodayAnimeScheduleListViewModel = HomeTodayAnimeScheduleListViewModel()) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 22, pinnedViews: [.sectionHeaders]) {
                headerView
                stateContentView
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
            .padding(.bottom, 28)
        }
        .safeAreaInset(edge: .top, spacing: 0) {
            stickyDayFilterView
        }
        .navigationTitle("播出時間表")
        .navigationBarTitleDisplayMode(.inline)
        .background(Color(.systemBackground))
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    Task { await viewModel.reload() }
                } label: {
                    Image(systemName: "arrow.trianglehead.counterclockwise")
                        .font(.body.weight(.bold))
                        .foregroundStyle(ThemeColor.sakura)
                        .frame(width: 44, height: 44)
                }
            }
        }
        .task {
            await viewModel.loadIfNeeded()
        }
        .animation(.easeInOut(duration: 0.22), value: viewModel.selectedDay)
    }

    private var stickyDayFilterView: some View {
        VStack(spacing: 10) {
            dayFilterView
                .padding(.horizontal, 16)

            Divider()
        }
        .padding(.top, 8)
        .background(.ultraThinMaterial)
    }

    private var headerView: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(viewModel.headerTitle)
                .font(.system(size: 32, weight: .bold, design: .rounded))
                .foregroundStyle(ThemeColor.sakura)

            Text(viewModel.headerSubtitle)
                .font(.subheadline)
                .foregroundStyle(ThemeColor.textSecondary)
                .fixedSize(horizontal: false, vertical: true)

            Text(viewModel.loadedCountText)
                .font(.caption.weight(.semibold))
                .foregroundStyle(ThemeColor.textPrimary)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(Color(.systemBackground).opacity(0.74))
                .clipShape(Capsule())
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background(headerBackground)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
    }

    private var headerBackground: some View {
        LinearGradient(
            colors: [
                ThemeColor.sakura.opacity(0.22),
                ThemeColor.sakura.opacity(0.08),
                Color(.secondarySystemBackground)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    private var dayFilterView: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(HomeScheduleDay.allCases) { day in
                    Button {
                        withAnimation(.spring(response: 0.32, dampingFraction: 0.86)) {
                            viewModel.selectedDay = day
                        }
                    } label: {
                        Text(day.title)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(viewModel.selectedDay == day ? ThemeColor.textPrimary : ThemeColor.textSecondary)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 10)
                            .background(dayFilterBackground(isSelected: viewModel.selectedDay == day))
                            .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.vertical, 2)
        }
    }

    private func dayFilterBackground(isSelected: Bool) -> some ShapeStyle {
        isSelected ? AnyShapeStyle(ThemeColor.sakura) : AnyShapeStyle(Color(.secondarySystemBackground))
    }

    @ViewBuilder
    private var stateContentView: some View {
        switch viewModel.screenState {
        case .loading:
            loadingView
                .transition(.opacity.combined(with: .move(edge: .bottom)))
        case .empty:
            emptyView
                .transition(.opacity.combined(with: .move(edge: .bottom)))
        case .error(let message):
            errorView(message: message)
                .transition(.opacity.combined(with: .move(edge: .bottom)))
        case .content(let sections):
            timelineListView(sections: sections)
                .transition(.opacity.combined(with: .move(edge: .bottom)))
        }
    }

    private func timelineListView(sections: [HomeTodayAnimeTimeSection]) -> some View {
        LazyVStack(alignment: .leading, spacing: 18, pinnedViews: [.sectionHeaders]) {
            ForEach(sections) { section in
                Section {
                    VStack(spacing: 12) {
                        ForEach(section.items) { item in
                            timelineRow(item)
                                .onAppear {
                                    Task {
                                        await viewModel.loadMoreIfNeeded(currentItem: item)
                                    }
                                }
                        }
                    }
                } header: {
                    timeSectionHeader(section)
                }
            }

            loadMoreFooterView
        }
    }

    private func timeSectionHeader(_ section: HomeTodayAnimeTimeSection) -> some View {
        HStack {
            Text(section.title)
                .font(.headline.weight(.bold))
                .foregroundStyle(ThemeColor.sakura)

            Text("\(section.items.count) 部")
                .font(.caption.weight(.semibold))
                .foregroundStyle(ThemeColor.textSecondary)

            Spacer()
        }
        .padding(.vertical, 8)
        .background(Color(.systemBackground))
    }

    private func timelineRow(_ item: HomeTodayAnimeTimelineItem) -> some View {
        Button {
            router.push(.animeDetail(malId: item.id))
        } label: {
            HStack(alignment: .top, spacing: 12) {
                posterView(item)

                VStack(alignment: .leading, spacing: 7) {
                    Text(item.title)
                        .font(.headline)
                        .foregroundStyle(ThemeColor.textPrimary)
                        .lineLimit(2)

                    Text(item.broadcastText)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(ThemeColor.sakura)
                        .lineLimit(1)

                    metadataView(item)

                    if let studio = item.studioText {
                        Text(studio)
                            .font(.caption)
                            .foregroundStyle(ThemeColor.textSecondary)
                            .lineLimit(1)
                    }

                    if let synopsis = item.synopsisPreview {
                        Text(synopsis)
                            .font(.caption)
                            .foregroundStyle(ThemeColor.textSecondary)
                            .lineLimit(2)
                    }
                }

                Spacer(minLength: 0)
            }
            .padding(10)
            .background(Color(.secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(alignment: .topTrailing) {
                MyListCollectionStatusBadgeView(malId: item.id, mediaKind: .anime)
                    .padding(8)
            }
        }
        .buttonStyle(.plain)
    }

    private func posterView(_ item: HomeTodayAnimeTimelineItem) -> some View {
        Group {
            if let imageURL = item.imageURL {
                RemotePosterImageView(url: imageURL)
            } else {
                Color(.secondarySystemFill)
                    .overlay {
                        Image(systemName: "photo")
                            .font(.title3)
                            .foregroundStyle(.secondary)
                    }
            }
        }
        .frame(width: 76, height: 112)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private func metadataView(_ item: HomeTodayAnimeTimelineItem) -> some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: 6) {
                metadataChips(item)
            }

            HStack(spacing: 6) {
                if let type = item.typeText {
                    metadataChip(type)
                }
                if let score = item.scoreText {
                    metadataChip("★ \(score)")
                }
            }
        }
    }

    @ViewBuilder
    private func metadataChips(_ item: HomeTodayAnimeTimelineItem) -> some View {
        if let type = item.typeText {
            metadataChip(type)
        }
        if let score = item.scoreText {
            metadataChip("★ \(score)")
        }
        if let episode = item.episodeText {
            metadataChip(episode)
        }
        if let status = item.statusText {
            metadataChip(status)
        }
    }

    private func metadataChip(_ text: String) -> some View {
        Text(text)
            .font(.caption2.weight(.semibold))
            .foregroundStyle(ThemeColor.textPrimary)
            .lineLimit(1)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(ThemeColor.sakura.opacity(0.55))
            .clipShape(Capsule())
    }

    private var loadingView: some View {
        VStack(alignment: .leading, spacing: 16) {
            ForEach(0..<3, id: \.self) { _ in
                VStack(alignment: .leading, spacing: 10) {
                    SkeletonBar(width: 72, height: 22, cornerRadius: 8)
                    ForEach(0..<2, id: \.self) { _ in
                        HStack(spacing: 12) {
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(Color(.systemGray5))
                                .frame(width: 76, height: 112)
                            VStack(alignment: .leading, spacing: 10) {
                                SkeletonBar(width: 160, height: 18, cornerRadius: 8)
                                SkeletonBar(width: 120, height: 14, cornerRadius: 8)
                                SkeletonBar(width: 190, height: 12, cornerRadius: 8)
                            }
                            Spacer()
                        }
                        .padding(10)
                        .background(Color(.secondarySystemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    }
                }
            }
        }
    }

    private var emptyView: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("這天目前沒有可顯示的 TV 動畫")
                .font(.title3.weight(.bold))
                .foregroundStyle(ThemeColor.textPrimary)

            Text("可以切換其他星期，或稍後再回來看看。")
                .font(.body)
                .foregroundStyle(ThemeColor.textSecondary)
        }
        .frame(maxWidth: .infinity, minHeight: 220, alignment: .center)
        .padding(24)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    private func errorView(message: String) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("播出表暫時讀不到")
                .font(.title3.weight(.bold))
                .foregroundStyle(ThemeColor.textPrimary)

            Text(message)
                .font(.body)
                .foregroundStyle(ThemeColor.textSecondary)

            Button("重新載入") {
                Task { await viewModel.reload() }
            }
            .buttonStyle(.borderedProminent)
            .tint(ThemeColor.sakura)
        }
        .frame(maxWidth: .infinity, minHeight: 220, alignment: .center)
        .padding(24)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    @ViewBuilder
    private var loadMoreFooterView: some View {
        switch viewModel.loadMoreState {
        case .hidden:
            EmptyView()
        case .available:
            Button("載入更多") {
                Task { await viewModel.loadMore() }
            }
            .buttonStyle(.borderedProminent)
            .tint(ThemeColor.sakura)
            .frame(maxWidth: .infinity, alignment: .center)
        case .loading:
            ProgressView()
                .frame(maxWidth: .infinity, minHeight: 44)
        case .error(let message):
            VStack(alignment: .leading, spacing: 10) {
                Text(message)
                    .font(.footnote)
                    .foregroundStyle(ThemeColor.textSecondary)

                Button("重試載入更多") {
                    Task { await viewModel.retryLoadMore() }
                }
                .buttonStyle(.borderedProminent)
                .tint(ThemeColor.sakura)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

#Preview {
    NavigationStack {
        HomeTodayAnimeScheduleListView()
            .environmentObject(MainHomeRouter())
    }
}
