//
//  ContentView.swift
//  WorkoutsFetch
//
//  Created by Jaydeep Joshi on 28/09/24.
//

import SwiftUI
import HealthKit

struct ContentView: View {
    @Environment(HKWrapper.self) var wrapper

    var body: some View {
        content.task {
            let shouldUpdate = UserDefaults.standard.bool(forKey: "update_workouts")
            if wrapper.workouts == nil || shouldUpdate {
                await wrapper.readWorkouts()
            }
        }
    }

    @ViewBuilder private var content: some View {
        if let workouts = wrapper.workouts {
            List {
                Section("Workouts") {
                    ForEach(workouts, id: \.uuid) { workout in
                        workoutRow(workout)
                    }
                }
            }
        } else {
            ProgressView()
        }
    }

    @ViewBuilder private func workoutRow(_ workout: HKWorkout) -> some View {
        let date = workout.startDate.formatted(date: .abbreviated, time: .shortened)
        LabeledContent(workout.workoutActivityType.commonName,
                       value: date)
    }
}

#Preview {
    ContentView()
}
