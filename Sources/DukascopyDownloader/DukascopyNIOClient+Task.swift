//
//  Created by Vitali Kurlovich on 28.05.22.
//

import AsyncHTTPClient
import DukascopyURL
import Foundation
import NIO
import NIOHTTP1

private var urlFactory = DukascopyRemoteURL()

struct CacheControlParser {
    // "max-age=604800"
}

public
extension DukascopyNIOClient {
    typealias Format = DukascopyRemoteURL.Format

    struct FetchTask {
        public let format: Format
        public let filename: String
        public let period: Range<Date>

        public let result: EventLoopFuture<(data: ByteBuffer?, filename: String, period: Range<Date>)>
    }

    enum FetchTaskError: Error {
        case requestFailed(HTTPResponseStatus)
    }

    func tasks(format: Format, for filename: String, range: Range<Date>) -> [FetchTask] {
        let quotes = urlFactory.quotes(format: format, for: filename, range: range)

        return quotes.map { (url: URL, range: Range<Date>, _, _) -> FetchTask in
            let request = try! HTTPClient.Request(url: url)

            let future = task(for: request)

            let result = future.flatMapThrowing { respose throws -> (data: ByteBuffer?, filename: String, period: Range<Date>) in
                let status = respose.status

                if respose.status != .ok {
                    throw FetchTaskError.requestFailed(status)
                }

                // let headers = respose.headers

                return (data: respose.body, filename: filename, period: range)
            }

            return .init(format: format, filename: filename, period: range, result: result)
        }
    }

    func task(format: Format, for filename: String, date: Date) -> FetchTask {
        let quotes = urlFactory.quotes(format: format, for: filename, date: date)

        let request = try! HTTPClient.Request(url: quotes.url)

        let future = task(for: request)

        let result = future.flatMapThrowing { respose throws -> (data: ByteBuffer?, filename: String, period: Range<Date>) in
            let status = respose.status
            guard status == .ok else {
                throw FetchTaskError.requestFailed(status)
            }

            return (data: respose.body, filename: filename, period: quotes.range)
        }

        return .init(format: format, filename: filename, period: quotes.range, result: result)
    }
}

public
extension DukascopyNIOClient {
    struct InfoTask {
        public let result: EventLoopFuture<ByteBuffer?>
    }

    func instrumentsTask() -> InfoTask {
        let instruments = urlFactory.instruments()

        var request = try! HTTPClient.Request(url: instruments.url)
        let headers = instruments.headers.map { (key: String, value: String) in
            (key, value)
        }
        request.headers = .init(headers)

        let future = task(for: request)

        let result = future.flatMapThrowing { respose throws -> ByteBuffer? in

            let status = respose.status

            guard status == .ok else {
                throw FetchTaskError.requestFailed(status)
            }

            return respose.body
        }

        return .init(result: result)
    }
}

internal
extension DukascopyNIOClient {
    func task(for request: HTTPClient.Request) -> EventLoopFuture<HTTPClient.Response> {
        let key = RequestKey(request)
        return cache.value(forKey: key).flatMapWithEventLoop { response, eventLoop -> EventLoopFuture<HTTPClient.Response> in
            if let response = response {
                return eventLoop.makeSucceededFuture(response)
            }

            return self.client.execute(request: request).map { response -> HTTPClient.Response in

                let status = response.status

                guard status == .ok else {
                    return response
                }

                let cost = response.body?.storageCapacity ?? 1

                let now = Date()
                let expireDate = now.addingTimeInterval(5)

                self.cache.setValue(response, forKey: key, expireDate: expireDate, cost: cost)

                return response
            }
        }
    }
}
