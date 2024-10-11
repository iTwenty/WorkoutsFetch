//
//  HKWrapper.swift
//  WorkoutsFetch
//
//  Created by Jaydeep Joshi on 28/09/24.
//

import Foundation
import HealthKit
import Observation

@Observable
final class HKWrapper {
    @ObservationIgnored private let store = HKHealthStore()
    @ObservationIgnored private var workoutsAnchor: HKQueryAnchor?
    @ObservationIgnored private var workoutUpdatesTask: Task<Void, Never>?
    var workouts: [HKWorkout]?

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

    func readWorkouts() async {
        let query = HKAnchoredObjectQueryDescriptor(predicates: [workoutSamplesPredicate()],
                                                    anchor: workoutsAnchor)
        do {
            let result = try await query.result(for: store)
            if result.addedSamples.isEmpty {
                return
            }
            workoutsAnchor = result.newAnchor
            workouts = result.addedSamples.sorted { lhs, rhs in
                lhs.startDate > rhs.startDate
            }
            startWorkoutUpdatesTask()
        } catch {
            print(error.localizedDescription)
        }
    }

    func startWorkoutUpdatesTask() {
        guard let anchor = workoutsAnchor else {
            return
        }
        workoutUpdatesTask?.cancel()
        let query = HKAnchoredObjectQueryDescriptor(predicates:[workoutSamplesPredicate()],
                                                    anchor: anchor)
        let results = query.results(for: store)
        workoutUpdatesTask = Task {
            do {
                for try await result in results {
                    try Task.checkCancellation()
                    let addedCount = result.addedSamples.count
                    let deletedCount = result.deletedObjects.count
                    if addedCount == 0, deletedCount == 0 {
                        continue
                    }
                    var updatedWorkouts = workouts
                    updatedWorkouts?.append(contentsOf: result.addedSamples)
                    updatedWorkouts?.removeAll { workout in
                        result.deletedObjects.contains { $0.uuid == workout.uuid }
                    }
                    updatedWorkouts?.sort { lhs, rhs in
                        return lhs.startDate > rhs.startDate
                    }
                    await MainActor.run { [updatedWorkouts] in
                        workouts = updatedWorkouts
                    }
                }
            } catch {
                print(error.localizedDescription)
            }
        }
    }

    func enableBackgroundWorkoutUpdates() async {
        let workoutType = HKObjectType.workoutType()
        do {
            try await store.enableBackgroundDelivery(for: workoutType, frequency: .immediate)
        } catch {
            print(error.localizedDescription)
        }

        let backgroundQuery = HKObserverQuery(sampleType: workoutType,
                                              predicate: samplesPredicate()) { query, completion, optError in
            if let error = optError {
                print(error.localizedDescription)
                return
            }

            UserDefaults.standard.setValue(true, forKey: "update_workouts")
            completion()
        }

        store.execute(backgroundQuery)
    }
}
