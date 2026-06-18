//
//  AnimeBroadcastReminderRepository.swift
//  WYJikanApp
//

import Combine
import Foundation
import SwiftData

protocol AnimeBroadcastReminderRepository: AnyObject {
    func connect(modelContext: ModelContext)

    var snapshotPublisher: AnyPublisher<AnimeBroadcastReminderSnapshotSet, Never> { get }

    func reload() throws

    func subscribe(snapshot: AnimeBroadcastReminderSnapshot) throws

    func unsubscribe(malId: Int) throws

    func removeAllSubscriptions() throws
}

final class SwiftDataAnimeBroadcastReminderRepository: AnimeBroadcastReminderRepository {
    var snapshotPublisher: AnyPublisher<AnimeBroadcastReminderSnapshotSet, Never> {
        snapshotSubject
            .removeDuplicates()
            .eraseToAnyPublisher()
    }

    private let snapshotSubject = CurrentValueSubject<AnimeBroadcastReminderSnapshotSet, Never>(
        AnimeBroadcastReminderSnapshotSet(subscriptions: [])
    )

    private var modelContext: ModelContext?

    init() {}

    func connect(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    func reload() throws {
        let modelContext = try requireModelContext()
        snapshotSubject.send(try makeSnapshotSet(from: modelContext))
    }

    func subscribe(snapshot: AnimeBroadcastReminderSnapshot) throws {
        let modelContext = try requireModelContext()

        if let existing = try fetchSubscription(malId: snapshot.malId, modelContext: modelContext) {
            existing.title = snapshot.title
            existing.broadcastDay = snapshot.broadcastDay
            existing.broadcastTime = snapshot.broadcastTime
            existing.broadcastTimezone = snapshot.broadcastTimezone
            existing.broadcastString = snapshot.broadcastString
        } else {
            modelContext.insert(
                AnimeBroadcastReminderSubscription(
                    malId: snapshot.malId,
                    title: snapshot.title,
                    broadcastDay: snapshot.broadcastDay,
                    broadcastTime: snapshot.broadcastTime,
                    broadcastTimezone: snapshot.broadcastTimezone,
                    broadcastString: snapshot.broadcastString,
                    subscribedAt: Date()
                )
            )
        }

        try modelContext.save()
        try publish(from: modelContext)
    }

    func unsubscribe(malId: Int) throws {
        let modelContext = try requireModelContext()

        guard let existing = try fetchSubscription(malId: malId, modelContext: modelContext) else {
            return
        }

        modelContext.delete(existing)

        do {
            try modelContext.save()
            try publish(from: modelContext)
        } catch {
            modelContext.rollback()
            throw error
        }
    }

    func removeAllSubscriptions() throws {
        let modelContext = try requireModelContext()
        let subscriptions = try modelContext.fetch(
            FetchDescriptor<AnimeBroadcastReminderSubscription>()
        )

        for subscription in subscriptions {
            modelContext.delete(subscription)
        }

        do {
            try modelContext.save()
            try publish(from: modelContext)
        } catch {
            modelContext.rollback()
            throw error
        }
    }

    private func requireModelContext() throws -> ModelContext {
        guard let modelContext else {
            throw RepositoryConnectionError.notConnected
        }
        return modelContext
    }

    private func publish(from modelContext: ModelContext) throws {
        snapshotSubject.send(try makeSnapshotSet(from: modelContext))
    }

    private func makeSnapshotSet(from modelContext: ModelContext) throws -> AnimeBroadcastReminderSnapshotSet {
        let subscriptions = try modelContext.fetch(
            FetchDescriptor<AnimeBroadcastReminderSubscription>(
                sortBy: [SortDescriptor(\.subscribedAt, order: .reverse)]
            )
        )
        return AnimeBroadcastReminderSnapshotSet(
            subscriptions: subscriptions.map(AnimeBroadcastReminderSnapshot.init(subscription:))
        )
    }

    private func fetchSubscription(
        malId: Int,
        modelContext: ModelContext
    ) throws -> AnimeBroadcastReminderSubscription? {
        var descriptor = FetchDescriptor<AnimeBroadcastReminderSubscription>(
            predicate: #Predicate<AnimeBroadcastReminderSubscription> {
                $0.malId == malId
            }
        )
        descriptor.fetchLimit = 1
        return try modelContext.fetch(descriptor).first
    }
}
