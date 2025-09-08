//
//  Excercise+Extensions.swift
//  GymTracker
//
//  Created by miguel gomez on 17/5/25.
//

import Foundation

extension Exercise {
    var categoryEnum: ExerciseCategory {
        get {
            ExerciseCategory(rawValue: category ?? "") ?? .chest // default fallback
        }
        set {
            category = newValue.rawValue
        }
    }
    
    var totalVolume: Double {
           guard let sets = self.setEntries as? Set<SetEntry> else { return 0 }
           return sets.reduce(0) { $0 + ($1.weight * Double($1.reps)) }
       }
}
