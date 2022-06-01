//
//  Created by Vitali Kurlovich on 31.05.22.
//

import Foundation
import NIO

final class NIOCache<Key: Hashable, Value> {
    internal
    struct CachedValue<Value> {
        let value: Value
        let expare: Date?
        let cost: Int
    }

    typealias ValueType = CachedValue<Value>

    private var cache: [Key: ValueType] = [:]
    private var _totalCost: Int = 0

    private let eventLoop: EventLoop

    var countLimit: Int = 0
    var totalCostLimit: Int = 0
    
    init(_ eventLoop: EventLoop) {
        self.eventLoop = eventLoop
    }
}


extension NIOCache {
    private
    func removeOldest() {
        
    }
    
    private
    func removeLowcost() {
        
    }
    
    private
    func removeByCost( requaredCost:Int ) {
        
    }
}

extension NIOCache {
    func setValue(_ value: Value,
                  forKey key: Key,
                  cost: Int = 1)
    {
       setValue(value, forKey: key, expare: nil, cost: cost)
    }
    
    func setValue(_ value: Value,
                  forKey key: Key,
                  expare:Date?,
                  cost: Int = 1)
    {
        eventLoop.execute {
            self.cache[key] = CachedValue(value: value, expare: expare, cost: cost)
            
            if self.countLimit != 0, self.cache.count + 1 >= self.countLimit {
                self.removeLowcost()
            }
            
            if self.totalCostLimit != 0, self._totalCost + cost > self.totalCostLimit {
                self.removeOldest()
            }
            
            self._totalCost += cost
        }
    }
   

    func value(forKey key: Key) -> EventLoopFuture<Value?> {
        let promise = eventLoop.makePromise(of: Value?.self)

        eventLoop.execute {
            guard let cachedValue = self.cache[key] else {
                promise.succeed(nil)
                return
            }

            if let expare = cachedValue.expare, expare <= Date() {
                self.cache.removeValue(forKey: key)
                self._totalCost -= cachedValue.cost

                promise.succeed(nil)

            } else {
                promise.succeed(cachedValue.value)
            }
        }

        return promise.futureResult
    }

    func removeValue(forKey key: Key) {
        eventLoop.execute {
            guard let cachedValue = self.cache[key] else {
                return
            }

            self.cache.removeValue(forKey: key)
            self._totalCost -= cachedValue.cost
        }
    }

    func removeAllValues() {
        eventLoop.execute {
            self.cache.removeAll()
            self._totalCost = 0
        }
    }
}
