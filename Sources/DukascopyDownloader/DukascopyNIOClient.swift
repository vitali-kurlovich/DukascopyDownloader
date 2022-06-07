//
//  Created by Vitali Kurlovich on 18.05.22.
//

import AsyncHTTPClient

import DukascopyModel
import Foundation
import KeyValueCache
import Logging
import NIO

public
final class DukascopyNIOClient {
    internal let client: HTTPClient

    internal let cache: KeyValueCache<RequestKey, HTTPClient.Response>

    internal let instrumentsCache: KeyValueCache<String, Instrument>
    internal let groupsCache: OneValueCache<[Group]>

    public init(eventLoopGroupProvider: HTTPClient.EventLoopGroupProvider,
                configuration: HTTPClient.Configuration = .init(),
                backgroundActivityLogger: Logger)
    {
        client = HTTPClient(eventLoopGroupProvider: eventLoopGroupProvider, configuration: configuration, backgroundActivityLogger: backgroundActivityLogger)

        let eventLoopGroup = client.eventLoopGroup.any()
        cache = .init(eventLoopGroupProvider: .shared(eventLoopGroup))

        instrumentsCache = .init(eventLoopGroupProvider: .shared(eventLoopGroup))

        groupsCache = .init(eventLoopGroupProvider: .shared(eventLoopGroup))
    }

    public init(eventLoopGroupProvider: HTTPClient.EventLoopGroupProvider,
                configuration: HTTPClient.Configuration = .init())
    {
        client = HTTPClient(eventLoopGroupProvider: eventLoopGroupProvider, configuration: configuration)

        let eventLoopGroup = client.eventLoopGroup.any()
        cache = .init(eventLoopGroupProvider: .shared(eventLoopGroup))

        instrumentsCache = .init(eventLoopGroupProvider: .shared(eventLoopGroup))

        groupsCache = .init(eventLoopGroupProvider: .shared(eventLoopGroup))
    }

    deinit {
        try? client.syncShutdown()
    }
}
