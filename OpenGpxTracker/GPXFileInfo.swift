//
//  Gpx Tracker
//
//  Developed by Andrea Piani in La Palma - 18 01 2024
//

import Foundation

/// Un modo pratico per ottenere informazioni su un file GPX.
///
/// Fornisce informazioni come il nome del file, la data di modifica e la dimensione del file.
///
class GPXFileInfo: NSObject {
    
    /// URL del file
    var fileURL: URL = URL(fileURLWithPath: "")
    
    /// Ultima volta in cui il file è stato modificato
    var modifiedDate: Date {
        // Utilizza force try (!) per recuperare i valori delle risorse.
        // Nota: l'uso di force try può causare un crash se la richiesta fallisce.
        // Recupera la data di modifica del contenuto del file, restituendo una data remota se non disponibile.
        return try! fileURL.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate ?? Date.distantPast
    }
    
    /// La data di modifica convertita in una stringa che indica il tempo trascorso da essa (esempio: "3 giorni fa")
    var modifiedDatetimeAgo: String {
        return modifiedDate.timeAgo(numericDates: true) // Utilizza una funzione esterna per formattare la data
    }
    
    /// Dimensione del file in byte
    var fileSize: Int {
        // Allo stesso modo, utilizza force try (!) per recuperare la dimensione del file, restituendo 0 se non disponibile.
        return try! fileURL.resourceValues(forKeys: [.fileSizeKey]).fileSize ?? 0
    }
    
    /// Dimensione del file in un formato più leggibile per l'utente (esempio: "10 KB")
    var fileSizeHumanised: String {
        return fileSize.asFileSize() // Utilizza una funzione esterna per convertire la dimensione in byte in un formato leggibile
    }
    
    /// Il nome del file senza l'estensione
    var fileName: String {
        // Rimuove l'estensione dall'URL e restituisce solo il nome del file
        return fileURL.deletingPathExtension().lastPathComponent
    }
    
    /// Inizializza l'oggetto con l'URL del file da cui ottenere le informazioni.
    ///
    /// - Parameters:
    ///     - fileURL: l'URL del file GPX.
    ///
    init(fileURL: URL) {
        self.fileURL = fileURL // Assegna l'URL del file alla variabile dell'istanza
        super.init() // Chiama il costruttore della classe base (NSObject)
    }
    
}
