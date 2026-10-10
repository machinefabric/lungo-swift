import Foundation
import LungoRuntime

/// The answer to an operation of an async program: how to encode it at the operation's answer
/// type. Generated packages make one per answer.
public struct LungoAnswer {
    let write: (inout LungoWriter) throws -> Void

    public init(_ write: @escaping (inout LungoWriter) throws -> Void) { self.write = write }
}

/// The facilities the host has installed, by identifier. Generated packages keep one.
public final class LungoInstalled: @unchecked Sendable {
    private let lock = NSLock()
    private var ids: Set<String> = []

    public init() {}

    public func add(_ id: String) {
        lock.lock()
        defer { lock.unlock() }
        ids.insert(id)
    }

    /// Throws unless the facility `id` is installed; `operation` names one of its operations.
    public func check(_ id: String, operation: String) throws {
        lock.lock()
        defer { lock.unlock() }
        guard ids.contains(id) else { throw LungoMissingFacility(facility: id, operation: operation) }
    }
}

/// A program waiting for the host's answer: given up (released by the runtime) unless it is
/// resumed, whatever ends the wait — an answer, an error, cancellation, or the task being dropped.
final class LungoResumption: @unchecked Sendable {
    private let lock = NSLock()
    private var id: UInt64

    init(_ id: UInt64) { self.id = id }

    deinit { cancel() }

    /// The resumption, which can no longer be cancelled: the runtime consumes it.
    func take() -> UInt64 {
        lock.lock()
        defer { lock.unlock() }
        let taken = id
        id = 0
        return taken
    }

    func cancel() {
        lock.lock()
        defer { lock.unlock() }
        if id != 0 {
            guard lungo_async_cancel(id) == 0 else {
                fatalError("lungo: resumption \(id) was resumed or cancelled already")
            }
            id = 0
        }
    }
}

/// The number of async programs waiting for an answer: zero once every async call has returned.
public func lungoOutstanding() -> Int { Int(lungo_async_outstanding()) }

extension LungoProgram {
    /// Calls `call`, an async program's entry point, and runs the program to its end: for each
    /// operation it asks, `perform` answers it, and the program resumes with the answer. An error
    /// of `perform`, or the task being cancelled, abandons the program: the runtime releases it,
    /// and the error is thrown.
    public func driveAsync<O, R>(
        _ call: LungoCall, typeArgs: [[UInt8]] = [], args: (inout LungoWriter) throws -> Void,
        op: LungoType<O>, value: LungoType<R>,
        perform: (O) async throws -> LungoAnswer
    ) async throws -> R {
        var w = LungoWriter(program: self, result: false)
        defer { w.temps.forEach(Host.release) }
        w.u32(UInt32(typeArgs.count))
        typeArgs.forEach { w.raw($0) }
        try args(&w)
        var (status, out) = w.bytes.withUnsafeBufferPointer { call($0.baseAddress, $0.count) }
        withExtendedLifetime(w.lent) {}
        switch status {
        case 0: break
        case 1: throw LungoMalformed(String(decoding: out, as: UTF8.self))
        default: fatalError("lungo: a generated entry point returned status \(status)")
        }
        while true {
            var r = LungoReader(out, program: self)
            let step: (kind: UInt8, op: O?, value: R?, resumption: UInt64)
            do {
                switch try r.u8() {
                case 0:
                    step = (0, nil, try value.decode(&r), 0)
                case 1:
                    let o = try op.decode(&r)
                    step = (1, o, nil, try r.u64())
                case let kind:
                    fatalError("lungo: the runtime produced a step of kind \(kind)")
                }
                try r.finish()
            } catch {
                fatalError("lungo: the runtime produced a malformed step: \(error)")
            }
            if step.kind == 0 { return step.value! }
            let resumption = LungoResumption(step.resumption)
            try Task.checkCancellation()
            let answer = try await perform(step.op!)
            try Task.checkCancellation()
            var a = LungoWriter(program: self, result: true)
            try answer.write(&a)
            let id = resumption.take()
            var buf = lungo_buffer()
            status = a.bytes.withUnsafeBufferPointer { lungo_async_resume(id, $0.baseAddress, $0.count, &buf) }
            out = take(&buf)
            guard status == 0 else {
                fatalError("lungo: resuming an async program returned status \(status): \(String(decoding: out, as: UTF8.self))")
            }
        }
    }
}
