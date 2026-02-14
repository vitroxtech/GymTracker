import SwiftUI

struct CSVDataView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @State private var csvText: String = ""
    @State private var showingImportAlert = false
    @State private var importMessage = ""
    @FocusState private var isTextFieldFocused: Bool

    var body: some View {
        VStack(spacing: 20) {
            Text("CSV Data Management")
                .font(.title)
                .padding(.top)

            VStack(alignment: .leading) {
                Text("CSV Content:")
                    .font(.headline)
                
                TextEditor(text: $csvText)
                    .font(.system(.caption, design: .monospaced))
                    .frame(maxHeight: .infinity)
                    .border(Color.gray, width: 1)
                    .background(Color(white: 0.95))
                    .cornerRadius(4)
                    .focused($isTextFieldFocused)
            }
            .padding(.horizontal)

            HStack {
                Button(action: exportData) {
                    Label("Export CSV", systemImage: "square.and.arrow.up")
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }

                Button(action: {
                    UIPasteboard.general.string = csvText
                }) {
                    Label("Copy", systemImage: "doc.on.doc")
                        .padding()
                        .background(Color.gray)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
            }

            HStack {
                Button(action: {
                    if let pasted = UIPasteboard.general.string {
                        csvText = pasted
                    }
                }) {
                    Label("Paste", systemImage: "doc.on.clipboard")
                        .padding()
                        .background(Color.gray)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }

                Button(action: {
                    showingImportAlert = true
                }) {
                    Label("Import CSV", systemImage: "square.and.arrow.down")
                        .padding()
                        .background(Color.orange)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
            }
            .padding(.bottom)
        }
        .navigationTitle("CSV Data")
        .alert("IMPORT & REPLACE DATA", isPresented: $showingImportAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Import & Erase Current", role: .destructive) {
                importData()
            }
        } message: {
            Text("WARNING: This will DELETE ALL current workouts, exercises, and sessions from the app and replace them with the data in the text editor. This action cannot be undone.")
        }
    }

    private func exportData() {
        csvText = CSVManager.shared.exportToCSV(context: viewContext)
        isTextFieldFocused = false
    }

    private func importData() {
        CSVManager.shared.importFromCSV(csvText, context: viewContext)
        isTextFieldFocused = false
        // Refresh or show success?
        csvText = "" // Clear after import or keep? Clear to show it's "processed"
    }
}

struct CSVDataView_Previews: PreviewProvider {
    static var previews: some View {
        CSVDataView()
    }
}
