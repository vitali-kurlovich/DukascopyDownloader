//
//  Created by Vitali Kurlovich on 29.05.22.
//

import Foundation

import DukascopyDecoder
import DukascopyModel
import NIO

public
extension DukascopyNIOClient {
    func fetchInstruments() -> EventLoopFuture<[Group]> {
        let task = instrumentsTask()

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
    func fetchQuoteTicks(for instrument: Instrument, date: Date) -> EventLoopFuture<(instrument: Instrument, period: Range<Date>, ticks: [Tick])> {
        let filename = instrument.history.filename

        let task = task(format: .ticks, for: filename, date: date)

        return task.result.flatMapThrowing { (data: ByteBuffer?, _: String, period: Range<Date>) -> (instrument: Instrument, period: Range<Date>, ticks: [Tick]) in

            guard let buffer = data else {
                return (instrument: instrument, period: period, ticks: [])
            }

            let decoder = TicksDecoder()

            let ticks = try decoder.decode(with: buffer)

            return (instrument: instrument, period: period, ticks: ticks)
        }
    }

    func fetchQuoteTicks(for instrument: Instrument, range: Range<Date>) -> EventLoopFuture<(instrument: Instrument, period: Range<Date>, ticks: [Tick])> {
        let filename = instrument.history.filename

        let tasks = tasks(format: .ticks, for: filename, range: range)

        let futures = tasks.map { task in

            task.result.flatMapThrowing { (data: ByteBuffer?, _: String, period: Range<Date>) -> (instrument: Instrument, period: Range<Date>, ticks: [Tick]) in

                guard let buffer = data else {
                    return (instrument: instrument, period: period, ticks: [])
                }

                let decoder = TicksDecoder()

                let ticks = try decoder.decode(with: buffer)

                return (instrument: instrument, period: period, ticks: ticks)
            }
        }

        let eventGroup = client.eventLoopGroup
        let eventLoop = eventGroup.any()

        return EventLoopFuture.whenAllComplete(futures, on: eventLoop)
            .flatMapThrowing { results -> (instrument: Instrument, period: Range<Date>, ticks: [Tick]) in

                typealias QuoteItem = (instrument: Instrument, period: Range<Date>, ticks: [Tick])

                var items: [QuoteItem] = []

                items.reserveCapacity(results.underestimatedCount)

                for result in results {
                    switch result {
                    case let .failure(error):
                        throw error
                    case let .success(item):
                        items.append(item)

                        precondition(items.first!.instrument == item.instrument)
                    }
                }

                items.sort { left, right in
                    left.period.lowerBound < right.period.lowerBound
                }

                let instrument = items.first!.instrument
                let period = items.first!.period.lowerBound ..< items.last!.period.upperBound

                let ticks = items.flatMap { (_, _, ticks: [Tick]) -> [Tick] in
                    ticks
                }

                return (instrument: instrument, period: period, ticks: ticks)
            }
    }
}
