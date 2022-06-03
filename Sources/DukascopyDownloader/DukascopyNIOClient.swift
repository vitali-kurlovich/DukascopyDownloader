//
//  Created by Vitali Kurlovich on 18.05.22.
//

import AsyncHTTPClient

import Foundation
import KeyValueCache
import Logging
import NIO

public
final class DukascopyNIOClient {
    internal let client: HTTPClient

    internal let cache: KeyValueCache<RequestKey, HTTPClient.Response>

    public init(eventLoopGroupProvider: HTTPClient.EventLoopGroupProvider,
                configuration: HTTPClient.Configuration = .init(),
                backgroundActivityLogger: Logger)
    {
        client = HTTPClient(eventLoopGroupProvider: eventLoopGroupProvider, configuration: configuration, backgroundActivityLogger: backgroundActivityLogger)

        let eventLoopGroup = client.eventLoopGroup.any()
        cache = .init(eventLoopGroupProvider: .shared(eventLoopGroup))
    }

    public init(eventLoopGroupProvider: HTTPClient.EventLoopGroupProvider,
                configuration: HTTPClient.Configuration = .init())
    {
        client = HTTPClient(eventLoopGroupProvider: eventLoopGroupProvider, configuration: configuration)

        let eventLoopGroup = client.eventLoopGroup.any()
        cache = .init(eventLoopGroupProvider: .shared(eventLoopGroup))
    }

    deinit {
        try? client.syncShutdown()
    }
}

public
extension DukascopyNIOClient {
    convenience init(eventLoopGroup: EventLoopGroup,
                     configuration: HTTPClient.Configuration = .init(),
                     backgroundActivityLogger: Logger)
    {
        self.init(eventLoopGroupProvider: .shared(eventLoopGroup), configuration: configuration, backgroundActivityLogger: backgroundActivityLogger)
    }

    convenience init(eventLoopGroup: EventLoopGroup,
                     configuration: HTTPClient.Configuration = .init())
    {
        self.init(eventLoopGroupProvider: .shared(eventLoopGroup), configuration: configuration)
    }
}
