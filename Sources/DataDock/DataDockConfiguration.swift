import Foundation
import FlyweightFactory

public struct DataDockConfiguration: Hashable {

    public static let `default`: DataDockConfiguration = .init(id: "default",
                                                               priority: URLSessionTask.defaultPriority,
                                                               isBackground: false,
                                                               isDiscretionary: false,
                                                               allowsCellularAccess: true,
                                                               cachePolicy: URLSessionConfiguration.ephemeral.requestCachePolicy,
                                                               timeoutInterval: URLSessionConfiguration.ephemeral.timeoutIntervalForRequest,
                                                               delegate: .init(),
                                                               operationQueue: Self.utilityOperationQueue)

    public static let background: DataDockConfiguration = .init(id: "background",
                                                                priority: URLSessionTask.defaultPriority,
                                                                isBackground: true,
                                                                isDiscretionary: false,
                                                                allowsCellularAccess: true,
                                                                cachePolicy: URLSessionConfiguration.default.requestCachePolicy,
                                                                timeoutInterval: URLSessionConfiguration.default.timeoutIntervalForRequest,
                                                                delegate: .init(),
                                                                operationQueue: Self.utilityOperationQueue)

    let id: String
    let priority: Float
    let isBackground: Bool
    let isDiscretionary: Bool
    let allowsCellularAccess: Bool
    let cachePolicy: URLRequest.CachePolicy
    let timeoutInterval: TimeInterval
    let delegate: DataDockDelegate
    let operationQueue: OperationQueue

    init(id: String,
         priority: Float,
         isBackground: Bool,
         isDiscretionary: Bool,
         allowsCellularAccess: Bool,
         cachePolicy: URLRequest.CachePolicy,
         timeoutInterval: TimeInterval,
         delegate: DataDockDelegate,
         operationQueue: OperationQueue) {
        // ensures id is not empty
        self.id = DataDock.domain + id
        self.priority = priority
        self.isBackground = isBackground
        self.isDiscretionary = isDiscretionary
        self.allowsCellularAccess = allowsCellularAccess
        self.cachePolicy = cachePolicy
        self.timeoutInterval = timeoutInterval
        self.delegate = delegate
        self.operationQueue = operationQueue
        // ensures a serial operation queue
        self.operationQueue.maxConcurrentOperationCount = 1
    }

    static var utilityOperationQueue: OperationQueue {
        let queue = OperationQueue()
        queue.qualityOfService = .utility
        return queue
    }

    static func instance(for id: String) -> DataDockConfiguration {
        Factory.instance(for: id, initializer: {
            DataDockConfiguration(id: id,
                                  priority: DataDockConfiguration.default.priority,
                                  isBackground: DataDockConfiguration.default.isBackground,
                                  isDiscretionary: DataDockConfiguration.default.isDiscretionary,
                                  allowsCellularAccess: DataDockConfiguration.default.allowsCellularAccess,
                                  cachePolicy: DataDockConfiguration.default.cachePolicy,
                                  timeoutInterval: DataDockConfiguration.default.timeoutInterval,
                                  delegate: DataDockConfiguration.default.delegate,
                                  operationQueue: DataDockConfiguration.default.operationQueue)
        })
    }

    static func destroy(for id: String) {
        Factory.destroy(with: id)
    }

    private struct Factory: FlyweightFactory {
        static var instances: [String : DataDockConfiguration] = [:]
    }
    
}
