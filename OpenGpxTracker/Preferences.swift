//
//
// Shared file: this file is also included in the OpenGpxTracker-Watch Extension target.

import Foundation
import CoreLocation

/// Chiave in Defaults per l'intero del Tile Server.
let kDefaultsKeyTileServerInt: String = "TileServerInt"

/// Chiave in Defaults per l'impostazione dell'uso della cache.
let kDefaultsKeyUseCache: String = "UseCache"

/// Chiave in Defaults per l'uso delle unità imperiali.
let kDefaultsKeyUseImperial: String = "UseImperial"

/// Chiave in Defaults per il tipo di attività selezionato corrente.
let kDefaultsKeyActivityType: String = "ActivityType"

/// Chiave in Defaults per il formato della data corrente.
let kDefaultsKeyDateFormat: String = "DateFormat"

/// Chiave in Defaults per il formato della data di input corrente.
let kDefaultsKeyDateFormatInput: String = "DateFormatPresetInput"

/// Chiave in Defaults per l'indice della cella del preset del formato della data selezionato corrente.
let kDefaultsKeyDateFormatPreset: String = "DateFormatPreset"

/// Chiave in Defaults per il formato della data selezionato corrente, per usare o meno il tempo UTC.
let kDefaultsKeyDateFormatUseUTC: String = "DateFormatPresetUseUTC"

/// Chiave in Defaults per il formato della data selezionato corrente, per usare la localizzazione locale o `en_US_POSIX`.
let kDefaultsKeyDateFormatUseEN: String = "DateFormatPresetUseEN"

/// Chiave in Defaults per la cartella in cui sono memorizzati i file GPX, `nil` indica la cartella predefinita.
let kDefaultsKeyGPXFilesFolder: String = "GPXFilesFolder"

/// Una classe per gestire le preferenze dell'app in un unico luogo.
/// Quando l'app viene avviata per la prima volta, vengono impostate le seguenti preferenze:
///
/// * useCache = true
/// * useImperial = in base a quanto impostato dalla località corrente (NSLocale.usesMetricUnits) o false
/// * tileServer = .apple
///

class Preferences: NSObject {

    /// Shared preferences singleton.
    /// Usage:
    ///      var preferences: Preferences = Preferences.shared
    ///      print (preferences.useCache)
    ///
    static let shared = Preferences()
    
    /// In memory value of the preference.
    private var _useImperial: Bool = false
    
    /// In memory value of the preference.
    private var _useCache: Bool = true
    
    /// In memory value of the preference.
    private var _tileServer: GPXTileServer = .apple
    
    /// In memory value of the preference.
    private var _activityType: CLActivityType = .other
    
    ///
    private var _dateFormat = "dd-MMM-yyyy-HHmm"
    
    ///
    private var _dateFormatInput = "{dd}-{MMM}-{yyyy}-{HH}{mm}"
    
    ///
    private var _dateFormatPreset: Int = 0
    
    ///
    private var _dateFormatUseUTC: Bool = false
    
    ///
    private var _dateFormatUseEN: Bool = false
    
    ///
    private var _gpxFilesFolderBookmark: Data?
    
    /// UserDefaults.standard shortcut
    private let defaults = UserDefaults.standard
    
    /// Carica le preferenze da UserDefaults.
    private override init() {
        // Carica le preferenze nelle variabili private

        // Utilizza unità imperiali
        if let useImperialDefaults = defaults.object(forKey: kDefaultsKeyUseImperial) as? Bool {
            print("** Preferences:: caricate dalle impostazioni predefinite. useImperial: \(useImperialDefaults)")
            _useImperial = useImperialDefaults
        } else { // Ottiene dalla configurazione locale
            let locale = NSLocale.current
            _useImperial = !locale.usesMetricSystem
            let langCode = locale.languageCode ?? "sconosciuto"
            let useMetric = locale.usesMetricSystem
            print("** Preferences:: NESSUNA impostazione predefinita per useImperial. Utilizzando localizzazione: \(langCode) useImperial: \(_useImperial) usaSistemaMetrico:\(useMetric)")
        }

        // Utilizza cache
        if let useCacheFromDefaults = defaults.object(forKey: kDefaultsKeyUseCache) as? Bool {
            _useCache = useCacheFromDefaults
            print("Preferences:: preferenza caricata dalle impostazioni predefinite useCache= \(useCacheFromDefaults)")
        }

        // Server per le mappe in tile
        if var tileServerInt = defaults.object(forKey: kDefaultsKeyTileServerInt) as? Int {
            // Verifica nel caso in cui fosse un tile server non più supportato
            tileServerInt = tileServerInt >= GPXTileServer.count ? GPXTileServer.apple.rawValue : tileServerInt
            _tileServer = GPXTileServer(rawValue: tileServerInt)!
            print("** Preferences:: preferenza caricata dalle impostazioni predefinite tileServerInt \(tileServerInt)")
        }

        // Carica il tipo di attività precedente
        if let activityTypeInt = defaults.object(forKey: kDefaultsKeyActivityType) as? Int {
            _activityType = CLActivityType(rawValue: activityTypeInt)!
            print("** Preferences:: preferenza caricata dalle impostazioni predefinite activityTypeInt \(activityTypeInt)")
        }

        // Carica il formato di data precedente
        if let dateFormatStr = defaults.object(forKey: kDefaultsKeyDateFormat) as? String {
            _dateFormat = dateFormatStr
            print("** Preferences:: preferenza caricata dalle impostazioni predefinite dateFormatStr \(dateFormatStr)")
        }

        // Carica il formato di data precedente (input utente)
        if let dateFormatStrIn = defaults.object(forKey: kDefaultsKeyDateFormatInput) as? String {
            _dateFormatInput = dateFormatStrIn
            print("** Preferences:: preferenza caricata dalle impostazioni predefinite dateFormatStrIn \(dateFormatStrIn)")
        }

        // Carica il preset del formato di data precedente
        if let dateFormatPresetInt = defaults.object(forKey: kDefaultsKeyDateFormatPreset) as? Int {
            _dateFormatPreset = dateFormatPresetInt
            print("** Preferences:: preferenza caricata dalle impostazioni predefinite dateFormatPresetInt \(dateFormatPresetInt)")
        }

        // Carica la preferenza precedente del formato di data, per utilizzare il tempo UTC invece del tempo locale
        if let dateFormatUTCBool = defaults.object(forKey: kDefaultsKeyDateFormatUseUTC) as? Bool {
            _dateFormatUseUTC = dateFormatUTCBool
            print("** Preferences:: preferenza caricata dalle impostazioni predefinite dateFormatPresetUTCBool \(dateFormatUTCBool)")
        }

        // Carica la preferenza precedente del formato di data, per utilizzare la localizzazione EN invece della localizzazione locale
        if let dateFormatENBool = defaults.object(forKey: kDefaultsKeyDateFormatUseEN) as? Bool {
            _dateFormatUseEN = dateFormatENBool
            print("** Preferences:: preferenza caricata dalle impostazioni predefinite dateFormatPresetENBool \(dateFormatENBool)")
        }

        // Carica il segnalibro della cartella dei file GPX precedente
        if let gpxFilesFolderBookmark = defaults.object(forKey: kDefaultsKeyGPXFilesFolder) as? Data {
            _gpxFilesFolderBookmark = gpxFilesFolderBookmark
            print("** Preferences:: preferenza caricata dalle impostazioni predefinite gpxFilesFolderBookmark \(gpxFilesFolderBookmark)")
        }
    }

    
    /// If true, user prefers to display imperial units (miles, feets). Otherwise metric units
    /// are displayed.
    var useImperial: Bool {
        get {
            return _useImperial
        }
        set {
            _useImperial = newValue
            defaults.set(newValue, forKey: kDefaultsKeyUseImperial)
        }
    }
    
    /// Gets and sets if user wants to use offline cache.
    var useCache: Bool {
        get {
            return _useCache
        }
        set {
            _useCache = newValue
            // Set defaults
            defaults.set(newValue, forKey: kDefaultsKeyUseCache)
        }
    }
    
    /// Gets and sets user preference of the map tile server.
    var tileServer: GPXTileServer {
        get {
            return _tileServer
        }
        
        set {
            _tileServer = newValue
             defaults.set(newValue.rawValue, forKey: kDefaultsKeyTileServerInt)
        }
    }
    
    /// Get and sets user preference of the map tile server as Int.
    var tileServerInt: Int {
        get {
            return _tileServer.rawValue
        }
        set {
            _tileServer = GPXTileServer(rawValue: newValue)!
             defaults.set(newValue, forKey: kDefaultsKeyTileServerInt)
        }
    }
    /// Gets and sets the type of activity preference
    var locationActivityType: CLActivityType {
        get {
            return _activityType
        }
        set {
            _activityType = newValue
            defaults.set(newValue.rawValue, forKey: kDefaultsKeyActivityType)
        }
    }
    
    /// Gets and sets the activity type as its int value
    var locationActivityTypeInt: Int {
        get {
            return _activityType.rawValue
        }
        set {
            _activityType = CLActivityType(rawValue: newValue)!
            defaults.set(newValue, forKey: kDefaultsKeyActivityType)
        }
    }
    
    /// Gets and sets the date formatter friendly date format
    var dateFormat: String {
        get {
            return _dateFormat
        }
        
        set {
             _dateFormat = newValue
             defaults.set(newValue, forKey: kDefaultsKeyDateFormat)
        }
    }
    
    /// Gets and sets the user friendly input date format
    var dateFormatInput: String {
        get {
            return _dateFormatInput
        }
        
        set {
             _dateFormatInput = newValue
             defaults.set(newValue, forKey: kDefaultsKeyDateFormatInput)
        }
    }
    
    /// Get and sets user preference of date format presets. (-1 if custom)
    var dateFormatPreset: Int {
        get {
            return _dateFormatPreset
        }
        set {
            _dateFormatPreset = newValue
             defaults.set(newValue, forKey: kDefaultsKeyDateFormatPreset)
        }
    }
    
    /// Get date format preset name
    var dateFormatPresetName: String {
        let presets =  ["Defaults", "ISO8601 (UTC)", "ISO8601 (UTC offset)", "Day, Date at time (12 hr)", "Day, Date at time (24 hr)"]
        return _dateFormatPreset < presets.count ? presets[_dateFormatPreset] : "???"
    }
    
    /// Get and sets whether to use UTC for date format
    var dateFormatUseUTC: Bool {
        get {
            return _dateFormatUseUTC
        }
        set {
            _dateFormatUseUTC = newValue
             defaults.set(newValue, forKey: kDefaultsKeyDateFormatUseUTC)
        }
    }
    
    /// Get and sets whether to use local locale or EN
    var dateFormatUseEN: Bool {
        get {
            return _dateFormatUseEN
        }
        set {
            _dateFormatUseEN = newValue
             defaults.set(newValue, forKey: kDefaultsKeyDateFormatUseEN)
        }
    }
    
    var gpxFilesFolderURL: URL? {
        get {
            guard let bookmarkData = self._gpxFilesFolderBookmark else {
                return nil
            }
            do {
                var isStale: Bool = false
                let url = try URL(resolvingBookmarkData: bookmarkData, bookmarkDataIsStale: &isStale)
                if isStale {
                    _ = url.startAccessingSecurityScopedResource()
                    defer {
                        url.stopAccessingSecurityScopedResource()
                    }
                    let newBookmark = try url.bookmarkData()
                    _gpxFilesFolderBookmark = newBookmark
                    defaults.set(newBookmark, forKey: kDefaultsKeyGPXFilesFolder)
                }
                return url
            } catch {
                print("** Preferences:: failed to retrieve url from bookmark data: \(String(describing: error))")
                return nil
            }
        }
        set {
            guard let newValue else {
                defaults.removeObject(forKey: kDefaultsKeyGPXFilesFolder)
                return
            }
            do {
                _ = newValue.startAccessingSecurityScopedResource()
                defer {
                    newValue.stopAccessingSecurityScopedResource()
                }
                let newBookmark = try newValue.bookmarkData()
                _gpxFilesFolderBookmark = newBookmark
                defaults.set(newBookmark, forKey: kDefaultsKeyGPXFilesFolder)
            } catch {
                print("** Preferences:: failed to generate bookmark data for url: \(String(describing: error))")
            }
        }
    }
}
