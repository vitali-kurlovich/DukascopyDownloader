//
//  DukascopyNIOClientTests.swift
//
//
//  Created by Vitali Kurlovich on 20.05.22.
//

import AsyncHTTPClient

@testable import DukascopyDownloader
import NIO
import XCTest

class DukascopyNIOClientTests: XCTestCase {
    func testDownloadData() throws {
        let expectation = XCTestExpectation(description: "Download Dukacopy bi5 file")

        let downloader = DukascopyNIOClient(eventLoopGroupProvider: .createNew)

        let date = formatter.date(from: "04-04-2019 11:00")!

        let task = try downloader.task(format: .ticks, for: "EURUSD", date: date)

        XCTAssertEqual(task.period, date ..< formatter.date(from: "04-04-2019 12:00")!)

        task.result.whenSuccess { (data: ByteBuffer?, currency: String, period: Range<Date>) in
            XCTAssertNotNil(data)
            XCTAssertEqual(currency, "EURUSD")

            XCTAssertEqual(data?.readableBytes, 50435)

            XCTAssertEqual(period, task.period)

            expectation.fulfill()
        }

        task.result.whenFailure { error in
            XCTFail(error.localizedDescription)
        }

        wait(for: [expectation], timeout: 10.0)
    }

    func testDownloadData_1() throws {
        let expectation = XCTestExpectation(description: "Download Dukacopy bi5 file")

        let downloader = DukascopyNIOClient(eventLoopGroupProvider: .createNew)

        let date = formatter.date(from: "06-01-2019 12:00")!

        let task = try downloader.task(format: .ticks, for: "EURUSD", date: date)

        XCTAssertEqual(task.period, date ..< formatter.date(from: "06-01-2019 13:00")!)

        task.result.whenSuccess { (data: ByteBuffer?, currency: String, period: Range<Date>) in

            XCTAssertNil(data)
            XCTAssertEqual(currency, "EURUSD")
            XCTAssertEqual(period, task.period)

            expectation.fulfill()
        }

        task.result.whenFailure { error in
            XCTFail(error.localizedDescription)
        }

        wait(for: [expectation], timeout: 10.0)
    }

    func testDownloadData_2() throws {
        let expectation = XCTestExpectation(description: "Download Dukacopy bi5 file")

        let downloader = DukascopyNIOClient(eventLoopGroupProvider: .createNew)

        let begin = formatter.date(from: "04-04-2019 11:00")!
        let end = formatter.date(from: "04-04-2019 19:00")!

        let tasks = try downloader.tasks(format: .ticks, for: "EURUSD", range: begin ..< end)

        XCTAssertEqual(tasks.count, 8)

        let results = tasks.map { task in
            task.result
        }

        let eventGroup = MultiThreadedEventLoopGroup(numberOfThreads: 1)

        let allTasks = EventLoopFuture.whenAllSucceed(results, on: eventGroup.any())

        allTasks.whenSuccess { result in
            result.forEach { (data: ByteBuffer?, currency: String, _: Range<Date>) in
                XCTAssertEqual(currency, "EURUSD")
                XCTAssertNotNil(data)
            }

            expectation.fulfill()
        }

        allTasks.whenFailure { error in
            XCTFail(error.localizedDescription)
        }

        wait(for: [expectation], timeout: 10.0)

        try eventGroup.syncShutdownGracefully()
    }

    func testDownloadInstruments() throws {
        let expectation = XCTestExpectation(description: "Download instruments groups")

        let downloader = DukascopyNIOClient(eventLoopGroupProvider: .createNew)

        let task = try downloader.instrumentsTask()

        task.whenSuccess { buffer in
            XCTAssertNotNil(buffer)
            expectation.fulfill()
        }

        task.whenFailure { error in
            XCTFail(error.localizedDescription)
        }

        wait(for: [expectation], timeout: 10.0)
    }
}

private let utc = TimeZone(identifier: "UTC")!

private let calendar: Calendar = {
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = utc
    return calendar
}()

private let formatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.calendar = calendar
    formatter.timeZone = utc
    formatter.dateFormat = "dd-MM-yyyy HH:mm"
    return formatter
}()
