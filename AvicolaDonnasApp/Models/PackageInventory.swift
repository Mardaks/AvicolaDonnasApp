//
//  PackageInventory.swift
//  AvicolaDonnasApp
//
//  Created by Victor Martinez on 26/06/25.
//

import Foundation

// MARK: - Estructura para organizar todos los paquetes (7kg - 13kg)
struct PackageInventory: Codable {
    var kg7: [Int] = Array(repeating: 0, count: 10) // 7.0 a 7.9
    var kg8: [Int] = Array(repeating: 0, count: 10) // 8.0 a 8.9
    var kg9: [Int] = Array(repeating: 0, count: 10) // 9.0 a 9.9
    var kg10: [Int] = Array(repeating: 0, count: 10) // 10.0 a 10.9
    var kg11: [Int] = Array(repeating: 0, count: 10) // 11.0 a 11.9
    var kg12: [Int] = Array(repeating: 0, count: 10) // 12.0 a 12.9
    var kg13: [Int] = Array(repeating: 0, count: 10) // 13.0 a 13.9
    
    // Computed properties para facilitar cálculos
    var allPackages: [[Int]] {
        [kg7, kg8, kg9, kg10, kg11, kg12, kg13]
    }
    
    var packageWeights: [Int] {
        [7, 8, 9, 10, 11, 12, 13]
    }
    
    // Métodos de utilidad
    func getTotalPackages() -> Int {
        allPackages.flatMap { $0 }.reduce(0, +)
    }
    
    func getTotalWeight() -> Double {
        var total: Double = 0
        for (index, packages) in allPackages.enumerated() {
            let weight = Double(packageWeights[index])
            let packageCount = packages.reduce(0, +)
            total += weight * Double(packageCount)
        }
        return total
    }
    
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
    
    // Método para agregar carga
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
    
    // Método para obtener array por peso
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
    
    // Método para actualizar array por peso
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
    
    // Método para verificar si hay stock
    func hasStock() -> Bool {
        return getTotalPackages() > 0
    }
    
    // Método para obtener un resumen por peso
    func getWeightSummary() -> [(weight: Int, count: Int)] {
        return packageWeights.map { weight in
            (weight: weight, count: getTotalForWeight(weight))
        }.filter { $0.count > 0 }
    }
}