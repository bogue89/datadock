import Foundation
import Synchronized

public extension DataDock {
    class DataDockDelegate: NSObject {

        @Synchronized
        private var handlers: [() -> Void] = []
        @Synchronized
        private var callbacks: [URL: [(Result<Data, Error>) -> Void]] = [:]
        @Synchronized
        private var stream: [URL: Data] = [:]

        public func hasCallbacks(for url: URL) -> Bool {
            guard let callbacks = self.callbacks[url] else { return false }
            return !callbacks.isEmpty
        }

        public func addCompletion(handler: @escaping (() -> Void)) {
            self.handlers.append(handler)
        }

        public func addCompletion(for url: URL, completion: @escaping (Result<Data, Error>) -> Void) {
            var callbacks = self.callbacks[url] ?? []
            callbacks.append(completion)
            self.callbacks[url] = callbacks
        }

        private func fireCallbacks(for url: URL, with result: Result<Data, Error>) {
            guard let callbacks = self.callbacks[url] else { return }
            callbacks.forEach { $0(result) }
            self.callbacks.removeValue(forKey: url)
            if self.callbacks.isEmpty {
                fireCompletion()
            }
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
        stream[url] = (self.stream[url] ?? Data()) + data
    }
}

extension DataDock.DataDockDelegate: URLSessionDelegate {
    public func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        guard let url = task.originalRequest?.url else { return }
        if let error = error {
            fireCallbacks(for: url, with: .failure(error))
        } else if let data = stream[url] {
            fireCallbacks(for: url, with: .success(data))
        }
    }
}

extension DataDock.DataDockDelegate: URLSessionDownloadDelegate {
    public func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        guard let url = downloadTask.originalRequest?.url, let data = try? Data(contentsOf: location) else { return }
        fireCallbacks(for: url, with: .success(data))
    }

    public func urlSessionDidFinishEvents(forBackgroundURLSession session: URLSession) {
        fireCompletion()
    }
}
