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
    
    // MARK: - Auth Methods
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
    
    // MARK: - Generic Firestore Methods
    func save<T: Codable>(_ object: T, to collection: String, documentId: String? = nil) async throws {
        let data = try Firestore.Encoder().encode(object)
        
        if let documentId = documentId {
            try await firestore.collection(collection).document(documentId).setData(data)
        } else {
            try await firestore.collection(collection).addDocument(data: data)
        }
    }

    func fetch<T: Codable>(_ type: T.Type, from collection: String, documentId: String) async throws -> T {
        let document = try await firestore.collection(collection).document(documentId).getDocument()
        
        guard document.exists else {
            throw NSError(domain: "FirebaseManager", code: 404, userInfo: [NSLocalizedDescriptionKey: "Document not found"])
        }
        
        // ✅ USAR document.data(as:) EN LUGAR DE Firestore.Decoder().decode
        return try document.data(as: type)
    }

    func fetchAll<T: Codable>(_ type: T.Type, from collection: String) async throws -> [T] {
        let snapshot = try await firestore.collection(collection).getDocuments()
        
        var results: [T] = []
        
        for document in snapshot.documents {
            do {
                // ✅ USAR document.data(as:) EN LUGAR DE Firestore.Decoder().decode
                let item = try document.data(as: type)
                results.append(item)
            } catch {
                print("❌ Error decodificando documento \(document.documentID): \(error)")
                // Continuar con los demás documentos
            }
        }
        
        return results
    }
    
    // MARK: - Métodos específicos para DailyStock
    func saveDailyStock(_ stock: DailyStock) async throws {
        guard let date = stock.id ?? stock.date as String? else {
            throw NSError(domain: "FirebaseManager", code: 400, userInfo: [NSLocalizedDescriptionKey: "Date is required"])
        }
        try await save(stock, to: "daily_stocks", documentId: date)
    }
    
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
    
    // MARK: - Métodos específicos para CargoEntry
    // GUARDAR - Sin cambios, funciona bien
    func saveCargoEntry(_ entry: CargoEntry) async throws {
        print("📤 Guardando CargoEntry...")
        try await save(entry, to: "cargo_entries")
        print("✅ CargoEntry guardado exitosamente")
    }

    // ✅ CONSULTA CORREGIDA - Usar Firestore.Decoder
    func fetchCargoEntries(for date: String) async throws -> [CargoEntry] {
        print("📍 Buscando CargoEntries para fecha: \(date)")
        
        let snapshot = try await firestore.collection("cargo_entries")
            .whereField("date", isEqualTo: date)
            .getDocuments()
        
        print("📍 Encontrados \(snapshot.documents.count) documentos")
        
        var entries: [CargoEntry] = []
        
        for document in snapshot.documents {
            do {
                // ✅ USAR FIRESTORE.DECODER - NO document.data()
                let entry = try document.data(as: CargoEntry.self)
                entries.append(entry)
                print("✅ CargoEntry decodificado: \(entry.supplier)")
            } catch {
                print("❌ Error decodificando CargoEntry: \(error)")
                // Continuar con los demás documentos
            }
        }
        
        // Ordenar por timestamp
        return entries.sorted { $0.timestamp > $1.timestamp }
    }

    // ✅ CONSULTA CORREGIDA - Usar Firestore.Decoder
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
                // ✅ USAR FIRESTORE.DECODER - NO document.data()
                let entry = try document.data(as: CargoEntry.self)
                entries.append(entry)
            } catch {
                print("❌ Error decodificando CargoEntry en rango: \(error)")
                // Continuar con los demás documentos
            }
        }
        
        return entries.sorted { $0.timestamp > $1.timestamp }
    }

    // ✅ CONSULTA CORREGIDA - Usar Firestore.Decoder
    func fetchAllCargoEntries() async throws -> [CargoEntry] {
        print("📍 Buscando todos los CargoEntries")
        
        let snapshot = try await firestore.collection("cargo_entries")
            .order(by: "timestamp", descending: true)
            .getDocuments()
        
        print("📍 Encontrados \(snapshot.documents.count) documentos totales")
        
        var entries: [CargoEntry] = []
        
        for document in snapshot.documents {
            do {
                // ✅ USAR FIRESTORE.DECODER - NO document.data()
                let entry = try document.data(as: CargoEntry.self)
                entries.append(entry)
            } catch {
                print("❌ Error decodificando CargoEntry (todos): \(error)")
                // Continuar con los demás documentos
            }
        }
        
        return entries
    }

    // ✅ NUEVO MÉTODO - Para obtener estadísticas del día
    func fetchCargoEntriesStats(for date: String) async throws -> (movementCount: Int, uniqueSuppliers: Int) {
        print("📊 Obteniendo estadísticas para fecha: \(date)")
        
        let entries = try await fetchCargoEntries(for: date)
        
        let movementCount = entries.count
        let uniqueSuppliers = Set(entries.map { $0.supplier }).count
        
        print("📊 Estadísticas: \(movementCount) movimientos, \(uniqueSuppliers) proveedores únicos")
        
        return (movementCount: movementCount, uniqueSuppliers: uniqueSuppliers)
    }
    
    // MARK: - Métodos para AppSettings
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
    
    // MARK: - Storage Methods
    func uploadImage(_ imageData: Data, path: String) async throws -> String {
        let storageRef = storage.reference().child(path)
        let _ = try await storageRef.putDataAsync(imageData)
        let downloadURL = try await storageRef.downloadURL()
        return downloadURL.absoluteString
    }
    
    func downloadImage(from url: String) async throws -> Data {
        let storageRef = storage.reference(forURL: url)
        let data = try await storageRef.data(maxSize: 10 * 1024 * 1024) // 10MB max
        return data
    }
    
    // MARK: - Utility Methods
    func deleteDocument(from collection: String, documentId: String) async throws {
        try await firestore.collection(collection).document(documentId).delete()
    }
    
    func updateDocument<T: Codable>(_ object: T, in collection: String, documentId: String) async throws {
        let data = try Firestore.Encoder().encode(object)
        try await firestore.collection(collection).document(documentId).updateData(data)
    }
}
