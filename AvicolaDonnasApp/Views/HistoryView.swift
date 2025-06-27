//
//  HistoryView.swift
//  AvicolaDonnasApp
//
//  Created by Victor Martinez on 26/06/25.
//

import SwiftUI

struct HistoryView: View {
    // ✅ USAR SINGLETON EN LUGAR DE CREAR NUEVA INSTANCIA
    @ObservedObject private var stockViewModel = StockViewModel.shared
    
    @State private var selectedSegment = 0 // 0: Por días, 1: Por movimientos
    @State private var selectedDateRange = DateRange.lastWeek
    @State private var customStartDate = Date()
    @State private var customEndDate = Date()
    @State private var searchText = ""
    @State private var selectedSupplier = "Todos"
    @State private var selectedEggType = EggTypeFilter.all
    @State private var showingFilters = false
    @State private var showingDatePicker = false
    
    // Datos filtrados
    @State private var filteredDailyStocks: [DailyStock] = []
    @State private var filteredCargoEntries: [CargoEntry] = []
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Segmented Control
                segmentedControl
                
                // Filtros y búsqueda
                filtersSection
                
                // Contenido principal
                TabView(selection: $selectedSegment) {
                    // Vista por días
                    dailyHistoryView
                        .tag(0)
                    
                    // Vista por movimientos
                    movementsHistoryView
                        .tag(1)
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
            }
            .navigationTitle("Historial")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showingFilters.toggle()
                    }) {
                        Image(systemName: "line.3.horizontal.decrease.circle")
                            .font(.title3)
                    }
                }
                
                // ✅ AGREGAR BOTÓN DE REFRESH
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Actualizar") {
                        Task {
                            await loadData()
                        }
                    }
                    .disabled(stockViewModel.isLoading)
                }
            }
            .sheet(isPresented: $showingFilters) {
                filtersSheet
            }
            .task {
                await loadData()
            }
            .refreshable {
                await loadData()
            }
        }
        .onAppear {
            print("📱 HistoryView apareció")
        }
    }
    
    // MARK: - Segmented Control
    @ViewBuilder
    private var segmentedControl: some View {
        Picker("Vista", selection: $selectedSegment) {
            Text("Por Días").tag(0)
            Text("Movimientos").tag(1)
        }
        .pickerStyle(SegmentedPickerStyle())
        .padding()
        .background(Color(.systemGray6))
    }
    
    // MARK: - Sección de filtros
    @ViewBuilder
    private var filtersSection: some View {
        VStack(spacing: 12) {
            // Búsqueda
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                
                TextField(selectedSegment == 0 ? "Buscar por fecha..." : "Buscar por proveedor...", text: $searchText)
                    .textFieldStyle(PlainTextFieldStyle())
                    .onChange(of: searchText) { _ in
                        applyFilters()
                    }
                
                if !searchText.isEmpty {
                    Button(action: {
                        searchText = ""
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color(.systemGray6))
            .cornerRadius(8)
            .padding(.top, 10)
            
            // Filtros rápidos
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(DateRange.allCases, id: \.self) { range in
                        filterChip(
                            title: range.displayName,
                            isSelected: selectedDateRange == range,
                            action: {
                                selectedDateRange = range
                                applyFilters()
                            }
                        )
                    }
                    
                    filterChip(
                        title: "Personalizado",
                        isSelected: selectedDateRange == .custom,
                        action: {
                            selectedDateRange = .custom
                            showingDatePicker = true
                        }
                    )
                }
                .padding(.horizontal)
            }
        }
        .padding(.horizontal)
        .padding(.bottom, 8)
        .background(Color(.systemBackground))
    }
    
    @ViewBuilder
    private func filterChip(title: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.caption)
                .fontWeight(.medium)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(isSelected ? Color.blue : Color(.systemGray5))
                .foregroundColor(isSelected ? .white : .primary)
                .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    // MARK: - Vista por días
    @ViewBuilder
    private var dailyHistoryView: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                if stockViewModel.isLoading {
                    ProgressView("Cargando historial...")
                        .padding()
                } else if filteredDailyStocks.isEmpty {
                    emptyStateView(message: "No hay días registrados en el período seleccionado")
                } else {
                    // Estadísticas del período
                    periodStatistics
                    
                    // Lista de días
                    ForEach(filteredDailyStocks) { dayStock in
                        NavigationLink(destination: DetailHistoryView(dayStock: dayStock)) {
                            dailyStockCard(dayStock)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
            }
            .padding()
        }
    }
    
    @ViewBuilder
    private func dailyStockCard(_ dayStock: DailyStock) -> some View {
        VStack(spacing: 12) {
            // Header con fecha y estado
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(formatDateFromString(dayStock.date))
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Text(relativeDateString(from: dayStock.date))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    HStack(spacing: 6) {
                        Circle()
                            .fill(dayStock.isClosed ? .red : .green)
                            .frame(width: 8, height: 8)
                        Text(dayStock.isClosed ? "Cerrado" : "Abierto")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(dayStock.isClosed ? .red : .green)
                    }
                    
                    if dayStock.isCurrentDay {
                        Text("HOY")
                            .font(.caption2)
                            .fontWeight(.bold)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(4)
                    }
                }
            }
            
            // Estadísticas del día
            HStack(spacing: 16) {
                statItem(
                    icon: "shippingbox.fill",
                    title: "Paquetes",
                    value: "\(dayStock.totalPackages)",
                    color: .blue
                )
                
                statItem(
                    icon: "scalemass.fill",
                    title: "Peso",
                    value: String(format: "%.1f kg", dayStock.totalWeight),
                    color: .green
                )
                
                if dayStock.rosadoPackages.getTotalPackages() > 0 {
                    statItem(
                        icon: "circle.fill",
                        title: "Rosado",
                        value: "\(dayStock.rosadoPackages.getTotalPackages())",
                        color: Color("rosado")
                    )
                }
                
                if dayStock.pardoPackages.getTotalPackages() > 0 {
                    statItem(
                        icon: "circle.fill",
                        title: "Pardo",
                        value: "\(dayStock.pardoPackages.getTotalPackages())",
                        color: Color("pardo")
                    )
                }
                
                Spacer()
            }
            
            // Últimas actualizaciones
            HStack {
                Image(systemName: "clock")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text("Actualizado: \(dayStock.updatedAt.timestampString)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    @ViewBuilder
    private func statItem(icon: String, title: String, value: String, color: Color) -> some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundColor(color)
            
            Text(value)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(color)
            
            Text(title)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
    }
    
    // MARK: - Vista por movimientos
    @ViewBuilder
    private var movementsHistoryView: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                if stockViewModel.isLoading {
                    ProgressView("Cargando movimientos...")
                        .padding()
                } else if filteredCargoEntries.isEmpty {
                    emptyStateView(message: "No hay movimientos registrados en el período seleccionado")
                } else {
                    // Resumen de movimientos
                    movementsStatistics
                    
                    // Lista de movimientos agrupados por día
                    ForEach(groupedMovements.keys.sorted(by: >), id: \.self) { date in
                        movementDaySection(date: date, entries: groupedMovements[date] ?? [])
                    }
                }
            }
            .padding()
        }
    }
    
    @ViewBuilder
    private func movementDaySection(date: String, entries: [CargoEntry]) -> some View {
        VStack(spacing: 8) {
            // Header del día
            HStack {
                Text(formatDateFromString(date))
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Text("\(entries.count) movimiento\(entries.count == 1 ? "" : "s")")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal)
            
            // Movimientos del día
            LazyVStack(spacing: 6) {
                ForEach(entries) { entry in
                    movementCard(entry)
                }
            }
        }
        .padding(.vertical, 8)
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    @ViewBuilder
    private func movementCard(_ entry: CargoEntry) -> some View {
        HStack(spacing: 12) {
            // Ícono del tipo de movimiento
            Image(systemName: entry.type.icon)
                .font(.title3)
                .foregroundColor(movementColor(for: entry.type))
                .frame(width: 32, height: 32)
                .background(movementColor(for: entry.type).opacity(0.1))
                .cornerRadius(8)
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(entry.type.displayName)
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    if !entry.supplier.isEmpty && entry.supplier != "Sistema" {
                        Text("• \(entry.supplier)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                }
                
                Text(entry.eggTypeSummary)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
                
                if let notes = entry.notes, !notes.isEmpty {
                    Text(notes)
                        .font(.caption)
                        .foregroundColor(.blue)
                        .lineLimit(1)
                        .truncationMode(.tail)
                }
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text("\(entry.totalPackages)")
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundColor(movementColor(for: entry.type))
                
                Text(String(format: "%.1f kg", entry.totalWeight))
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text(entry.timestamp.timestampString.components(separatedBy: " ").last ?? "")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color(.systemBackground))
        .cornerRadius(8)
    }
    
    // MARK: - Estadísticas del período
    @ViewBuilder
    private var periodStatistics: some View {
        VStack(spacing: 12) {
            HStack {
                Text("Resumen del Período")
                    .font(.headline)
                    .fontWeight(.semibold)
                Spacer()
                Text(selectedDateRange.displayName)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                periodStatCard(
                    title: "Días Registrados",
                    value: "\(filteredDailyStocks.count)",
                    icon: "calendar",
                    color: .blue
                )
                
                periodStatCard(
                    title: "Total Paquetes",
                    value: "\(totalPackagesInPeriod)",
                    icon: "shippingbox.fill",
                    color: .green
                )
                
                periodStatCard(
                    title: "Peso Total",
                    value: String(format: "%.1f kg", totalWeightInPeriod),
                    icon: "scalemass.fill",
                    color: .orange
                )
                
                periodStatCard(
                    title: "Promedio/Día",
                    value: "\(averagePackagesPerDay)",
                    icon: "chart.bar",
                    color: .purple
                )
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    @ViewBuilder
    private func periodStatCard(title: String, value: String, icon: String, color: Color) -> some View {
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
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(8)
    }
    
    // MARK: - Estadísticas de movimientos
    @ViewBuilder
    private var movementsStatistics: some View {
        VStack(spacing: 12) {
            HStack {
                Text("Resumen de Movimientos")
                    .font(.headline)
                    .fontWeight(.semibold)
                Spacer()
            }
            
            HStack(spacing: 12) {
                ForEach(LoadType.allCases, id: \.self) { type in
                    let count = filteredCargoEntries.filter { $0.type == type }.count
                    if count > 0 {
                        movementTypeCard(type: type, count: count)
                    }
                }
                
                Spacer()
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    @ViewBuilder
    private func movementTypeCard(type: LoadType, count: Int) -> some View {
        VStack(spacing: 6) {
            Image(systemName: type.icon)
                .font(.title3)
                .foregroundColor(movementColor(for: type))
            
            Text("\(count)")
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(movementColor(for: type))
            
            Text(type.displayName)
                .font(.caption2)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(movementColor(for: type).opacity(0.1))
        .cornerRadius(8)
    }
    
    // MARK: - Vista vacía
    @ViewBuilder
    private func emptyStateView(message: String) -> some View {
        VStack(spacing: 16) {
            Image(systemName: selectedSegment == 0 ? "calendar.badge.exclamationmark" : "tray")
                .font(.system(size: 60))
                .foregroundColor(.gray)
            
            Text(message)
                .font(.headline)
                .fontWeight(.medium)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Button("Actualizar") {
                Task {
                    await loadData()
                }
            }
            .font(.subheadline)
            .foregroundColor(.blue)
        }
        .padding(.vertical, 60)
    }
    
    // MARK: - Sheet de filtros
    @ViewBuilder
    private var filtersSheet: some View {
        NavigationView {
            Form {
                Section("Rango de Fechas") {
                    Picker("Período", selection: $selectedDateRange) {
                        ForEach(DateRange.allCases, id: \.self) { range in
                            Text(range.displayName).tag(range)
                        }
                    }
                    
                    if selectedDateRange == .custom {
                        DatePicker("Fecha inicio", selection: $customStartDate, displayedComponents: .date)
                        DatePicker("Fecha fin", selection: $customEndDate, displayedComponents: .date)
                    }
                }
                
                if selectedSegment == 1 {
                    Section("Filtrar Movimientos") {
                        Picker("Proveedor", selection: $selectedSupplier) {
                            Text("Todos").tag("Todos")
                            ForEach(uniqueSuppliers, id: \.self) { supplier in
                                Text(supplier).tag(supplier)
                            }
                        }
                        
                        Picker("Tipo de Huevo", selection: $selectedEggType) {
                            ForEach(EggTypeFilter.allCases, id: \.self) { filter in
                                Text(filter.displayName).tag(filter)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Filtros")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cerrar") {
                        showingFilters = false
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Aplicar") {
                        applyFilters()
                        showingFilters = false
                    }
                }
            }
        }
    }
    
    // MARK: - Computed Properties
    private var groupedMovements: [String: [CargoEntry]] {
        Dictionary(grouping: filteredCargoEntries) { $0.date }
    }
    
    private var totalPackagesInPeriod: Int {
        filteredDailyStocks.reduce(0) { $0 + $1.totalPackages }
    }
    
    private var totalWeightInPeriod: Double {
        filteredDailyStocks.reduce(0) { $0 + $1.totalWeight }
    }
    
    private var averagePackagesPerDay: Int {
        guard !filteredDailyStocks.isEmpty else { return 0 }
        return totalPackagesInPeriod / filteredDailyStocks.count
    }
    
    private var uniqueSuppliers: [String] {
        Array(Set(stockViewModel.allCargoEntries
            .filter { !$0.supplier.isEmpty && $0.supplier != "Sistema" }
            .map { $0.supplier }))
            .sorted()
    }
    
    // MARK: - Helper Functions
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
            displayFormatter.dateFormat = "dd MMM yyyy"
            displayFormatter.locale = Locale(identifier: "es_ES")
            return displayFormatter.string(from: date)
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
    
    private func loadData() async {
        print("🔄 Cargando datos del historial...")
        await stockViewModel.loadStockHistory()
        await stockViewModel.loadAllCargoEntries()
        applyFilters()
        print("✅ Datos del historial cargados")
    }
    
    private func applyFilters() {
        let (startDate, endDate) = selectedDateRange.dateRange(customStart: customStartDate, customEnd: customEndDate)
        
        // Filtrar días
        filteredDailyStocks = stockViewModel.stockHistory.filter { stock in
            guard let date = DateFormatter.dailyFormat.date(from: stock.date) else { return false }
            return date >= startDate && date <= endDate
        }
        
        // Aplicar búsqueda en días
        if !searchText.isEmpty && selectedSegment == 0 {
            filteredDailyStocks = filteredDailyStocks.filter { stock in
                stock.date.contains(searchText) || formatDateFromString(stock.date).localizedCaseInsensitiveContains(searchText)
            }
        }
        
        // Filtrar movimientos
        filteredCargoEntries = stockViewModel.allCargoEntries.filter { entry in
            guard let date = DateFormatter.dailyFormat.date(from: entry.date) else { return false }
            var matches = date >= startDate && date <= endDate
            
            // Filtrar por proveedor
            if selectedSupplier != "Todos" {
                matches = matches && entry.supplier == selectedSupplier
            }
            
            // Filtrar por tipo de huevo
            switch selectedEggType {
            case .rosado:
                matches = matches && entry.hasEggType(.rosado)
            case .pardo:
                matches = matches && entry.hasEggType(.pardo)
            case .all:
                break
            }
            
            return matches
        }
        
        // Aplicar búsqueda en movimientos
        if !searchText.isEmpty && selectedSegment == 1 {
            filteredCargoEntries = filteredCargoEntries.filter { entry in
                entry.supplier.localizedCaseInsensitiveContains(searchText) ||
                entry.type.displayName.localizedCaseInsensitiveContains(searchText) ||
                (entry.notes?.localizedCaseInsensitiveContains(searchText) ?? false)
            }
        }
        
        print("📊 Filtros aplicados: \(filteredDailyStocks.count) días, \(filteredCargoEntries.count) movimientos")
    }
}

// MARK: - Supporting Types
enum DateRange: CaseIterable {
    case today, yesterday, lastWeek, lastMonth, last3Months, custom
    
    var displayName: String {
        switch self {
        case .today: return "Hoy"
        case .yesterday: return "Ayer"
        case .lastWeek: return "7 días"
        case .lastMonth: return "30 días"
        case .last3Months: return "3 meses"
        case .custom: return "Personalizado"
        }
    }
    
    func dateRange(customStart: Date = Date(), customEnd: Date = Date()) -> (start: Date, end: Date) {
        let calendar = Calendar.current
        let today = Date()
        
        switch self {
        case .today:
            return (start: calendar.startOfDay(for: today), end: today)
        case .yesterday:
            let yesterday = calendar.date(byAdding: .day, value: -1, to: today)!
            return (start: calendar.startOfDay(for: yesterday), end: calendar.startOfDay(for: today))
        case .lastWeek:
            let weekAgo = calendar.date(byAdding: .day, value: -7, to: today)!
            return (start: weekAgo, end: today)
        case .lastMonth:
            let monthAgo = calendar.date(byAdding: .day, value: -30, to: today)!
            return (start: monthAgo, end: today)
        case .last3Months:
            let threeMonthsAgo = calendar.date(byAdding: .month, value: -3, to: today)!
            return (start: threeMonthsAgo, end: today)
        case .custom:
            return (start: customStart, end: customEnd)
        }
    }
}

#Preview {
    HistoryView()
}
