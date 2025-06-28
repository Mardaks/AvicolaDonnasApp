//
//  DailyStock.swift
//  AvicolaDonnasApp
//
//  Created by Victor Martinez on 26/06/25.
//

import Foundation
import FirebaseFirestore
import SwiftUI

// MARK: - 📦 Modelo Central: Stock Diario del Negocio
/// Representa el inventario completo de un día específico
/// Este es el "estado actual" que se actualiza con cada movimiento
struct DailyStock: Codable, Identifiable {
    @DocumentID var id: String?
    var date: String                    // Fecha en formato "yyyy-MM-dd"
    var rosadoPackages: PackageInventory // Inventario completo de huevo rosado
    var pardoPackages: PackageInventory  // Inventario completo de huevo pardo
    var totalPackages: Int              // Total calculado automáticamente
    var totalWeight: Double             // Peso total calculado automáticamente
    var isClosed: Bool                  // Indica si el día ya fue cerrado
    var isCurrentDay: Bool              // Marca el día activo actual
    var closedAt: Date?                 // Momento del cierre
    var createdAt: Date                 // Cuándo se creó este registro
    var updatedAt: Date                 // Última modificación
    
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
        
        // Inicializar fechas de auditoría
        let now = Date()
        self.createdAt = now
        self.updatedAt = now
        
        updateTotals() // Calcular totales iniciales
    }
    
    // MARK: - 🔄 Sistema de Actualización Automática
    /// Recalcula todos los totales y actualiza timestamp
    /// Se llama automáticamente después de cada cambio
    mutating func updateTotals() {
        totalPackages = rosadoPackages.getTotalPackages() + pardoPackages.getTotalPackages()
        totalWeight = rosadoPackages.getTotalWeight() + pardoPackages.getTotalWeight()
        
        // Actualizar fecha de modificación para auditoría
        updatedAt = Date()
    }
    
    // MARK: - ➕ Métodos de Gestión de Inventario
    /// Agrega nuevos paquetes al stock existente (suma al inventario actual)
    mutating func addLoad(_ packages: PackageInventory, type: EggType) {
        switch type {
        case .rosado:
            rosadoPackages.addPackages(packages)
        case .pardo:
            pardoPackages.addPackages(packages)
        }
        updateTotals()
    }
    
    /// Reemplaza completamente el inventario de un tipo (para ajustes)
    mutating func setPackagesForType(_ type: EggType, packages: PackageInventory) {
        switch type {
        case .rosado:
            rosadoPackages = packages
        case .pardo:
            pardoPackages = packages
        }
        updateTotals()
    }
    
    /// Obtiene el inventario actual de un tipo específico
    func getPackagesForType(_ type: EggType) -> PackageInventory {
        switch type {
        case .rosado:
            return rosadoPackages
        case .pardo:
            return pardoPackages
        }
    }
}

// MARK: - 🥚 Clasificación de Tipos de Huevo
/// Define los dos tipos de huevo que maneja el negocio
enum EggType: String, Codable, CaseIterable {
    case rosado = "rosado"
    case pardo = "pardo"
    
    /// Nombres completos para mostrar en la interfaz
    var displayName: String {
        switch self {
        case .rosado: return "Huevo Rosado"
        case .pardo: return "Huevo Pardo"
        }
    }
    
    /// Colores personalizados definidos en Assets
    var color: Color {
        switch self {
        case .rosado: return Color("rosado")
        case .pardo: return Color("pardo")
        }
    }
    
    /// Iconos para representar cada tipo visualmente
    var icon: String {
        switch self {
        case .rosado: return "circle.fill"
        case .pardo: return "circle.fill"
        }
    }
}
