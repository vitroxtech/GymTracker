import Foundation
import CoreData

class GoogleSheetsSyncManager: ObservableObject {
    static let shared = GoogleSheetsSyncManager()
    
    private let urlKey = "google_sheets_webhook_url"
    
    @Published var webhookURL: String {
        didSet {
            UserDefaults.standard.set(webhookURL, forKey: urlKey)
        }
    }
    
    @Published var isSyncing = false
    @Published var lastSyncError: String?
    
    private init() {
        self.webhookURL = UserDefaults.standard.string(forKey: urlKey) ?? ""
    }
    
    func sync(context: NSManagedObjectContext) {
        guard !webhookURL.isEmpty else {
            print("Sync failed: Webhook URL is empty")
            return
        }
        
        guard let url = URL(string: webhookURL) else {
            lastSyncError = "Invalid Webhook URL"
            return
        }
        
        isSyncing = true
        lastSyncError = nil
        
        // Export CSV data
        let csvBody = CSVManager.shared.exportToCSV(context: context)
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("text/csv", forHTTPHeaderField: "Content-Type")
        request.httpBody = csvBody.data(using: .utf8)
        
        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            DispatchQueue.main.async {
                self?.isSyncing = false
                
                if let error = error {
                    self?.lastSyncError = "Network error: \(error.localizedDescription)"
                    print("Sync failed: \(error.localizedDescription)")
                    return
                }
                
                if let httpResponse = response as? HTTPURLResponse, !(200...299).contains(httpResponse.statusCode) {
                    self?.lastSyncError = "Server error: \(httpResponse.statusCode)"
                    print("Sync failed: Server returned \(httpResponse.statusCode)")
                    return
                }
                
                print("Sync successful!")
            }
        }.resume()
    }
}
