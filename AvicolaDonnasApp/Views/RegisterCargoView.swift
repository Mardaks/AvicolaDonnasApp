//
//  RegisterCargoView.swift
//  AvicolaDonnasApp
//
//  Created by Victor Martinez on 25/06/25.
//

import SwiftUI

struct RegisterCargoView: View {
    
    // Paquetes de 7 kg
    @State private var sieteCero: Int = 0
    @State private var sieteUno: Int = 0
    @State private var sieteDos: Int = 0
    @State private var sieteTres: Int = 0
    @State private var sieteCuatro: Int = 0
    @State private var sieteCinco: Int = 0
    @State private var sieteSeis: Int = 0
    @State private var sieteSiete: Int = 0
    @State private var sieteOcho: Int = 0
    @State private var sieteNueve: Int = 0
    
    // Paquetes de 8 kg
    @State private var ochoCero: Int = 0
    @State private var ochoUno: Int = 0
    @State private var ochoDos: Int = 0
    @State private var ochoTres: Int = 0
    @State private var ochoCuatro: Int = 0
    @State private var ochoCinco: Int = 0
    @State private var ochoSeis: Int = 0
    @State private var ochoSiete: Int = 0
    @State private var ochoOcho: Int = 0
    @State private var ochoNueve: Int = 0
    
    // Paquetes de 9 kg
    @State private var nueveCero: Int = 0
    @State private var nueveUno: Int = 0
    @State private var nueveDos: Int = 0
    @State private var nueveTres: Int = 0
    @State private var nueveCuatro: Int = 0
    @State private var nueveCinco: Int = 0
    @State private var nueveSeis: Int = 0
    @State private var nueveSiete: Int = 0
    @State private var nueveOcho: Int = 0
    @State private var nueveNueve: Int = 0
    
    // Paquetes de 10 kg
    @State private var diezCero: Int = 0
    @State private var diezUno: Int = 0
    @State private var diezDos: Int = 0
    @State private var diezTres: Int = 0
    @State private var diezCuatro: Int = 0
    @State private var diezCinco: Int = 0
    @State private var diezSeis: Int = 0
    @State private var diezSiete: Int = 0
    @State private var diezOcho: Int = 0
    @State private var diezNueve: Int = 0
    
    // Paquetes de 11 kg
    @State private var onceCero: Int = 0
    @State private var onceUno: Int = 0
    @State private var onceDos: Int = 0
    @State private var onceTres: Int = 0
    @State private var onceCuatro: Int = 0
    @State private var onceCinco: Int = 0
    @State private var onceSeis: Int = 0
    @State private var onceSiete: Int = 0
    @State private var onceOcho: Int = 0
    @State private var onceNueve: Int = 0
    
    // Paquetes de 12 kg
    @State private var doceCero: Int = 0
    @State private var doceUno: Int = 0
    @State private var doceDos: Int = 0
    @State private var doceTres: Int = 0
    @State private var doceCuatro: Int = 0
    @State private var doceCinco: Int = 0
    @State private var doceSeis: Int = 0
    @State private var doceSiete: Int = 0
    @State private var doceOcho: Int = 0
    @State private var doceNueve: Int = 0
    
    var body: some View {
        Form {
            Section("Paquetes de 9 kg") {
                HStack {
                    Text("Paquete 9.0:")
                    Spacer()
                    TextField("0", value: $nueveCero, format: .number)
                        .keyboardType(.numberPad)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .frame(width: 50)
                }
                HStack {
                    Text("Paquete 9.1:")
                    Spacer()
                    TextField("0", value: $nueveUno, format: .number)
                        .keyboardType(.numberPad)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .frame(width: 50)
                }
                HStack {
                    Text("Paquete 9.2:")
                    Spacer()
                    TextField("0", value: $nueveDos, format: .number)
                        .keyboardType(.numberPad)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .frame(width: 50)
                }
                HStack {
                    Text("Paquete 9.3:")
                    Spacer()
                    TextField("0", value: $nueveTres, format: .number)
                        .keyboardType(.numberPad)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .frame(width: 50)
                }
                HStack {
                    Text("Paquete 9.4:")
                    Spacer()
                    TextField("0", value: $nueveCuatro, format: .number)
                        .keyboardType(.numberPad)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .frame(width: 50)
                }
                HStack {
                    Text("Paquete 9.5:")
                    Spacer()
                    TextField("0", value: $nueveCinco, format: .number)
                        .keyboardType(.numberPad)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .frame(width: 50)
                }
                HStack {
                    Text("Paquete 9.6:")
                    Spacer()
                    TextField("0", value: $nueveSeis, format: .number)
                        .keyboardType(.numberPad)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .frame(width: 50)
                }
                HStack {
                    Text("Paquete 9.7:")
                    Spacer()
                    TextField("0", value: $nueveSiete, format: .number)
                        .keyboardType(.numberPad)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .frame(width: 50)
                }
                HStack {
                    Text("Paquete 9.8:")
                    Spacer()
                    TextField("0", value: $nueveOcho, format: .number)
                        .keyboardType(.numberPad)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .frame(width: 50)
                }
                HStack {
                    Text("Paquete 9.9:")
                    Spacer()
                    TextField("0", value: $nueveNueve, format: .number)
                        .keyboardType(.numberPad)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .frame(width: 50)
                }
            }
            Section("Paquetes de 10 kg") {
                HStack {
                    Text("Paquete 10.0:")
                    Spacer()
                    TextField("0", value: $diezCero, format: .number)
                        .keyboardType(.numberPad)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .frame(width: 50)
                }
                HStack {
                    Text("Paquete 10.1:")
                    Spacer()
                    TextField("0", value: $diezUno, format: .number)
                        .keyboardType(.numberPad)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .frame(width: 50)
                }
                HStack {
                    Text("Paquete 10.2:")
                    Spacer()
                    TextField("0", value: $diezDos, format: .number)
                        .keyboardType(.numberPad)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .frame(width: 50)
                }
                HStack {
                    Text("Paquete 10.3:")
                    Spacer()
                    TextField("0", value: $diezTres, format: .number)
                        .keyboardType(.numberPad)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .frame(width: 50)
                }
                HStack {
                    Text("Paquete 10.4:")
                    Spacer()
                    TextField("0", value: $diezCuatro, format: .number)
                        .keyboardType(.numberPad)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .frame(width: 50)
                }
                HStack {
                    Text("Paquete 10.5:")
                    Spacer()
                    TextField("0", value: $diezCinco, format: .number)
                        .keyboardType(.numberPad)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .frame(width: 50)
                }
                HStack {
                    Text("Paquete 10.6:")
                    Spacer()
                    TextField("0", value: $diezSeis, format: .number)
                        .keyboardType(.numberPad)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .frame(width: 50)
                }
                HStack {
                    Text("Paquete 10.7:")
                    Spacer()
                    TextField("0", value: $diezSiete, format: .number)
                        .keyboardType(.numberPad)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .frame(width: 50)
                }
                HStack {
                    Text("Paquete 10.8:")
                    Spacer()
                    TextField("0", value: $diezOcho, format: .number)
                        .keyboardType(.numberPad)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .frame(width: 50)
                }
                HStack {
                    Text("Paquete 10.9:")
                    Spacer()
                    TextField("0", value: $diezNueve, format: .number)
                        .keyboardType(.numberPad)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .frame(width: 50)
                }
            }
            Section("Paquetes de 11 kg") {
                HStack {
                    Text("Paquete 11.0:")
                    Spacer()
                    TextField("0", value: $onceCero, format: .number)
                        .keyboardType(.numberPad)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .frame(width: 50)
                }
                HStack {
                    Text("Paquete 11.1:")
                    Spacer()
                    TextField("0", value: $onceUno, format: .number)
                        .keyboardType(.numberPad)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .frame(width: 50)
                }
                HStack {
                    Text("Paquete 11.2:")
                    Spacer()
                    TextField("0", value: $onceDos, format: .number)
                        .keyboardType(.numberPad)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .frame(width: 50)
                }
                HStack {
                    Text("Paquete 11.3:")
                    Spacer()
                    TextField("0", value: $onceTres, format: .number)
                        .keyboardType(.numberPad)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .frame(width: 50)
                }
                HStack {
                    Text("Paquete 11.4:")
                    Spacer()
                    TextField("0", value: $onceCuatro, format: .number)
                        .keyboardType(.numberPad)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .frame(width: 50)
                }
                HStack {
                    Text("Paquete 11.5:")
                    Spacer()
                    TextField("0", value: $onceCinco, format: .number)
                        .keyboardType(.numberPad)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .frame(width: 50)
                }
                HStack {
                    Text("Paquete 11.6:")
                    Spacer()
                    TextField("0", value: $onceSeis, format: .number)
                        .keyboardType(.numberPad)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .frame(width: 50)
                }
                HStack {
                    Text("Paquete 11.7:")
                    Spacer()
                    TextField("0", value: $onceSiete, format: .number)
                        .keyboardType(.numberPad)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .frame(width: 50)
                }
                HStack {
                    Text("Paquete 11.8:")
                    Spacer()
                    TextField("0", value: $onceOcho, format: .number)
                        .keyboardType(.numberPad)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .frame(width: 50)
                }
                HStack {
                    Text("Paquete 11.9:")
                    Spacer()
                    TextField("0", value: $onceNueve, format: .number)
                        .keyboardType(.numberPad)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .frame(width: 50)
                }
            }
            Section("Paquetes de 12 kg") {
                HStack {
                    Text("Paquete 12.0:")
                    Spacer()
                    TextField("0", value: $doceCero, format: .number)
                        .keyboardType(.numberPad)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .frame(width: 50)
                }
                HStack {
                    Text("Paquete 12.1:")
                    Spacer()
                    TextField("0", value: $doceUno, format: .number)
                        .keyboardType(.numberPad)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .frame(width: 50)
                }
                HStack {
                    Text("Paquete 12.2:")
                    Spacer()
                    TextField("0", value: $doceDos, format: .number)
                        .keyboardType(.numberPad)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .frame(width: 50)
                }
                HStack {
                    Text("Paquete 12.3:")
                    Spacer()
                    TextField("0", value: $doceTres, format: .number)
                        .keyboardType(.numberPad)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .frame(width: 50)
                }
                HStack {
                    Text("Paquete 12.4:")
                    Spacer()
                    TextField("0", value: $doceCuatro, format: .number)
                        .keyboardType(.numberPad)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .frame(width: 50)
                }
                HStack {
                    Text("Paquete 12.5:")
                    Spacer()
                    TextField("0", value: $doceCinco, format: .number)
                        .keyboardType(.numberPad)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .frame(width: 50)
                }
                HStack {
                    Text("Paquete 12.6:")
                    Spacer()
                    TextField("0", value: $doceSeis, format: .number)
                        .keyboardType(.numberPad)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .frame(width: 50)
                }
                HStack {
                    Text("Paquete 12.7:")
                    Spacer()
                    TextField("0", value: $doceSiete, format: .number)
                        .keyboardType(.numberPad)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .frame(width: 50)
                }
                HStack {
                    Text("Paquete 12.8:")
                    Spacer()
                    TextField("0", value: $doceOcho, format: .number)
                        .keyboardType(.numberPad)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .frame(width: 50)
                }
                HStack {
                    Text("Paquete 12.9:")
                    Spacer()
                    TextField("0", value: $doceNueve, format: .number)
                        .keyboardType(.numberPad)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .frame(width: 50)
                }
            }
        }
        .navigationTitle("Registrar Paquetes")
    }
}

#Preview {
    RegisterCargoView()
}
