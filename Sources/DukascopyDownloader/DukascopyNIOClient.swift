//
//  Created by Vitali Kurlovich on 18.05.22.
//

import AsyncHTTPClient
import DukascopyURL
import Foundation
import Logging
import NIO
import NIOHTTP1

public
final class DukascopyNIOClient {
    public typealias Format = URLFactory.Format

    private let client: HTTPClient
    private let urlFactory = URLFactory()

    public init(eventLoopGroup: EventLoopGroup,
                configuration: HTTPClient.Configuration = .init(),
                backgroundActivityLogger: Logger)
    {
        client = HTTPClient(eventLoopGroupProvider: .shared(eventLoopGroup), configuration: configuration, backgroundActivityLogger: backgroundActivityLogger)
    }

    public init(eventLoopGroup: EventLoopGroup,
                configuration: HTTPClient.Configuration = .init())
    {
        client = HTTPClient(eventLoopGroupProvider: .shared(eventLoopGroup), configuration: configuration)
    }

    public init(eventLoopGroupProvider: HTTPClient.EventLoopGroupProvider,
                configuration: HTTPClient.Configuration = .init(),
                backgroundActivityLogger: Logger)
    {
        client = HTTPClient(eventLoopGroupProvider: eventLoopGroupProvider, configuration: configuration, backgroundActivityLogger: backgroundActivityLogger)
    }

    public init(eventLoopGroupProvider: HTTPClient.EventLoopGroupProvider,
                configuration: HTTPClient.Configuration = .init())
    {
        client = HTTPClient(eventLoopGroupProvider: eventLoopGroupProvider, configuration: configuration)
    }

    deinit {
        try? client.syncShutdown()
    }
}

public
extension DukascopyNIOClient {
    struct FetchTask {
        public let format: Format
        public let currency: String
        public let period: Range<Date>
        // public let future: EventLoopFuture<HTTPClient.Response>

        public let result: EventLoopFuture<(data: ByteBuffer?, currency: String, period: Range<Date>)>
    }

    enum FetchTaskError: Error {
        case requestFailed(HTTPResponseStatus)
    }

    func tasks(format: Format, for currency: String, range: Range<Date>) throws -> [FetchTask] {
        let quotes = urlFactory.quotes(format: format, for: currency, range: range)

        return try quotes.map { (url: URL, range: Range<Date>) -> FetchTask in
            let request = try HTTPClient.Request(url: url)

            let future = client.execute(request: request)

            let result = future.flatMapThrowing { respose throws -> (data: ByteBuffer?, currency: String, period: Range<Date>) in
                let status = respose.status
                if respose.status != .ok {
                    throw FetchTaskError.requestFailed(status)
                }

                return (data: respose.body, currency: currency, period: range)
            }

            return .init(format: format, currency: currency, period: range, result: result)
        }
    }

    func task(format: Format, for currency: String, date: Date) throws -> FetchTask {
        let quotes = urlFactory.quotes(format: format, for: currency, date: date)

        let request = try HTTPClient.Request(url: quotes.url)

        let future = client.execute(request: request)

        let result = future.flatMapThrowing { respose throws -> (data: ByteBuffer?, currency: String, period: Range<Date>) in
            let status = respose.status
            if respose.status != .ok {
                throw FetchTaskError.requestFailed(status)
            }

            return (data: respose.body, currency: currency, period: quotes.range)
        }

        return .init(format: format, currency: currency, period: quotes.range, result: result)
    }
}
