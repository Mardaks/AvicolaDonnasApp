//
//  HomeView.swift
//  AvicolaDonnasApp
//
//  Created by Victor Martinez on 25/06/25.
//

import SwiftUI
import FirebaseFirestore

struct HomeView: View {
    
    var body: some View {
        NavigationView {
            VStack {
                VStack {
                    Image("logoAvDonnas")
                        .resizable()
                        .frame(width: 200, height: 200)
                        .cornerRadius(100)
                    Text("Avícola Donna's")
                        .font(.system(size: 40, weight: .bold, design: .serif))
                    Divider().frame(width: 330)
                }.padding(.bottom, 40)
                
                VStack(spacing: 15) {
                    NavigationLink(destination: CurrentStockView()) {
                        Text("Stock Actual")
                            .frame(width: 270, height: 50)
                            .background(.blue)
                            .font(.title2)
                            .foregroundStyle(.white)
                            .bold()
                            .cornerRadius(8)
                    }
                    
                    NavigationLink(destination: RegisterCargoView()) {
                        Text("Registrar Carga")
                            .frame(width: 270, height: 50)
                            .background(.green)
                            .font(.title2)
                            .foregroundStyle(.white)
                            .bold()
                            .cornerRadius(8)
                    }
                    
                    NavigationLink(destination: HistoryView()) {
                        Text("Historial de Inventario")
                            .frame(width: 270, height: 50)
                            .background(.orange)
                            .font(.title2)
                            .foregroundStyle(.white)
                            .bold()
                            .cornerRadius(8)
                    }
                    
                    NavigationLink(destination: RegisterEndDayView()) {
                        Text("Registrar Fin de Día")
                            .frame(width: 270, height: 50)
                            .background(.red)
                            .font(.title2)
                            .foregroundStyle(.white)
                            .bold()
                            .cornerRadius(8)
                    }
                    
                    NavigationLink(destination: ReportsView()) {
                        Text("Reportes")
                            .frame(width: 270, height: 50)
                            .background(.purple)
                            .font(.title2)
                            .foregroundStyle(.white)
                            .bold()
                            .cornerRadius(8)
                    }
                }
            }
        }
        .onAppear {
            Task {                
                // Probar Firebase
                do {
                    let testData = ["test": "hello firebase", "timestamp": Date()]
                    try await Firestore.firestore().collection("test").addDocument(data: testData)
                    print("✅ Firebase funciona!")
                } catch {
                    print("❌ Error Firebase: \(error)")
                }
            }
        }
        .navigationBarHidden(true)
    }
}

#Preview {
    HomeView()
}
