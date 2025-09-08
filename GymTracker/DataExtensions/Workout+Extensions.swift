//
//  Workout+CoreDataClass.swift
//  GymTracker
//
//  Created by miguel gomez on 17/5/25.
//
import Foundation
import CoreData

extension Workout {
    var exercisesArray: [Exercise] {
        let set = exercises as? Set<Exercise> ?? []
        return set.sorted { ($0.name ?? "") < ($1.name ?? "") }
    }
}
