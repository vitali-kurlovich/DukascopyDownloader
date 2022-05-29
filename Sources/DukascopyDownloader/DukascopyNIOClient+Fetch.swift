//
//  Created by Vitali Kurlovich on 29.05.22.
//

import Foundation

import DukascopyDecoder
import DukascopyModel
import NIO

public
extension DukascopyNIOClient {
    func fetchInstruments() throws -> EventLoopFuture<[Group]> {
        let task = try instrumentsTask()

        let result = task.result.flatMapThrowing { buffer -> [Group] in

            guard let buffer = buffer else {
                return []
            }

            let decoder = InstrumentsGroupsDecoder()

            return try decoder.decode(with: buffer)
        }

        return result
    }
}

public
extension DukascopyNIOClient {
    func fetchQuotesTicks(for instrument: Instrument, date: Date) throws -> EventLoopFuture<(instrument: Instrument, period: Range<Date>, ticks: [Tick])> {
        let filename = instrument.history.filename

        let task = try task(format: .ticks, for: filename, date: date)

        return task.result.flatMapThrowing { (data: ByteBuffer?, _: String, period: Range<Date>) -> (instrument: Instrument, period: Range<Date>, ticks: [Tick]) in

            guard let buffer = data else {
                return (instrument: instrument, period: period, ticks: [])
            }

            let decoder = TicksDecoder()

            let ticks = try decoder.decode(with: buffer)

            return (instrument: instrument, period: period, ticks: ticks)
        }
    }
}
