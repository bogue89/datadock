import XCTest
@testable import DataDock

final class DataDockTests: XCTestCase {

    let url: URL = URL(string: "https://www.wikipedia.org/portal/wikipedia.org/assets/img/Wikipedia-logo-v2.png")!
    var request: URLRequest { .init(url: url) }

    func testAvoidDuplicateWork() throws {
        let dataDock = DataDock.default

        let count = 3
        var tasks: [URLSessionTask?] = []
        var results: [Result<Data,Error>] = []

        let sessionTask = URLSession.shared.dataTask(with: url)

        // we added a suspended task
        dataDock.delegate?.addTask(sessionTask)

        (0..<count).forEach { n in
            let expectation = self.expectation(description: "e\(n)")
            let task = dataDock.dataTask(url) { result in
                results.append(result)
                expectation.fulfill()
            }
            tasks.append(task)
        }

        // tell the delegate we completed the task
        dataDock.delegate?.urlSession(.shared, task: sessionTask, didCompleteWithError: nil)
        URLSession.shared.invalidateAndCancel()

        self.waitForExpectations(timeout: 1)
        XCTAssertEqual(tasks.compactMap({ $0 }).count, 0)
        XCTAssertEqual(results.count, count)
    }

    func testShareDelegateAvoidDuplicateWork() throws {
        let delegate = DataDockDelegate()
        let defaultDataDock = DataDock(configuration: .default, delegate: delegate)
        let backgroundDataDock = DataDock(configuration: .background, delegate: delegate)

        var results: [Result<Data,Error>] = []

        let expectations = (self.expectation(description: "1"), self.expectation(description: "2"))
        let sessionTask = URLSession.shared.dataTask(with: url)

        delegate.addTask(sessionTask)
        defaultDataDock.dataTask(request) { result in
            results.append(result)
            expectations.0.fulfill()
        }
        backgroundDataDock.dataTask(request) { result in
            results.append(result)
            expectations.1.fulfill()
        }

        delegate.urlSession(.shared, task: sessionTask, didCompleteWithError: nil)
        URLSession.shared.invalidateAndCancel()

        self.waitForExpectations(timeout: 1)
        XCTAssertEqual(results.count, 2)
    }
}
