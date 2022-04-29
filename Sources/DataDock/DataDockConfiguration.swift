import Foundation
import FlyweightFactory

public struct DataDockConfiguration: Hashable {

    public static let `default`: DataDockConfiguration = .init(id: "default",
                                                               priority: URLSessionTask.defaultPriority,
                                                               isBackground: false,
                                                               isDiscretionary: false,
                                                               allowsCellularAccess: true,
                                                               cachePolicy: URLSessionConfiguration.ephemeral.requestCachePolicy,
                                                               timeoutInterval: URLSessionConfiguration.ephemeral.timeoutIntervalForRequest)

    public static let background: DataDockConfiguration = .init(id: "background",
                                                                priority: URLSessionTask.defaultPriority,
                                                                isBackground: true,
                                                                isDiscretionary: false,
                                                                allowsCellularAccess: true,
                                                                cachePolicy: URLSessionConfiguration.default.requestCachePolicy,
                                                                timeoutInterval: URLSessionConfiguration.default.timeoutIntervalForRequest)

    let id: String
    let priority: Float
    let isBackground: Bool
    let isDiscretionary: Bool
    let allowsCellularAccess: Bool
    let cachePolicy: URLRequest.CachePolicy
    let timeoutInterval: TimeInterval

    static func instance(for id: String) -> DataDockConfiguration {
        Factory.instance(for: id, initializer: {
            DataDockConfiguration(id: id,
                                  priority: DataDockConfiguration.default.priority,
                                  isBackground: DataDockConfiguration.default.isBackground,
                                  isDiscretionary: DataDockConfiguration.default.isDiscretionary,
                                  allowsCellularAccess: DataDockConfiguration.default.allowsCellularAccess,
                                  cachePolicy: DataDockConfiguration.default.cachePolicy,
                                  timeoutInterval: DataDockConfiguration.default.timeoutInterval)
        })
    }

    static func destroy(for id: String) {
        Factory.destroy(with: id)
    }

    private struct Factory: FlyweightFactory {
        static var instances: [String : DataDockConfiguration] = [:]
    }
    
}
