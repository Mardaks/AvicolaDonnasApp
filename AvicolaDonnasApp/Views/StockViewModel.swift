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
    
    // MARK: - Published Properties
    @Published var currentDayStock: DailyStock?
    @Published var stockHistory: [DailyStock] = []
    @Published var todayLoadEntries: [LoadEntry] = []
    @Published var allLoadEntries: [LoadEntry] = []
    @Published var appSettings: AppSettings = AppSettings()
    
    // MARK: - UI State
    @Published var isLoading = false
    @Published var showingError = false
    @Published var errorMessage = ""
    @Published var selectedDate = Date()
    
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
    
    var isDayOpen: Bool {
        !(currentDayStock?.isClosed ?? true)
    }
    
    // MARK: - Firebase Manager
    private let firebaseManager = FirebaseManager.shared
    
    // MARK: - Initialization
    init() {
        Task {
            await loadInitialData()
        }
    }
    
    // MARK: - Initial Data Loading
    func loadInitialData() async {
        isLoading = true
        do {
            // Cargar configuración
            await loadAppSettings()
            
            // Cargar stock del día actual
            await loadCurrentDayStock()
            
            // Cargar historial
            await loadStockHistory()
            
            // Cargar movimientos de hoy
            await loadTodayLoadEntries()
            
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
            } else {
                // Primera vez, crear configuración inicial
                appSettings = AppSettings()
                try await firebaseManager.saveAppSettings(appSettings)
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
            }
        } catch {
            await handleError(error)
        }
    }
    
    func updateCurrentDayStock() async {
        guard var stock = currentDayStock else { return }
        
        do {
            stock.updatedAt = Date()
            stock.totalPackages = stock.packages.getTotalPackages()
            stock.totalWeight = stock.packages.getTotalWeight()
            
            try await firebaseManager.saveDailyStock(stock)
            currentDayStock = stock
        } catch {
            await handleError(error)
        }
    }
    
    // MARK: - Load Entry Methods
    func addLoadEntry(packages: PackageInventory, supplier: String, notes: String? = nil, type: LoadType = .incoming) async {
        do {
            let entry = LoadEntry(
                date: currentDateString,
                packages: packages,
                type: type,
                supplier: supplier,
                notes: notes
            )
            
            // Guardar el movimiento
            try await firebaseManager.saveLoadEntry(entry)
            
            // Actualizar el stock del día actual
            if var currentStock = currentDayStock {
                if type == .incoming {
                    currentStock.packages.addLoad(packages)
                } else if type == .outgoing {
                    // Para salidas, restar del stock
                    subtractFromStock(&currentStock.packages, packages: packages)
                }
                
                currentStock.updatedAt = Date()
                currentStock.totalPackages = currentStock.packages.getTotalPackages()
                currentStock.totalWeight = currentStock.packages.getTotalWeight()
                
                try await firebaseManager.saveDailyStock(currentStock)
                currentDayStock = currentStock
            }
            
            // Recargar movimientos de hoy
            await loadTodayLoadEntries()
            
            // Agregar proveedor a la lista si no existe
            if type == .incoming && !supplier.isEmpty && !appSettings.frequentSuppliers.contains(supplier) {
                appSettings.frequentSuppliers.append(supplier)
                try await firebaseManager.saveAppSettings(appSettings)
            }
            
        } catch {
            await handleError(error)
        }
    }
    
    func loadTodayLoadEntries() async {
        do {
            todayLoadEntries = try await firebaseManager.fetchLoadEntries(for: currentDateString)
        } catch {
            await handleError(error)
        }
    }
    
    func loadAllLoadEntries() async {
        do {
            allLoadEntries = try await firebaseManager.fetchAllLoadEntries()
        } catch {
            await handleError(error)
        }
    }
    
    // MARK: - Stock History Methods
    func loadStockHistory() async {
        do {
            stockHistory = try await firebaseManager.fetchAllDailyStocks()
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
            updatedStock.updatedAt = Date()
            updatedStock.totalPackages = updatedStock.packages.getTotalPackages()
            updatedStock.totalWeight = updatedStock.packages.getTotalWeight()
            
            try await firebaseManager.saveDailyStock(updatedStock)
            
            // Actualizar en el historial
            if let index = stockHistory.firstIndex(where: { $0.date == stock.date }) {
                stockHistory[index] = updatedStock
            }
            
            // Si es el día actual, actualizar también
            if stock.date == currentDateString {
                currentDayStock = updatedStock
            }
        } catch {
            await handleError(error)
        }
    }
    
    // MARK: - Day Close Methods
    func closeCurrentDay() async {
        guard var stock = currentDayStock else { return }
        
        do {
            // Crear entrada de cierre
            let closeEntry = LoadEntry(
                date: currentDateString,
                packages: stock.packages,
                type: .dayClose,
                supplier: "Sistema",
                notes: "Cierre automático del día"
            )
            
            try await firebaseManager.saveLoadEntry(closeEntry)
            
            // Marcar día como cerrado
            stock.isClosed = true
            stock.isCurrentDay = false
            stock.closedAt = Date()
            stock.updatedAt = Date()
            
            try await firebaseManager.saveDailyStock(stock)
            currentDayStock = stock
            
            // Recargar datos
            await loadStockHistory()
            await loadTodayLoadEntries()
            
        } catch {
            await handleError(error)
        }
    }
    
    func reopenDay(_ date: String) async {
        do {
            if var stock = try await firebaseManager.fetchDailyStock(for: date) {
                stock.isClosed = false
                stock.closedAt = nil
                stock.updatedAt = Date()
                
                if date == currentDateString {
                    stock.isCurrentDay = true
                    currentDayStock = stock
                }
                
                try await firebaseManager.saveDailyStock(stock)
                await loadStockHistory()
            }
        } catch {
            await handleError(error)
        }
    }
    
    // MARK: - Report Methods
    func generateReport(type: ReportType, startDate: String, endDate: String) async -> ReportData? {
        do {
            let dailyStocks = try await firebaseManager.fetchDailyStocks(from: startDate, to: endDate)
            let loadEntries = try await firebaseManager.fetchLoadEntries(from: startDate, to: endDate)
            
            let dateRange = "\(startDate) - \(endDate)"
            let title = "\(type.displayName) - \(dateRange)"
            
            return ReportData(
                title: title,
                dateRange: dateRange,
                startDate: startDate,
                endDate: endDate,
                dailyStocks: dailyStocks,
                loadEntries: loadEntries,
                reportType: type
            )
        } catch {
            await handleError(error)
            return nil
        }
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
        // Validar que no haya valores negativos
        for weight in packages.packageWeights {
            let weightPackages = packages.getPackagesForWeight(weight)
            if weightPackages.contains(where: { $0 < 0 }) {
                return false
            }
        }
        return true
    }
    
    func getPackageDecimalString(_ weight: Int, decimal: Int) -> String {
        return "\(weight).\(decimal)"
    }
    
    // MARK: - Error Handling
    private func handleError(_ error: Error) async {
        errorMessage = error.localizedDescription
        showingError = true
        print("StockViewModel Error: \(error)")
    }
    
    func clearError() {
        showingError = false
        errorMessage = ""
    }
    
    // MARK: - Refresh Methods
    func refreshAllData() async {
        await loadInitialData()
    }
    
    func refreshCurrentStock() async {
        await loadCurrentDayStock()
        await loadTodayLoadEntries()
    }
}
