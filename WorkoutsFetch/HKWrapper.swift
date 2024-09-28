//
//  HKWrapper.swift
//  WorkoutsFetch
//
//  Created by Jaydeep Joshi on 28/09/24.
//

import Foundation
import HealthKit

final actor HKWrapper {
    private init() {}
    static let shared = HKWrapper()
    private let store = HKHealthStore()
    private var workoutsAnchor: HKQueryAnchor? = nil

    func requestAuthorization() async -> HKAuthorizationStatus {
        guard HKHealthStore.isHealthDataAvailable() else {
            return .sharingDenied
        }
        do {
            try await store.requestAuthorization(toShare: [], read: [HKQuantityType.workoutType()])
        } catch {
            fatalError("*** An unexpected error occurred while requesting" +
                       " authorization: \(error.localizedDescription) ***")
        }
        return store.authorizationStatus(for: HKQuantityType.workoutType())
    }

    // Predicate that can be used to query any samples over last 3 months.
    private func samplesPredicate() -> NSPredicate {
        let threeMonthsAgo = Calendar.current.date(byAdding: .month, value: -3, to: .now)
        return HKQuery.predicateForSamples(withStart: threeMonthsAgo, end: .now)
    }

    // Predicate for workouts in last 3 months.
    private func workoutSamplesPredicate() -> HKSamplePredicate<HKWorkout> {
        HKSamplePredicate.workout(samplesPredicate())
    }

    func readWorkouts() async  -> [HKWorkout]? {
        let query = HKSampleQueryDescriptor(predicates: [workoutSamplesPredicate()],
                                            sortDescriptors: [SortDescriptor(\.startDate, order: .reverse)])
        do {
            let result = try await query.result(for: store)
            return result
        } catch {
            return nil
        }
    }
}
