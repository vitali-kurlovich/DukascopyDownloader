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
    init(_ client: HTTPRequestExecutorImpl, eventLoopGroupProvider: ClientEventLoopGroupProvider) {
        self.eventLoopGroupProvider = eventLoopGroupProvider

        self.client = client

        cache = .init(eventLoopGroupProvider: .shared(eventLoopGroupProvider.eventLoopGroup))
        groupsCache = .init(eventLoopGroupProvider: .shared(eventLoopGroupProvider.eventLoopGroup))
    }

    /// public let eventLoopGroup: EventLoopGroup
    internal let eventLoopGroupProvider: ClientEventLoopGroupProvider

    internal let client: HTTPRequestExecutorImpl

    internal let cache: KeyValueCache<RequestKey, HTTPClient.Response>
    internal let groupsCache: OneValueCache<[Group]>
}

public
extension DukascopyNIOClient {
    convenience init(eventLoopGroupProvider: EventLoopGroupProvider,
                     backgroundActivityLogger: Logger)
    {
        let provider = ClientEventLoopGroupProvider(eventLoopGroupProvider)
        let imp = HTTPClientRequestExecutorImpl(eventLoopGroup: provider.eventLoopGroup, backgroundActivityLogger: backgroundActivityLogger)
        self.init(imp, eventLoopGroupProvider: provider)
    }

    convenience init(eventLoopGroupProvider: EventLoopGroupProvider) {
        let provider = ClientEventLoopGroupProvider(eventLoopGroupProvider)

        let imp = HTTPClientRequestExecutorImpl(eventLoopGroup: provider.eventLoopGroup)

        self.init(imp, eventLoopGroupProvider: provider)
    }

    var eventLoopGroup: EventLoopGroup {
        eventLoopGroupProvider.eventLoopGroup
    }
}
