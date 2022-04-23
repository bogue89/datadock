import Foundation
import Synchronized

public extension DataDock {
    class DataDockDelegate: NSObject {

        @Synchronized
        private var handlers: [(() -> Void)] = []
        @Synchronized
        private var callbacks: [URL: [((Data?) -> Void)]] = [:]

        public func hasCallbacks(for url: URL) -> Bool {
            guard let callbacks = self.callbacks[url] else { return false }
            return !callbacks.isEmpty
        }

        public func addCompletion(handler: @escaping (() -> Void)) {
            self.handlers.append(handler)
        }

        public func addCompletion(for url: URL, completion: @escaping (Data?) -> Void) {
            var callbacks = self.callbacks[url] ?? []
            callbacks.append(completion)
            self.callbacks[url] = callbacks
        }

        private func fireCallbacks(for url: URL, with data: Data?) {
            guard let callbacks = self.callbacks[url] else { return }
            callbacks.forEach { $0(data) }
            self.callbacks[url] = []
        }

        private func fireCompletion() {
            handlers.forEach { $0() }
            handlers = []
        }

    }

}

extension DataDock.DataDockDelegate: URLSessionDataDelegate {
    public func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        guard let url = dataTask.originalRequest?.url else { return }
        fireCallbacks(for: url, with: data)
    }
}

extension DataDock.DataDockDelegate: URLSessionDownloadDelegate {
    public func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        guard let url = downloadTask.originalRequest?.url else { return }
        fireCallbacks(for: url, with: try? Data(contentsOf: location))
    }

    public func urlSessionDidFinishEvents(forBackgroundURLSession session: URLSession) {
        fireCompletion()
    }
}
