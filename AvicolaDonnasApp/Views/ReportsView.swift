//
//  ReportsView.swift
//  AvicolaDonnasApp
//
//  Created by Victor Martinez on 26/06/25.
//

import SwiftUI
import Charts

struct ReportsView: View {
    @StateObject private var stockViewModel = StockViewModel()
    @State private var selectedReportType: ReportType = .daily
    @State private var selectedDateRange: ReportDateRange = .lastWeek
    @State private var customStartDate = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
    @State private var customEndDate = Date()
    @State private var selectedEggTypeFilter: EggTypeFilter = .all
    @State private var selectedSupplierFilter = "Todos"
    @State private var showingFilters = false
    @State private var isGeneratingReport = false
    @State private var currentReportData: ReportData?
    @State private var showingExportOptions = false
    @State private var selectedChartType: ChartType = .line
    
    var body: some View {
        NavigationView {
            ScrollView {
                LazyVStack(spacing: 20) {
                    // Header con controles principales
                    reportControlsSection
                    
                    // Botón de generar reporte
                    generateReportButton
                    
                    // Contenido del reporte
                    if let reportData = currentReportData {
                        reportContentSection(reportData)
                    } else {
                        emptyReportState
                    }
                    
                    Spacer(minLength: 100)
                }
                .padding()
            }
            .navigationTitle("Reportes")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        showingFilters.toggle()
                    }) {
                        Image(systemName: "slider.horizontal.3")
                            .font(.title3)
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    if currentReportData != nil {
                        Button(action: {
                            showingExportOptions.toggle()
                        }) {
                            Image(systemName: "square.and.arrow.up")
                                .font(.title3)
                        }
                    }
                }
            }
            .sheet(isPresented: $showingFilters) {
                filtersSheet
            }
            .actionSheet(isPresented: $showingExportOptions) {
                exportActionSheet
            }
        }
        .task {
            await loadInitialData()
        }
    }
    
    // MARK: - Controles principales del reporte
    @ViewBuilder
    private var reportControlsSection: some View {
        VStack(spacing: 16) {
            // Selector de tipo de reporte
            VStack(alignment: .leading, spacing: 8) {
                Text("Tipo de Reporte")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Picker("Tipo de Reporte", selection: $selectedReportType) {
                    ForEach(ReportType.allCases, id: \.self) { type in
                        Text(type.displayName).tag(type)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
            }
            
            // Selector de rango de fechas
            VStack(alignment: .leading, spacing: 8) {
                Text("Período")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(ReportDateRange.allCases, id: \.self) { range in
                            dateRangeChip(range)
                        }
                    }
                    .padding(.horizontal)
                }
            }
            
            // Fechas personalizadas
            if selectedDateRange == .custom {
                VStack(spacing: 12) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Fecha Inicio")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            DatePicker("", selection: $customStartDate, displayedComponents: .date)
                                .labelsHidden()
                        }
                        
                        Spacer()
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Fecha Fin")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            DatePicker("", selection: $customEndDate, displayedComponents: .date)
                                .labelsHidden()
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    @ViewBuilder
    private func dateRangeChip(_ range: ReportDateRange) -> some View {
        Button(action: {
            selectedDateRange = range
        }) {
            VStack(spacing: 4) {
                Text(range.displayName)
                    .font(.caption)
                    .fontWeight(.medium)
                
                Text(range.description)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(selectedDateRange == range ? Color.blue : Color(.systemGray5))
            .foregroundColor(selectedDateRange == range ? .white : .primary)
            .cornerRadius(10)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    // MARK: - Botón de generar reporte
    @ViewBuilder
    private var generateReportButton: some View {
        Button(action: {
            Task {
                await generateReport()
            }
        }) {
            HStack {
                if isGeneratingReport {
                    ProgressView()
                        .scaleEffect(0.8)
                        .tint(.white)
                } else {
                    Image(systemName: "chart.bar.doc.horizontal")
                        .font(.title3)
                }
                
                Text(isGeneratingReport ? "Generando Reporte..." : "Generar Reporte")
                    .fontWeight(.semibold)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(isGeneratingReport ? Color.gray : Color.blue)
            .foregroundColor(.white)
            .cornerRadius(12)
        }
        .disabled(isGeneratingReport)
    }
    
    // MARK: - Contenido del reporte
    @ViewBuilder
    private func reportContentSection(_ reportData: ReportData) -> some View {
        VStack(spacing: 20) {
            // Header del reporte
            reportHeaderSection(reportData)
            
            // Métricas principales
            keyMetricsSection(reportData)
            
            // Gráfico principal
            mainChartSection(reportData)
            
            // Análisis por tipo de huevo
            eggTypeAnalysisSection(reportData)
            
            // Análisis por proveedor
            supplierAnalysisSection(reportData)
            
            // Tendencias y resumen
            trendsAndSummarySection(reportData)
        }
    }
    
    @ViewBuilder
    private func reportHeaderSection(_ reportData: ReportData) -> some View {
        VStack(spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(reportData.title)
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("Generado el \(Date().displayString)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text(reportData.dateRange)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.blue)
                    
                    Text("\(reportData.dailyStocks.count) días")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Divider()
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    @ViewBuilder
    private func keyMetricsSection(_ reportData: ReportData) -> some View {
        VStack(spacing: 12) {
            HStack {
                Text("Métricas Principales")
                    .font(.headline)
                    .fontWeight(.semibold)
                Spacer()
            }
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                metricCard(
                    title: "Total Paquetes",
                    value: "\(reportData.totalPackages)",
                    subtitle: "en el período",
                    icon: "shippingbox.fill",
                    color: .blue,
                    trend: reportData.packagesTrend
                )
                
                metricCard(
                    title: "Peso Total",
                    value: String(format: "%.1f kg", reportData.totalWeight),
                    subtitle: "acumulado",
                    icon: "scalemass.fill",
                    color: .green,
                    trend: reportData.weightTrend
                )
                
                metricCard(
                    title: "Promedio Diario",
                    value: "\(reportData.averagePackagesPerDay)",
                    subtitle: "paquetes/día",
                    icon: "chart.bar",
                    color: .orange,
                    trend: nil
                )
                
                metricCard(
                    title: "Días Activos",
                    value: "\(reportData.activeDays)",
                    subtitle: "con movimientos",
                    icon: "calendar",
                    color: .purple,
                    trend: nil
                )
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    @ViewBuilder
    private func metricCard(title: String, value: String, subtitle: String, icon: String, color: Color, trend: TrendDirection?) -> some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)
                
                Spacer()
                
                if let trend = trend {
                    Image(systemName: trend.icon)
                        .font(.caption)
                        .foregroundColor(trend.color)
                }
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(color)
                
                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                
                Text(subtitle)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(8)
    }
    
    // MARK: - Gráfico principal
    @ViewBuilder
    private func mainChartSection(_ reportData: ReportData) -> some View {
        VStack(spacing: 12) {
            HStack {
                Text("Tendencia de Paquetes")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Picker("Tipo de Gráfico", selection: $selectedChartType) {
                    ForEach(ChartType.allCases, id: \.self) { type in
                        Image(systemName: type.icon).tag(type)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .frame(width: 120)
            }
            
            if #available(iOS 16.0, *) {
                Chart {
                    ForEach(reportData.chartData, id: \.date) { dataPoint in
                        switch selectedChartType {
                        case .line:
                            LineMark(
                                x: .value("Fecha", dataPoint.date),
                                y: .value("Paquetes", dataPoint.totalPackages)
                            )
                            .foregroundStyle(.blue)
                            .symbol(Circle())
                            
                        case .bar:
                            BarMark(
                                x: .value("Fecha", dataPoint.date),
                                y: .value("Paquetes", dataPoint.totalPackages)
                            )
                            .foregroundStyle(.blue)
                            
                        case .area:
                            AreaMark(
                                x: .value("Fecha", dataPoint.date),
                                y: .value("Paquetes", dataPoint.totalPackages)
                            )
                            .foregroundStyle(.blue.opacity(0.3))
                        }
                        
                        // Líneas separadas para rosado y pardo si hay datos
                        if selectedChartType == .line && dataPoint.rosadoPackages > 0 {
                            LineMark(
                                x: .value("Fecha", dataPoint.date),
                                y: .value("Rosado", dataPoint.rosadoPackages)
                            )
                            .foregroundStyle(Color("rosado"))
                            .symbol(Circle())
                        }
                        
                        if selectedChartType == .line && dataPoint.pardoPackages > 0 {
                            LineMark(
                                x: .value("Fecha", dataPoint.date),
                                y: .value("Pardo", dataPoint.pardoPackages)
                            )
                            .foregroundStyle(Color("pardo"))
                            .symbol(Circle())
                        }
                    }
                }
                .frame(height: 200)
                .chartYAxis {
                    AxisMarks(position: .leading)
                }
                .chartXAxis {
                    AxisMarks(values: .automatic(desiredCount: 5))
                }
            } else {
                // Fallback para iOS 15
                VStack {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                        .font(.system(size: 60))
                        .foregroundColor(.gray)
                    Text("Gráficos disponibles en iOS 16+")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(height: 200)
            }
            
            // Leyenda
            HStack {
                legendItem(color: .blue, label: "Total")
                if reportData.hasRosadoData {
                    legendItem(color: Color("rosado"), label: "Rosado")
                }
                if reportData.hasPardoData {
                    legendItem(color: Color("pardo"), label: "Pardo")
                }
                Spacer()
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    @ViewBuilder
    private func legendItem(color: Color, label: String) -> some View {
        HStack(spacing: 4) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
    
    // MARK: - Análisis por tipo de huevo
    @ViewBuilder
    private func eggTypeAnalysisSection(_ reportData: ReportData) -> some View {
        VStack(spacing: 12) {
            HStack {
                Text("Análisis por Tipo de Huevo")
                    .font(.headline)
                    .fontWeight(.semibold)
                Spacer()
            }
            
            HStack(spacing: 12) {
                eggTypeCard(
                    type: .rosado,
                    packages: reportData.totalRosadoPackages,
                    percentage: reportData.rosadoPercentage,
                    trend: reportData.rosadoTrend
                )
                
                eggTypeCard(
                    type: .pardo,
                    packages: reportData.totalPardoPackages,
                    percentage: reportData.pardoPercentage,
                    trend: reportData.pardoTrend
                )
            }
            
            // Distribución por peso
            weightDistributionChart(reportData)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    @ViewBuilder
    private func eggTypeCard(type: EggType, packages: Int, percentage: Double, trend: TrendDirection?) -> some View {
        VStack(spacing: 12) {
            HStack {
                Circle()
                    .fill(type.color)
                    .frame(width: 16, height: 16)
                Text(type.displayName)
                    .font(.subheadline)
                    .fontWeight(.medium)
                Spacer()
                if let trend = trend {
                    Image(systemName: trend.icon)
                        .font(.caption)
                        .foregroundColor(trend.color)
                }
            }
            
            VStack(spacing: 4) {
                Text("\(packages)")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(type.color)
                
                Text(String(format: "%.1f%%", percentage))
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(type.color)
                
                Text("del total")
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
                        .fill(type.color)
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
                .stroke(type.color.opacity(0.3), lineWidth: 1)
        )
    }
    
    @ViewBuilder
    private func weightDistributionChart(_ reportData: ReportData) -> some View {
        VStack(spacing: 8) {
            HStack {
                Text("Distribución por Peso")
                    .font(.subheadline)
                    .fontWeight(.medium)
                Spacer()
            }
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 8) {
                ForEach(7...13, id: \.self) { weight in
                    let data = reportData.getWeightDistribution(weight)
                    if data.total > 0 {
                        weightDistributionCard(weight: weight, data: data)
                    }
                }
            }
        }
    }
    
    @ViewBuilder
    private func weightDistributionCard(weight: Int, data: (rosado: Int, pardo: Int, total: Int)) -> some View {
        VStack(spacing: 6) {
            Text("\(weight)kg")
                .font(.caption2)
                .fontWeight(.semibold)
            
            Text("\(data.total)")
                .font(.caption)
                .fontWeight(.bold)
                .foregroundColor(.blue)
            
            if data.rosado > 0 && data.pardo > 0 {
                HStack(spacing: 1) {
                    Rectangle()
                        .fill(Color("rosado"))
                        .frame(width: CGFloat(data.rosado) / CGFloat(data.total) * 20, height: 3)
                    Rectangle()
                        .fill(Color("pardo"))
                        .frame(width: CGFloat(data.pardo) / CGFloat(data.total) * 20, height: 3)
                }
                .cornerRadius(1.5)
            } else {
                Rectangle()
                    .fill(data.rosado > 0 ? Color("rosado") : Color("pardo"))
                    .frame(width: 20, height: 3)
                    .cornerRadius(1.5)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(Color(.systemBackground))
        .cornerRadius(6)
    }
    
    // MARK: - Análisis por proveedor
    @ViewBuilder
    private func supplierAnalysisSection(_ reportData: ReportData) -> some View {
        if !reportData.supplierData.isEmpty {
            VStack(spacing: 12) {
                HStack {
                    Text("Análisis por Proveedor")
                        .font(.headline)
                        .fontWeight(.semibold)
                    Spacer()
                    Text("\(reportData.supplierData.count) proveedores")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                LazyVStack(spacing: 8) {
                    ForEach(reportData.topSuppliers, id: \.name) { supplier in
                        supplierRow(supplier)
                    }
                }
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
        }
    }
    
    @ViewBuilder
    private func supplierRow(_ supplier: SupplierData) -> some View {
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
                Text("\(supplier.totalPackages)")
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundColor(.blue)
                
                Text(String(format: "%.1f%%", supplier.percentage))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(8)
    }
    
    // MARK: - Tendencias y resumen
    @ViewBuilder
    private func trendsAndSummarySection(_ reportData: ReportData) -> some View {
        VStack(spacing: 16) {
            // Insights automáticos
            insightsSection(reportData)
            
            // Recomendaciones
            recommendationsSection(reportData)
        }
    }
    
    @ViewBuilder
    private func insightsSection(_ reportData: ReportData) -> some View {
        VStack(spacing: 12) {
            HStack {
                Text("Insights Automáticos")
                    .font(.headline)
                    .fontWeight(.semibold)
                Spacer()
            }
            
            LazyVStack(spacing: 8) {
                ForEach(reportData.insights, id: \.self) { insight in
                    insightCard(insight)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    @ViewBuilder
    private func insightCard(_ insight: String) -> some View {
        HStack {
            Image(systemName: "lightbulb.fill")
                .foregroundColor(.yellow)
            
            Text(insight)
                .font(.subheadline)
                .multilineTextAlignment(.leading)
            
            Spacer()
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(8)
    }
    
    @ViewBuilder
    private func recommendationsSection(_ reportData: ReportData) -> some View {
        VStack(spacing: 12) {
            HStack {
                Text("Recomendaciones")
                    .font(.headline)
                    .fontWeight(.semibold)
                Spacer()
            }
            
            LazyVStack(spacing: 8) {
                ForEach(reportData.recommendations, id: \.self) { recommendation in
                    recommendationCard(recommendation)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    @ViewBuilder
    private func recommendationCard(_ recommendation: String) -> some View {
        HStack {
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(.green)
            
            Text(recommendation)
                .font(.subheadline)
                .multilineTextAlignment(.leading)
            
            Spacer()
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(8)
    }
    
    // MARK: - Estado vacío
    @ViewBuilder
    private var emptyReportState: some View {
        VStack(spacing: 20) {
            Image(systemName: "chart.bar.doc.horizontal")
                .font(.system(size: 80))
                .foregroundColor(.gray)
            
            VStack(spacing: 8) {
                Text("Generar Reporte")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.secondary)
                
                Text("Selecciona el tipo de reporte y el período que deseas analizar")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
        }
        .padding(.vertical, 60)
    }
    
    // MARK: - Sheet de filtros
    @ViewBuilder
    private var filtersSheet: some View {
        NavigationView {
            Form {
                Section("Filtros de Datos") {
                    Picker("Tipo de Huevo", selection: $selectedEggTypeFilter) {
                        ForEach(EggTypeFilter.allCases, id: \.self) { filter in
                            Text(filter.displayName).tag(filter)
                        }
                    }
                    
                    Picker("Proveedor", selection: $selectedSupplierFilter) {
                        Text("Todos").tag("Todos")
                        ForEach(uniqueSuppliers, id: \.self) { supplier in
                            Text(supplier).tag(supplier)
                        }
                    }
                }
                
                Section("Opciones de Visualización") {
                    Picker("Tipo de Gráfico", selection: $selectedChartType) {
                        ForEach(ChartType.allCases, id: \.self) { type in
                            Label(type.displayName, systemImage: type.icon).tag(type)
                        }
                    }
                }
            }
            .navigationTitle("Filtros Avanzados")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cerrar") {
                        showingFilters = false
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Aplicar") {
                        showingFilters = false
                        Task {
                            await generateReport()
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - ActionSheet de exportación
    private var exportActionSheet: ActionSheet {
        ActionSheet(
            title: Text("Exportar Reporte"),
            message: Text("Selecciona el formato de exportación"),
            buttons: [
                .default(Text("Compartir como PDF")) {
                    exportToPDF()
                },
                .default(Text("Compartir como Excel")) {
                    exportToExcel()
                },
                .default(Text("Compartir Imagen")) {
                    exportToImage()
                },
                .cancel()
            ]
        )
    }
    
    // MARK: - Computed Properties
    private var uniqueSuppliers: [String] {
        Array(Set(stockViewModel.allCargoEntries
            .filter { !$0.supplier.isEmpty && $0.supplier != "Sistema" }
            .map { $0.supplier }))
            .sorted()
    }
    
    // MARK: - Functions
    private func loadInitialData() async {
        await stockViewModel.loadStockHistory()
        await stockViewModel.loadAllCargoEntries()
    }
    
    private func generateReport() async {
        isGeneratingReport = true
        
        let (startDate, endDate) = selectedDateRange.dateRange(
            customStart: customStartDate,
            customEnd: customEndDate
        )
        
        let startDateString = DateFormatter.dailyFormat.string(from: startDate)
        let endDateString = DateFormatter.dailyFormat.string(from: endDate)
        
        currentReportData = await stockViewModel.generateReport(
            type: selectedReportType,
            startDate: startDateString,
            endDate: endDateString
        )
        
        isGeneratingReport = false
    }
    
    private func exportToPDF() {
        // Implementar exportación a PDF
        print("Exportando a PDF...")
    }
    
    private func exportToExcel() {
        // Implementar exportación a Excel
        print("Exportando a Excel...")
    }
    
    private func exportToImage() {
        // Implementar exportación de imagen
        print("Exportando imagen...")
    }
}

#Preview {
    ReportsView()
}
