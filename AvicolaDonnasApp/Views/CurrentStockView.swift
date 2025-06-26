//
//  CurrentStockView.swift
//  AvicolaDonnasApp
//
//  Created by Victor Martinez on 26/06/25.
//

import SwiftUI

struct CurrentStockView: View {
    @StateObject private var stockViewModel = StockViewModel()
    @State private var isEditMode = false
    @State private var selectedEggType: EggType = .rosado
    @State private var expandedSections: Set<String> = []
    @State private var showingUpdateConfirmation = false
    @State private var tempRosadoInventory = PackageInventory()
    @State private var tempPardoInventory = PackageInventory()
    
    var body: some View {
        NavigationView {
            ScrollView {
                LazyVStack(spacing: 16) {
                    // Header con resumen general
                    stockSummaryHeader
                    
                    // Estadísticas por tipo de huevo
                    eggTypeStatistics
                    
                    // Stock detallado por tipo de huevo
                    if stockViewModel.hasStockForType(.rosado) || isEditMode {
                        eggTypeStockSection(for: .rosado)
                    }
                    
                    if stockViewModel.hasStockForType(.pardo) || isEditMode {
                        eggTypeStockSection(for: .pardo)
                    }
                    
                    // Si no hay stock de ningún tipo
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
                }
                
                ToolbarItem(placement: .navigationBarLeading) {
                    if isEditMode {
                        Button("Cancelar") {
                            cancelEditMode()
                        }
                        .foregroundColor(.red)
                    }
                }
            }
            .refreshable {
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
            await stockViewModel.refreshCurrentStock()
        }
    }
    
    // MARK: - Header con resumen general
    @ViewBuilder
    private var stockSummaryHeader: some View {
        VStack(spacing: 16) {
            // Fecha actual
            HStack {
                Image(systemName: "calendar")
                    .foregroundColor(.blue)
                Text("Hoy - \(Date().displayString)")
                    .font(.headline)
                    .fontWeight(.semibold)
                Spacer()
                
                // Estado del día
                HStack {
                    Circle()
                        .fill(stockViewModel.isDayOpen ? .green : .red)
                        .frame(width: 8, height: 8)
                    Text(stockViewModel.isDayOpen ? "Abierto" : "Cerrado")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(stockViewModel.isDayOpen ? .green : .red)
                }
            }
            
            // Tarjetas de resumen
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
    
    // MARK: - Estadísticas por tipo de huevo
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
    
    // MARK: - Sección de stock por tipo de huevo
    @ViewBuilder
    private func eggTypeStockSection(for eggType: EggType) -> some View {
        let inventory = isEditMode ?
            (eggType == .rosado ? tempRosadoInventory : tempPardoInventory) :
            stockViewModel.getStockForType(eggType)
        let sectionId = "stock_\(eggType.rawValue)"
        let isExpanded = expandedSections.contains(sectionId)
        
        VStack(spacing: 0) {
            // Header de la sección
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
            
            // Contenido expandible
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
    
    @ViewBuilder
    private func weightSection(for weight: Int, eggType: EggType, inventory: PackageInventory) -> some View {
        let packages = inventory.getPackagesForWeight(weight)
        let total = packages.reduce(0, +)
        let weightSectionId = "\(eggType.rawValue)_\(weight)"
        let isWeightExpanded = expandedSections.contains(weightSectionId)
        
        VStack(spacing: 0) {
            // Header del peso
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
            
            // Detalles por decimal
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
    
    @ViewBuilder
    private func decimalRow(weight: Int, decimal: Int, value: Int, eggType: EggType, isEditable: Bool) -> some View {
        HStack {
            Text("\(weight).\(decimal):")
                .font(.caption)
                .fontWeight(.medium)
                .frame(width: 40, alignment: .leading)
            
            Spacer()
            
            if isEditable {
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
    
    // MARK: - Vista vacía
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
    
    // MARK: - Functions
    private func enterEditMode() {
        isEditMode = true
        tempRosadoInventory = stockViewModel.getStockForType(.rosado)
        tempPardoInventory = stockViewModel.getStockForType(.pardo)
        
        // Expandir todas las secciones en modo edición
        expandedSections.insert("stock_rosado")
        expandedSections.insert("stock_pardo")
    }
    
    private func cancelEditMode() {
        isEditMode = false
        tempRosadoInventory = PackageInventory()
        tempPardoInventory = PackageInventory()
    }
    
    private func updateTempInventory(eggType: EggType, weight: Int, decimal: Int, increment: Int) {
        let targetInventory = eggType == .rosado ? tempRosadoInventory : tempPardoInventory
        var packages = targetInventory.getPackagesForWeight(weight)
        packages[decimal] = max(0, packages[decimal] + increment)
        
        if eggType == .rosado {
            tempRosadoInventory.setPackagesForWeight(weight, packages: packages)
        } else {
            tempPardoInventory.setPackagesForWeight(weight, packages: packages)
        }
    }
    
    private func saveChanges() async {
        await stockViewModel.updateStockForType(.rosado, packages: tempRosadoInventory)
        await stockViewModel.updateStockForType(.pardo, packages: tempPardoInventory)
        
        isEditMode = false
        tempRosadoInventory = PackageInventory()
        tempPardoInventory = PackageInventory()
        
        await stockViewModel.refreshCurrentStock()
    }
}

#Preview {
    CurrentStockView()
}
