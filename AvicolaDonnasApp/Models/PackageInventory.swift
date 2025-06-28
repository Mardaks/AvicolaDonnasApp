//
//  PackageInventory.swift
//  AvicolaDonnasApp
//
//  Created by Victor Martinez on 26/06/25.
//

import Foundation

// MARK: - 📊 Sistema Avanzado de Inventario por Peso
/// Organiza los paquetes por peso exacto (7.0kg hasta 13.9kg)
/// Cada array representa las décimas: [7.0, 7.1, 7.2, ..., 7.9]
/// Esta es la estructura que hace único al sistema
struct PackageInventory: Codable {
    var kg7: [Int] = Array(repeating: 0, count: 10)  // 7.0kg a 7.9kg
    var kg8: [Int] = Array(repeating: 0, count: 10)  // 8.0kg a 8.9kg
    var kg9: [Int] = Array(repeating: 0, count: 10)  // 9.0kg a 9.9kg
    var kg10: [Int] = Array(repeating: 0, count: 10) // 10.0kg a 10.9kg
    var kg11: [Int] = Array(repeating: 0, count: 10) // 11.0kg a 11.9kg
    var kg12: [Int] = Array(repeating: 0, count: 10) // 12.0kg a 12.9kg
    var kg13: [Int] = Array(repeating: 0, count: 10) // 13.0kg a 13.9kg
    
    // MARK: - 🔍 Propiedades para Cálculos Automáticos
    /// Agrupa todos los arrays para facilitar iteraciones
    var allPackages: [[Int]] {
        [kg7, kg8, kg9, kg10, kg11, kg12, kg13]
    }
    
    /// Lista de pesos base para cálculos
    var packageWeights: [Int] {
        [7, 8, 9, 10, 11, 12, 13]
    }
    
    // MARK: - 🧮 Métodos de Cálculo Inteligente
    /// Cuenta todos los paquetes sin importar el peso
    func getTotalPackages() -> Int {
        allPackages.flatMap { $0 }.reduce(0, +)
    }
    
    /// Calcula el peso total real considerando el peso específico de cada paquete
    /// Ejemplo: 5 paquetes de 7kg + 3 paquetes de 8kg = 35kg + 24kg = 59kg
    func getTotalWeight() -> Double {
        var total: Double = 0
        for (index, packages) in allPackages.enumerated() {
            let weight = Double(packageWeights[index])
            let packageCount = packages.reduce(0, +)
            total += weight * Double(packageCount)
        }
        return total
    }
    
    /// Obtiene el total de paquetes de un peso específico
    /// Suma todas las décimas: 7.0 + 7.1 + 7.2 + ... + 7.9
    func getTotalForWeight(_ weight: Int) -> Int {
        switch weight {
        case 7: return kg7.reduce(0, +)
        case 8: return kg8.reduce(0, +)
        case 9: return kg9.reduce(0, +)
        case 10: return kg10.reduce(0, +)
        case 11: return kg11.reduce(0, +)
        case 12: return kg12.reduce(0, +)
        case 13: return kg13.reduce(0, +)
        default: return 0
        }
    }
    
    // MARK: - ➕ Sistema de Adición de Inventario
    /// Método principal para agregar nuevos paquetes al inventario existente
    mutating func addLoad(_ newLoad: PackageInventory) {
        for i in 0..<10 {
            kg7[i] += newLoad.kg7[i]
            kg8[i] += newLoad.kg8[i]
            kg9[i] += newLoad.kg9[i]
            kg10[i] += newLoad.kg10[i]
            kg11[i] += newLoad.kg11[i]
            kg12[i] += newLoad.kg12[i]
            kg13[i] += newLoad.kg13[i]
        }
    }
    
    /// Alias más claro para el método anterior
    mutating func addPackages(_ newPackages: PackageInventory) {
        addLoad(newPackages)
    }
    
    // MARK: - 🔧 Métodos de Acceso y Modificación
    /// Obtiene el array completo de décimas para un peso específico
    func getPackagesForWeight(_ weight: Int) -> [Int] {
        switch weight {
        case 7: return kg7
        case 8: return kg8
        case 9: return kg9
        case 10: return kg10
        case 11: return kg11
        case 12: return kg12
        case 13: return kg13
        default: return Array(repeating: 0, count: 10)
        }
    }
    
    /// Actualiza completamente el array de un peso específico
    mutating func setPackagesForWeight(_ weight: Int, packages: [Int]) {
        guard packages.count == 10 else { return }
        switch weight {
        case 7: kg7 = packages
        case 8: kg8 = packages
        case 9: kg9 = packages
        case 10: kg10 = packages
        case 11: kg11 = packages
        case 12: kg12 = packages
        case 13: kg13 = packages
        default: break
        }
    }
    
    // MARK: - 📈 Métodos de Análisis y Reportes
    /// Verifica rápidamente si hay inventario disponible
    func hasStock() -> Bool {
        return getTotalPackages() > 0
    }
    
    /// Genera un resumen compacto solo de los pesos que tienen stock
    /// Útil para reportes y vistas de resumen
    func getWeightSummary() -> [(weight: Int, count: Int)] {
        return packageWeights.map { weight in
            (weight: weight, count: getTotalForWeight(weight))
        }.filter { $0.count > 0 }
    }
}
