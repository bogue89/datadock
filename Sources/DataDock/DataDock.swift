import Foundation
import FlyweightFactory

public struct DataDock {

    static let domain = "mx.pewpew.DataDock."

    private let configuration: DataDockConfiguration

    public init(configuration: DataDockConfiguration) {
        self.configuration = configuration
    }

    public static let `default` = DataDock(configuration: .default)
    public static let `background` = DataDock(configuration: .background)

    @discardableResult
    public func dataTask(_ url: URL,
                         priority: Float? = nil,
                         completion: ((Result<Data, Error>) -> Void)? = nil) -> URLSessionDataTask? {
        let request = URLRequest(url: url, cachePolicy: configuration.cachePolicy, timeoutInterval: configuration.timeoutInterval)
        return dataTask(request,
                        priority: priority ?? configuration.priority,
                        completion: completion)
    }

    @discardableResult
    public func dataTask(_ request: URLRequest,
                         priority: Float? = nil,
                         completion: ((Result<Data, Error>) -> Void)? = nil) -> URLSessionDataTask? {
        return dataTask(request,
                        session: Self.session(for: configuration),
                        delegate: configuration.delegate,
                        priority: priority ?? configuration.priority,
                        completion: completion)
    }

    @discardableResult
    public func dataTask(_ request: URLRequest,
                         session: URLSession,
                         delegate: DataDockDelegate,
                         priority: Float = URLSessionDataTask.defaultPriority,
                         completion: ((Result<Data, Error>) -> Void)? = nil) -> URLSessionDataTask? {
        guard let url = request.url else { return nil }

        var task: URLSessionDataTask?
        if !delegate.hasTask(for: url, withEqualOrGreaterPriority: priority) {
            task = session.dataTask(with: request)
        }
        if let task = task {
            delegate.addTask(task)
        }
        if let completion = completion {
            delegate.addTaskCompletion(url, completion: completion)
        }
        return startTask(task, with: priority)
    }

    @discardableResult
    public func downloadTask(_ url: URL,
                             priority: Float? = nil,
                             completion: ((Result<Data, Error>) -> Void)? = nil) -> URLSessionDownloadTask? {
        let request = URLRequest(url: url, cachePolicy: configuration.cachePolicy, timeoutInterval: configuration.timeoutInterval)
        return downloadTask(request,
                            priority: priority ?? configuration.priority,
                            completion: completion)
    }

    @discardableResult
    public func downloadTask(_ request: URLRequest,
                             priority: Float? = nil,
                             completion: ((Result<Data, Error>) -> Void)? = nil) -> URLSessionDownloadTask? {
        return downloadTask(request,
                            session: Self.session(for: configuration),
                            delegate: configuration.delegate,
                            priority: priority ?? configuration.priority,
                            completion: completion)
    }

    @discardableResult
    public func downloadTask(_ request: URLRequest,
                             session: URLSession,
                             delegate: DataDockDelegate,
                             priority: Float = URLSessionDataTask.defaultPriority,
                             completion: ((Result<Data, Error>) -> Void)? = nil) -> URLSessionDownloadTask? {
        guard let url = request.url else { return nil }

        var task: URLSessionDownloadTask?
        if !delegate.hasTask(for: url, withEqualOrGreaterPriority: priority) {
            task = session.downloadTask(with: request)
        }
        if let task = task {
            delegate.addTask(task)
        }
        if let completion = completion {
            delegate.addTaskCompletion(url, completion: completion)
        }
        return startTask(task, with: priority)
    }

    @discardableResult
    public func uploadTask(_ url: URL,
                           priority: Float? = nil,
                           completion: ((Result<Data, Error>) -> Void)? = nil) -> URLSessionUploadTask? {
        let request = URLRequest(url: url, cachePolicy: configuration.cachePolicy, timeoutInterval: configuration.timeoutInterval)
        return uploadTask(request,
                          priority: priority ?? configuration.priority,
                          completion: completion)
    }

    @discardableResult
    public func uploadTask(_ request: URLRequest,
                           priority: Float? = nil,
                           completion: ((Result<Data, Error>) -> Void)? = nil) -> URLSessionUploadTask? {
        return uploadTask(request,
                          session: Self.session(for: configuration),
                          delegate: configuration.delegate,
                          priority: priority ?? configuration.priority,
                          completion: completion)
    }

    @discardableResult
    public func uploadTask(_ request: URLRequest,
                           session: URLSession,
                           delegate: DataDockDelegate,
                           priority: Float = URLSessionDataTask.defaultPriority,
                           completion: ((Result<Data, Error>) -> Void)? = nil) -> URLSessionUploadTask? {
        guard let url = request.url else { return nil }

        var task: URLSessionUploadTask?
        if !delegate.hasTask(for: url, withEqualOrGreaterPriority: priority) {
            task = session.uploadTask(with: request, from: request.httpBody ?? Data())
        }
        if let task = task {
            delegate.addTask(task)
        }
        if let completion = completion {
            delegate.addTaskCompletion(url, completion: completion)
        }
        return startTask(task, with: priority)
    }

    private func startTask<T: URLSessionTask>(_ task: T?, with priority: Float) -> T? {
        task?.priority = priority
        task?.resume()
        return task
    }

}

extension DataDock {
    private struct Factory: FlyweightFactory {
        static var instances: [DataDockConfiguration : URLSession] = [:]
    }

    private static func session(for config: DataDockConfiguration) -> URLSession {
        Factory.instance(for: config, initializer: {
            let configuration: URLSessionConfiguration
            if config.isBackground {
                configuration = URLSessionConfiguration.background(withIdentifier: config.id)
                if #available(macOS 11.0, *) {
                    configuration.sessionSendsLaunchEvents = true
                }
            } else {
                configuration = URLSessionConfiguration.ephemeral
            }
            configuration.allowsCellularAccess = config.allowsCellularAccess
            configuration.isDiscretionary = config.isDiscretionary
            config.delegate.addCompletionHandler {
                // invalidate the session, cancel pending tasks, and removing the session form memory
                terminateSession(with: config.id)
            }
            return URLSession(configuration: configuration, delegate: config.delegate, delegateQueue: config.operationQueue)
        })
    }

    @discardableResult
    public static func launchSession(with id: String, completionHandler: @escaping () -> Void) -> URLSession {
        let config = DataDockConfiguration.instance(for: id)
        config.delegate.addCompletionHandler(completionHandler)
        return session(for: config)
    }

    public static func terminateSession(with id: String) {
        let config = DataDockConfiguration.instance(for: id)
        Factory.instance(for: config)?.invalidateAndCancel()
        Factory.destroy(with: config)
        DataDockConfiguration.destroy(for: id)
    }
}
