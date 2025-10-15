//
//  HabitListViewModel.swift
//  HabitApp
//
//  Created by Aula03 on 15/10/25.
//

import Foundation
import SwiftUI

class HabitListViewModel: ObservableObject{
    
    @Published var habits: [Habit] = {
        Habit(title: "Hacer ejercicio", priority: High),
        Habit(title: "Estudiar")
    }
    
}
