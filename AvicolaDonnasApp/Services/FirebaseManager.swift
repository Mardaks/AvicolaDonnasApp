//
//  FirebaseManager.swift
//  AvicolaDonnasApp
//
//  Created by Victor Martinez on 4/06/25.
//

import Foundation
import Firebase
import FirebaseAuth
import FirebaseFirestore
import FirebaseStorage

// MARK: - 🔥 Servicio Central de Comunicación con Firebase
/// Maneja TODA la comunicación con la base de datos
/// Patrón Singleton: una sola instancia para toda la app
final class FirebaseManager: ObservableObject {
    static let shared = FirebaseManager()
    
    let auth: Auth
    let firestore: Firestore
    let storage: Storage
    
    private init() {
        self.auth = Auth.auth()
        self.firestore = Firestore.firestore()
        self.storage = Storage.storage()
    }
    
    // MARK: - 🔐 Sistema de Autenticación (Preparado para Futuro)
    /// Métodos preparados para cuando se implemente login/registro
    func signIn(email: String, password: String) async throws -> AuthDataResult {
        return try await auth.signIn(withEmail: email, password: password)
    }
    
    func signUp(email: String, password: String) async throws -> AuthDataResult {
        return try await auth.createUser(withEmail: email, password: password)
    }
    
    func signOut() throws {
        try auth.signOut()
    }
    
    var currentUser: User? {
        return auth.currentUser
    }
    
    // MARK: - ⚡ Métodos Genéricos Reutilizables
    /// Guarda cualquier objeto que implemente Codable en Firebase
    /// Este diseño permite agregar nuevos modelos sin duplicar código
    func save<T: Codable>(_ object: T, to collection: String, documentId: String? = nil) async throws {
        let data = try Firestore.Encoder().encode(object)
        
        if let documentId = documentId {
            try await firestore.collection(collection).document(documentId).setData(data)
        } else {
            try await firestore.collection(collection).addDocument(data: data)
        }
    }

    /// Obtiene un documento específico y lo convierte al tipo deseado
    func fetch<T: Codable>(_ type: T.Type, from collection: String, documentId: String) async throws -> T {
        let document = try await firestore.collection(collection).document(documentId).getDocument()
        
        guard document.exists else {
            throw NSError(domain: "FirebaseManager", code: 404, userInfo: [NSLocalizedDescriptionKey: "Document not found"])
        }
        
        return try document.data(as: type)
    }

    /// Obtiene toda una colección con manejo robusto de errores
    /// Si un documento falla, continúa con los demás
    func fetchAll<T: Codable>(_ type: T.Type, from collection: String) async throws -> [T] {
        let snapshot = try await firestore.collection(collection).getDocuments()
        
        var results: [T] = []
        
        for document in snapshot.documents {
            do {
                let item = try document.data(as: type)
                results.append(item)
            } catch {
                print("❌ Error decodificando documento \(document.documentID): \(error)")
            }
        }
        
        return results
    }
    
    // MARK: - 📦 Métodos Especializados para Stock Diario
    /// Guarda el stock usando la fecha como ID único del documento
    func saveDailyStock(_ stock: DailyStock) async throws {
        guard let date = stock.id ?? stock.date as String? else {
            throw NSError(domain: "FirebaseManager", code: 400, userInfo: [NSLocalizedDescriptionKey: "La fecha es obligatoria"])
        }
        try await save(stock, to: "daily_stocks", documentId: date)
    }
    
    /// Busca el stock de una fecha específica
    /// Retorna nil si no existe (día sin actividad)
    func fetchDailyStock(for date: String) async throws -> DailyStock? {
        do {
            let document = try await firestore.collection("daily_stocks").document(date).getDocument()
            
            guard document.exists else {
                print("📍 No existe documento para fecha: \(date)")
                return nil
            }
            
            print("📍 Documento encontrado, decodificando...")
            let stock = try document.data(as: DailyStock.self)
            print("✅ Stock decodificado exitosamente")
            return stock
            
        } catch {
            print("❌ Error específico en fetchDailyStock: \(error)")
            return nil
        }
    }
    
    /// Obtiene stocks en un rango de fechas para reportes
    /// Usa query compuesto con ordenamiento automático
    func fetchDailyStocks(from startDate: String, to endDate: String) async throws -> [DailyStock] {
        let snapshot = try await firestore.collection("daily_stocks")
            .whereField("date", isGreaterThanOrEqualTo: startDate)
            .whereField("date", isLessThanOrEqualTo: endDate)
            .order(by: "date")
            .getDocuments()
        
        return snapshot.documents.compactMap { document in
            do {
                return try document.data(as: DailyStock.self)
            } catch {
                print("❌ Error decodificando DailyStock en rango: \(error)")
                return nil
            }
        }
    }
    
    /// Obtiene todo el historial ordenado por fecha descendente
    func fetchAllDailyStocks() async throws -> [DailyStock] {
        let snapshot = try await firestore.collection("daily_stocks")
            .order(by: "date", descending: true)
            .getDocuments()
        
        return snapshot.documents.compactMap { document in
            do {
                return try document.data(as: DailyStock.self)
            } catch {
                print("❌ Error decodificando DailyStock: \(error)")
                return nil
            }
        }
    }
    
    // MARK: - 📋 Métodos para Movimientos de Carga
    /// Guarda un nuevo movimiento (entrada/salida/ajuste)
    func saveCargoEntry(_ entry: CargoEntry) async throws {
        print("📤 Guardando CargoEntry...")
        try await save(entry, to: "cargo_entries")
        print("✅ CargoEntry guardado exitosamente")
    }

    /// Obtiene todos los movimientos de una fecha específica
    /// Ordenados por timestamp (más reciente primero)
    func fetchCargoEntries(for date: String) async throws -> [CargoEntry] {
        print("📍 Buscando CargoEntries para fecha: \(date)")
        
        let snapshot = try await firestore.collection("cargo_entries")
            .whereField("date", isEqualTo: date)
            .getDocuments()
        
        print("📍 Encontrados \(snapshot.documents.count) documentos")
        
        var entries: [CargoEntry] = []
        
        for document in snapshot.documents {
            do {
                let entry = try document.data(as: CargoEntry.self)
                entries.append(entry)
                print("✅ CargoEntry decodificado: \(entry.supplier)")
            } catch {
                print("❌ Error decodificando CargoEntry: \(error)")
            }
        }
        
        // Ordenar por timestamp (más reciente primero)
        return entries.sorted { $0.timestamp > $1.timestamp }
    }

    /// Obtiene movimientos en rango de fechas para reportes avanzados
    func fetchCargoEntries(from startDate: String, to endDate: String) async throws -> [CargoEntry] {
        print("📍 Buscando CargoEntries desde \(startDate) hasta \(endDate)")
        
        let snapshot = try await firestore.collection("cargo_entries")
            .whereField("date", isGreaterThanOrEqualTo: startDate)
            .whereField("date", isLessThanOrEqualTo: endDate)
            .order(by: "date")
            .getDocuments()
        
        print("📍 Encontrados \(snapshot.documents.count) documentos en rango")
        
        var entries: [CargoEntry] = []
        
        for document in snapshot.documents {
            do {
                let entry = try document.data(as: CargoEntry.self)
                entries.append(entry)
            } catch {
                print("❌ Error decodificando CargoEntry en rango: \(error)")
            }
        }
        
        return entries.sorted { $0.timestamp > $1.timestamp }
    }

    /// Obtiene todo el historial de movimientos
    func fetchAllCargoEntries() async throws -> [CargoEntry] {
        print("📍 Buscando todos los CargoEntries")
        
        let snapshot = try await firestore.collection("cargo_entries")
            .order(by: "timestamp", descending: true)
            .getDocuments()
        
        print("📍 Encontrados \(snapshot.documents.count) documentos totales")
        
        var entries: [CargoEntry] = []
        
        for document in snapshot.documents {
            do {
                let entry = try document.data(as: CargoEntry.self)
                entries.append(entry)
            } catch {
                print("❌ Error decodificando CargoEntry (todos): \(error)")
            }
        }
        
        return entries
    }

    /// Calcula estadísticas rápidas para el dashboard
    /// Ejemplo de procesamiento eficiente de datos
    func fetchCargoEntriesStats(for date: String) async throws -> (movementCount: Int, uniqueSuppliers: Int) {
        print("📊 Obteniendo estadísticas para fecha: \(date)")
        
        let entries = try await fetchCargoEntries(for: date)
        
        let movementCount = entries.count
        let uniqueSuppliers = Set(entries.map { $0.supplier }).count
        
        print("📊 Estadísticas: \(movementCount) movimientos, \(uniqueSuppliers) proveedores únicos")
        
        return (movementCount: movementCount, uniqueSuppliers: uniqueSuppliers)
    }
    
    // MARK: - ⚙️ Métodos para Configuración de la App
    func saveAppSettings(_ settings: AppSettings) async throws {
        try await save(settings, to: "app_settings", documentId: "main")
    }
    
    func fetchAppSettings() async throws -> AppSettings? {
        do {
            return try await fetch(AppSettings.self, from: "app_settings", documentId: "main")
        } catch {
            return nil
        }
    }
    
    // MARK: - 🖼️ Métodos de Almacenamiento de Archivos
    func uploadImage(_ imageData: Data, path: String) async throws -> String {
        let storageRef = storage.reference().child(path)
        let _ = try await storageRef.putDataAsync(imageData)
        let downloadURL = try await storageRef.downloadURL()
        return downloadURL.absoluteString
    }
    
    func downloadImage(from url: String) async throws -> Data {
        let storageRef = storage.reference(forURL: url)
        let data = try await storageRef.data(maxSize: 10 * 1024 * 1024)
        return data
    }
    
    // MARK: - 🛠️ Métodos de Utilidad General
    func deleteDocument(from collection: String, documentId: String) async throws {
        try await firestore.collection(collection).document(documentId).delete()
    }
    
    func updateDocument<T: Codable>(_ object: T, in collection: String, documentId: String) async throws {
        let data = try Firestore.Encoder().encode(object)
        try await firestore.collection(collection).document(documentId).updateData(data)
    }
}
