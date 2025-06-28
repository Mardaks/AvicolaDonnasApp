//
//  CurrentStockView.swift
//  AvicolaDonnasApp
//
//  Created by Victor Martinez on 26/06/25.
//

import SwiftUI

// MARK: - 📊 Vista Principal: Pantalla de Stock Actual
/// Esta es la pantalla central donde los usuarios ven TODO su inventario
/// Demuestra el patrón MVVM en acción con reactividad completa
struct CurrentStockView: View {
    @ObservedObject private var stockViewModel = StockViewModel.shared
    
    // MARK: - 🎛️ Estados Locales de la Vista
    @State private var isEditMode = false                    // Control del modo edición
    @State private var selectedEggType: EggType = .rosado    // Tipo seleccionado
    @State private var expandedSections: Set<String> = []    // Secciones expandidas
    @State private var showingUpdateConfirmation = false     // Confirmación de guardado
    @State private var tempRosadoInventory = PackageInventory() // Inventario temporal para edición
    @State private var tempPardoInventory = PackageInventory()  // Inventario temporal para edición
    
    var body: some View {
        NavigationView {
            ScrollView {
                LazyVStack(spacing: 16) {
                    // MARK: - 📈 Header Inteligente con Resumen
                    /// Muestra automáticamente el estado actual del día
                    stockSummaryHeader
                    
                    // MARK: - 🥚 Estadísticas por Tipo de Huevo
                    /// Cards reactivas que se actualizan automáticamente
                    eggTypeStatistics
                    
                    // MARK: - 📦 Stock Detallado Expandible
                    /// Sistema de acordeón que muestra solo lo necesario
                    if stockViewModel.hasStockForType(.rosado) || isEditMode {
                        eggTypeStockSection(for: .rosado)
                    }
                    
                    if stockViewModel.hasStockForType(.pardo) || isEditMode {
                        eggTypeStockSection(for: .pardo)
                    }
                    
                    // MARK: - 🔍 Estado Vacío Inteligente
                    /// Solo se muestra cuando realmente no hay inventario
                    if !stockViewModel.hasStockForType(.rosado) && !stockViewModel.hasStockForType(.pardo) && !isEditMode {
                        emptyStockView
                    }
                    
                    Spacer(minLength: 100)
                }
                .padding()
            }
            .navigationTitle("Stock Actual")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                // MARK: - 🛠️ Barra de Herramientas Inteligente
                /// Cambia dinámicamente según el modo actual
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(isEditMode ? "Guardar" : "Editar") {
                        if isEditMode {
                            showingUpdateConfirmation = true
                        } else {
                            enterEditMode()
                        }
                    }
                    .foregroundColor(isEditMode ? .green : .blue)
                    .fontWeight(.semibold)
                    .disabled(stockViewModel.isLoading)
                }
                
                ToolbarItem(placement: .navigationBarLeading) {
                    if isEditMode {
                        Button("Cancelar") {
                            cancelEditMode()
                        }
                        .foregroundColor(.red)
                    } else {
                        Button("Actualizar") {
                            Task {
                                await stockViewModel.refreshCurrentStock()
                            }
                        }
                        .disabled(stockViewModel.isLoading)
                    }
                }
            }
            .refreshable {
                // MARK: - 🔄 Pull-to-Refresh Nativo
                /// Actualización manual del usuario
                await stockViewModel.refreshCurrentStock()
            }
            .alert("Confirmar Actualización", isPresented: $showingUpdateConfirmation) {
                Button("Cancelar", role: .cancel) { }
                Button("Guardar") {
                    Task {
                        await saveChanges()
                    }
                }
            } message: {
                Text("¿Estás seguro de que quieres actualizar el stock actual?")
            }
        }
        .task {
            // MARK: - ⚡ Carga Automática al Aparecer
            /// Se ejecuta automáticamente cuando aparece la vista
            await stockViewModel.refreshCurrentStock()
        }
        .onAppear {
            print("📱 CurrentStockView apareció")
        }
    }
    
    // MARK: - 📊 Header Dinámico con Estado del Día
    /// Diseño responsivo que muestra el resumen más importante
    @ViewBuilder
    private var stockSummaryHeader: some View {
        VStack(spacing: 16) {
            // Fecha y estado del día
            HStack {
                Image(systemName: "calendar")
                    .foregroundColor(.blue)
                Text("Hoy - \(Date().displayString)")
                    .font(.headline)
                    .fontWeight(.semibold)
                Spacer()
                
                // MARK: - 🚦 Indicador Visual de Estado
                /// Verde = Abierto, Rojo = Cerrado
                HStack {
                    Circle()
                        .fill(stockViewModel.isDayOpen ? .green : .red)
                        .frame(width: 8, height: 8)
                    Text(stockViewModel.isDayOpen ? "Abierto" : "Cerrado")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(stockViewModel.isDayOpen ? .green : .red)
                }
                
                if stockViewModel.isLoading {
                    ProgressView()
                        .scaleEffect(0.8)
                }
            }
            
            // MARK: - 🎯 Cards de Resumen Principales
            /// Datos más importantes: Total de paquetes y peso
            HStack(spacing: 12) {
                summaryCard(
                    title: "Total Paquetes",
                    value: "\(stockViewModel.todayTotalPackages)",
                    icon: "shippingbox.fill",
                    color: .blue
                )
                
                summaryCard(
                    title: "Peso Total",
                    value: String(format: "%.1f kg", stockViewModel.todayTotalWeight),
                    icon: "scalemass.fill",
                    color: .green
                )
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    @ViewBuilder
    private func summaryCard(title: String, value: String, icon: String, color: Color) -> some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(color)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(8)
    }
    
    // MARK: - 🥚 Sistema de Estadísticas por Tipo
    /// Distribución automática entre huevo rosado y pardo
    @ViewBuilder
    private var eggTypeStatistics: some View {
        VStack(spacing: 12) {
            HStack {
                Text("Distribución por Tipo")
                    .font(.headline)
                    .fontWeight(.semibold)
                Spacer()
            }
            
            HStack(spacing: 12) {
                // Estadística de huevo rosado
                eggTypeStatCard(for: .rosado)
                
                // Estadística de huevo pardo
                eggTypeStatCard(for: .pardo)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    @ViewBuilder
    private func eggTypeStatCard(for eggType: EggType) -> some View {
        // MARK: - 🧮 Cálculos Automáticos en Tiempo Real
        /// Estos valores se actualizan automáticamente cuando cambia el stock
        let packages = stockViewModel.getStockForType(eggType).getTotalPackages()
        let weight = stockViewModel.getStockForType(eggType).getTotalWeight()
        let hasStock = packages > 0
        
        VStack(spacing: 8) {
            HStack {
                Circle()
                    .fill(eggType.color)
                    .frame(width: 12, height: 12)
                Text(eggType.displayName)
                    .font(.subheadline)
                    .fontWeight(.medium)
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("Paquetes:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text("\(packages)")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(hasStock ? eggType.color : .secondary)
                }
                
                HStack {
                    Text("Peso:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text(String(format: "%.1f kg", weight))
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(hasStock ? eggType.color : .secondary)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(hasStock ? eggType.color.opacity(0.3) : Color.clear, lineWidth: 1)
        )
    }
    
    // MARK: - 📦 Sistema de Acordeón Inteligente para Stock Detallado
    /// Muestra inventario completo con mi sistema único de pesos con décimas
    @ViewBuilder
    private func eggTypeStockSection(for eggType: EggType) -> some View {
        // MARK: - 🔄 Lógica de Inventario Temporal vs Real
        /// En modo edición usa inventario temporal, sino usa el real
        let inventory = isEditMode ?
            (eggType == .rosado ? tempRosadoInventory : tempPardoInventory) :
            stockViewModel.getStockForType(eggType)
        let sectionId = "stock_\(eggType.rawValue)"
        let isExpanded = expandedSections.contains(sectionId)
        
        VStack(spacing: 0) {
            // MARK: - 🎯 Header Expandible con Totales
            /// Tap para expandir/contraer + resumen rápido
            Button(action: {
                withAnimation(.easeInOut(duration: 0.3)) {
                    if isExpanded {
                        expandedSections.remove(sectionId)
                    } else {
                        expandedSections.insert(sectionId)
                    }
                }
            }) {
                HStack {
                    Circle()
                        .fill(eggType.color)
                        .frame(width: 16, height: 16)
                    
                    Text(eggType.displayName)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("\(inventory.getTotalPackages()) paquetes")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(eggType.color)
                        
                        Text(String(format: "%.1f kg", inventory.getTotalWeight()))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .animation(.easeInOut(duration: 0.2), value: isExpanded)
                }
                .padding()
                .background(Color(.systemGray6))
            }
            .buttonStyle(PlainButtonStyle())
            
            // MARK: - 📋 Contenido Expandible: Mi Sistema de Pesos
            /// Aquí se muestra mi innovación: inventario por peso específico
            if isExpanded {
                LazyVStack(spacing: 12) {
                    ForEach(7...13, id: \.self) { weight in
                        weightSection(for: weight, eggType: eggType, inventory: inventory)
                    }
                }
                .padding()
                .background(Color(.systemBackground))
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(eggType.color.opacity(0.2), lineWidth: 1)
        )
    }
    
    // MARK: - Sección de Peso con Décimas
    /// Cada peso (7kg, 8kg, etc.) se subdivide en décimas (7.0, 7.1, 7.2...)
    @ViewBuilder
    private func weightSection(for weight: Int, eggType: EggType, inventory: PackageInventory) -> some View {
        let packages = inventory.getPackagesForWeight(weight)
        let total = packages.reduce(0, +)
        let weightSectionId = "\(eggType.rawValue)_\(weight)"
        let isWeightExpanded = expandedSections.contains(weightSectionId)
        
        VStack(spacing: 0) {
            // Header del peso con total
            Button(action: {
                withAnimation(.easeInOut(duration: 0.2)) {
                    if isWeightExpanded {
                        expandedSections.remove(weightSectionId)
                    } else {
                        expandedSections.insert(weightSectionId)
                    }
                }
            }) {
                HStack {
                    Text("Paquetes de \(weight) kg")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    Text("Total: \(total)")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(total > 0 ? eggType.color : .secondary)
                    
                    Image(systemName: isWeightExpanded ? "chevron.up.circle.fill" : "chevron.down.circle")
                        .font(.caption)
                        .foregroundColor(eggType.color)
                        .animation(.easeInOut(duration: 0.2), value: isWeightExpanded)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color(.systemGray6))
                .cornerRadius(8)
            }
            .buttonStyle(PlainButtonStyle())
            
            // MARK: - Décimas de Peso
            /// Grid de 2 columnas mostrando cada décima específica
            if isWeightExpanded {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 8) {
                    ForEach(0..<10, id: \.self) { decimal in
                        decimalRow(
                            weight: weight,
                            decimal: decimal,
                            value: packages[decimal],
                            eggType: eggType,
                            isEditable: isEditMode
                        )
                    }
                }
                .padding(.top, 8)
                .transition(.opacity.combined(with: .scale(scale: 0.95)))
            }
        }
    }
    
    // MARK: - 🔢 Fila Individual de Décimas con Control de Edición
    /// Cada peso específico (ej: 7.3kg) con botones +/- en modo edición
    @ViewBuilder
    private func decimalRow(weight: Int, decimal: Int, value: Int, eggType: EggType, isEditable: Bool) -> some View {
        HStack {
            Text("\(weight).\(decimal):")
                .font(.caption)
                .fontWeight(.medium)
                .frame(width: 40, alignment: .leading)
            
            Spacer()
            
            if isEditable {
                // MARK: - ✏️ Controles de Edición Intuitivos
                /// Botones +/- con validación automática
                HStack(spacing: 8) {
                    Button(action: {
                        updateTempInventory(eggType: eggType, weight: weight, decimal: decimal, increment: -1)
                    }) {
                        Image(systemName: "minus.circle.fill")
                            .foregroundColor(value > 0 ? .red : .gray)
                            .font(.caption)
                    }
                    .disabled(value <= 0)
                    
                    Text("\(value)")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(value > 0 ? eggType.color : .secondary)
                        .frame(width: 30)
                    
                    Button(action: {
                        updateTempInventory(eggType: eggType, weight: weight, decimal: decimal, increment: 1)
                    }) {
                        Image(systemName: "plus.circle.fill")
                            .foregroundColor(eggType.color)
                            .font(.caption)
                    }
                }
            } else {
                Text("\(value)")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(value > 0 ? eggType.color : .secondary)
                    .frame(width: 30)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(value > 0 ? eggType.color.opacity(0.1) : Color(.systemGray6))
        )
    }
    
    // MARK: - 🗂️ Vista de Estado Vacío
    @ViewBuilder
    private var emptyStockView: some View {
        VStack(spacing: 16) {
            Image(systemName: "shippingbox")
                .font(.system(size: 60))
                .foregroundColor(.gray)
            
            Text("No hay stock registrado")
                .font(.headline)
                .fontWeight(.medium)
                .foregroundColor(.secondary)
            
            Text("Registra tu primera carga para comenzar a ver el inventario")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .padding(.vertical, 40)
    }
    
    // MARK: - 🛠️ Funciones de Control de Estado
    /// Gestión inteligente del modo edición con auto-expansión
    private func enterEditMode() {
        print("📝 Entrando en modo edición")
        isEditMode = true
        tempRosadoInventory = stockViewModel.getStockForType(.rosado)
        tempPardoInventory = stockViewModel.getStockForType(.pardo)
        
        // MARK: - 🎯 Auto-Expansión Inteligente
        /// Expande automáticamente las secciones relevantes
        expandedSections.insert("stock_rosado")
        expandedSections.insert("stock_pardo")
        
        // Expandir subsecciones que tienen stock
        for weight in 7...13 {
            if tempRosadoInventory.getPackagesForWeight(weight).reduce(0, +) > 0 {
                expandedSections.insert("rosado_\(weight)")
            }
            if tempPardoInventory.getPackagesForWeight(weight).reduce(0, +) > 0 {
                expandedSections.insert("pardo_\(weight)")
            }
        }
    }
    
    private func cancelEditMode() {
        print("❌ Cancelando modo edición")
        isEditMode = false
        tempRosadoInventory = PackageInventory()
        tempPardoInventory = PackageInventory()
    }
    
    // MARK: - 🔄 Actualización de Inventario Temporal
    /// Actualiza el inventario temporal mientras el usuario edita
    private func updateTempInventory(eggType: EggType, weight: Int, decimal: Int, increment: Int) {
        print("🔄 Actualizando inventario temporal: \(eggType.displayName) \(weight).\(decimal) \(increment > 0 ? "+" : "")\(increment)")
        
        let targetInventory = eggType == .rosado ? tempRosadoInventory : tempPardoInventory
        var packages = targetInventory.getPackagesForWeight(weight)
        packages[decimal] = max(0, packages[decimal] + increment)
        
        if eggType == .rosado {
            tempRosadoInventory.setPackagesForWeight(weight, packages: packages)
        } else {
            tempPardoInventory.setPackagesForWeight(weight, packages: packages)
        }
    }
    
    // MARK: - 💾 Persistencia de Cambios
    /// Guarda los cambios temporales al ViewModel y luego a Firebase
    private func saveChanges() async {
        print("💾 Guardando cambios en el stock...")
        
        await stockViewModel.updateStockForType(.rosado, packages: tempRosadoInventory)
        await stockViewModel.updateStockForType(.pardo, packages: tempPardoInventory)
        
        isEditMode = false
        tempRosadoInventory = PackageInventory()
        tempPardoInventory = PackageInventory()
        
        await stockViewModel.refreshCurrentStock()
        
        print("✅ Cambios guardados exitosamente")
    }
}

#Preview {
    CurrentStockView()
}
