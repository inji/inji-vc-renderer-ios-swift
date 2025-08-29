import Foundation

class NetworkHandler {
    func fetchSvgAsText(url: String) -> String? {
        guard let url = URL(string: url) else { return nil }
        
        var result: String? = nil
        let semaphore = DispatchSemaphore(value: 0)
        
        let task = URLSession.shared.dataTask(with: url) { data, response, error in
            defer { semaphore.signal() }
            
            if let error = error {
                print("Network error: \(error)")
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200 else {
                print("Unexpected response")
                return
            }
            
            guard let mimeType = httpResponse.mimeType,
                  mimeType == "image/svg+xml" else {
                print("Expected image/svg+xml but got something else")
                return
            }
            
            if let data = data, let text = String(data: data, encoding: .utf8) {
                result = text
            }
        }
        
        task.resume()
        semaphore.wait() // 🚨 Blocks until request finishes (sync like OkHttp in Kotlin)
        return result
    }
}
