//
//  Report.swift
//  AvicolaDonnasApp
//
//  Created by Victor Martinez on 26/06/25.
//

import Foundation
import SwiftUI

// MARK: - Enums de Report
enum ReportType: String, CaseIterable, Codable {
    case daily = "daily"
    case weekly = "weekly"
    case monthly = "monthly"
    case supplier = "supplier"
    case eggType = "eggType"
    
    var displayName: String {
        switch self {
        case .daily: return "Diario"
        case .weekly: return "Semanal"
        case .monthly: return "Mensual"
        case .supplier: return "Proveedor"
        case .eggType: return "Tipo Huevo"
        }
    }
}

enum ReportDateRange: CaseIterable {
    case lastWeek, lastMonth, last3Months, lastYear, custom
    
    var displayName: String {
        switch self {
        case .lastWeek: return "7 días"
        case .lastMonth: return "30 días"
        case .last3Months: return "3 meses"
        case .lastYear: return "1 año"
        case .custom: return "Personalizado"
        }
    }
    
    var description: String {
        switch self {
        case .lastWeek: return "Última semana"
        case .lastMonth: return "Último mes"
        case .last3Months: return "Últimos 3 meses"
        case .lastYear: return "Último año"
        case .custom: return "Rango personalizado"
        }
    }
    
    func dateRange(customStart: Date = Date(), customEnd: Date = Date()) -> (start: Date, end: Date) {
        let calendar = Calendar.current
        let today = Date()
        
        switch self {
        case .lastWeek:
            let weekAgo = calendar.date(byAdding: .day, value: -7, to: today)!
            return (start: weekAgo, end: today)
        case .lastMonth:
            let monthAgo = calendar.date(byAdding: .day, value: -30, to: today)!
            return (start: monthAgo, end: today)
        case .last3Months:
            let threeMonthsAgo = calendar.date(byAdding: .month, value: -3, to: today)!
            return (start: threeMonthsAgo, end: today)
        case .lastYear:
            let yearAgo = calendar.date(byAdding: .year, value: -1, to: today)!
            return (start: yearAgo, end: today)
        case .custom:
            return (start: customStart, end: customEnd)
        }
    }
}

enum ChartType: CaseIterable {
    case line, bar, area
    
    var displayName: String {
        switch self {
        case .line: return "Línea"
        case .bar: return "Barras"
        case .area: return "Área"
        }
    }
    
    var icon: String {
        switch self {
        case .line: return "chart.xyaxis.line"
        case .bar: return "chart.bar"
        case .area: return "chart.line.uptrend.xyaxis"
        }
    }
}

enum TrendDirection {
    case up, down, stable
    
    var icon: String {
        switch self {
        case .up: return "arrow.up.circle.fill"
        case .down: return "arrow.down.circle.fill"
        case .stable: return "minus.circle.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .up: return .green
        case .down: return .red
        case .stable: return .orange
        }
    }
}

enum EggTypeFilter: CaseIterable {
    case all, rosado, pardo
    
    var displayName: String {
        switch self {
        case .all: return "Todos"
        case .rosado: return "Solo Rosado"
        case .pardo: return "Solo Pardo"
        }
    }
}

// MARK: - Modelo de datos de Report
struct ReportData: Codable {
    let title: String
    let dateRange: String
    let startDate: String
    let endDate: String
    let dailyStocks: [DailyStock]
    let cargoEntries: [CargoEntry]
    let reportType: ReportType
    
    // Computed properties
    var totalPackages: Int {
        dailyStocks.reduce(0) { $0 + $1.totalPackages }
    }
    
    var totalWeight: Double {
        dailyStocks.reduce(0) { $0 + $1.totalWeight }
    }
    
    var totalRosadoPackages: Int {
        dailyStocks.reduce(0) { $0 + $1.rosadoPackages.getTotalPackages() }
    }
    
    var totalPardoPackages: Int {
        dailyStocks.reduce(0) { $0 + $1.pardoPackages.getTotalPackages() }
    }
    
    var averagePackagesPerDay: Int {
        guard !dailyStocks.isEmpty else { return 0 }
        return totalPackages / dailyStocks.count
    }
    
    var activeDays: Int {
        dailyStocks.filter { $0.totalPackages > 0 }.count
    }
    
    var rosadoPercentage: Double {
        guard totalPackages > 0 else { return 0 }
        return Double(totalRosadoPackages) / Double(totalPackages) * 100
    }
    
    var pardoPercentage: Double {
        guard totalPackages > 0 else { return 0 }
        return Double(totalPardoPackages) / Double(totalPackages) * 100
    }
    
    var hasRosadoData: Bool {
        totalRosadoPackages > 0
    }
    
    var hasPardoData: Bool {
        totalPardoPackages > 0
    }
    
    var chartData: [ChartDataPoint] {
        dailyStocks.map { stock in
            ChartDataPoint(
                date: ReportDateFormatter.chartFormat.date(from: stock.date) ?? Date(),
                totalPackages: stock.totalPackages,
                rosadoPackages: stock.rosadoPackages.getTotalPackages(),
                pardoPackages: stock.pardoPackages.getTotalPackages()
            )
        }.sorted { $0.date < $1.date }
    }
    
    var supplierData: [SupplierData] {
        let incomingEntries = cargoEntries.filter { $0.type == .incoming && !$0.supplier.isEmpty && $0.supplier != "Sistema" }
        let grouped = Dictionary(grouping: incomingEntries) { $0.supplier }
        
        return grouped.map { (supplier, entries) in
            let totalPackages = entries.reduce(0) { $0 + $1.totalPackages }
            let percentage = self.totalPackages > 0 ? Double(totalPackages) / Double(self.totalPackages) * 100 : 0
            
            return SupplierData(
                name: supplier,
                totalPackages: totalPackages,
                deliveries: entries.count,
                percentage: percentage
            )
        }.sorted { $0.totalPackages > $1.totalPackages }
    }
    
    var topSuppliers: [SupplierData] {
        Array(supplierData.prefix(5))
    }
    
    // Tendencias
    var packagesTrend: TrendDirection {
        guard dailyStocks.count >= 2 else { return .stable }
        let recent = Array(dailyStocks.suffix(3)).reduce(0) { $0 + $1.totalPackages }
        let previous = Array(dailyStocks.prefix(3)).reduce(0) { $0 + $1.totalPackages }
        
        if recent > Int(Double(previous) * 1.1) { return .up }
        else if recent < Int(Double(previous) * 0.9) { return .down }
        else { return .stable }
    }
    
    var weightTrend: TrendDirection {
        guard dailyStocks.count >= 2 else { return .stable }
        let recent = Array(dailyStocks.suffix(3)).reduce(0) { $0 + $1.totalWeight }
        let previous = Array(dailyStocks.prefix(3)).reduce(0) { $0 + $1.totalWeight }
        
        if recent > previous * 1.1 { return .up }
        else if recent < previous * 0.9 { return .down }
        else { return .stable }
    }
    
    var rosadoTrend: TrendDirection {
        guard dailyStocks.count >= 2 else { return .stable }
        let recent = Array(dailyStocks.suffix(3)).reduce(0) { $0 + $1.rosadoPackages.getTotalPackages() }
        let previous = Array(dailyStocks.prefix(3)).reduce(0) { $0 + $1.rosadoPackages.getTotalPackages() }
        
        if recent > Int(Double(previous) * 1.1) { return .up }
        else if recent < Int(Double(previous) * 0.9) { return .down }
        else { return .stable }
    }
    
    var pardoTrend: TrendDirection {
        guard dailyStocks.count >= 2 else { return .stable }
        let recent = Array(dailyStocks.suffix(3)).reduce(0) { $0 + $1.pardoPackages.getTotalPackages() }
        let previous = Array(dailyStocks.prefix(3)).reduce(0) { $0 + $1.pardoPackages.getTotalPackages() }
        
        if recent > Int(Double(previous) * 1.1) { return .up }
        else if recent < Int(Double(previous) * 0.9) { return .down }
        else { return .stable }
    }
    
    func getWeightDistribution(_ weight: Int) -> (rosado: Int, pardo: Int, total: Int) {
        let rosado = dailyStocks.reduce(0) { $0 + $1.rosadoPackages.getTotalForWeight(weight) }
        let pardo = dailyStocks.reduce(0) { $0 + $1.pardoPackages.getTotalForWeight(weight) }
        return (rosado: rosado, pardo: pardo, total: rosado + pardo)
    }
    
    var insights: [String] {
        var insights: [String] = []
        
        // Insight sobre el día más productivo
        if let bestDay = dailyStocks.max(by: { $0.totalPackages < $1.totalPackages }) {
            let dateString = ReportDateFormatter.displayFormat.string(from: ReportDateFormatter.dailyFormat.date(from: bestDay.date) ?? Date())
            insights.append("El día más productivo fue el \(dateString) con \(bestDay.totalPackages) paquetes")
        }
        
        // Insight sobre tendencia
        switch packagesTrend {
        case .up:
            insights.append("Se observa una tendencia positiva en la producción durante el período")
        case .down:
            insights.append("Se observa una disminución en la producción durante el período")
        case .stable:
            insights.append("La producción se mantiene estable durante el período")
        }
        
        // Insight sobre tipos de huevo
        if hasRosadoData && hasPardoData {
            if rosadoPercentage > 70 {
                insights.append("El huevo rosado representa el \(String(format: "%.0f", rosadoPercentage))% de la producción total")
            } else if pardoPercentage > 70 {
                insights.append("El huevo pardo representa el \(String(format: "%.0f", pardoPercentage))% de la producción total")
            } else {
                insights.append("Hay una distribución equilibrada entre huevo rosado (\(String(format: "%.0f", rosadoPercentage))%) y pardo (\(String(format: "%.0f", pardoPercentage))%)")
            }
        }
        
        // Insight sobre proveedores
        if !supplierData.isEmpty {
            let topSupplier = supplierData[0]
            insights.append("El proveedor principal es \(topSupplier.name) con \(topSupplier.totalPackages) paquetes (\(String(format: "%.1f", topSupplier.percentage))%)")
        }
        
        return insights
    }
    
    var recommendations: [String] {
        var recommendations: [String] = []
        
        // Recomendación basada en tendencia
        switch packagesTrend {
        case .down:
            recommendations.append("Considera revisar los procesos de producción para identificar oportunidades de mejora")
        case .up:
            recommendations.append("Mantén las prácticas actuales que están generando el crecimiento en producción")
        case .stable:
            recommendations.append("Explora oportunidades para optimizar y aumentar la eficiencia")
        }
        
        // Recomendación sobre diversificación
        if hasRosadoData && !hasPardoData {
            recommendations.append("Considera diversificar con huevo pardo para ampliar tu oferta")
        } else if !hasRosadoData && hasPardoData {
            recommendations.append("Considera diversificar con huevo rosado para ampliar tu oferta")
        }
        
        // Recomendación sobre proveedores
        if supplierData.count == 1 {
            recommendations.append("Considera diversificar proveedores para reducir riesgos de suministro")
        } else if supplierData.count > 5 {
            recommendations.append("Evalúa consolidar con los proveedores más eficientes para simplificar operaciones")
        }
        
        // Recomendación sobre días inactivos
        let inactiveDays = dailyStocks.count - activeDays
        if inactiveDays > 0 {
            recommendations.append("Hay \(inactiveDays) días sin actividad. Considera optimizar la programación de entregas")
        }
        
        return recommendations
    }
}

struct ChartDataPoint: Codable {
    let date: Date
    let totalPackages: Int
    let rosadoPackages: Int
    let pardoPackages: Int
}

struct SupplierData: Codable {
    let name: String
    let totalPackages: Int
    let deliveries: Int
    let percentage: Double
}

// MARK: - Extenciones de formato de fecha para Reportes
struct ReportDateFormatter {
    static let chartFormat: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()
    
    static let displayFormat: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd MMM"
        formatter.locale = Locale(identifier: "es_ES")
        return formatter
    }()
    
    static let dailyFormat: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()
}
