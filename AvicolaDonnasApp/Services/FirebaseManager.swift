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
    
    // MARK: - Firestore Methods
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
}
