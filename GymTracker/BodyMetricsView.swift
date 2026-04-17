import SwiftUI
import CoreData
import Charts

struct BodyMetricsView: View {
    @Environment(\.managedObjectContext) private var viewContext
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \BodyMetrics.date, ascending: false)],
        animation: .default)
    private var metrics: FetchedResults<BodyMetrics>
    
    @State private var showingAddMetrics = false
    
    var body: some View {
        NavigationStack {
            List {
                if !metrics.isEmpty {
                    Section {
                        VStack(alignment: .leading) {
                            Text("Body Fat Trend")
                                .font(.headline)
                                .padding(.bottom, 5)
                            
                            Chart {
                                ForEach(metrics.reversed(), id: \.self) { metric in
                                    if let date = metric.date, metric.bodyFatPercentage > 0 {
                                        LineMark(
                                            x: .value("Date", date),
                                            y: .value("Body Fat %", metric.bodyFatPercentage)
                                        )
                                        .symbol(Circle())
                                        .interpolationMethod(.catmullRom)
                                    }
                                }
                            }
                            .frame(height: 150)
                            .chartYScale(domain: [minBodyFat - 2, maxBodyFat + 2])
                        }
                        .padding(.vertical, 8)
                    }
                }
                
                Section(header: Text("History")) {
                    if metrics.isEmpty {
                        Text("No metrics recorded yet.")
                            .foregroundColor(.secondary)
                    } else {
                        ForEach(metrics, id: \.self) { metric in
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(metric.date ?? Date(), formatter: dateFormatter)
                                        .font(.headline)
                                    Text(String(format: "Weight: %.1f kg", metric.weight))
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                }
                                
                                Spacer()
                                
                                if metric.bodyFatPercentage > 0 {
                                    VStack(alignment: .trailing, spacing: 4) {
                                        Text(String(format: "%.1f%%", metric.bodyFatPercentage))
                                            .font(.title3)
                                            .fontWeight(.bold)
                                            .foregroundColor(.blue)
                                        Text("Fat")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                }
                            }
                        }
                        .onDelete(perform: deleteMetrics)
                    }
                }
            }
            .navigationTitle("Body Metrics")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button(action: { showingAddMetrics = true }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddMetrics) {
                AddBodyMetricsView()
            }
        }
    }
    
    private var minBodyFat: Double {
        let nonZero = metrics.map { $0.bodyFatPercentage }.filter { $0 > 0.0 }
        return nonZero.min() ?? 0
    }
    
    private var maxBodyFat: Double {
        let nonZero = metrics.map { $0.bodyFatPercentage }.filter { $0 > 0.0 }
        return nonZero.max() ?? 20
    }
    
    private func deleteMetrics(offsets: IndexSet) {
        withAnimation {
            offsets.map { metrics[$0] }.forEach(viewContext.delete)
            do {
                try viewContext.save()
            } catch {
                print("Error deleting metric: \(error)")
            }
        }
    }
}

private let dateFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateStyle = .medium
    formatter.timeStyle = .none
    return formatter
}()
