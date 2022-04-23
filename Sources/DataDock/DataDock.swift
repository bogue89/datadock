import Foundation
import FlyweightFactory

public struct DataDock {

    public static let shared = DataDock()

    private struct Factory: FlyweightFactory {
        static var instances: [DataDockConfiguration : URLSession] = [:]
    }

    public func session(for config: DataDockConfiguration) -> URLSession {
        Factory.instance(for: config, initializer: {
            let configuration: URLSessionConfiguration
            if config.isBackground {
                configuration = URLSessionConfiguration.background(withIdentifier: config.id)
            } else {
                configuration = URLSessionConfiguration.ephemeral
            }
            configuration.allowsCellularAccess = config.allowsCellularAccess
            configuration.isDiscretionary = config.isDiscretionary
            return URLSession(configuration: configuration, delegate: config.delegate, delegateQueue: config.operationQueue)
        })
    }

    @discardableResult
    public func launchSession(with id: String, completionHandler: (() -> Void)?) -> URLSession {
        let config = DataDockConfiguration.instance(for: id)
        if let handler = completionHandler {
            config.delegate.addCompletion(handler: handler)
        }
        let session = session(for: config)
        return session
    }

    @discardableResult
    public func dataTask(_ url: URL,
                         with configuration: DataDockConfiguration = .default,
                         priority: Float? = nil,
                         completion: ((Data?) -> Void)? = nil) -> URLSessionDataTask? {
        let request = URLRequest(url: url, cachePolicy: configuration.cachePolicy, timeoutInterval: configuration.timeoutInterval)
        return dataTask(request,
                        with: configuration,
                        priority: priority ?? configuration.priority,
                        completion: completion)
    }

    @discardableResult
    public func dataTask(_ request: URLRequest,
                         with configuration: DataDockConfiguration = .default,
                         priority: Float? = nil,
                         completion: ((Data?) -> Void)? = nil) -> URLSessionDataTask? {
        return dataTask(request,
                        session: session(for: configuration),
                        delegate: configuration.delegate,
                        priority: priority ?? configuration.priority,
                        completion: completion)
    }

    @discardableResult
    public func dataTask(_ request: URLRequest,
                         session: URLSession,
                         delegate: DataDockDelegate,
                         priority: Float = URLSessionDataTask.defaultPriority,
                         completion: ((Data?) -> Void)? = nil) -> URLSessionDataTask? {
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
                             with configuration: DataDockConfiguration = .default,
                             priority: Float? = nil,
                             completion: ((Data?) -> Void)? = nil) -> URLSessionDownloadTask? {
        let request = URLRequest(url: url, cachePolicy: configuration.cachePolicy, timeoutInterval: configuration.timeoutInterval)
        return downloadTask(request,
                            with: configuration,
                            priority: priority ?? configuration.priority,
                            completion: completion)
    }

    @discardableResult
    public func downloadTask(_ request: URLRequest,
                             with configuration: DataDockConfiguration = .default,
                             priority: Float? = nil,
                             completion: ((Data?) -> Void)? = nil) -> URLSessionDownloadTask? {
        return downloadTask(request,
                            session: session(for: configuration),
                            delegate: configuration.delegate,
                            priority: priority ?? configuration.priority,
                            completion: completion)
    }

    @discardableResult
    public func downloadTask(_ request: URLRequest,
                             session: URLSession,
                             delegate: DataDockDelegate,
                             priority: Float = URLSessionDataTask.defaultPriority,
                             completion: ((Data?) -> Void)? = nil) -> URLSessionDownloadTask? {
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
                           with configuration: DataDockConfiguration = .default,
                           priority: Float? = nil,
                           completion: ((Data?) -> Void)? = nil) -> URLSessionUploadTask? {
        let request = URLRequest(url: url, cachePolicy: configuration.cachePolicy, timeoutInterval: configuration.timeoutInterval)
        return uploadTask(request,
                          with: configuration,
                          priority: priority ?? configuration.priority,
                          completion: completion)
    }

    @discardableResult
    public func uploadTask(_ request: URLRequest,
                           with configuration: DataDockConfiguration = .default,
                           priority: Float? = nil,
                           completion: ((Data?) -> Void)? = nil) -> URLSessionUploadTask? {
        return uploadTask(request,
                          session: session(for: configuration),
                          delegate: configuration.delegate,
                          priority: priority ?? configuration.priority,
                          completion: completion)
    }

    @discardableResult
    public func uploadTask(_ request: URLRequest,
                           session: URLSession,
                           delegate: DataDockDelegate,
                           priority: Float = URLSessionDataTask.defaultPriority,
                           completion: ((Data?) -> Void)? = nil) -> URLSessionUploadTask? {
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
