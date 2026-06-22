//
//  ProducerDetailSectionViews.swift
//  WYJikanApp
//

import SwiftUI

// MARK: - Header

struct ProducerDetailHeaderSectionView: View {
    let viewModel: ProducerDetailViewModel
    let producer: ProducerDetailDTO

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top, spacing: 16) {
                logoView

                VStack(alignment: .leading, spacing: 8) {
                    Text("動畫製作公司")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(ThemeColor.sakura)
                        .textCase(.uppercase)

                    DetailCopyableText(
                        text: viewModel.displayName(for: producer),
                        style: .primary
                    )

                    if let japaneseName = viewModel.japaneseName(for: producer) {
                        DetailCopyableText(
                            text: japaneseName,
                            style: .secondary
                        )
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            HStack(spacing: 12) {
                ProducerDetailMetricView(
                    title: "收錄動畫",
                    value: viewModel.animeCountText(for: producer),
                    systemImage: "play.rectangle.fill"
                )
                ProducerDetailMetricView(
                    title: "MAL 收藏",
                    value: viewModel.favoritesText(for: producer),
                    systemImage: "heart.fill"
                )
            }
        }
    }

    @ViewBuilder
    private var logoView: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color(.secondarySystemBackground))

            if let url = viewModel.logoURL(for: producer) {
                RemotePosterImageView(
                    url: url,
                    contentMode: .fit,
                    fixedSize: CGSize(width: 108, height: 108)
                )
                .padding(12)
            } else {
                Image(systemName: "building.2.crop.circle")
                    .font(.system(size: 40, weight: .medium))
                    .foregroundStyle(ThemeColor.textTertiary)
            }
        }
        .frame(width: 132, height: 132)
    }
}

// MARK: - Info

struct ProducerDetailInfoSectionView: View {
    let viewModel: ProducerDetailViewModel
    let producer: ProducerDetailDTO

    var body: some View {
        AnimeDetailSectionCard("公司資訊") {
            VStack(alignment: .leading, spacing: 12) {
                AnimeDetailInfoRow(
                    title: "名稱",
                    value: viewModel.displayName(for: producer),
                    isValueCopyable: true
                )

                if let japaneseName = viewModel.japaneseName(for: producer) {
                    AnimeDetailInfoRow(
                        title: "日文名",
                        value: japaneseName,
                        isValueCopyable: true
                    )
                }

                AnimeDetailInfoRow(
                    title: "成立",
                    value: viewModel.establishedText(for: producer)
                )

                AnimeDetailInfoRow(
                    title: "作品數",
                    value: viewModel.animeCountText(for: producer)
                )

                AnimeDetailInfoRow(
                    title: "收藏",
                    value: viewModel.favoritesText(for: producer)
                )

                if let alternateNames = viewModel.alternateNamesText(for: producer) {
                    AnimeDetailInfoRow(
                        title: "別名",
                        value: alternateNames,
                        isValueCopyable: true
                    )
                }
            }
        }
    }
}

// MARK: - About

struct ProducerDetailAboutSectionView: View {
    let viewModel: ProducerDetailViewModel
    let producer: ProducerDetailDTO

    var body: some View {
        if let about = viewModel.aboutText(for: producer) {
            AnimeDetailSectionCard("公司簡介") {
                Text(about)
                    .font(.body)
                    .foregroundStyle(ThemeColor.textPrimary.opacity(0.9))
                    .lineSpacing(4)
                    .textSelection(.enabled)
            }
        }
    }
}

// MARK: - Metric

private struct ProducerDetailMetricView: View {
    let title: String
    let value: String
    let systemImage: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(title, systemImage: systemImage)
                .font(.caption.weight(.semibold))
                .foregroundStyle(ThemeColor.textSecondary)

            Text(value)
                .font(.title3.weight(.bold))
                .foregroundStyle(ThemeColor.textPrimary)
                .contentTransition(.numericText())
        }
        .frame(maxWidth: .infinity, minHeight: 80, alignment: .leading)
        .padding(16)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

// MARK: - Error

struct ProducerDetailErrorView: View {
    let failure: FeatureLoadFailure
    let onRetry: () -> Void

    var body: some View {
        ErrorMessageRetryCardView(
            state: ErrorMessageView.State(failure: failure),
            title: "無法載入製作公司",
            retryTitle: "再試一次",
            onRetry: onRetry
        )
    }
}

// MARK: - Skeleton

struct ProducerDetailHeaderSkeletonView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top, spacing: 16) {
                SkeletonBar(width: 132, height: 132, cornerRadius: 20)

                VStack(alignment: .leading, spacing: 12) {
                    SkeletonBar(width: 84, height: 12, cornerRadius: 4)
                    SkeletonBar(width: 180, height: 24, cornerRadius: 6)
                    SkeletonBar(width: 132, height: 16, cornerRadius: 4)
                }
            }

            HStack(spacing: 12) {
                SkeletonBar(width: nil, height: 80, cornerRadius: 16)
                SkeletonBar(width: nil, height: 80, cornerRadius: 16)
            }
        }
    }
}

struct ProducerDetailInfoSkeletonView: View {
    var body: some View {
        SectionCardSkeleton(rowCount: 5)
    }
}

struct ProducerDetailAboutSkeletonView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            SkeletonBar(width: 96, height: 24, cornerRadius: 8)
            SkeletonBar(width: nil, height: 16, cornerRadius: 4)
            SkeletonBar(width: nil, height: 16, cornerRadius: 4)
            SkeletonBar(width: 220, height: 16, cornerRadius: 4)
        }
    }
}
