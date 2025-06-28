//
//  RegisterEndDayView.swift
//  AvicolaDonnasApp
//
//  Created by Victor Martinez on 26/06/25.
//

import SwiftUI

struct RegisterEndDayView: View {
    @ObservedObject private var stockViewModel = StockViewModel.shared
    
    @State private var showingCloseConfirmation = false
    @State private var showingReopenConfirmation = false
    @State private var closingNotes = ""
    @State private var isLoadingAction = false
    @State private var showingSuccessAlert = false
    @State private var successMessage = ""
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                LazyVStack(spacing: 20) {
                    // Header con estado actual
                    dayStatusHeader
                    
                    // Resumen del día
                    dailySummarySection
                    
                    // Movimientos del día
                    dailyMovementsSection
                    
                    // Resumen por tipo de huevo
                    eggTypeSummarySection
                    
                    // Resumen por proveedor
                    supplierSummarySection
                    
                    // Sección de acciones
                    actionsSection
                    
                    Spacer(minLength: 100)
                }
                .padding()
            }
            .navigationTitle("Cierre de Día")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cerrar") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Actualizar") {
                        Task {
                            await stockViewModel.refreshCurrentStock()
                        }
                    }
                    .disabled(stockViewModel.isLoading)
                }
            }
            .refreshable {
                await stockViewModel.refreshCurrentStock()
            }
            .alert("Confirmar Cierre de Día", isPresented: $showingCloseConfirmation) {
                Button("Cancelar", role: .cancel) { }
                Button("Cerrar Día") {
                    Task {
                        await closeDay()
                    }
                }
            } message: {
                Text("¿Estás seguro de que quieres cerrar el día? Esta acción no se puede deshacer fácilmente.")
            }
            .alert("Reabrir Día", isPresented: $showingReopenConfirmation) {
                Button("Cancelar", role: .cancel) { }
                Button("Reabrir") {
                    Task {
                        await reopenDay()
                    }
                }
            } message: {
                Text("¿Estás seguro de que quieres reabrir el día? Podrás volver a registrar movimientos.")
            }
            .alert("Éxito", isPresented: $showingSuccessAlert) {
                Button("OK") {
                    if stockViewModel.currentDayStock?.isClosed == true {
                        dismiss()
                    }
                }
            } message: {
                Text(successMessage)
            }
        }
        .task {
            // Cargar datos al apareces la vista
            await stockViewModel.refreshCurrentStock()
        }
        .onAppear {
            print("📱 RegisterEndDayView apareció")
        }
    }
    
    // MARK: - Header con estado del día
    @ViewBuilder
    private var dayStatusHeader: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Estado del Día")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Text(Date().displayString)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                HStack(spacing: 8) {
                    Circle()
                        .fill(stockViewModel.isDayOpen ? .green : .red)
                        .frame(width: 12, height: 12)
                    
                    Text(stockViewModel.isDayOpen ? "Día Abierto" : "Día Cerrado")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(stockViewModel.isDayOpen ? .green : .red)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(stockViewModel.isDayOpen ? .green.opacity(0.1) : .red.opacity(0.1))
                )
            }
            
            if let closedAt = stockViewModel.currentDayStock?.closedAt {
                HStack {
                    Image(systemName: "clock.fill")
                        .foregroundColor(.secondary)
                    Text("Cerrado el \(closedAt.timestampString)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    // MARK: - Resumen del día
    @ViewBuilder
    private var dailySummarySection: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Resumen del Día")
                    .font(.headline)
                    .fontWeight(.semibold)
                Spacer()
                
                if stockViewModel.isLoading {
                    ProgressView()
                        .scaleEffect(0.8)
                }
            }
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                summaryCard(
                    title: "Total Paquetes",
                    value: "\(stockViewModel.todayTotalPackages)",
                    subtitle: "paquetes",
                    icon: "shippingbox.fill",
                    color: .blue
                )
                
                summaryCard(
                    title: "Peso Total",
                    value: String(format: "%.1f", stockViewModel.todayTotalWeight),
                    subtitle: "kg",
                    icon: "scalemass.fill",
                    color: .green
                )
                
                summaryCard(
                    title: "Movimientos",
                    value: "\(stockViewModel.todayMovementCount)",
                    subtitle: "registros",
                    icon: "arrow.up.arrow.down",
                    color: .orange
                )
                
                summaryCard(
                    title: "Proveedores",
                    value: "\(stockViewModel.todaySupplierCount)",
                    subtitle: "diferentes",
                    icon: "person.2.fill",
                    color: .purple
                )
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    @ViewBuilder
    private func summaryCard(title: String, value: String, subtitle: String, icon: String, color: Color) -> some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text(value)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(color)
                
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .lineLimit(2)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(8)
    }
    
    // MARK: - Movimientos del día
    @ViewBuilder
    private var dailyMovementsSection: some View {
        VStack(spacing: 12) {
            HStack {
                Text("Movimientos de Hoy")
                    .font(.headline)
                    .fontWeight(.semibold)
                Spacer()
                Text("\(stockViewModel.todayCargoEntries.count) registros")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            if stockViewModel.todayCargoEntries.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "tray")
                        .font(.title)
                        .foregroundColor(.gray)
                    Text("No hay movimientos registrados")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.vertical, 20)
            } else {
                LazyVStack(spacing: 8) {
                    ForEach(stockViewModel.todayCargoEntries.prefix(5)) { entry in
                        movementRow(entry)
                    }
                    
                    if stockViewModel.todayCargoEntries.count > 5 {
                        Button("Ver todos los movimientos (\(stockViewModel.todayCargoEntries.count))") {
                        }
                        .font(.caption)
                        .foregroundColor(.blue)
                        .padding(.top, 4)
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    @ViewBuilder
    private func movementRow(_ entry: CargoEntry) -> some View {
        HStack(spacing: 12) {
            // Ícono del tipo de movimiento
            Image(systemName: entry.type.icon)
                .font(.title3)
                .foregroundColor(entry.type == .incoming ? .green : .red)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text(entry.type.displayName)
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    if !entry.supplier.isEmpty && entry.supplier != "Sistema" {
                        Text("• \(entry.supplier)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Text(entry.eggTypeSummary)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 2) {
                Text("\(entry.totalPackages)")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(entry.type == .incoming ? .green : .red)
                
                Text(entry.timestamp.timestampString.components(separatedBy: " ").last ?? "")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color(.systemBackground))
        .cornerRadius(8)
    }
    
    // MARK: - Resumen por tipo de huevo
    @ViewBuilder
    private var eggTypeSummarySection: some View {
        VStack(spacing: 12) {
            HStack {
                Text("Stock por Tipo de Huevo")
                    .font(.headline)
                    .fontWeight(.semibold)
                Spacer()
            }
            
            HStack(spacing: 12) {
                eggTypeCard(for: .rosado)
                eggTypeCard(for: .pardo)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    @ViewBuilder
    private func eggTypeCard(for eggType: EggType) -> some View {
        let packages = stockViewModel.getStockForType(eggType).getTotalPackages()
        let weight = stockViewModel.getStockForType(eggType).getTotalWeight()
        let hasStock = packages > 0
        
        VStack(spacing: 12) {
            HStack {
                Circle()
                    .fill(eggType.color)
                    .frame(width: 16, height: 16)
                Text(eggType.displayName)
                    .font(.subheadline)
                    .fontWeight(.medium)
                Spacer()
            }
            
            VStack(spacing: 8) {
                VStack(spacing: 2) {
                    Text("\(packages)")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(hasStock ? eggType.color : .secondary)
                    Text("paquetes")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                VStack(spacing: 2) {
                    Text(String(format: "%.1f", weight))
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(hasStock ? eggType.color : .secondary)
                    Text("kg")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            // Distribución por peso
            if hasStock {
                let distribution = stockViewModel.getWeightDistribution(for: eggType)
                if !distribution.isEmpty {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Distribución:")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        ForEach(distribution.prefix(3), id: \.weight) { item in
                            HStack {
                                Text("\(item.weight)kg:")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Spacer()
                                Text("\(item.count)")
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .foregroundColor(eggType.color)
                            }
                        }
                        
                        if distribution.count > 3 {
                            Text("+ \(distribution.count - 3) más")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
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
    
    // MARK: - Resumen por proveedor
    @ViewBuilder
    private var supplierSummarySection: some View {
        let supplierSummary = stockViewModel.getTodaySupplierSummary()
        
        if !supplierSummary.isEmpty {
            VStack(spacing: 12) {
                HStack {
                    Text("Proveedores del Día")
                        .font(.headline)
                        .fontWeight(.semibold)
                    Spacer()
                    Text("\(supplierSummary.count) proveedores")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                LazyVStack(spacing: 8) {
                    ForEach(Array(supplierSummary.keys.sorted()), id: \.self) { supplier in
                        if let summary = supplierSummary[supplier] {
                            supplierRow(supplier: supplier, summary: summary)
                        }
                    }
                }
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
        }
    }
    
    @ViewBuilder
    private func supplierRow(supplier: String, summary: (packages: Int, deliveries: Int)) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(supplier)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text("\(summary.deliveries) \(summary.deliveries == 1 ? "entrega" : "entregas")")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 2) {
                Text("\(summary.packages)")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.blue)
                
                Text("paquetes")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color(.systemBackground))
        .cornerRadius(8)
    }
    
    // MARK: - Sección de acciones
    @ViewBuilder
    private var actionsSection: some View {
        VStack(spacing: 12) {
            if stockViewModel.isDayOpen {
                // Sección de notas para el cierre
                VStack(alignment: .leading, spacing: 8) {
                    Text("Notas del Cierre (Opcional)")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    TextField("Agregar observaciones del día...", text: $closingNotes, axis: .vertical)
                        .textFieldStyle(.roundedBorder)
                        .lineLimit(3...6)
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
                
                // Botón de cerrar día
                Button(action: {
                    showingCloseConfirmation = true
                }) {
                    HStack {
                        if isLoadingAction {
                            ProgressView()
                                .scaleEffect(0.8)
                                .tint(.white)
                        } else {
                            Image(systemName: "lock.fill")
                        }
                        Text("Cerrar Día")
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.red)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
                .disabled(isLoadingAction)
                
            } else {
                // Botón de reabrir día
                Button(action: {
                    showingReopenConfirmation = true
                }) {
                    HStack {
                        if isLoadingAction {
                            ProgressView()
                                .scaleEffect(0.8)
                                .tint(.white)
                        } else {
                            Image(systemName: "lock.open.fill")
                        }
                        Text("Reabrir Día")
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
                .disabled(isLoadingAction)
            }
        }
    }
    
    // MARK: - Funciones
    private func closeDay() async {
        isLoadingAction = true
        
        // Agregar las notas si hay
        if !closingNotes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            // Crear una entrada adicional con las notas
            await stockViewModel.addCargoEntry(
                packages: PackageInventory(),
                eggType: .rosado,
                supplier: "Sistema",
                notes: "Notas de cierre: \(closingNotes)",
                type: .adjustment
            )
        }
        
        await stockViewModel.closeCurrentDay()
        
        isLoadingAction = false
        successMessage = "El día ha sido cerrado exitosamente"
        showingSuccessAlert = true
    }
    
    private func reopenDay() async {
        isLoadingAction = true
        
        await stockViewModel.reopenDay(stockViewModel.currentDateString)
        
        isLoadingAction = false
        successMessage = "El día ha sido reabierto. Puedes continuar registrando movimientos."
        showingSuccessAlert = true
    }
}

#Preview {
    RegisterEndDayView()
}
