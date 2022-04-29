import Foundation
import Synchronized
import FlyweightFactory

public class DataDockDelegate: NSObject {

    public let operationQueue: OperationQueue
    @Synchronized
    private var handlers: [() -> Void] = []
    @Synchronized
    private var tasks: [URL: Task] = [:]

    public init(qualityOfService: QualityOfService = .utility) {
        let operationQueue = OperationQueue()
        operationQueue.qualityOfService = qualityOfService
        operationQueue.maxConcurrentOperationCount = 1
        self.operationQueue = operationQueue
    }
    
}

extension DataDockDelegate {

    private struct Task {
        var wrappedValue: URLSessionTask
        var callbacks: [(Result<Data, Error>) -> Void] = []
        var data: Data = .init()
    }

    // MARK: DataDockDelegate Factory
    public static func instance(for id: String) -> DataDockDelegate {
        Factory.instance(for: id, initializer: {
            DataDockDelegate()
        })
    }

    public static func destroy(for id: String) {
        Factory.destroy(with: id)
    }

    private struct Factory: FlyweightFactory {
        static var instances: [String : DataDockDelegate] = [:]
    }

    // MARK: DataDockDelegate handlers
    public func addCompletionHandler(_ completion: @escaping () -> Void) {
        handlers.append(completion)
    }

    private func fireCompletion() {
        handlers.forEach { $0() }
        handlers.removeAll()
    }

    // MARK: DataDockDelegate.Task Handling
    public func hasTask(for url: URL, withEqualOrGreaterPriority priority: Float = 0) -> Bool {
        guard let task = tasks[url] else { return false }
        return task.wrappedValue.priority >= priority
    }

    public func addTask(_ sessionTask: URLSessionTask) {
        guard let url = sessionTask.originalRequest?.url else { return }
        tasks[url]?.wrappedValue.cancel()
        tasks[url] = Task(wrappedValue: sessionTask)
    }

    public func addTaskCompletion(_ url: URL, completion: @escaping (Result<Data, Error>) -> Void) {
        guard var task = tasks[url] else { return }
        task.callbacks.append(completion)
        tasks[url] = task
    }

    private func fireCallbacks(for url: URL, with result: Result<Data, Error>) {
        if let task = tasks[url] {
            task.callbacks.forEach { $0(result) }
            tasks.removeValue(forKey: url)
        }
        if tasks.isEmpty {
            fireCompletion()
        }
    }
}

extension DataDockDelegate: URLSessionDelegate, URLSessionDataDelegate, URLSessionDownloadDelegate {
    // MARK: URLSessionDelegate
    public func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        guard let url = task.originalRequest?.url else { return }
        if let error = error {
            fireCallbacks(for: url, with: .failure(error))
        } else if let data = self.tasks[url]?.data {
            fireCallbacks(for: url, with: .success(data))
        }
    }

    // MARK: URLSessionDataDelegate
    public func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        guard let url = dataTask.originalRequest?.url else { return }
        let stream = self.tasks[url]?.data ?? Data()
        self.tasks[url]?.data = stream + data
    }

    // MARK: URLSessionDownloadDelegate
    public func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        guard let url = downloadTask.originalRequest?.url, let data = try? Data(contentsOf: location) else { return }
        fireCallbacks(for: url, with: .success(data))
    }

    public func urlSessionDidFinishEvents(forBackgroundURLSession session: URLSession) {
        fireCompletion()
    }
}
