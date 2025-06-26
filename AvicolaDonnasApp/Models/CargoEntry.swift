//
//  CargoEntry.swift
//  AvicolaDonnasApp
//
//  Created by Victor Martinez on 26/06/25.
//

import Foundation
import FirebaseFirestore

// MARK: - Modelo para cargas registradas (historial de movimientos)
struct CargoEntry: Codable, Identifiable {
    @DocumentID var id: String?
    let date: String
    let rosadoPackages: PackageInventory
    let pardoPackages: PackageInventory
    let type: LoadType
    let supplier: String
    let notes: String?
    let timestamp: Date
    
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
    
    var totalPackages: Int {
        rosadoPackages.getTotalPackages() + pardoPackages.getTotalPackages()
    }
    
    var totalWeight: Double {
        rosadoPackages.getTotalWeight() + pardoPackages.getTotalWeight()
    }
    
    var displayDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd/MM/yyyy"
        formatter.locale = Locale(identifier: "es_ES")
        return formatter.string(from: timestamp)
    }
    
    var displayTime: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: timestamp)
    }
}

// MARK: - Tipos de movimiento de carga
enum LoadType: String, Codable, CaseIterable {
    case incoming = "carga" // Carga entrante
    case outgoing = "salida" // Salida de productos
    case adjustment = "ajuste" // Ajuste de inventario
    case dayClose = "cierre" // Cierre de día
    
    var displayName: String {
        switch self {
        case .incoming: return "Carga Entrante"
        case .outgoing: return "Salida"
        case .adjustment: return "Ajuste"
        case .dayClose: return "Cierre de Día"
        }
    }
    
    var icon: String {
        switch self {
        case .incoming: return "plus.circle.fill"
        case .outgoing: return "minus.circle.fill"
        case .adjustment: return "pencil.circle.fill"
        case .dayClose: return "checkmark.circle.fill"
        }
    }
}

// MARK: - Formatos de exportación
enum ExportFormat: String, CaseIterable {
    case pdf = "pdf"
    case excel = "xlsx"
    case csv = "csv"
    
    var displayName: String {
        switch self {
        case .pdf: return "PDF"
        case .excel: return "Excel"
        case .csv: return "CSV"
        }
    }
    
    var fileExtension: String {
        return self.rawValue
    }
}
