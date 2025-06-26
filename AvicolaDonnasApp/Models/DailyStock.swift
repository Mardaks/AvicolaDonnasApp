//
//  DailyStock.swift
//  AvicolaDonnasApp
//
//  Created by Victor Martinez on 26/06/25.
//

import Foundation
import FirebaseFirestore
import SwiftUI

// MARK: - Modelo principal para el stock diario
struct DailyStock: Codable, Identifiable {
    @DocumentID var id: String?
    let date: String
    var rosadoPackages: PackageInventory
    var pardoPackages: PackageInventory
    var totalPackages: Int
    var totalWeight: Double
    var isClosed: Bool
    var isCurrentDay: Bool
    var closedAt: Date?
    var createdAt: Date
    var updatedAt: Date
    
    init(id: String? = nil,
         date: String,
         rosadoPackages: PackageInventory = PackageInventory(),
         pardoPackages: PackageInventory = PackageInventory()) {
        self.id = id
        self.date = date
        self.rosadoPackages = rosadoPackages
        self.pardoPackages = pardoPackages
        self.totalPackages = 0
        self.totalWeight = 0.0
        self.isClosed = false
        self.isCurrentDay = false
        self.closedAt = nil
        
        // Inicializar fechas
        let now = Date()
        self.createdAt = now
        self.updatedAt = now
        
        updateTotals()
    }
    
    mutating func updateTotals() {
        totalPackages = rosadoPackages.getTotalPackages() + pardoPackages.getTotalPackages()
        totalWeight = rosadoPackages.getTotalWeight() + pardoPackages.getTotalWeight()
        
        // Actualizar fecha de modificación
        updatedAt = Date()
    }
    
    mutating func addLoad(_ packages: PackageInventory, type: EggType) {
        switch type {
        case .rosado:
            rosadoPackages.addPackages(packages)
        case .pardo:
            pardoPackages.addPackages(packages)
        }
        updateTotals()
    }
    
    mutating func setPackagesForType(_ type: EggType, packages: PackageInventory) {
        switch type {
        case .rosado:
            rosadoPackages = packages
        case .pardo:
            pardoPackages = packages
        }
        updateTotals()
    }
    
    func getPackagesForType(_ type: EggType) -> PackageInventory {
        switch type {
        case .rosado:
            return rosadoPackages
        case .pardo:
            return pardoPackages
        }
    }
}

// MARK: - Enum para tipos de huevo
enum EggType: String, Codable, CaseIterable {
    case rosado = "rosado"
    case pardo = "pardo"
    
    var displayName: String {
        switch self {
        case .rosado: return "Huevo Rosado"
        case .pardo: return "Huevo Pardo"
        }
    }
    
    var color: Color {
        switch self {
        case .rosado: return Color("rosado")
        case .pardo: return Color("pardo")
        }
    }
    
    var icon: String {
        switch self {
        case .rosado: return "circle.fill"
        case .pardo: return "circle.fill"
        }
    }
}
