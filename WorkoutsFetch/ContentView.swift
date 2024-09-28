//
//  ContentView.swift
//  WorkoutsFetch
//
//  Created by Jaydeep Joshi on 28/09/24.
//

import SwiftUI
import HealthKit

struct ContentView: View {
    @State private var workouts: [HKWorkout]?

    var body: some View {
        content.task {
            workouts = await HKWrapper.shared.readWorkouts()
        }
    }

    @ViewBuilder private var content: some View {
        if let workouts = workouts {
            List(workouts, id: \.uuid) { workout in
                LabeledContent(workout.workoutActivityType.commonName,
                               value: workout.startDate.formatted(date: .abbreviated, time: .shortened))
            }
        } else {
            ProgressView()
        }
    }
}

#Preview {
    ContentView()
}
