//
//  GPXTileServer.swift
//  OpenGpxTracker
//
//  Creato da merlos il 25/01/15.
//
// File condiviso: questo file è incluso anche nel target dell'estensione OpenGpxTracker-Watch.

import Foundation

///
/// Configurazione per i server di tiles supportati.
///
/// Le mappe visualizzate nell'applicazione sono composte da piccole immagini quadrate chiamate tiles. Esistono diversi server
/// che forniscono queste tiles.
///
/// Un tile server è definito da un id interno (ad esempio .openStreetMap), una stringa di nome per la visualizzazione
/// sull'interfaccia e un template URL.
///
enum GPXTileServer: Int {
    
    /// Tile server di Apple
    case apple
    
    /// Tile server satellite di Apple
    case appleSatellite
    
    /// Tile server di Open Street Map
    case openStreetMap
    // case AnotherMap
    
    /// Tile server di CartoDB
    case cartoDB
    
    /// Tile server di CartoDB (tiles 2x)
    case cartoDBRetina
    
    /// Tile server di OpenTopoMap
    case openTopoMap
    
    /// Tile server di OpenSeaMap
    case openSeaMap
    
    /// Stringa che descrive il tile server selezionato.
    var name: String {
        switch self {
        case .apple: return "Apple Mapkit (senza cache offline)"
        case .appleSatellite: return "Apple Satellite (senza cache offline)"
        case .openStreetMap: return "Open Street Map"
        case .cartoDB: return "Carto DB"
        case .cartoDBRetina: return "Carto DB (Risoluzione Retina)"
        case .openTopoMap: return "OpenTopoMap"
        case .openSeaMap: return "OpenSeaMap"
        }
    }
    
    /// Template URL del tile server corrente (è nella forma http://{s}.map.tile.server/{z}/{x}/{y}.png)
    var templateUrl: String {
        switch self {
        case .apple: return ""
        case .appleSatellite: return ""
        case .openStreetMap: return "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png"
        case .cartoDB: return "https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}.png"
        case .cartoDBRetina: return "https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}@2x.png"
        case .openTopoMap: return "https://{s}.tile.opentopomap.org/{z}/{x}/{y}.png"
        case .openSeaMap: return "https://tiles.openseamap.org/seamark/{z}/{x}/{y}.png"
        }
    }
    
    /// Nei `templateUrl` la `{s}` indica il sottodominio, tipicamente i sottodomini disponibili sono a, b e c
    /// Verifica i sottodomini disponibili per il tuo server.
    ///
    /// Imposta un array vuoto (`[]`) nel caso in cui non usi `{s}` nel tuo `templateUrl`.
    ///
    /// I sottodomini sono utili per distribuire la richiesta di download delle tiles tra i diversi server
    /// e visualizzarli più rapidamente come risultato.
    var subdomains: [String] {
        switch self {
        case .apple: return []
        case .appleSatellite: return []
        case .openStreetMap: return ["a", "b", "c"]
        case .cartoDB, .cartoDBRetina: return ["a", "b", "c"]
        case .openTopoMap: return ["a", "b", "c"]
        case .openSeaMap: return []
        // case .AnotherMap: return ["a","b"]
        }
    }
    
    /// Livello di zoom massimo supportato dal tile server
    /// I tile server forniscono file fino a un certo livello di zoom che varia da 0 a maximumZ.
    /// Se la mappa effettua zoom oltre il livello limite, non verranno richieste tiles.
    ///
    /// Tipicamente il valore è intorno a 19, 20 o 21.
    ///
    /// Usa un valore negativo per evitare di impostare un limite.
    ///
    /// - vedi https://wiki.openstreetmap.org/wiki/Slippy_map_tilenames#Tile_servers
    ///
    var maximumZ: Int {
        switch self {
        case .apple:
            return -1
        case .appleSatellite:
            return -1
        case .openStreetMap:
            return 19
        case .cartoDB, .cartoDBRetina:
            return 21
        case .openTopoMap:
            return 17
        case .openSeaMap:
            return 16
        }
    }
    ///
    /// Livello di zoom minimo supportato dal tile server
    ///
    /// Questo limita le tiles richieste in base al livello di zoom corrente.
    /// Non verranno richieste tiles per livelli di zoom inferiori a questo.
    ///
    /// Deve essere 0 o maggiore.
    ///
    var minimumZ: Int {
        switch self {
        case .apple:
            return 0
        case .appleSatellite:
            return 0
        case .openStreetMap:
            return 0
        case .cartoDB, .cartoDBRetina:
            return 0
        case .openTopoMap:
            return 0
        case .openSeaMap:
            return 0
        // case .AnotherMap: return 0
        }
    }
    
    /// Il tile overlay sostituisce la mappa?
    /// Generalmente tutte le tiles fornite sostituiscono AppleMaps. Tuttavia ci sono eccezioni.
    var canReplaceMapContent: Bool {
        switch self {
        case .openSeaMap: return false
        default: return true
        }
    }
    
    /// Dimensione delle tiles di terze parti.
    ///
    /// Le tiles 1x sono 256x256
    /// Le tiles 2x/retina sono 512x512
    var tileSize: Int {
        switch self {
        case .cartoDBRetina: return 512
        default: return 256
        }
    }
    
    /// Necessità di forzare la modalità scura.
    var needForceDarkMode: Bool {
        return self == .appleSatellite
    }

    /// Restituisce il numero di tile server attualmente definiti
    static var count: Int { return GPXTileServer.openSeaMap.rawValue + 1 }
}
