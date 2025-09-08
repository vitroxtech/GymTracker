//
//  ExcerciseCategory.swift
//  GymTracker
//
//  Created by miguel gomez on 17/5/25.
//

import Foundation

enum ExerciseCategory: String, CaseIterable, Identifiable {
    case legs, biceps, triceps, abs, back, shoulders, chest

    var id: String { self.rawValue }

    var displayName: String {
        rawValue.capitalized
    }
}
