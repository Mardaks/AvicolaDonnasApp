//
//  StockViewModel.swift
//  AvicolaDonnasApp
//
//  Created by Victor Martinez on 25/06/25.
//

import Foundation
import SwiftUI

// MARK: - 🧠 ViewModel Principal: Cerebro de Toda la Aplicación
/// Coordina TODA la lógica de negocio entre la UI y Firebase
/// Patrón MVVM: Mantiene la UI reactiva y separada de la lógica
@MainActor
final class StockViewModel: ObservableObject {
    
    static let shared = StockViewModel()
    private let firebaseManager = FirebaseManager.shared
    
    // MARK: - 📊 Estado Principal de la Aplicación
    @Published var currentDayStock: DailyStock?       // Stock del día actual
    @Published var stockHistory: [DailyStock] = []    // Historial completo
    @Published var todayCargoEntries: [CargoEntry] = [] // Movimientos de hoy
    @Published var allCargoEntries: [CargoEntry] = []   // Todos los movimientos
    @Published var appSettings: AppSettings = AppSettings() // Configuración
    
    // MARK: - 🎛️ Control de Interface y Estados
    @Published var isLoading = false          // Indicador de carga
    @Published var showingError = false       // Control de errores
    @Published var errorMessage = ""          // Mensaje de error actual
    @Published var selectedDate = Date()      // Fecha seleccionada en UI
    
    // MARK: - 📈 Estadísticas en Tiempo Real
    @Published var todayMovementCount = 0     // Movimientos del día
    @Published var todaySupplierCount = 0     // Proveedores únicos hoy
    
    // MARK: - 🔢 Propiedades Calculadas para UI
    /// Estas propiedades se actualizan automáticamente cuando cambia el estado
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
    
    private init() {
        Task {
            await loadInitialData()
        }
    }
    
    // MARK: - 🚀 Inicialización: Carga Secuencial de Datos
    /// Carga todos los datos necesarios al iniciar la app
    /// Orden específico para optimizar la experiencia del usuario
    func loadInitialData() async {
        isLoading = true
        do {
            print("🔄 Cargando datos iniciales...")
            
            // 1. Configuración (rápida)
            await loadAppSettings()
            
            // 2. Stock actual (prioritario para el usuario)
            await loadCurrentDayStock()
            
            // 3. Historial (para navegación)
            await loadStockHistory()
            
            // 4. Movimientos de hoy (para el dashboard)
            await loadTodayCargoEntries()
            
            // 5. Estadísticas (calculadas)
            await loadTodayStatistics()
            
            print("✅ Datos iniciales cargados exitosamente")
            
        } catch {
            await handleError(error)
        }
        isLoading = false
    }
    
    // MARK: - ⚙️ Gestión de Configuración
    func loadAppSettings() async {
        do {
            if let settings = try await firebaseManager.fetchAppSettings() {
                appSettings = settings
                print("✅ Configuración cargada")
            } else {
                // Primera vez: crear configuración inicial
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
    
    // MARK: - 📦 Gestión de Stock Actual
    /// Carga o crea el stock del día actual
    /// Auto-creación si es el primer acceso del día
    func loadCurrentDayStock() async {
        do {
            let today = currentDateString
            currentDayStock = try await firebaseManager.fetchDailyStock(for: today)
            
            // Si no existe, crear uno nuevo automáticamente
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
    
    /// Actualiza el stock actual con recálculo automático
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
    
    // MARK: - 📋 Gestión Avanzada de Movimientos
    /// Método principal para registrar cualquier tipo de movimiento
    /// Actualiza automáticamente el stock y las estadísticas
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
            
            // 1. Guardar el movimiento en historial
            try await firebaseManager.saveCargoEntry(entry)
            print("✅ Movimiento guardado en Firebase")
            
            // 2. Actualizar stock actual según el tipo de operación
            if var currentStock = currentDayStock {
                if type == .incoming {
                    // Sumar al inventario
                    currentStock.addLoad(rosadoPackages, type: .rosado)
                    currentStock.addLoad(pardoPackages, type: .pardo)
                } else if type == .outgoing {
                    // Restar del inventario (validando no quedar en negativo)
                    subtractFromStock(&currentStock.rosadoPackages, packages: rosadoPackages)
                    subtractFromStock(&currentStock.pardoPackages, packages: pardoPackages)
                    currentStock.updateTotals()
                }
                
                try await firebaseManager.saveDailyStock(currentStock)
                currentDayStock = currentStock
                print("✅ Stock actualizado")
            }
            
            // 3. Recargar datos dependientes
            await loadTodayCargoEntries()
            await loadTodayStatistics()
            
            // 4. Aprendizaje automático: agregar proveedor nuevo a lista frecuente
            if type == .incoming && !supplier.isEmpty && !appSettings.frequentSuppliers.contains(supplier) {
                appSettings.frequentSuppliers.append(supplier)
                try await firebaseManager.saveAppSettings(appSettings)
                print("✅ Nuevo proveedor agregado a la lista")
            }
            
        } catch {
            await handleError(error)
        }
    }
    
    /// Método de conveniencia para registrar un solo tipo de huevo
    /// Simplifica el uso desde la UI
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
    
    // MARK: - 📊 Sistema de Estadísticas en Tiempo Real
    /// Calcula estadísticas del día actual
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
    
    // MARK: - 📚 Gestión de Historial
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
    
    /// Actualiza stock de cualquier fecha con propagación inteligente
    func updateStockForDate(_ stock: DailyStock) async {
        do {
            var updatedStock = stock
            updatedStock.updateTotals()
            
            try await firebaseManager.saveDailyStock(updatedStock)
            
            // Actualizar en memoria para UI reactiva
            if let index = stockHistory.firstIndex(where: { $0.date == stock.date }) {
                stockHistory[index] = updatedStock
            }
            
            // Si es hoy, actualizar también el stock actual
            if stock.date == currentDateString {
                currentDayStock = updatedStock
                await loadTodayStatistics() // Recalcular estadísticas
            }
        } catch {
            await handleError(error)
        }
    }
    
    // MARK: - 🔧 Manipulación Directa de Stock
    func updateStockForType(_ eggType: EggType, packages: PackageInventory) async {
        guard var stock = currentDayStock else { return }
        
        stock.setPackagesForType(eggType, packages: packages)
        await updateCurrentDayStock()
    }
    
    func getStockForType(_ eggType: EggType) -> PackageInventory {
        guard let stock = currentDayStock else { return PackageInventory() }
        return stock.getPackagesForType(eggType)
    }
    
    // MARK: - 🔒 Sistema de Cierre de Día
    /// Cierra el día actual con registro automático
    func closeCurrentDay() async {
        guard var stock = currentDayStock else { return }
        
        do {
            print("🔒 Cerrando día actual...")
            
            // Crear entrada automática de cierre
            let closeEntry = CargoEntry(
                date: currentDateString,
                rosadoPackages: stock.rosadoPackages,
                pardoPackages: stock.pardoPackages,
                type: .dayClose,
                supplier: "Sistema",
                notes: "Cierre automático del día"
            )
            
            try await firebaseManager.saveCargoEntry(closeEntry)
            
            // Marcar como cerrado con timestamp
            stock.isClosed = true
            stock.isCurrentDay = false
            stock.closedAt = Date()
            stock.updateTotals()
            
            try await firebaseManager.saveDailyStock(stock)
            currentDayStock = stock
            
            // Actualizar datos dependientes
            await loadStockHistory()
            await loadTodayCargoEntries()
            await loadTodayStatistics()
            
            print("✅ Día cerrado exitosamente")
            
        } catch {
            await handleError(error)
        }
    }
    
    /// Reabre un día cerrado (para correcciones)
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
    
    // MARK: - 📈 Generador de Reportes Avanzados
    /// Genera reportes con análisis completo de datos
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
    
    // MARK: - 📊 Análisis de Datos Inteligente
    /// Genera estadísticas por tipo de huevo
    func getEggTypeStatistics() -> [(type: EggType, packages: Int, weight: Double)] {
        guard let stock = currentDayStock else { return [] }
        
        return [
            (type: .rosado, packages: stock.rosadoPackages.getTotalPackages(), weight: stock.rosadoPackages.getTotalWeight()),
            (type: .pardo, packages: stock.pardoPackages.getTotalPackages(), weight: stock.pardoPackages.getTotalWeight())
        ].filter { $0.packages > 0 }
    }
    
    /// Distribución de pesos para gráficos
    func getWeightDistribution(for eggType: EggType) -> [(weight: Int, count: Int)] {
        let packages = getStockForType(eggType)
        return packages.getWeightSummary()
    }
    
    /// Análisis de proveedores del día
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
    
    /// Lista de proveedores únicos de hoy
    func getTodayUniqueSuppliers() -> Set<String> {
        return Set(todayCargoEntries
            .filter { $0.type == .incoming && !$0.supplier.isEmpty && $0.supplier != "Sistema" }
            .map { $0.supplier })
    }
    
    // MARK: - 🛠️ Métodos de Utilidad y Validación
    /// Resta paquetes del stock evitando valores negativos
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
    
    /// Valida que no haya valores negativos en paquetes
    func validatePackageInput(_ packages: PackageInventory) -> Bool {
        for weight in packages.packageWeights {
            let weightPackages = packages.getPackagesForWeight(weight)
            if weightPackages.contains(where: { $0 < 0 }) {
                return false
            }
        }
        return true
    }
    
    /// Validación completa de entrada de carga
    func validateCargoEntry(rosadoPackages: PackageInventory, pardoPackages: PackageInventory) -> Bool {
        return validatePackageInput(rosadoPackages) && validatePackageInput(pardoPackages)
    }
    
    /// Formatea peso con decimales para UI
    func getPackageDecimalString(_ weight: Int, decimal: Int) -> String {
        return "\(weight).\(decimal)"
    }
    
    /// Verificación rápida de disponibilidad de stock
    func hasStockForType(_ eggType: EggType) -> Bool {
        return getStockForType(eggType).hasStock()
    }
    
    // MARK: - ⚠️ Sistema Robusto de Manejo de Errores
    /// Centraliza el manejo de errores con logging detallado
    private func handleError(_ error: Error) async {
        errorMessage = error.localizedDescription
        showingError = true
        print("❌ StockViewModel Error: \(error)")
    }
    
    func clearError() {
        showingError = false
        errorMessage = ""
    }
    
    // MARK: - 🔄 Métodos de Actualización y Sincronización
    /// Recarga completa de todos los datos
    func refreshAllData() async {
        print("🔄 Refrescando todos los datos...")
        await loadInitialData()
    }
    
    /// Actualización rápida solo del estado actual
    func refreshCurrentStock() async {
        print("🔄 Refrescando stock actual...")
        await loadCurrentDayStock()
        await loadTodayCargoEntries()
        await loadTodayStatistics()
    }
}
