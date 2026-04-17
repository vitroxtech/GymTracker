import SwiftUI

struct AddBodyMetricsView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    
    @State private var weight: String = ""
    @State private var triceps: String = ""
    @State private var subscapular: String = ""
    @State private var abdominal: String = ""
    @State private var suprailiac: String = ""
    
    @State private var selectedGender: String = "Male"
    let genders = ["Male", "Female"]
    
    var bodyFatPercentage: Double {
        let t = Double(triceps) ?? 0.0
        let s = Double(subscapular) ?? 0.0
        let a = Double(abdominal) ?? 0.0
        let si = Double(suprailiac) ?? 0.0
        
        let sum = t + s + a + si
        if sum == 0 { return 0.0 }
        
        // Faulkner 4-skinfold formula
        return (sum * 0.153) + 5.783
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Gender Selection")) {
                    Picker("Gender", selection: $selectedGender) {
                        ForEach(genders, id: \.self) {
                            Text($0)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                }
                
                Section(header: Text("Weight")) {
                    HStack {
                        TextField("Weight", text: $weight)
                            .keyboardType(.decimalPad)
                        Text("kg")
                            .foregroundColor(.secondary)
                    }
                }
                
                Section(header: Text("Skinfolds (mm)")) {
                    HStack {
                        Text("Triceps")
                        Spacer()
                        TextField("0", text: $triceps).keyboardType(.decimalPad).multilineTextAlignment(.trailing)
                    }
                    HStack {
                        Text("Subescapular")
                        Spacer()
                        TextField("0", text: $subscapular).keyboardType(.decimalPad).multilineTextAlignment(.trailing)
                    }
                    HStack {
                        Text("Abdominal")
                        Spacer()
                        TextField("0", text: $abdominal).keyboardType(.decimalPad).multilineTextAlignment(.trailing)
                    }
                    HStack {
                        Text("Suprailiaco")
                        Spacer()
                        TextField("0", text: $suprailiac).keyboardType(.decimalPad).multilineTextAlignment(.trailing)
                    }
                }
                
                Section(header: Text("Results")) {
                    HStack {
                        Text("Estimated Body Fat")
                        Spacer()
                        Text(String(format: "%.1f %%", bodyFatPercentage))
                            .fontWeight(.bold)
                            .foregroundColor(bodyFatPercentage > 0 ? .blue : .primary)
                    }
                }
            }
            .navigationTitle("Add Metrics")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveMetrics()
                    }
                    .disabled(weight.isEmpty)
                }
            }
        }
    }
    
    private func saveMetrics() {
        let newMetrics = BodyMetrics(context: viewContext)
        newMetrics.date = Date()
        newMetrics.weight = Double(weight) ?? 0.0
        newMetrics.triceps = Double(triceps) ?? 0.0
        newMetrics.subscapular = Double(subscapular) ?? 0.0
        newMetrics.abdominal = Double(abdominal) ?? 0.0
        newMetrics.suprailiac = Double(suprailiac) ?? 0.0
        newMetrics.bodyFatPercentage = bodyFatPercentage
        newMetrics.gender = selectedGender
        
        do {
            try viewContext.save()
            dismiss()
        } catch {
            print("Failed to save metrics: \(error.localizedDescription)")
        }
    }
}
