//
//  Created by Vitali Kurlovich on 9.06.22.
//

import AsyncHTTPClient
import Foundation
import NIO

final class HTTPClientRequestExecutorImpl: HTTPRequestExecutorImpl {
    let client: HTTPClient

    init(_ client: HTTPClient) {
        self.client = client
    }

    override
    func execute(request: HTTPClient.Request, deadline: NIODeadline?) -> EventLoopFuture<HTTPClient.Response> {
        client.execute(request: request, deadline: deadline)
    }

    func syncShutdown() throws {
        try client.syncShutdown()
    }
}
