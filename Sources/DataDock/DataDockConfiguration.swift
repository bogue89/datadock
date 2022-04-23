import Foundation
import FlyweightFactory

public extension DataDock {

    struct DataDockConfiguration: Hashable {

        public static let `default`: DataDockConfiguration = .init()

        let id: String
        let priority: Float
        let isBackground: Bool
        let isDiscretionary: Bool
        let allowsCellularAccess: Bool
        let cachePolicy: URLRequest.CachePolicy
        let timeoutInterval: TimeInterval
        let delegate: DataDockDelegate
        let operationQueue: OperationQueue

        init(id: String = "",
             priority: Float = 0.5,
             isBackground: Bool = true,
             isDiscretionary: Bool = false,
             allowsCellularAccess: Bool = true,
             cachePolicy: URLRequest.CachePolicy = URLSessionConfiguration.default.requestCachePolicy,
             timeoutInterval: TimeInterval = URLSessionConfiguration.default.timeoutIntervalForRequest,
             delegate: DataDockDelegate = .init(),
             operationQueue: OperationQueue = DataDockConfiguration.utilityOperationQueue) {
            self.id = id
            self.priority = priority
            self.isBackground = isBackground
            self.isDiscretionary = isDiscretionary
            self.allowsCellularAccess = allowsCellularAccess
            self.cachePolicy = cachePolicy
            self.timeoutInterval = timeoutInterval
            self.delegate = delegate
            self.operationQueue = operationQueue
        }

        static var utilityOperationQueue: OperationQueue {
            let queue = OperationQueue()
            queue.qualityOfService = .utility
            return queue
        }

        static func instance(for id: String) -> DataDockConfiguration {
            Factory.instance(for: id, initializer: { DataDockConfiguration.default })
        }

        private struct Factory: FlyweightFactory {
            static var instances: [String : DataDockConfiguration] = [:]
        }
    }

}
