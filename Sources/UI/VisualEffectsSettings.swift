import Foundation

enum AudioSource: String, CaseIterable {
    case spotify
    case appleMusic

    var bundleID: String {
        switch self {
        case .spotify: return "com.spotify.client"
        case .appleMusic: return "com.apple.Music"
        }
    }

    var displayName: String {
        switch self {
        case .spotify: return "Spotify"
        case .appleMusic: return "Apple Music"
        }
    }
}

private enum SettingsKey {
    static let kaleidoscope = "VisualEffectsSettings.kaleidoscope"
    static let echoTrails = "VisualEffectsSettings.echoTrails"
    static let chromaticAberration = "VisualEffectsSettings.chromaticAberration"
    static let hueCycling = "VisualEffectsSettings.hueCycling"
    static let atmosphereMode = "VisualEffectsSettings.atmosphereMode"
    static let showNowPlayingWidget = "VisualEffectsSettings.showNowPlayingWidget"
    static let audioSource = "VisualEffectsSettings.audioSource"
}

final class VisualEffectsSettings: @unchecked Sendable {
    static let shared = VisualEffectsSettings()
    static let showNowPlayingWidgetChanged = Notification.Name("VisualEffectsSettings.showNowPlayingWidgetChanged")
    static let audioSourceChanged = Notification.Name("VisualEffectsSettings.audioSourceChanged")

    private let lock = NSLock()
    private let defaults = UserDefaults.standard
    private var _kaleidoscope = false
    private var _echoTrails = false
    private var _chromaticAberration = false
    private var _hueCycling = false
    private var _atmosphereMode = 0
    private var _showNowPlayingWidget = true
    private var _audioSource: AudioSource = .spotify

    private init() {
        if defaults.object(forKey: SettingsKey.kaleidoscope) != nil {
            _kaleidoscope = defaults.bool(forKey: SettingsKey.kaleidoscope)
        }
        if defaults.object(forKey: SettingsKey.echoTrails) != nil {
            _echoTrails = defaults.bool(forKey: SettingsKey.echoTrails)
        }
        if defaults.object(forKey: SettingsKey.chromaticAberration) != nil {
            _chromaticAberration = defaults.bool(forKey: SettingsKey.chromaticAberration)
        }
        if defaults.object(forKey: SettingsKey.hueCycling) != nil {
            _hueCycling = defaults.bool(forKey: SettingsKey.hueCycling)
        }
        if defaults.object(forKey: SettingsKey.atmosphereMode) != nil {
            _atmosphereMode = defaults.integer(forKey: SettingsKey.atmosphereMode)
        }
        if defaults.object(forKey: SettingsKey.showNowPlayingWidget) != nil {
            _showNowPlayingWidget = defaults.bool(forKey: SettingsKey.showNowPlayingWidget)
        }
        if let rawSource = defaults.string(forKey: SettingsKey.audioSource),
           let source = AudioSource(rawValue: rawSource) {
            _audioSource = source
        }
    }

    var atmosphereMode: Int {
        get { lock.lock(); defer { lock.unlock() }; return _atmosphereMode }
        set {
            lock.lock(); _atmosphereMode = newValue; lock.unlock()
            defaults.set(newValue, forKey: SettingsKey.atmosphereMode)
        }
    }

    var kaleidoscope: Bool {
        get { lock.lock(); defer { lock.unlock() }; return _kaleidoscope }
        set {
            lock.lock(); _kaleidoscope = newValue; lock.unlock()
            defaults.set(newValue, forKey: SettingsKey.kaleidoscope)
        }
    }

    var echoTrails: Bool {
        get { lock.lock(); defer { lock.unlock() }; return _echoTrails }
        set {
            lock.lock(); _echoTrails = newValue; lock.unlock()
            defaults.set(newValue, forKey: SettingsKey.echoTrails)
        }
    }

    var chromaticAberration: Bool {
        get { lock.lock(); defer { lock.unlock() }; return _chromaticAberration }
        set {
            lock.lock(); _chromaticAberration = newValue; lock.unlock()
            defaults.set(newValue, forKey: SettingsKey.chromaticAberration)
        }
    }

    var hueCycling: Bool {
        get { lock.lock(); defer { lock.unlock() }; return _hueCycling }
        set {
            lock.lock(); _hueCycling = newValue; lock.unlock()
            defaults.set(newValue, forKey: SettingsKey.hueCycling)
        }
    }

    var showNowPlayingWidget: Bool {
        get { lock.lock(); defer { lock.unlock() }; return _showNowPlayingWidget }
        set {
            lock.lock(); _showNowPlayingWidget = newValue; lock.unlock()
            defaults.set(newValue, forKey: SettingsKey.showNowPlayingWidget)
            NotificationCenter.default.post(name: Self.showNowPlayingWidgetChanged, object: nil)
        }
    }

    var audioSource: AudioSource {
        get { lock.lock(); defer { lock.unlock() }; return _audioSource }
        set {
            lock.lock(); _audioSource = newValue; lock.unlock()
            defaults.set(newValue.rawValue, forKey: SettingsKey.audioSource)
            NotificationCenter.default.post(name: Self.audioSourceChanged, object: nil)
        }
    }
}
