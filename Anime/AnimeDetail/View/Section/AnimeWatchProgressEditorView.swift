//
//  AnimeWatchProgressEditorView.swift
//  WYJikanApp
//

import SwiftUI

struct AnimeWatchProgressEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var draft: AnimeWatchProgressEditorDraft
    @State private var episodeText: String
    @FocusState private var isEpisodeFieldFocused: Bool

    let onSave: (AnimeWatchProgressEditorDraft) -> Void

    init(
        draft: AnimeWatchProgressEditorDraft,
        onSave: @escaping (AnimeWatchProgressEditorDraft) -> Void
    ) {
        _draft = State(initialValue: draft)
        _episodeText = State(initialValue: draft.currentEpisode > 0 ? "\(draft.currentEpisode)" : "")
        self.onSave = onSave
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("集數") {
                    TextField("0", text: $episodeText)
                        .keyboardType(.numberPad)
                        .focused($isEpisodeFieldFocused)
                        .font(.title2.weight(.semibold))
                        .monospacedDigit()

                    if let totalEpisodes = draft.totalEpisodes {
                        Text("共 \(totalEpisodes) 集")
                            .font(.footnote)
                            .foregroundStyle(ThemeColor.textSecondary)
                    }
                }

                Section("狀態") {
                    Picker("觀看狀態", selection: $draft.status) {
                        ForEach(AnimeWatchStatus.allCases) { status in
                            Label(status.title, systemImage: status.systemImageName)
                                .tag(status)
                        }
                    }
                    .pickerStyle(.inline)
                }
            }
            .navigationTitle("觀看進度")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("儲存") {
                        save()
                    }
                }
            }
            .task {
                isEpisodeFieldFocused = true
            }
            .onChange(of: draft.status) { _, newStatus in
                guard newStatus == .completed, let totalEpisodes = draft.totalEpisodes else {
                    return
                }
                episodeText = "\(totalEpisodes)"
            }
        }
    }

    // MARK: - Private Methods

    private func save() {
        draft.currentEpisode = normalizedEpisode
        draft.status = normalizedStatus(for: draft.currentEpisode)
        onSave(draft)
        dismiss()
    }

    private var normalizedEpisode: Int {
        let parsedEpisode = Int(episodeText) ?? 0
        let positiveEpisode = max(parsedEpisode, 0)
        guard let totalEpisodes = draft.totalEpisodes else { return positiveEpisode }
        return min(positiveEpisode, totalEpisodes)
    }

    private func normalizedStatus(for currentEpisode: Int) -> AnimeWatchStatus {
        switch draft.status {
        case .onHold:
            return draft.status
        case .dropped:
            return draft.status
        case .completed:
            return draft.status
        case .planned:
            guard currentEpisode > 0 else { return .planned }
            if let totalEpisodes = draft.totalEpisodes, currentEpisode >= totalEpisodes {
                return .completed
            }
            return .watching
        case .watching:
            guard currentEpisode > 0 else { return .planned }
            if let totalEpisodes = draft.totalEpisodes, currentEpisode >= totalEpisodes {
                return .completed
            }
            return .watching
        }
    }
}
