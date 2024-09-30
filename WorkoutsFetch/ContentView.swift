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
            if wrapper.workouts == nil {
                await wrapper.readWorkouts()
            }
        }
    }

    @ViewBuilder private var content: some View {
        if let workouts = wrapper.workouts {
            List {
                Section {
                    ForEach(workouts, id: \.uuid) { workout in
                        LabeledContent(workout.workoutActivityType.commonName,
                                       value: workout.startDate.formatted(date: .abbreviated, time: .shortened))
                    }
                } footer: {
                    Button("Load older workouts") {
                        Task {
                            await wrapper.readWorkouts()
                        }
                    }
                }
            }
        } else {
            ProgressView()
        }
    }
}

#Preview {
    ContentView()
}
