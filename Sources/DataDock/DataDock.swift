import Foundation
import FlyweightFactory

public struct DataDock {

    private static let domain = "mx.pewpew.DataDock."

    public static let `default` = DataDock(configuration: .default)
    public static let background = DataDock(configuration: .background)

    public let configuration: DataDockConfiguration
    public let delegate: DataDockDelegate

    public init(configuration: DataDockConfiguration, delegate: DataDockDelegate = .init()) {
        self.configuration = configuration
        self.delegate = delegate
    }

    private var session: URLSession {
        Self.session(for: configuration, with: delegate)
    }
    
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
                        session: session,
                        priority: priority ?? configuration.priority,
                        completion: completion)
    }

    @discardableResult
    public func dataTask(_ request: URLRequest,
                         session: URLSession,
                         priority: Float = URLSessionDataTask.defaultPriority,
                         completion: ((Result<Data, Error>) -> Void)? = nil) -> URLSessionDataTask? {
        guard let url = request.url else { return nil }
        return startTask(url, priority: priority, delegate: delegate, completion: completion, createTask: {
            session.dataTask(with: request)
        })
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
                            session: session,
                            priority: priority ?? configuration.priority,
                            completion: completion)
    }

    @discardableResult
    public func downloadTask(_ request: URLRequest,
                             session: URLSession,
                             priority: Float = URLSessionDataTask.defaultPriority,
                             completion: ((Result<Data, Error>) -> Void)? = nil) -> URLSessionDownloadTask? {
        guard let url = request.url else { return nil }
        return startTask(url, priority: priority, delegate: delegate, completion: completion, createTask: {
            session.downloadTask(with: request)
        })
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
                          session: session,
                          priority: priority ?? configuration.priority,
                          completion: completion)
    }

    @discardableResult
    public func uploadTask(_ request: URLRequest,
                           session: URLSession,
                           priority: Float = URLSessionDataTask.defaultPriority,
                           completion: ((Result<Data, Error>) -> Void)? = nil) -> URLSessionUploadTask? {
        guard let url = request.url else { return nil }
        return startTask(url, priority: priority, delegate: delegate, completion: completion, createTask: {
            session.uploadTask(with: request, from: request.httpBody ?? Data())
        })
    }

    private func startTask<T: URLSessionTask>(_ url: URL,
                                              priority: Float,
                                              delegate: DataDockDelegate?,
                                              completion: ((Result<Data, Error>) -> Void)?,
                                              createTask: @escaping(() -> T)) -> T? {
        var task: T?
        if !(delegate?.hasTask(for: url, withEqualOrGreaterPriority: priority) ?? false) {
            task = createTask()
        }
        if let task = task {
            delegate?.addTask(task)
        }
        if let completion = completion {
            delegate?.addTaskCompletion(url, completion: completion)
        }
        task?.priority = priority
        task?.resume()
        return task
    }
}

extension DataDock {
    private struct Factory: FlyweightFactory {
        static var instances: [DataDockConfiguration : URLSession] = [:]
    }

    private static func session(for config: DataDockConfiguration, with delegate: DataDockDelegate) -> URLSession {
        return Factory.instance(for: config, initializer: { [weak delegate] in
            let configuration: URLSessionConfiguration
            if config.isBackground {
                configuration = URLSessionConfiguration.background(withIdentifier: config.id)
                #if os(macOS)
                if #available(macOS 11.0, *) {
                    configuration.sessionSendsLaunchEvents = true
                }
                #else
                configuration.sessionSendsLaunchEvents = true
                #endif
            } else {
                configuration = URLSessionConfiguration.ephemeral
            }
            configuration.allowsCellularAccess = config.allowsCellularAccess
            configuration.isDiscretionary = config.isDiscretionary
            delegate?.addCompletionHandler {
                // invalidate the session, cancel pending tasks, and removing the session form memory
                Self.terminateSession(with: config.id)
            }
            return URLSession(configuration: configuration, delegate: delegate, delegateQueue: delegate?.operationQueue)
        })
    }

    @discardableResult
    public static func launchSession(with id: String, completionHandler: @escaping () -> Void) -> URLSession {
        let config = DataDockConfiguration.instance(for: id)
        let delegate = DataDockDelegate.instance(for: id)
        delegate.addCompletionHandler(completionHandler)
//        delegate.addCompletionHandler {
//            // invalidate the session, cancel pending tasks, and removing the session form memory
//            Self.terminateSession(with: config.id)
//        }
        return Self.session(for: config, with: delegate)
    }

    public static func terminateSession(with id: String) {
        let config = DataDockConfiguration.instance(for: id)
        Factory.instance(for: config)?.invalidateAndCancel()
        Factory.destroy(with: config)

        DataDockConfiguration.destroy(for: id)
        DataDockDelegate.destroy(for: id)
    }
}
