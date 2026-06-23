//
//  MangaReadingProgressEditorView.swift
//  WYJikanApp
//
//  Created by Willy Hsu on 2026/6/11.
//

import SwiftUI

struct MangaReadingProgressEditorView: View {

    // MARK: - Properties

    @Environment(\.dismiss) private var dismiss
    @State private var draft: MangaReadingProgressEditorDraft
    @State private var chapterText: String
    @FocusState private var isChapterFieldFocused: Bool

    let onSave: (MangaReadingProgressEditorDraft) -> Void

    // MARK: - Lifecycle

    init(
        draft: MangaReadingProgressEditorDraft,
        onSave: @escaping (MangaReadingProgressEditorDraft) -> Void
    ) {
        _draft = State(initialValue: draft)
        _chapterText = State(initialValue: draft.currentChapter > 0 ? "\(draft.currentChapter)" : "")
        self.onSave = onSave
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            Form {
                Section("話數") {
                    TextField("0", text: $chapterText)
                        .keyboardType(.numberPad)
                        .focused($isChapterFieldFocused)
                        .font(.title2.weight(.semibold))
                        .monospacedDigit()

                    if let totalChapters = draft.totalChapters {
                        Text("共 \(totalChapters) 話")
                            .font(.footnote)
                            .foregroundStyle(ThemeColor.textSecondary)
                    }
                }

                Section("狀態") {
                    Picker("閱讀狀態", selection: $draft.status) {
                        ForEach(MangaReadingStatus.allCases) { status in
                            Label(status.title, systemImage: status.systemImageName)
                                .tag(status)
                        }
                    }
                    .pickerStyle(.inline)
                }
            }
            .navigationTitle("閱讀進度")
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
                isChapterFieldFocused = true
            }
            .onChange(of: draft.status) { _, newStatus in
                guard newStatus == .completed, let totalChapters = draft.totalChapters else {
                    return
                }
                chapterText = "\(totalChapters)"
            }
        }
    }

    // MARK: - Private Methods

    private func save() {
        draft.currentChapter = normalizedChapter
        draft.status = normalizedStatus(for: draft.currentChapter)
        onSave(draft)
        dismiss()
    }

    private var normalizedChapter: Int {
        let parsedChapter = Int(chapterText) ?? 0
        let positiveChapter = max(parsedChapter, 0)
        guard let totalChapters = draft.totalChapters else { return positiveChapter }
        return min(positiveChapter, totalChapters)
    }

    private func normalizedStatus(for currentChapter: Int) -> MangaReadingStatus {
        switch draft.status {
        case .onHold:
            return draft.status
        case .dropped:
            return draft.status
        case .completed:
            return draft.status
        case .planned:
            guard currentChapter > 0 else { return .planned }
            if let totalChapters = draft.totalChapters, currentChapter >= totalChapters {
                return .completed
            }
            return .reading
        case .reading:
            guard currentChapter > 0 else { return .planned }
            if let totalChapters = draft.totalChapters, currentChapter >= totalChapters {
                return .completed
            }
            return .reading
        }
    }
}
