//
//  Habit.swift
//  HabitApp
//
//  Created by Aula03 on 15/10/25.
//
import Foundation

struct Habit: Identifiable{
    let id = UUID()
    var title: String
    var isCompleted: Bool = false
    var dueDate: Date?
    var priority: Priority?
}

enum Priority: String, Codable{
    case low, medium, high
}
