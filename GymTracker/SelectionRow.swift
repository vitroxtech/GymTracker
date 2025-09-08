//
//  GenericSelectionRow.swift
//  GymTracker
//
//  Created by miguel gomez on 18/5/25.
//
import SwiftUI

struct SelectionRow<Content: View>: View {
    let isSelected: Bool
    let showCircle: Bool
    let action: () -> Void
    let content: () -> Content

    var body: some View {
        Button(action: action) {
            HStack {
                content()
                Spacer()
                if isSelected {
                    Image(systemName: showCircle ? "checkmark.circle.fill" : "checkmark")
                        .foregroundColor(.accentColor)
                } else if showCircle {
                    Image(systemName: "circle")
                        .foregroundColor(.gray)
                }
            }
            .padding(.vertical, 4)
        }
    }
}

struct MultipleWorkoutSelectionRow: View {
    var title: String
    var isSelected: Bool
    var action: () -> Void

    var body: some View {
        SelectionRow(isSelected: isSelected, showCircle: false, action: action) {
            Text(title)
        }
    }
}

struct MultipleSelectionRow: View {
    var exercise: Exercise
    var isSelected: Bool
    var onTap: () -> Void

    var body: some View {
        SelectionRow(isSelected: isSelected, showCircle: false, action: onTap) {
            VStack(alignment: .leading) {
                Text(exercise.name ?? "Unnamed Exercise")
                    .font(.headline)
                Text(exercise.categoryEnum.id)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
    }
}
