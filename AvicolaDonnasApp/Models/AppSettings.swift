//
//  AppSettings.swift
//  AvicolaDonnasApp
//
//  Created by Victor Martinez on 26/06/25.
//

import Foundation

// MARK: - Modelo para configuración de la app
struct AppSettings: Codable {
    var currentDate: String
    var isFirstLaunch: Bool
    var lastBackupDate: Date?
    var autoBackupEnabled: Bool
    var companyName: String
    var companyLogo: String?
    var frequentSuppliers: [String]
    var defaultEggType: EggType
    var showBothEggTypes: Bool
    
    init() {
        self.currentDate = DateFormatter.dailyFormat.string(from: Date())
        self.isFirstLaunch = true
        self.lastBackupDate = nil
        self.autoBackupEnabled = true
        self.companyName = "Avícola Donna's"
        self.companyLogo = nil
        self.frequentSuppliers = []
        self.defaultEggType = .rosado
        self.showBothEggTypes = false
    }
}

// MARK: - Extensiones para Date formatting
extension DateFormatter {
    static let dailyFormat: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()
    
    static let displayFormat: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd/MM/yyyy"
        formatter.locale = Locale(identifier: "es_ES")
        return formatter
    }()
    
    static let timestampFormat: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd/MM/yyyy HH:mm:ss"
        formatter.locale = Locale(identifier: "es_ES")
        return formatter
    }()
}

// MARK: - Extensiones de utilidad
extension Date {
    var dailyString: String {
        return DateFormatter.dailyFormat.string(from: self)
    }
    
    var displayString: String {
        return DateFormatter.displayFormat.string(from: self)
    }
    
    var timestampString: String {
        return DateFormatter.timestampFormat.string(from: self)
    }
}
