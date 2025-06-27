//
//  StockViewModel.swift
//  AvicolaDonnasApp
//
//  Created by Victor Martinez on 25/06/25.
//

import Foundation
import SwiftUI

@MainActor
final class StockViewModel: ObservableObject {
    
    // MARK: - Singleton Pattern (NUEVA IMPLEMENTACIÓN)
    static let shared = StockViewModel()
    
    // MARK: - Published Properties
    @Published var currentDayStock: DailyStock?
    @Published var stockHistory: [DailyStock] = []
    @Published var todayCargoEntries: [CargoEntry] = []
    @Published var allCargoEntries: [CargoEntry] = []
    @Published var appSettings: AppSettings = AppSettings()
    
    // MARK: - UI State
    @Published var isLoading = false
    @Published var showingError = false
    @Published var errorMessage = ""
    @Published var selectedDate = Date()
    
    // ✅ NUEVAS PROPIEDADES PARA ESTADÍSTICAS
    @Published var todayMovementCount = 0
    @Published var todaySupplierCount = 0
    
    // MARK: - Computed Properties
    var currentDateString: String {
        Date().dailyString
    }
    
    var selectedDateString: String {
        selectedDate.dailyString
    }
    
    var todayTotalPackages: Int {
        currentDayStock?.totalPackages ?? 0
    }
    
    var todayTotalWeight: Double {
        currentDayStock?.totalWeight ?? 0.0
    }
    
    var todayRosadoPackages: Int {
        currentDayStock?.rosadoPackages.getTotalPackages() ?? 0
    }
    
    var todayPardoPackages: Int {
        currentDayStock?.pardoPackages.getTotalPackages() ?? 0
    }
    
    var todayRosadoWeight: Double {
        currentDayStock?.rosadoPackages.getTotalWeight() ?? 0.0
    }
    
    var todayPardoWeight: Double {
        currentDayStock?.pardoPackages.getTotalWeight() ?? 0.0
    }
    
    var isDayOpen: Bool {
        !(currentDayStock?.isClosed ?? true)
    }
    
    // MARK: - Firebase Manager
    private let firebaseManager = FirebaseManager.shared
    
    // MARK: - Initialization
    private init() {
        Task {
            await loadInitialData()
        }
    }
    
    // MARK: - Initial Data Loading
    func loadInitialData() async {
        isLoading = true
        do {
            print("🔄 Cargando datos iniciales...")
            
            // Cargar configuración
            await loadAppSettings()
            
            // Cargar stock del día actual
            await loadCurrentDayStock()
            
            // Cargar historial
            await loadStockHistory()
            
            // Cargar movimientos de hoy
            await loadTodayCargoEntries()
            
            // ✅ CARGAR ESTADÍSTICAS
            await loadTodayStatistics()
            
            print("✅ Datos iniciales cargados exitosamente")
            
        } catch {
            await handleError(error)
        }
        isLoading = false
    }
    
    // MARK: - App Settings Methods
    func loadAppSettings() async {
        do {
            if let settings = try await firebaseManager.fetchAppSettings() {
                appSettings = settings
                print("✅ Configuración cargada")
            } else {
                // Primera vez, crear configuración inicial
                appSettings = AppSettings()
                try await firebaseManager.saveAppSettings(appSettings)
                print("✅ Configuración inicial creada")
            }
        } catch {
            await handleError(error)
        }
    }
    
    func updateAppSettings(_ newSettings: AppSettings) async {
        do {
            appSettings = newSettings
            try await firebaseManager.saveAppSettings(appSettings)
        } catch {
            await handleError(error)
        }
    }
    
    // MARK: - Current Day Stock Methods
    func loadCurrentDayStock() async {
        do {
            let today = currentDateString
            currentDayStock = try await firebaseManager.fetchDailyStock(for: today)
            
            // Si no existe, crear uno nuevo
            if currentDayStock == nil {
                currentDayStock = DailyStock(date: today)
                currentDayStock?.isCurrentDay = true
                try await firebaseManager.saveDailyStock(currentDayStock!)
                print("✅ Nuevo stock diario creado para \(today)")
            } else {
                print("✅ Stock diario cargado para \(today)")
            }
        } catch {
            await handleError(error)
        }
    }
    
    func updateCurrentDayStock() async {
        guard var stock = currentDayStock else { return }
        
        do {
            stock.updateTotals()
            
            try await firebaseManager.saveDailyStock(stock)
            currentDayStock = stock
            print("✅ Stock actual actualizado")
        } catch {
            await handleError(error)
        }
    }
    
    // MARK: - Cargo Entry Methods
    func addCargoEntry(rosadoPackages: PackageInventory = PackageInventory(),
                     pardoPackages: PackageInventory = PackageInventory(),
                     supplier: String,
                     notes: String? = nil,
                     type: LoadType = .incoming) async {
        do {
            print("📦 Agregando nuevo movimiento: \(type.displayName)")
            
            let entry = CargoEntry(
                date: currentDateString,
                rosadoPackages: rosadoPackages,
                pardoPackages: pardoPackages,
                type: type,
                supplier: supplier,
                notes: notes
            )
            
            // Guardar el movimiento
            try await firebaseManager.saveCargoEntry(entry)
            print("✅ Movimiento guardado en Firebase")
            
            // Actualizar el stock del día actual
            if var currentStock = currentDayStock {
                if type == .incoming {
                    currentStock.addLoad(rosadoPackages, type: .rosado)
                    currentStock.addLoad(pardoPackages, type: .pardo)
                } else if type == .outgoing {
                    // Para salidas, restar del stock
                    subtractFromStock(&currentStock.rosadoPackages, packages: rosadoPackages)
                    subtractFromStock(&currentStock.pardoPackages, packages: pardoPackages)
                    currentStock.updateTotals()
                }
                
                try await firebaseManager.saveDailyStock(currentStock)
                currentDayStock = currentStock
                print("✅ Stock actualizado")
            }
            
            // Recargar movimientos y estadísticas
            await loadTodayCargoEntries()
            await loadTodayStatistics()
            
            // Agregar proveedor a la lista si no existe
            if type == .incoming && !supplier.isEmpty && !appSettings.frequentSuppliers.contains(supplier) {
                appSettings.frequentSuppliers.append(supplier)
                try await firebaseManager.saveAppSettings(appSettings)
                print("✅ Nuevo proveedor agregado a la lista")
            }
            
        } catch {
            await handleError(error)
        }
    }
    
    // Método de conveniencia para agregar solo un tipo de huevo
    func addCargoEntry(packages: PackageInventory,
                     eggType: EggType,
                     supplier: String,
                     notes: String? = nil,
                     type: LoadType = .incoming) async {
        switch eggType {
        case .rosado:
            await addCargoEntry(rosadoPackages: packages, supplier: supplier, notes: notes, type: type)
        case .pardo:
            await addCargoEntry(pardoPackages: packages, supplier: supplier, notes: notes, type: type)
        }
    }
    
    func loadTodayCargoEntries() async {
        do {
            print("📋 Cargando movimientos de hoy...")
            todayCargoEntries = try await firebaseManager.fetchCargoEntries(for: currentDateString)
            print("✅ Cargados \(todayCargoEntries.count) movimientos")
        } catch {
            await handleError(error)
        }
    }
    
    func loadAllCargoEntries() async {
        do {
            print("📋 Cargando todos los movimientos...")
            allCargoEntries = try await firebaseManager.fetchAllCargoEntries()
            print("✅ Cargados \(allCargoEntries.count) movimientos totales")
        } catch {
            await handleError(error)
        }
    }
    
    // ✅ NUEVO MÉTODO - Cargar estadísticas del día
    func loadTodayStatistics() async {
        do {
            print("📊 Cargando estadísticas del día...")
            let (movements, suppliers) = try await firebaseManager.fetchCargoEntriesStats(for: currentDateString)
            
            todayMovementCount = movements
            todaySupplierCount = suppliers
            
            print("📊 Estadísticas: \(movements) movimientos, \(suppliers) proveedores")
        } catch {
            await handleError(error)
        }
    }
    
    // MARK: - Stock History Methods
    func loadStockHistory() async {
        do {
            stockHistory = try await firebaseManager.fetchAllDailyStocks()
            print("✅ Historial cargado: \(stockHistory.count) días")
        } catch {
            await handleError(error)
        }
    }
    
    func loadStockForDate(_ date: String) async -> DailyStock? {
        do {
            return try await firebaseManager.fetchDailyStock(for: date)
        } catch {
            await handleError(error)
            return nil
        }
    }
    
    func updateStockForDate(_ stock: DailyStock) async {
        do {
            var updatedStock = stock
            updatedStock.updateTotals()
            
            try await firebaseManager.saveDailyStock(updatedStock)
            
            // Actualizar en el historial
            if let index = stockHistory.firstIndex(where: { $0.date == stock.date }) {
                stockHistory[index] = updatedStock
            }
            
            // Si es el día actual, actualizar también
            if stock.date == currentDateString {
                currentDayStock = updatedStock
                await loadTodayStatistics() // Actualizar estadísticas
            }
        } catch {
            await handleError(error)
        }
    }
    
    // MARK: - Stock Manipulation Methods
    func updateStockForType(_ eggType: EggType, packages: PackageInventory) async {
        guard var stock = currentDayStock else { return }
        
        stock.setPackagesForType(eggType, packages: packages)
        await updateCurrentDayStock()
    }
    
    func getStockForType(_ eggType: EggType) -> PackageInventory {
        guard let stock = currentDayStock else { return PackageInventory() }
        return stock.getPackagesForType(eggType)
    }
    
    // MARK: - Day Close Methods
    func closeCurrentDay() async {
        guard var stock = currentDayStock else { return }
        
        do {
            print("🔒 Cerrando día actual...")
            
            // Crear entrada de cierre
            let closeEntry = CargoEntry(
                date: currentDateString,
                rosadoPackages: stock.rosadoPackages,
                pardoPackages: stock.pardoPackages,
                type: .dayClose,
                supplier: "Sistema",
                notes: "Cierre automático del día"
            )
            
            try await firebaseManager.saveCargoEntry(closeEntry)
            
            // Marcar día como cerrado
            stock.isClosed = true
            stock.isCurrentDay = false
            stock.closedAt = Date()
            stock.updateTotals()
            
            try await firebaseManager.saveDailyStock(stock)
            currentDayStock = stock
            
            // Recargar datos
            await loadStockHistory()
            await loadTodayCargoEntries()
            await loadTodayStatistics()
            
            print("✅ Día cerrado exitosamente")
            
        } catch {
            await handleError(error)
        }
    }
    
    func reopenDay(_ date: String) async {
        do {
            print("🔓 Reabriendo día: \(date)")
            
            if var stock = try await firebaseManager.fetchDailyStock(for: date) {
                stock.isClosed = false
                stock.closedAt = nil
                stock.updateTotals()
                
                if date == currentDateString {
                    stock.isCurrentDay = true
                    currentDayStock = stock
                }
                
                try await firebaseManager.saveDailyStock(stock)
                await loadStockHistory()
                
                if date == currentDateString {
                    await loadTodayCargoEntries()
                    await loadTodayStatistics()
                }
                
                print("✅ Día reabierto exitosamente")
            }
        } catch {
            await handleError(error)
        }
    }
    
    // MARK: - Report Methods
    func generateReport(type: ReportType, startDate: String, endDate: String) async -> ReportData? {
        do {
            let dailyStocks = try await firebaseManager.fetchDailyStocks(from: startDate, to: endDate)
            let cargoEntries = try await firebaseManager.fetchCargoEntries(from: startDate, to: endDate)
            
            let dateRange = "\(startDate) - \(endDate)"
            let title = "\(type.displayName) - \(dateRange)"
            
            return ReportData(
                title: title,
                dateRange: dateRange,
                startDate: startDate,
                endDate: endDate,
                dailyStocks: dailyStocks,
                cargoEntries: cargoEntries,
                reportType: type
            )
        } catch {
            await handleError(error)
            return nil
        }
    }
    
    // MARK: - Statistics Methods
    func getEggTypeStatistics() -> [(type: EggType, packages: Int, weight: Double)] {
        guard let stock = currentDayStock else { return [] }
        
        return [
            (type: .rosado, packages: stock.rosadoPackages.getTotalPackages(), weight: stock.rosadoPackages.getTotalWeight()),
            (type: .pardo, packages: stock.pardoPackages.getTotalPackages(), weight: stock.pardoPackages.getTotalWeight())
        ].filter { $0.packages > 0 }
    }
    
    func getWeightDistribution(for eggType: EggType) -> [(weight: Int, count: Int)] {
        let packages = getStockForType(eggType)
        return packages.getWeightSummary()
    }
    
    // ✅ NUEVO MÉTODO - Obtener resumen de proveedores
    func getTodaySupplierSummary() -> [String: (packages: Int, deliveries: Int)] {
        let incomingEntries = todayCargoEntries.filter {
            $0.type == .incoming && !$0.supplier.isEmpty && $0.supplier != "Sistema"
        }
        
        var summary: [String: (packages: Int, deliveries: Int)] = [:]
        
        for entry in incomingEntries {
            if let existing = summary[entry.supplier] {
                summary[entry.supplier] = (
                    packages: existing.packages + entry.totalPackages,
                    deliveries: existing.deliveries + 1
                )
            } else {
                summary[entry.supplier] = (
                    packages: entry.totalPackages,
                    deliveries: 1
                )
            }
        }
        
        return summary
    }
    
    // ✅ NUEVO MÉTODO - Obtener proveedores únicos
    func getTodayUniqueSuppliers() -> Set<String> {
        return Set(todayCargoEntries
            .filter { $0.type == .incoming && !$0.supplier.isEmpty && $0.supplier != "Sistema" }
            .map { $0.supplier })
    }
    
    // MARK: - Utility Methods
    private func subtractFromStock(_ stock: inout PackageInventory, packages: PackageInventory) {
        for weight in stock.packageWeights {
            let currentPackages = stock.getPackagesForWeight(weight)
            let packagesToSubtract = packages.getPackagesForWeight(weight)
            
            var newPackages = currentPackages
            for i in 0..<10 {
                newPackages[i] = max(0, newPackages[i] - packagesToSubtract[i])
            }
            
            stock.setPackagesForWeight(weight, packages: newPackages)
        }
    }
    
    func validatePackageInput(_ packages: PackageInventory) -> Bool {
        for weight in packages.packageWeights {
            let weightPackages = packages.getPackagesForWeight(weight)
            if weightPackages.contains(where: { $0 < 0 }) {
                return false
            }
        }
        return true
    }
    
    func validateCargoEntry(rosadoPackages: PackageInventory, pardoPackages: PackageInventory) -> Bool {
        return validatePackageInput(rosadoPackages) && validatePackageInput(pardoPackages)
    }
    
    func getPackageDecimalString(_ weight: Int, decimal: Int) -> String {
        return "\(weight).\(decimal)"
    }
    
    func hasStockForType(_ eggType: EggType) -> Bool {
        return getStockForType(eggType).hasStock()
    }
    
    // MARK: - Error Handling
    private func handleError(_ error: Error) async {
        errorMessage = error.localizedDescription
        showingError = true
        print("❌ StockViewModel Error: \(error)")
    }
    
    func clearError() {
        showingError = false
        errorMessage = ""
    }
    
    // MARK: - Refresh Methods
    func refreshAllData() async {
        print("🔄 Refrescando todos los datos...")
        await loadInitialData()
    }
    
    func refreshCurrentStock() async {
        print("🔄 Refrescando stock actual...")
        await loadCurrentDayStock()
        await loadTodayCargoEntries()
        await loadTodayStatistics()
    }
}
