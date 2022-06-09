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
    public enum EventLoopGroupProvider {
        /// `EventLoopGroup` will be provided by the user. Owner of this group is responsible for its lifecycle.
        case shared(EventLoopGroup)
        /// `EventLoopGroup` will be created by the client. When `syncShutdown` is called, created `EventLoopGroup` will be shut down as well.
        case createNew
    }

    internal
    init(_ client: HTTPRequestExecutorImpl, eventLoopGroup: EventLoopGroup) {
        self.client = client

        cache = .init(eventLoopGroupProvider: .shared(eventLoopGroup))
        groupsCache = .init(eventLoopGroupProvider: .shared(eventLoopGroup))
    }

    internal let client: HTTPRequestExecutorImpl
    internal let cache: KeyValueCache<RequestKey, HTTPClient.Response>
    internal let groupsCache: OneValueCache<[Group]>

    deinit {
        try? client.syncShutdown()
    }
}

public
extension DukascopyNIOClient {
    convenience init(eventLoopGroupProvider: EventLoopGroupProvider,
                     backgroundActivityLogger: Logger)
    {
        let groupProvider: HTTPClient.EventLoopGroupProvider

        switch eventLoopGroupProvider {
        case let .shared(group):
            groupProvider = .shared(group)
        case .createNew:
            groupProvider = .createNew
        }

        let client = HTTPClient(eventLoopGroupProvider: groupProvider, backgroundActivityLogger: backgroundActivityLogger)

        let eventLoopGroup = client.eventLoopGroup.any()

        self.init(HTTPClientRequestExecutorImpl(client), eventLoopGroup: eventLoopGroup)
    }

    convenience init(eventLoopGroupProvider: EventLoopGroupProvider) {
        let groupProvider: HTTPClient.EventLoopGroupProvider

        switch eventLoopGroupProvider {
        case let .shared(group):
            groupProvider = .shared(group)
        case .createNew:
            groupProvider = .createNew
        }

        let client = HTTPClient(eventLoopGroupProvider: groupProvider)

        let eventLoopGroup = client.eventLoopGroup.any()

        self.init(HTTPClientRequestExecutorImpl(client), eventLoopGroup: eventLoopGroup)
    }
}
