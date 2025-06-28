//
//  CargoEntry.swift
//  AvicolaDonnasApp
//
//  Created by Victor Martinez on 26/06/25.
//

import Foundation
import FirebaseFirestore

// MARK: - ✅ Modelo Principal: Registro de Movimientos de Carga
/// Representa cada movimiento de huevos en el sistema (entradas, salidas, ajustes)
/// Esta es la base del historial de todas las operaciones
struct CargoEntry: Codable, Identifiable {
    @DocumentID var id: String?
    var date: String                    // Fecha del movimiento
    var rosadoPackages: PackageInventory // Paquetes de huevo rosado
    var pardoPackages: PackageInventory  // Paquetes de huevo pardo
    var type: LoadType                   // Tipo de operación (carga/salida/ajuste)
    var supplier: String                 // Nombre del proveedor
    var notes: String?                   // Notas adicionales opcionales
    var timestamp: Date                  // Momento exacto del registro
    
    init(id: String? = nil,
         date: String,
         rosadoPackages: PackageInventory = PackageInventory(),
         pardoPackages: PackageInventory = PackageInventory(),
         type: LoadType,
         supplier: String,
         notes: String? = nil,
         timestamp: Date = Date()) {
        self.id = id
        self.date = date
        self.rosadoPackages = rosadoPackages
        self.pardoPackages = pardoPackages
        self.type = type
        self.supplier = supplier
        self.notes = notes
        self.timestamp = timestamp
    }
    
    // MARK: - 🔢 Propiedades Calculadas para Resúmenes
    /// Calcula automáticamente el total de paquetes de ambos tipos
    var totalPackages: Int {
        rosadoPackages.getTotalPackages() + pardoPackages.getTotalPackages()
    }
    
    /// Calcula el peso total combinado de todo el movimiento
    var totalWeight: Double {
        rosadoPackages.getTotalWeight() + pardoPackages.getTotalWeight()
    }
    
    // MARK: - 📅 Formateo de Fechas para UI
    /// Convierte timestamp a formato legible: "25/06/2025"
    var displayDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd/MM/yyyy"
        formatter.locale = Locale(identifier: "es_ES")
        return formatter.string(from: timestamp)
    }
    
    /// Extrae solo la hora: "14:30"
    var displayTime: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: timestamp)
    }
    
    // MARK: - 📊 Métodos de Presentación Inteligente
    /// Genera un resumen automático del contenido para mostrar en listas
    /// Ejemplo: "Rosado: 50 • Pardo: 30" o "Solo Rosado: 45 paquetes"
    var eggTypeSummary: String {
        let rosadoCount = rosadoPackages.getTotalPackages()
        let pardoCount = pardoPackages.getTotalPackages()
        
        if rosadoCount > 0 && pardoCount > 0 {
            return "Rosado: \(rosadoCount) • Pardo: \(pardoCount)"
        } else if rosadoCount > 0 {
            return "Rosado: \(rosadoCount) paquetes"
        } else if pardoCount > 0 {
            return "Pardo: \(pardoCount) paquetes"
        } else {
            return "Sin paquetes"
        }
    }
    
    /// Verifica si este movimiento incluye un tipo específico de huevo
    func hasEggType(_ eggType: EggType) -> Bool {
        switch eggType {
        case .rosado:
            return rosadoPackages.getTotalPackages() > 0
        case .pardo:
            return pardoPackages.getTotalPackages() > 0
        }
    }
}

// MARK: - 🏷️ Tipos de Operaciones del Negocio
/// Define todas las operaciones posibles en el sistema
enum LoadType: String, Codable, CaseIterable {
    case incoming = "carga"      // Llegada de huevos de proveedores
    case outgoing = "salida"     // Venta o salida de huevos
    case adjustment = "ajuste"   // Correcciones manuales
    case dayClose = "cierre"     // Cierre automático del día
    
    /// Nombres amigables para mostrar al usuario
    var displayName: String {
        switch self {
        case .incoming: return "Carga Entrante"
        case .outgoing: return "Salida"
        case .adjustment: return "Ajuste"
        case .dayClose: return "Cierre de Día"
        }
    }
    
    /// Iconos SF Symbols para cada tipo de operación
    var icon: String {
        switch self {
        case .incoming: return "plus.circle.fill"
        case .outgoing: return "minus.circle.fill"
        case .adjustment: return "pencil.circle.fill"
        case .dayClose: return "checkmark.circle.fill"
        }
    }
}
