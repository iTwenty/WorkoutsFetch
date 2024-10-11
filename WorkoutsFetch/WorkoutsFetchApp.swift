//
//  WorkoutsFetchApp.swift
//  WorkoutsFetch
//
//  Created by Jaydeep Joshi on 28/09/24.
//

import SwiftUI
import HealthKit

@main
struct WorkoutsFetchApp: App {
    @State private var authStatus = HKAuthorizationStatus.notDetermined
    @State private var wrapper = HKWrapper()

    var body: some Scene {
        WindowGroup {
            content
                .task {
                    if authStatus == .notDetermined {
                        authStatus = await wrapper.requestAuthorization()
                    }
                }
                .onChange(of: authStatus) { _, new in
                    if authStatus == .sharingAuthorized {
                        Task {
                            await wrapper.enableBackgroundWorkoutUpdates()
                        }
                    }
                }
                .environment(wrapper)
        }
    }

    @ViewBuilder private var content: some View {
        switch authStatus {
        case .notDetermined: ProgressView()
        default: ContentView()
        }
    }
}
