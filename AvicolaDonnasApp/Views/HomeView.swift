//
//  HomeView.swift
//  AvicolaDonnasApp
//
//  Created by Victor Martinez on 25/06/25.
//

import SwiftUI

struct HomeView: View {
    
    /*
     Variables
     */
    
    
    var body: some View {
        NavigationView {
            VStack {
                VStack {
                    Image("logoAvDonnas").resizable().frame(width: 200, height: 200).cornerRadius(100)
                    Text("Avicola Donna's").font(.system(size: 40, weight: .bold, design: .serif))
                    Divider().frame(width: 330)
                }.padding(.bottom, 40)
                VStack(spacing: 10) {
                    NavigationLink(destination: InventoryView()) {
                        Text("Ver Inventario")
                            .frame(width: 270, height: 50)
                            .background(.blue)
                            .font(.title)
                            .foregroundStyle(.white).bold()
                            .cornerRadius(8)
                    }
                    NavigationLink(destination: RegisterCargoView()) {
                        Text("Registrar Carga")
                            .frame(width: 270, height: 50)
                            .background(.yellow)
                            .font(.title)
                            .foregroundStyle(.white).bold()
                            .cornerRadius(8)
                    }
                    NavigationLink(destination: RegisterEndDayView()) {
                        Text("Registrar Fin de Día")
                            .frame(width: 270, height: 50)
                            .background(.gray)
                            .font(.title)
                            .foregroundStyle(.white).bold()
                            .cornerRadius(8)
                    }
                }
            }
        }.navigationBarHidden(true)
    }
}

#Preview {
    HomeView()
}
