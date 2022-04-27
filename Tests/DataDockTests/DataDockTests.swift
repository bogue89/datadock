import XCTest
@testable import DataDock

final class DataDockTests: XCTestCase {

    let url: URL = URL(string: "https://www.wikipedia.org/portal/wikipedia.org/assets/img/Wikipedia-logo-v2.png")!
    var request: URLRequest { .init(url: url) }

    let dataDockDelegate = DataDockDelegate()

    lazy
    var dataDockConfiguration = DataDockConfiguration(id: "test",
                                                      priority: URLSessionTask.defaultPriority,
                                                      isBackground: false,
                                                      isDiscretionary: false,
                                                      allowsCellularAccess: false,
                                                      cachePolicy: .reloadIgnoringLocalAndRemoteCacheData,
                                                      timeoutInterval: .greatestFiniteMagnitude,
                                                      delegate: dataDockDelegate,
                                                      operationQueue: DataDockConfiguration.utilityOperationQueue)
    lazy
    var dataDock = DataDock(configuration: dataDockConfiguration)

    func testAvoidDuplicateWork() throws {
        let count = 3
        var tasks: [URLSessionTask?] = []
        var results: [Result<Data,Error>] = []

        let sessionTask = URLSession.shared.dataTask(with: url)

        dataDockDelegate.addTask(sessionTask)

        (0..<count).forEach { n in
            let expectation = self.expectation(description: "e\(n)")
            let task = dataDock.dataTask(url) { result in
                results.append(result)
                expectation.fulfill()
            }
            tasks.append(task)
        }

        dataDockDelegate.urlSession(.shared, task: sessionTask, didCompleteWithError: nil)
        URLSession.shared.invalidateAndCancel()

        self.waitForExpectations(timeout: 1)
        XCTAssertEqual(tasks.compactMap({ $0 }).count, 0)
        XCTAssertEqual(results.count, count)
    }
    
}
