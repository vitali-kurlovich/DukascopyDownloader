//
//  Created by Vitali Kurlovich on 18.05.22.
//

import AsyncHTTPClient

import Foundation
import Logging
import NIO

public
final class DukascopyNIOClient {
    internal let client: HTTPClient

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
