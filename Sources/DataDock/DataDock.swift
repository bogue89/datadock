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

    private struct Factory: FlyweightFactory {
        static var instances: [DataDockConfiguration : URLSession] = [:]
    }

    private static func session(for config: DataDockConfiguration) -> URLSession {
        Factory.instance(for: config, initializer: {
            let configuration: URLSessionConfiguration
            if config.isBackground {
                configuration = URLSessionConfiguration.background(withIdentifier: config.id)
                configuration.sessionSendsLaunchEvents = true
            } else {
                configuration = URLSessionConfiguration.ephemeral
            }
            configuration.allowsCellularAccess = config.allowsCellularAccess
            configuration.isDiscretionary = config.isDiscretionary
            config.delegate.addCompletion {
                // invalidate the session, cancel pending tasks, and removing the session form memory
                invalidateSession(for: config)
            }
            return URLSession(configuration: configuration, delegate: config.delegate, delegateQueue: config.operationQueue)
        })
    }

    private static func invalidateSession(for config: DataDockConfiguration) {
        Factory.instance(for: config)?.invalidateAndCancel()
        Factory.destroy(with: config)
    }

    @discardableResult
    public static func launchSession(with id: String, completionHandler: @escaping () -> Void) -> URLSession {
        let config = DataDockConfiguration.instance(for: id)
        config.delegate.addCompletion(handler: completionHandler)
        return session(for: config)
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
        let hasTask = delegate.hasCallbacks(for: url)
        if let completion = completion {
            delegate.addCompletion(for: url, completion: completion)
        }
        if !hasTask {
            return startTask(session.dataTask(with: request), with: priority)
        }
        return nil
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
        let hasTask = delegate.hasCallbacks(for: url)
        if let completion = completion {
            delegate.addCompletion(for: url, completion: completion)
        }
        if !hasTask {
            return startTask(session.downloadTask(with: request), with: priority)
        }
        return nil
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
        let hasTask = delegate.hasCallbacks(for: url)
        if let completion = completion {
            delegate.addCompletion(for: url, completion: completion)
        }
        if !hasTask {
            return startTask(session.uploadTask(with: request, from: request.httpBody ?? Data()), with: priority)
        }
        return nil
    }

    public func startTask<T: URLSessionTask>(_ task: T, with priority: Float) -> T {
        task.priority = priority
        task.resume()
        return task
    }

}
