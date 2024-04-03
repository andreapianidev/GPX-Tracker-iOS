//
//  OpenGpxTracker
//
//  Sviluppato da Andrea Piani a La Palma - 18 01 2024
//

import Foundation

/// Per mantenere ogni tipo di pattern di data per `DateFieldTypeView`
struct DateField {
    
    /// Titolo/tipo del pattern (ad esempio Anno / Secondo)
    var type: String
    
    /// Pattern che rientrano nel suddetto tipo (ad esempio `YYYY` / `ss`)
    var patterns: [String]
    
    /// Per facilitare la spiegazione del suddetto pattern, che rientra nello stesso tipo, se necessario.
    ///
    /// La chiave del sottotitolo dovrebbe essere accessibile in `patterns`
    var subtitles: [String: String]?
}
