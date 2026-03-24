import Foundation
import CallKit

class CallDirectoryHandler: CXCallDirectoryProvider {

    override func beginRequest(with context: CXCallDirectoryExtensionContext) {
        context.delegate = self

        // 1. Fetch data from the shared App Group container
        if let data = fetchNotesFromAppGroup() {
            // 2. Add identification entries (must be sorted by phone number)
            addAllIdentificationPhoneNumbers(to: context, data: data)
        }
        
        context.completeRequest()
    }

    private func fetchNotesFromAppGroup() -> [[String: String]]? {
        let appGroupId = "group.com.liquid.dialer.shared" // MUST match Flutter constant
        let fileName = "call_directory_data.json"
        
        guard let sharedContainer = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupId) else {
            return nil
        }
        
        let fileURL = sharedContainer.appendingPathComponent(fileName)
        
        do {
            let data = try Data(contentsOf: fileURL)
            let json = try JSONSerialization.jsonObject(with: data, options: []) as? [[String: String]]
            return json
        } catch {
            print("Error reading shared data: \(error)")
            return nil
        }
    }

    private func addAllIdentificationPhoneNumbers(to context: CXCallDirectoryExtensionContext, data: [[String: String]]) {
        for entry in data {
            if let numberString = entry["number"], 
               let label = entry["label"],
               let phoneNumber = Int64(numberString) {
                context.addIdentificationEntry(withNextSequentialPhoneNumber: phoneNumber, label: label)
            }
        }
    }
}

extension CallDirectoryHandler: CXCallDirectoryExtensionContextDelegate {
    func requestFailed(for extensionContext: CXCallDirectoryExtensionContext, withError error: Error) {
        // An error occurred while adding/removing identification or blocking entries
    }
}
