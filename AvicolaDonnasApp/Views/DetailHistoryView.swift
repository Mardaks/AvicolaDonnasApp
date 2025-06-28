//
//  DetailHistoryView.swift
//  AvicolaDonnasApp
//
//  Created by Victor Martinez on 26/06/25.
//

import SwiftUI

struct DetailHistoryView: View {
    let dayStock: DailyStock
    
    @ObservedObject private var stockViewModel = StockViewModel.shared
    
    @State private var cargoEntries: [CargoEntry] = []
    @State private var selectedTab = 0 // 0: Resumen, 1: Stock, 2: Movimientos
    @State private var expandedSections: Set<String> = []
    @State private var showingShareSheet = false
    @State private var isLoading = true
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 20) {
                // Header con información del día
                dayHeaderSection
                
                // Navegación de tabs
                tabSelector
                
                // Contenido según tab seleccionado
                TabView(selection: $selectedTab) {
                    // Tab 0: Resumen
                    summaryTab
                        .tag(0)
                    
                    // Tab 1: Stock detallado
                    stockDetailTab
                        .tag(1)
                    
                    // Tab 2: Movimientos
                    movementsTab
                        .tag(2)
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                .frame(height: UIScreen.main.bounds.height * 0.6)
                
                Spacer(minLength: 100)
            }
            .padding()
        }
        .navigationTitle("Detalle del Día")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Button(action: {
                        showingShareSheet = true
                    }) {
                        Label("Compartir", systemImage: "square.and.arrow.up")
                    }
                    
                    Button(action: {
                        // Exportar como PDF
                    }) {
                        Label("Exportar PDF", systemImage: "doc.fill")
                    }
                    
                    if !dayStock.isClosed && dayStock.isCurrentDay {
                        Button(action: {
                            // Ir a editar día
                        }) {
                            Label("Editar Stock", systemImage: "pencil")
                        }
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .font(.title3)
                }
            }
        }
        .task {
            await loadMovements()
        }
        .refreshable {
            await loadMovements()
        }
        .onAppear {
            print("📱 DetailHistoryView apareció para: \(dayStock.date)")
        }
    }
    
    // MARK: - Header del día
    @ViewBuilder
    private var dayHeaderSection: some View {
        VStack(spacing: 16) {
            // Fecha y estado
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(formatDateFromString(dayStock.date))
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text(relativeDateString(from: dayStock.date))
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    HStack(spacing: 8) {
                        Circle()
                            .fill(dayStock.isClosed ? .red : .green)
                            .frame(width: 12, height: 12)
                        Text(dayStock.isClosed ? "Día Cerrado" : "Día Abierto")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(dayStock.isClosed ? .red : .green)
                    }
                    
                    if dayStock.isCurrentDay {
                        Text("DÍA ACTUAL")
                            .font(.caption)
                            .fontWeight(.bold)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(6)
                    }
                    
                    if isLoading {
                        ProgressView()
                            .scaleEffect(0.8)
                    }
                }
            }
            
            // Métricas principales
            HStack(spacing: 0) {
                metricCard(
                    title: "Total Paquetes",
                    value: "\(dayStock.totalPackages)",
                    icon: "shippingbox.fill",
                    color: .blue
                )
                
                Divider()
                    .frame(height: 60)
                
                metricCard(
                    title: "Peso Total",
                    value: String(format: "%.1f kg", dayStock.totalWeight),
                    icon: "scalemass.fill",
                    color: .green
                )
                
                Divider()
                    .frame(height: 60)
                
                metricCard(
                    title: "Movimientos",
                    value: "\(cargoEntries.count)",
                    icon: "arrow.up.arrow.down",
                    color: .orange
                )
            }
            .background(Color(.systemGray6))
            .cornerRadius(12)
            
            // Fechas de creación y cierre
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Image(systemName: "plus.circle")
                        .foregroundColor(.green)
                    Text("Creado: \(dayStock.createdAt.timestampString)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                }
                
                HStack {
                    Image(systemName: "pencil.circle")
                        .foregroundColor(.blue)
                    Text("Actualizado: \(dayStock.updatedAt.timestampString)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                }
                
                if let closedAt = dayStock.closedAt {
                    HStack {
                        Image(systemName: "lock.circle")
                            .foregroundColor(.red)
                        Text("Cerrado: \(closedAt.timestampString)")
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
    }
    
    @ViewBuilder
    private func metricCard(title: String, value: String, icon: String, color: Color) -> some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            Text(value)
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(color)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
    }
    
    // MARK: - Selector de tabs
    @ViewBuilder
    private var tabSelector: some View {
        HStack(spacing: 0) {
            tabButton(title: "Resumen", index: 0, icon: "chart.bar.fill")
            tabButton(title: "Stock", index: 1, icon: "shippingbox.fill")
            tabButton(title: "Movimientos", index: 2, icon: "list.bullet")
        }
        .background(Color(.systemGray5))
        .cornerRadius(12)
    }
    
    @ViewBuilder
    private func tabButton(title: String, index: Int, icon: String) -> some View {
        Button(action: {
            withAnimation(.easeInOut(duration: 0.2)) {
                selectedTab = index
            }
        }) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.caption)
                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(selectedTab == index ? Color(.systemBackground) : Color.clear)
            .foregroundColor(selectedTab == index ? .primary : .secondary)
            .cornerRadius(8)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    // MARK: - Tab 0: Resumen
    @ViewBuilder
    private var summaryTab: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                // Distribución por tipo de huevo
                eggTypeDistribution
                
                // Resumen de movimientos
                movementsSummary
                
                // Distribución por peso
                weightDistribution
                
                // Proveedores del día
                suppliersSummary
            }
            .padding(.vertical)
        }
    }
    
    @ViewBuilder
    private var eggTypeDistribution: some View {
        VStack(spacing: 12) {
            HStack {
                Text("Distribución por Tipo de Huevo")
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
        let inventory = dayStock.getPackagesForType(eggType)
        let packages = inventory.getTotalPackages()
        let weight = inventory.getTotalWeight()
        let hasStock = packages > 0
        let percentage = dayStock.totalPackages > 0 ? Double(packages) / Double(dayStock.totalPackages) * 100 : 0
        
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
                Text("\(packages)")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(hasStock ? eggType.color : .secondary)
                
                Text(String(format: "%.1f%%", percentage))
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(hasStock ? eggType.color : .secondary)
                
                Text(String(format: "%.1f kg", weight))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            // Barra de progreso
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color(.systemGray4))
                        .frame(height: 4)
                    
                    RoundedRectangle(cornerRadius: 2)
                        .fill(eggType.color)
                        .frame(width: geometry.size.width * CGFloat(percentage / 100), height: 4)
                }
            }
            .frame(height: 4)
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
    
    @ViewBuilder
    private var movementsSummary: some View {
        VStack(spacing: 12) {
            HStack {
                Text("Resumen de Movimientos")
                    .font(.headline)
                    .fontWeight(.semibold)
                Spacer()
                Text("\(cargoEntries.count) total")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                ForEach(LoadType.allCases, id: \.self) { type in
                    let entries = cargoEntries.filter { $0.type == type }
                    if !entries.isEmpty {
                        movementTypeCard(type: type, entries: entries)
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    @ViewBuilder
    private func movementTypeCard(type: LoadType, entries: [CargoEntry]) -> some View {
        let totalPackages = entries.reduce(0) { $0 + $1.totalPackages }
        let color = movementColor(for: type)
        
        VStack(spacing: 8) {
            Image(systemName: type.icon)
                .font(.title2)
                .foregroundColor(color)
            
            Text("\(entries.count)")
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(color)
            
            Text(type.displayName)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            if totalPackages > 0 {
                Text("\(totalPackages) paq")
                    .font(.caption2)
                    .fontWeight(.medium)
                    .foregroundColor(color)
            }
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(color.opacity(0.1))
        .cornerRadius(8)
    }
    
    @ViewBuilder
    private var weightDistribution: some View {
        VStack(spacing: 12) {
            HStack {
                Text("Distribución por Peso")
                    .font(.headline)
                    .fontWeight(.semibold)
                Spacer()
            }
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 8) {
                ForEach(7...13, id: \.self) { weight in
                    let rosadoCount = dayStock.rosadoPackages.getTotalForWeight(weight)
                    let pardoCount = dayStock.pardoPackages.getTotalForWeight(weight)
                    let total = rosadoCount + pardoCount
                    
                    if total > 0 {
                        weightCard(weight: weight, rosadoCount: rosadoCount, pardoCount: pardoCount)
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    @ViewBuilder
    private func weightCard(weight: Int, rosadoCount: Int, pardoCount: Int) -> some View {
        VStack(spacing: 6) {
            Text("\(weight) kg")
                .font(.caption)
                .fontWeight(.semibold)
            
            Text("\(rosadoCount + pardoCount)")
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(.blue)
            
            if rosadoCount > 0 && pardoCount > 0 {
                HStack(spacing: 2) {
                    Rectangle()
                        .fill(Color("rosado"))
                        .frame(width: CGFloat(rosadoCount) / CGFloat(rosadoCount + pardoCount) * 20, height: 3)
                    Rectangle()
                        .fill(Color("pardo"))
                        .frame(width: CGFloat(pardoCount) / CGFloat(rosadoCount + pardoCount) * 20, height: 3)
                }
                .cornerRadius(1.5)
            } else {
                Rectangle()
                    .fill(rosadoCount > 0 ? Color("rosado") : Color("pardo"))
                    .frame(width: 20, height: 3)
                    .cornerRadius(1.5)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(Color(.systemBackground))
        .cornerRadius(8)
    }
    
    @ViewBuilder
    private var suppliersSummary: some View {
        let suppliers = uniqueSuppliersWithStats
        
        if !suppliers.isEmpty {
            VStack(spacing: 12) {
                HStack {
                    Text("Proveedores del Día")
                        .font(.headline)
                        .fontWeight(.semibold)
                    Spacer()
                    Text("\(suppliers.count) proveedores")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                LazyVStack(spacing: 8) {
                    ForEach(suppliers, id: \.name) { supplier in
                        supplierCard(supplier)
                    }
                }
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
        }
    }
    
    @ViewBuilder
    private func supplierCard(_ supplier: (name: String, packages: Int, deliveries: Int)) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(supplier.name)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text("\(supplier.deliveries) \(supplier.deliveries == 1 ? "entrega" : "entregas")")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 2) {
                Text("\(supplier.packages)")
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundColor(.blue)
                
                Text("paquetes")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(8)
    }
    
    // MARK: - Tab 1: Stock detallado
    @ViewBuilder
    private var stockDetailTab: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                // Stock de huevo rosado
                if dayStock.rosadoPackages.getTotalPackages() > 0 {
                    stockTypeSection(for: .rosado, inventory: dayStock.rosadoPackages)
                }
                
                // Stock de huevo pardo
                if dayStock.pardoPackages.getTotalPackages() > 0 {
                    stockTypeSection(for: .pardo, inventory: dayStock.pardoPackages)
                }
                
                if dayStock.totalPackages == 0 {
                    VStack(spacing: 16) {
                        Image(systemName: "shippingbox")
                            .font(.system(size: 60))
                            .foregroundColor(.gray)
                        
                        Text("No hay stock registrado")
                            .font(.headline)
                            .fontWeight(.medium)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 40)
                }
            }
            .padding(.vertical)
        }
    }
    
    @ViewBuilder
    private func stockTypeSection(for eggType: EggType, inventory: PackageInventory) -> some View {
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
                        let packages = inventory.getPackagesForWeight(weight)
                        let total = packages.reduce(0, +)
                        
                        if total > 0 {
                            weightDetailSection(weight: weight, packages: packages, eggType: eggType)
                        }
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
    private func weightDetailSection(weight: Int, packages: [Int], eggType: EggType) -> some View {
        let total = packages.reduce(0, +)
        
        VStack(spacing: 8) {
            HStack {
                Text("Paquetes de \(weight) kg")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Spacer()
                
                Text("Total: \(total)")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(eggType.color)
            }
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 5), spacing: 6) {
                ForEach(0..<10, id: \.self) { decimal in
                    if packages[decimal] > 0 {
                        VStack(spacing: 2) {
                            Text("\(weight).\(decimal)")
                                .font(.caption2)
                                .fontWeight(.medium)
                            
                            Text("\(packages[decimal])")
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundColor(eggType.color)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 4)
                        .background(eggType.color.opacity(0.1))
                        .cornerRadius(4)
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
    
    // MARK: - Tab 2: Movimientos
    @ViewBuilder
    private var movementsTab: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                if isLoading {
                    ProgressView("Cargando movimientos...")
                        .padding()
                } else if cargoEntries.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "tray")
                            .font(.system(size: 60))
                            .foregroundColor(.gray)
                        
                        Text("No hay movimientos registrados")
                            .font(.headline)
                            .fontWeight(.medium)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 40)
                } else {
                    ForEach(cargoEntries.sorted(by: { $0.timestamp > $1.timestamp })) { entry in
                        movementDetailCard(entry)
                    }
                }
            }
            .padding(.vertical)
        }
    }
    
    @ViewBuilder
    private func movementDetailCard(_ entry: CargoEntry) -> some View {
        VStack(spacing: 12) {
            // Header del movimiento
            HStack {
                Image(systemName: entry.type.icon)
                    .font(.title2)
                    .foregroundColor(movementColor(for: entry.type))
                    .frame(width: 32, height: 32)
                    .background(movementColor(for: entry.type).opacity(0.1))
                    .cornerRadius(8)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(entry.type.displayName)
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Text(entry.timestamp.timestampString)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 2) {
                    Text("\(entry.totalPackages)")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(movementColor(for: entry.type))
                    
                    Text(String(format: "%.1f kg", entry.totalWeight))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            // Información del proveedor
            if !entry.supplier.isEmpty && entry.supplier != "Sistema" {
                HStack {
                    Image(systemName: "person.fill")
                        .foregroundColor(.blue)
                    Text("Proveedor: \(entry.supplier)")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    Spacer()
                }
                .padding(.horizontal)
            }
            
            // Desglose por tipo de huevo
            if entry.rosadoPackages.getTotalPackages() > 0 || entry.pardoPackages.getTotalPackages() > 0 {
                VStack(spacing: 8) {
                    HStack {
                        Text("Desglose por Tipo:")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        Spacer()
                    }
                    
                    HStack(spacing: 12) {
                        if entry.rosadoPackages.getTotalPackages() > 0 {
                            eggTypeMovementCard(
                                type: .rosado,
                                packages: entry.rosadoPackages.getTotalPackages(),
                                weight: entry.rosadoPackages.getTotalWeight()
                            )
                        }
                        
                        if entry.pardoPackages.getTotalPackages() > 0 {
                            eggTypeMovementCard(
                                type: .pardo,
                                packages: entry.pardoPackages.getTotalPackages(),
                                weight: entry.pardoPackages.getTotalWeight()
                            )
                        }
                    }
                }
                .padding(.horizontal)
            }
            
            // Notas
            if let notes = entry.notes, !notes.isEmpty {
                HStack {
                    Image(systemName: "note.text")
                        .foregroundColor(.orange)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Notas:")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.secondary)
                        Text(notes)
                            .font(.subheadline)
                    }
                    Spacer()
                }
                .padding(.horizontal)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    @ViewBuilder
    private func eggTypeMovementCard(type: EggType, packages: Int, weight: Double) -> some View {
        HStack {
            Circle()
                .fill(type.color)
                .frame(width: 12, height: 12)
            
            VStack(alignment: .leading, spacing: 2) {
                Text("\(packages) paq")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(type.color)
                
                Text(String(format: "%.1f kg", weight))
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 4)
        .padding(.horizontal, 8)
        .background(type.color.opacity(0.1))
        .cornerRadius(6)
    }
    
    // MARK: - Propiedades calculadas
    private var uniqueSuppliersWithStats: [(name: String, packages: Int, deliveries: Int)] {
        let incomingEntries = cargoEntries.filter { $0.type == LoadType.incoming && !$0.supplier.isEmpty && $0.supplier != "Sistema" }
        
        let grouped = Dictionary(grouping: incomingEntries) { $0.supplier }
        
        return grouped.map { (supplier, entries) in
            (
                name: supplier,
                packages: entries.reduce(0) { $0 + $1.totalPackages },
                deliveries: entries.count
            )
        }.sorted { $0.packages > $1.packages }
    }
    
    // MARK: - Funciones de ayuda
    private func movementColor(for type: LoadType) -> Color {
        switch type {
        case .incoming: return .green
        case .outgoing: return .red
        case .adjustment: return .orange
        case .dayClose: return .blue
        }
    }
    
    private func formatDateFromString(_ dateString: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        
        if let date = formatter.date(from: dateString) {
            let displayFormatter = DateFormatter()
            displayFormatter.dateFormat = "EEEE, dd MMMM yyyy"
            displayFormatter.locale = Locale(identifier: "es_ES")
            return displayFormatter.string(from: date).capitalized
        }
        
        return dateString
    }
    
    private func relativeDateString(from dateString: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        
        guard let date = formatter.date(from: dateString) else { return "" }
        
        let calendar = Calendar.current
        let today = Date()
        
        if calendar.isDateInToday(date) {
            return "Hoy"
        } else if calendar.isDateInYesterday(date) {
            return "Ayer"
        } else {
            let components = calendar.dateComponents([.day], from: date, to: today)
            if let days = components.day {
                if days > 0 {
                    return "Hace \(days) día\(days == 1 ? "" : "s")"
                } else {
                    return "En \(-days) día\(days == -1 ? "" : "s")"
                }
            }
        }
        
        return ""
    }
    
    private func loadMovements() async {
        print("🔄 Cargando movimientos para: \(dayStock.date)")
        isLoading = true
        cargoEntries = await fetchCargoEntries(for: dayStock.date)
        isLoading = false
        print("✅ Cargados \(cargoEntries.count) movimientos")
    }
    
    private func fetchCargoEntries(for date: String) async -> [CargoEntry] {
        do {
            return try await FirebaseManager.shared.fetchCargoEntries(for: date)
        } catch {
            print("❌ Error fetching cargo entries: \(error)")
            return []
        }
    }
}

#Preview {
    NavigationView {
        DetailHistoryView(dayStock: DailyStock(date: "2025-06-27"))
    }
}
