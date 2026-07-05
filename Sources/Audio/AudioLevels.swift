import Foundation
import QuartzCore

final class AudioLevels: @unchecked Sendable {
    static let shared = AudioLevels()
    private let lock = NSLock()

    private var bass: Float = 0
    private var mid: Float = 0
    private var treble: Float = 0

    private var bassBaseline: Float = 0
    private var previousRawMid: Float = 0
    private var previousRawTreble: Float = 0
    private var beatPulseValue: Float = 0
    private var lastBeatTime: CFTimeInterval = 0

    static let ripplePoolSize = 8
    private var ripplePulses = [Float](repeating: 0, count: AudioLevels.ripplePoolSize)

    private var kickPulseValue: Float = 0
    private var lastKickTime: CFTimeInterval = 0
    private var lastRippleTime: CFTimeInterval = 0
    private var lastUpdateTime: CFTimeInterval = CACurrentMediaTime()

    private var vocalActivityValue: Float = 0

    private init() {}

    func update(bass: Float, mid: Float, treble: Float) {
        lock.lock()

        let now = CACurrentMediaTime()
        let dt = Float(max(now - lastUpdateTime, 0.001))
        lastUpdateTime = now

        self.bass = attackRelease(current: self.bass, target: bass)
        self.mid = attackRelease(current: self.mid, target: mid)
        self.treble = attackRelease(current: self.treble, target: treble)

        let bassBaselineRate: Float = 1 - exp(-dt / 0.35)
        let bassOnset = bass > bassBaseline * 1.6 && bass > 1000
        bassBaseline += (bass - bassBaseline) * bassBaselineRate
        let midOnset = mid > previousRawMid * 1.7 && mid > 22
        let trebleOnset = treble > previousRawTreble * 2.0 && treble > 0.45
        if (bassOnset || midOnset || trebleOnset) && (now - lastBeatTime) > 0.45 {
            beatPulseValue = 1.0
            lastBeatTime = now
        }
        if bassOnset && (now - lastKickTime) > 0.15 {
            kickPulseValue = 1.0
            lastKickTime = now
        }
        if bassOnset && (now - lastRippleTime) > 0.45 {
            lastRippleTime = now
            if let freeSlot = ripplePulses.firstIndex(where: { $0 <= 0 }) {
                ripplePulses[freeSlot] = 1.0
            }
        }

        let trebleN = min(1, max(0, treble / 2))
        let trebleRate = min(1, abs(treble - previousRawTreble) / dt / 8)
        vocalActivityValue = min(1, trebleN * 0.6 + trebleRate * 0.4)

        previousRawMid = mid
        previousRawTreble = treble

        lock.unlock()
    }

    func getLevels() -> (bass: Float, mid: Float, treble: Float) {
        lock.lock()
        defer { lock.unlock() }
        return (bass, mid, treble)
    }

    func getVocalActivity() -> Float {
        lock.lock()
        defer { lock.unlock() }
        return vocalActivityValue
    }

    func consumeBeatPulse(deltaTime: Float) -> Float {
        lock.lock()
        defer { lock.unlock() }
        let value = beatPulseValue
        beatPulseValue = max(0, beatPulseValue - deltaTime * 0.15)
        return value
    }

    func consumeRipplePulses(deltaTime: Float) -> [Float] {
        lock.lock()
        defer { lock.unlock() }
        let values = ripplePulses
        for i in 0..<ripplePulses.count {
            ripplePulses[i] = max(0, ripplePulses[i] - deltaTime * 0.15)
        }
        return values
    }

    func consumeKickPulse(deltaTime: Float) -> Float {
        lock.lock()
        defer { lock.unlock() }
        let value = kickPulseValue
        kickPulseValue = max(0, kickPulseValue - deltaTime * 3.0)
        return value
    }

    private func attackRelease(current: Float, target: Float) -> Float {
        let rate: Float = target > current ? 0.6 : 0.12
        return current + (target - current) * rate
    }
}
