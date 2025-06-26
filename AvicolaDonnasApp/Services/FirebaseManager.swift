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
        
        guard let data = document.data() else {
            throw NSError(domain: "FirebaseManager", code: 404, userInfo: [NSLocalizedDescriptionKey: "Document not found"])
        }
        
        return try Firestore.Decoder().decode(type, from: data)
    }
    
    func fetchAll<T: Codable>(_ type: T.Type, from collection: String) async throws -> [T] {
        let snapshot = try await firestore.collection(collection).getDocuments()
        
        return try snapshot.documents.compactMap { document in
            try Firestore.Decoder().decode(type, from: document.data())
        }
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
            return try await fetch(DailyStock.self, from: "daily_stocks", documentId: date)
        } catch {
            // Si no existe el documento, retornar nil en lugar de error
            return nil
        }
    }
    
    func fetchDailyStocks(from startDate: String, to endDate: String) async throws -> [DailyStock] {
        let snapshot = try await firestore.collection("daily_stocks")
            .whereField("date", isGreaterThanOrEqualTo: startDate)
            .whereField("date", isLessThanOrEqualTo: endDate)
            .order(by: "date")
            .getDocuments()
        
        return try snapshot.documents.compactMap { document in
            try Firestore.Decoder().decode(DailyStock.self, from: document.data())
        }
    }
    
    func fetchAllDailyStocks() async throws -> [DailyStock] {
        let snapshot = try await firestore.collection("daily_stocks")
            .order(by: "date", descending: true)
            .getDocuments()
        
        return try snapshot.documents.compactMap { document in
            try Firestore.Decoder().decode(DailyStock.self, from: document.data())
        }
    }
    
    // MARK: - Métodos específicos para CargoEntry
    // GUARDAR - Sin cambios, funciona bien
    func saveCargoEntry(_ entry: CargoEntry) async throws {
        try await save(entry, to: "cargo_entries")
    }

    // CONSULTA SIMPLIFICADA - Solo por fecha (SIN ORDENAR)
    func fetchCargoEntries(for date: String) async throws -> [CargoEntry] {
        let snapshot = try await firestore.collection("cargo_entries")
            .whereField("date", isEqualTo: date)
            .getDocuments()
        
        return try snapshot.documents.compactMap { document in
            try Firestore.Decoder().decode(CargoEntry.self, from: document.data())
        }.sorted { $0.timestamp > $1.timestamp } // Ordenar en Swift por ahora
    }

    // CONSULTA SIMPLIFICADA - Sin filtros de rango, traer todo y filtrar en Swift
    func fetchCargoEntries(from startDate: String, to endDate: String) async throws -> [CargoEntry] {
        let snapshot = try await firestore.collection("cargo_entries")
            .getDocuments()
        
        return try snapshot.documents.compactMap { document in
            try Firestore.Decoder().decode(CargoEntry.self, from: document.data())
        }.filter { entry in
            entry.date >= startDate && entry.date <= endDate
        }.sorted { $0.timestamp > $1.timestamp }
    }

    // CONSULTA SIMPLIFICADA - Traer todo sin ordenar
    func fetchAllCargoEntries() async throws -> [CargoEntry] {
        let snapshot = try await firestore.collection("cargo_entries")
            .getDocuments()
        
        return try snapshot.documents.compactMap { document in
            try Firestore.Decoder().decode(CargoEntry.self, from: document.data())
        }.sorted { $0.timestamp > $1.timestamp }
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
