//
//  RegisterCargoView.swift
//  AvicolaDonnasApp
//
//  Created by Victor Martinez on 25/06/25.
//

import SwiftUI

struct RegisterCargoView: View {
    
    // MARK: - 📊 Estructura de Datos Personalizada para UI
    /// Organiza los paquetes por categorías de peso para facilitar la entrada
    struct PackageCategory {
        var weight: Int
        var name: String
        var packages: [Int] // Array de 10 elementos (0-9)
        var isVisible: Bool = false
        
        init(weight: Int) {
            self.weight = weight
            self.name = "Paquetes de \(weight) kg"
            self.packages = Array(repeating: 0, count: 10)
        }
    }
    
    // MARK: - 🥚 Estados Separados por Tipo de Huevo
    /// Cada tipo tiene su propio conjunto de categorías de peso
    @State private var rosadoPackageCategories: [PackageCategory] = [
        PackageCategory(weight: 7),
        PackageCategory(weight: 8),
        PackageCategory(weight: 9),
        PackageCategory(weight: 10),
        PackageCategory(weight: 11),
        PackageCategory(weight: 12),
        PackageCategory(weight: 13)
    ]
    
    /// Estados para huevo pardo
    @State private var pardoPackageCategories: [PackageCategory] = [
        PackageCategory(weight: 7),
        PackageCategory(weight: 8),
        PackageCategory(weight: 9),
        PackageCategory(weight: 10),
        PackageCategory(weight: 11),
        PackageCategory(weight: 12),
        PackageCategory(weight: 13)
    ]
    
    // MARK: - 🎛️ Controles de la Interfaz
    @State private var includePardoEggs = false         // Toggle para incluir huevo pardo
    @State private var lastSavedTotal = 0               // Ultimo total guardado
    @State private var supplier = ""                    // Proveedor seleccionado
    @State private var notes = ""                       // Notas opcionales
    @State private var showingSupplierSheet = false     // Modal de seleccion de proveedor
    @State private var showingSaveConfirmation = false  // Confirmacion antes de guardar
    @State private var showingSuccessAlert = false      // Alerta de exito
    @State private var isLoading = false                // Estado de cargo
    
    @ObservedObject private var stockViewModel = StockViewModel.shared
    
    var body: some View {
        NavigationView {
            Form {
                // MARK: - 📋 Sección de Información General
                /// Datos básicos del movimiento: proveedor y notas
                Section("Información de la Carga") {
                    HStack {
                        Text("Proveedor:")
                        Spacer()
                        Button(supplier.isEmpty ? "Seleccionar" : supplier) {
                            showingSupplierSheet = true
                        }
                        .foregroundColor(supplier.isEmpty ? .blue : .primary)
                    }
                    
                    TextField("Notas adicionales (opcional)", text: $notes, axis: .vertical)
                        .lineLimit(2...4)
                }
                
                // MARK: - 🔄 Control Dinámico de Tipos de Huevo
                /// Toggle que habilita/deshabilita la sección de huevo pardo
                Section {
                    Toggle("Incluir Huevo Pardo", isOn: $includePardoEggs)
                        .tint(Color("pardo"))
                }
                
                /// Sección de huevo rosado (siempre visible)
                eggTypeSection(
                    title: "Huevo Rosado",
                    color: Color("rosado"),
                    icon: "circle.fill",
                    categories: $rosadoPackageCategories
                )
                
                /// Sección de huevo pardo (condicional)
                if includePardoEggs {
                    eggTypeSection(
                        title: "Huevo Pardo",
                        color: Color("pardo"),
                        icon: "circle.fill",
                        categories: $pardoPackageCategories
                    )
                }
                
                // MARK: - 📊 Resumen Dinámico en Tiempo Real
                /// Se actualiza automáticamente mientras el usuario ingresa datos
                if hasVisibleCategories {
                    Section {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("Total General:")
                                    .font(.headline)
                                    .fontWeight(.bold)
                                Spacer()
                                Text("\(totalPackages) paquetes")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundColor(.green)
                            }
                            
                            /// Muestra solo los tipos que tienen datos
                            if totalRosadoPackages > 0 {
                                HStack {
                                    Circle()
                                        .fill(Color("rosado"))
                                        .frame(width: 12, height: 12)
                                    Text("Rosado:")
                                    Spacer()
                                    Text("\(totalRosadoPackages) paquetes")
                                        .fontWeight(.semibold)
                                }
                                .font(.subheadline)
                            }
                            
                            if includePardoEggs && totalPardoPackages > 0 {
                                HStack {
                                    Circle()
                                        .fill(Color("pardo"))
                                        .frame(width: 12, height: 12)
                                    Text("Pardo:")
                                    Spacer()
                                    Text("\(totalPardoPackages) paquetes")
                                        .fontWeight(.semibold)
                                }
                                .font(.subheadline)
                            }
                            
                            // MARK: - ⚖️ Cálculo Automático de Peso
                            /// El sistema calcula automáticamente el peso basado en los pesos específicos
                            HStack {
                                Text("Peso estimado:")
                                    .font(.subheadline)
                                Spacer()
                                Text(String(format: "%.1f kg", estimatedTotalWeight))
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.blue)
                            }
                        }
                        .padding(.vertical, 8)
                    }
                }
                
                // MARK: - 🎯 Sección de Acciones con Validación
                /// Botones de guardar y limpiar con validaciones integradas
                if hasVisibleCategories {
                    Section {
                        Button("Guardar Carga") {
                            showingSaveConfirmation = true
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(supplier.isEmpty || isLoading ? Color.gray : Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                        .disabled(supplier.isEmpty || isLoading)    // Validacion automatica
                        
                        if isLoading {
                            HStack {
                                ProgressView()
                                    .scaleEffect(0.8)
                                Text("Guardando...")
                                    .font(.subheadline)
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                        }
                        
                        Button("Limpiar Todo") {
                            clearAllPackages()
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.red)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                        .disabled(isLoading)
                    }
                }
            }
            .navigationTitle("Registrar Carga")
            .navigationBarTitleDisplayMode(.inline)
            .disabled(isLoading)
            .sheet(isPresented: $showingSupplierSheet) {
                /// Reutiliza proveedores frecuentes y permite crear nuevos
                SupplierSelectionView(
                    selectedSupplier: $supplier,
                    frequentSuppliers: stockViewModel.appSettings.frequentSuppliers
                )
            }
            .alert("Confirmar Registro", isPresented: $showingSaveConfirmation) {
                Button("Cancelar", role: .cancel) { }
                Button("Guardar") {
                    Task {
                        await savePackages()
                    }
                }
            } message: {
                Text("¿Estás seguro de que quieres registrar esta carga de \(totalPackages) paquetes del proveedor \(supplier)?")
            }
            .alert("¡Carga Registrada!", isPresented: $showingSuccessAlert) {
                Button("OK") { }
            } message: {
                Text("La carga se registró exitosamente. Total: \(lastSavedTotal) paquetes.")
            }
        }
        .onAppear {
            print("📱 RegisterCargoView apareció")
        }
    }
    
    // MARK: - Seccion Reutilizable para tipos de huevo
    /// Maneja el sistema unico de pesos
    @ViewBuilder
    private func eggTypeSection(
        title: String,
        color: Color,
        icon: String,
        categories: Binding<[PackageCategory]>
    ) -> some View {
        /// El usuario puede activar/desactivar categorias de peso especificas
        Section {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                Text(title)
                    .font(.headline)
                    .fontWeight(.semibold)
                Spacer()
                if getTotalForCategories(categories.wrappedValue) > 0 {
                    Text("(\(getTotalForCategories(categories.wrappedValue)))")
                        .foregroundColor(color)
                        .fontWeight(.bold)
                }
            }
            
            /// Cada peso tiene su propio toggle y contador dinamico
            ForEach(categories.indices, id: \.self) { categoryIndex in
                HStack {
                    if categories[categoryIndex].isVisible.wrappedValue {
                        let totalForCategory = categories[categoryIndex].packages.wrappedValue.reduce(0, +)
                        Text("(\(totalForCategory))")
                            .foregroundColor(color)
                            .fontWeight(.semibold)
                            .frame(width: 40)
                    } else {
                        Text("")
                            .frame(width: 40)
                    }
                    
                    Toggle(categories[categoryIndex].name.wrappedValue,
                           isOn: categories[categoryIndex].isVisible)
                        .tint(color)
                }
            }
        } header: {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                Text("Seleccionar Tipos de Paquetes - \(title)")
            }
        }
        
        // MARK: - Entrada por Décimas
        /// Solo muestra las categorías que el usuario activó
        ForEach(categories.indices, id: \.self) { categoryIndex in
            if categories[categoryIndex].isVisible.wrappedValue {
                let categoryTotal = categories[categoryIndex].packages.wrappedValue.reduce(0, +)
                Section {
                    ForEach(0..<10, id: \.self) { packageIndex in
                        PackageInputRow(
                            label: "Paquete \(categories[categoryIndex].weight.wrappedValue).\(packageIndex):",
                            value: categories[categoryIndex].packages[packageIndex],
                            accentColor: color
                        )
                    }
                } header: {
                    HStack {
                        Image(systemName: icon)
                            .foregroundColor(color)
                        Text("\(categories[categoryIndex].name.wrappedValue) - Total: \(categoryTotal)")
                        
                        /// Muestra el paso estimado en tiempo real
                        Spacer()
                        let estimatedWeight = Double(categoryTotal) * Double(categories[categoryIndex].weight.wrappedValue)
                        Text(String(format: "%.1f kg", estimatedWeight))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
    }
    
    // MARK: - Propiedad calculadas
    /// Se actualizan automaticamente mientras el usuario ingresa datos
    private var hasVisibleCategories: Bool {
        rosadoPackageCategories.contains(where: { $0.isVisible }) ||
        (includePardoEggs && pardoPackageCategories.contains(where: { $0.isVisible }))
    }
    
    private var totalPackages: Int {
        totalRosadoPackages + totalPardoPackages
    }
    
    private var totalRosadoPackages: Int {
        getTotalForCategories(rosadoPackageCategories)
    }
    
    private var totalPardoPackages: Int {
        includePardoEggs ? getTotalForCategories(pardoPackageCategories) : 0
    }
    
    private var estimatedTotalWeight: Double {
        let rosadoWeight = estimatedWeightForCategories(rosadoPackageCategories)
        let pardoWeight = includePardoEggs ? estimatedWeightForCategories(pardoPackageCategories) : 0.0
        return rosadoWeight + pardoWeight
    }
    
    private func getTotalForCategories(_ categories: [PackageCategory]) -> Int {
        categories
            .filter { $0.isVisible }
            .flatMap { $0.packages }
            .reduce(0, +)
    }
    
    private func estimatedWeightForCategories(_ categories: [PackageCategory]) -> Double {
        return categories
            .filter { $0.isVisible }
            .reduce(0.0) { total, category in
                let packageCount = category.packages.reduce(0, +)
                return total + (Double(packageCount) * Double(category.weight))
            }
    }
    
    // MARK: - Funciones
    /// Convierte los datos de la UI al formato de PackageInventory y los guarda
    private func savePackages() async {
        guard !supplier.isEmpty else { return }
        
        print("💾 Iniciando guardado de carga...")
        print("📦 Proveedor: \(supplier)")
        print("📊 Total paquetes: \(totalPackages)")
        
        isLoading = true
        
        let totalToSave = totalPackages
        
        /// Convierte las categorias de la UI al formato de PackageInventory
        let rosadoInventory = createPackageInventory(from: rosadoPackageCategories)
        let pardoInventory = includePardoEggs ? createPackageInventory(from: pardoPackageCategories) : PackageInventory()
        
        /// Delega al StockViewModel que maneje toda la logica de negocio
        await stockViewModel.addCargoEntry(
            rosadoPackages: rosadoInventory,
            pardoPackages: pardoInventory,
            supplier: supplier,
            notes: notes.isEmpty ? nil : notes,
            type: LoadType.incoming
        )
        
        isLoading = false
        
        lastSavedTotal = totalToSave
        
        /// Resetea el formulario para una nueva entrada
        clearAllPackages()
        supplier = ""
        notes = ""
        includePardoEggs = false
        
        /// Mostrar alerta de éxito
        showingSuccessAlert = true
        
        print("✅ Carga guardada exitosamente: \(totalToSave) paquetes")
    }
    
    /// Convierte la estructura de UI al PackageInventory del modelo
    private func createPackageInventory(from categories: [PackageCategory]) -> PackageInventory {
        var inventory = PackageInventory()
        
        for category in categories where category.isVisible {
            inventory.setPackagesForWeight(category.weight, packages: category.packages)
        }
        
        return inventory
    }
    
    private func clearAllPackages() {
        print("🧹 Limpiando formulario...")
        
        for categoryIndex in rosadoPackageCategories.indices {
            rosadoPackageCategories[categoryIndex].packages = Array(repeating: 0, count: 10)
            rosadoPackageCategories[categoryIndex].isVisible = false
        }
        
        for categoryIndex in pardoPackageCategories.indices {
            pardoPackageCategories[categoryIndex].packages = Array(repeating: 0, count: 10)
            pardoPackageCategories[categoryIndex].isVisible = false
        }
    }
}

// MARK: - Componente reutilizable para cada fila de paquete
/// Control personalizado con botones ➕/➖ y validacion automatica
struct PackageInputRow: View {
    let label: String
    @Binding var value: Int
    let accentColor: Color
    
    var body: some View {
        HStack {
            Text(label)
                .font(.system(size: 16, weight: .medium))
            
            Spacer()
            
            /// Desactiva el boton ➖ cuando el valor es 0
            Button(action: {
                if value > 0 {
                    value -= 1
                }
            }) {
                Image(systemName: "minus.circle.fill")
                    .foregroundColor(value > 0 ? .red : .gray)
                    .font(.title2)
            }
            .disabled(value <= 0)
            .buttonStyle(PlainButtonStyle())
            
            /// Solo acepta numeros positivos
            TextField("0", value: Binding(
                get: { value },
                set: { newValue in
                    if newValue >= 0 {
                        value = newValue
                    }
                }
            ), format: .number)
                .keyboardType(.numberPad)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .frame(width: 60)
                .multilineTextAlignment(.center)
            
            /// Siempre activo el boton de ➕
            Button(action: {
                value += 1
            }) {
                Image(systemName: "plus.circle.fill")
                    .foregroundColor(accentColor)
                    .font(.title2)
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding(.vertical, 2)
    }
}

// MARK: - Vista para seleccionar proveedor
/// Reutuliza proveedores frecuentes y permite crear nuevos
struct SupplierSelectionView: View {
    @Binding var selectedSupplier: String
    let frequentSuppliers: [String]
    @Environment(\.dismiss) private var dismiss
    @State private var newSupplier = ""
    
    var body: some View {
        NavigationView {
            Form {
                Section("Proveedores Frecuentes") {
                    if frequentSuppliers.isEmpty {
                        Text("No hay proveedores guardados")
                            .foregroundColor(.gray)
                    } else {
                        ForEach(frequentSuppliers, id: \.self) { supplier in
                            Button(supplier) {
                                selectedSupplier = supplier
                                dismiss()
                            }
                        }
                    }
                }
                
                Section("Nuevo Proveedor") {
                    TextField("Nombre del proveedor", text: $newSupplier)
                    
                    Button("Usar Nuevo Proveedor") {
                        selectedSupplier = newSupplier
                        dismiss()
                    }
                    .disabled(newSupplier.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .navigationTitle("Seleccionar Proveedor")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden()
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancelar") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Vista de resumen
struct PackageSummaryView: View {
    let rosadoCategories: [RegisterCargoView.PackageCategory]
    let pardoCategories: [RegisterCargoView.PackageCategory]
    let includePardo: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Resumen de Carga")
                .font(.headline)
                .padding(.bottom, 5)
            
            /// Muestra un resumen de los paquetes en tiempo real
            VStack(alignment: .leading, spacing: 5) {
                HStack {
                    Circle()
                        .fill(Color("rosado"))
                        .frame(width: 12, height: 12)
                    Text("Huevo Rosado")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                }
                
                ForEach(rosadoCategories.indices, id: \.self) { categoryIndex in
                    let category = rosadoCategories[categoryIndex]
                    if category.isVisible {
                        let totalPackages = category.packages.reduce(0, +)
                        if totalPackages > 0 {
                            HStack {
                                Text("  \(category.weight) kg:")
                                    .font(.caption)
                                Spacer()
                                Text("\(totalPackages) paquetes")
                                    .font(.caption)
                                    .fontWeight(.bold)
                            }
                        }
                    }
                }
            }
            
            /// Muestra un resumen de los paquetes en tiempo real
            if includePardo {
                VStack(alignment: .leading, spacing: 5) {
                    HStack {
                        Circle()
                            .fill(Color("pardo"))
                            .frame(width: 12, height: 12)
                        Text("Huevo Pardo")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                    }
                    
                    ForEach(pardoCategories.indices, id: \.self) { categoryIndex in
                        let category = pardoCategories[categoryIndex]
                        if category.isVisible {
                            let totalPackages = category.packages.reduce(0, +)
                            if totalPackages > 0 {
                                HStack {
                                    Text("  \(category.weight) kg:")
                                        .font(.caption)
                                    Spacer()
                                    Text("\(totalPackages) paquetes")
                                        .font(.caption)
                                        .fontWeight(.bold)
                                }
                            }
                        }
                    }
                }
            }
            
            /// Muestra total general actualizado en tiempo real
            Divider()
            HStack {
                Text("Total General:")
                    .font(.subheadline)
                    .fontWeight(.bold)
                Spacer()
                let totalRosado = rosadoCategories.filter { $0.isVisible }.flatMap { $0.packages }.reduce(0, +)
                let totalPardo = includePardo ? pardoCategories.filter { $0.isVisible }.flatMap { $0.packages }.reduce(0, +) : 0
                Text("\(totalRosado + totalPardo) paquetes")
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundColor(.green)
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(8)
    }
}

#Preview {
    RegisterCargoView()
}
