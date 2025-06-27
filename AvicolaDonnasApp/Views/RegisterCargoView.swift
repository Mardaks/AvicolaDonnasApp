//
//  RegisterCargoView.swift
//  AvicolaDonnasApp
//
//  Created by Victor Martinez on 25/06/25.
//

import SwiftUI

struct RegisterCargoView: View {
    
    // Estructura para organizar los datos de paquetes por tipo de huevo
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
    
    // Estados para huevo rosado
    @State private var rosadoPackageCategories: [PackageCategory] = [
        PackageCategory(weight: 7),
        PackageCategory(weight: 8),
        PackageCategory(weight: 9),
        PackageCategory(weight: 10),
        PackageCategory(weight: 11),
        PackageCategory(weight: 12),
        PackageCategory(weight: 13)
    ]
    
    // Estados para huevo pardo
    @State private var pardoPackageCategories: [PackageCategory] = [
        PackageCategory(weight: 7),
        PackageCategory(weight: 8),
        PackageCategory(weight: 9),
        PackageCategory(weight: 10),
        PackageCategory(weight: 11),
        PackageCategory(weight: 12),
        PackageCategory(weight: 13)
    ]
    
    // Control para mostrar sección de huevo pardo
    @State private var includePardoEggs = false
    
    // Datos adicionales para el registro
    @State private var lastSavedTotal = 0
    @State private var supplier = ""
    @State private var notes = ""
    @State private var showingSupplierSheet = false
    @State private var showingSaveConfirmation = false
    @State private var showingSuccessAlert = false
    @State private var isLoading = false
    
    // ✅ USAR SINGLETON EN LUGAR DE CREAR NUEVA INSTANCIA
    @ObservedObject private var stockViewModel = StockViewModel.shared
    
    var body: some View {
        NavigationView {
            Form {
                // Sección de información general
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
                
                // Toggle para incluir huevo pardo
                Section {
                    Toggle("Incluir Huevo Pardo", isOn: $includePardoEggs)
                        .tint(Color("pardo"))
                }
                
                // Sección de huevo rosado
                eggTypeSection(
                    title: "Huevo Rosado",
                    color: Color("rosado"),
                    icon: "circle.fill",
                    categories: $rosadoPackageCategories
                )
                
                // Sección de huevo pardo (condicional)
                if includePardoEggs {
                    eggTypeSection(
                        title: "Huevo Pardo",
                        color: Color("pardo"),
                        icon: "circle.fill",
                        categories: $pardoPackageCategories
                    )
                }
                
                // Total general
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
                            
                            // Desglose por tipo
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
                            
                            // ✅ MOSTRAR PESO TOTAL ESTIMADO
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
                
                // Sección de acciones
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
                        .disabled(supplier.isEmpty || isLoading)
                        
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
    
    // MARK: - Vista reutilizable para cada tipo de huevo
    @ViewBuilder
    private func eggTypeSection(
        title: String,
        color: Color,
        icon: String,
        categories: Binding<[PackageCategory]>
    ) -> some View {
        // Sección de controles de visibilidad
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
        
        // Secciones de paquetes (solo las visibles)
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
                        
                        // ✅ AGREGAR PESO ESTIMADO POR CATEGORÍA
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
    
    // MARK: - Computed Properties
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
    
    // ✅ NUEVA PROPIEDAD CALCULADA - Peso total estimado
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
    
    // ✅ NUEVA FUNCIÓN - Calcular peso estimado
    private func estimatedWeightForCategories(_ categories: [PackageCategory]) -> Double {
        return categories
            .filter { $0.isVisible }
            .reduce(0.0) { total, category in
                let packageCount = category.packages.reduce(0, +)
                return total + (Double(packageCount) * Double(category.weight))
            }
    }
    
    // MARK: - Functions
    private func savePackages() async {
        guard !supplier.isEmpty else { return }
        
        print("💾 Iniciando guardado de carga...")
        print("📦 Proveedor: \(supplier)")
        print("📊 Total paquetes: \(totalPackages)")
        
        isLoading = true
        
        let totalToSave = totalPackages
        let suppplierToShow = supplier
        
        let rosadoInventory = createPackageInventory(from: rosadoPackageCategories)
        let pardoInventory = includePardoEggs ? createPackageInventory(from: pardoPackageCategories) : PackageInventory()
        
        // ✅ USAR LoadType EXPLÍCITAMENTE
        await stockViewModel.addCargoEntry(
            rosadoPackages: rosadoInventory,
            pardoPackages: pardoInventory,
            supplier: supplier,
            notes: notes.isEmpty ? nil : notes,
            type: LoadType.incoming // ✅ Especificar el tipo explícitamente
        )
        
        isLoading = false
        
        lastSavedTotal = totalToSave
        
        // Limpiar formulario después de guardar
        clearAllPackages()
        supplier = ""
        notes = ""
        includePardoEggs = false
        
        // Mostrar alerta de éxito
        showingSuccessAlert = true
        
        print("✅ Carga guardada exitosamente: \(totalToSave) paquetes")
    }
    
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
struct PackageInputRow: View {
    let label: String
    @Binding var value: Int
    let accentColor: Color
    
    var body: some View {
        HStack {
            Text(label)
                .font(.system(size: 16, weight: .medium))
            
            Spacer()
            
            // Botón de decrementar
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
            
            // Campo de texto con validación
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
            
            // Botón de incrementar
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
            
            // Resumen de huevo rosado
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
            
            // Resumen de huevo pardo
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
            
            // Total general
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
