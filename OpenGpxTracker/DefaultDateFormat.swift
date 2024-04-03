//
//  OpenGpxTracker
//
//  Sviluppato da Andrea Piani a La Palma - 18 01 2024
//

import Foundation

// Gestisce l'elaborazione del formato della data inserito dall'utente, il trattamento del formato di esempio della data, ecc.
class DefaultDateFormat {
    
    // DateFormatter utilizzato in ogni istanza.
    let dateFormatter = DateFormatter()
    
    // Restituisce un formato di data 'elaborato', compatibile con `DateFormatter`.
    // Verifica anche la validità del formato fornito.
    func getDateFormat(unprocessed: String) -> (String, Bool) {
        var newText = ""
        var isInvalid = false
        // Impedisce di riconoscere formati di data non terminati come validi
        if (unprocessed.countInstances(of: "{") != unprocessed.countInstances(of: "}"))
        || unprocessed.countInstances(of: "{}") > 0 {
            newText = "'invalido'"
            isInvalid = true
        } else {
            let arr = unprocessed.components(separatedBy: CharacterSet(charactersIn: "{}"))
            var lastField: String?
            let arrCount = arr.count
            for i in 0...arrCount - 1 {
                if let lastField = lastField, lastField.countInstances(of: String(arr[i].last ?? Character(" "))) > 0 {
                    newText = "'invalido: { ... } non deve ripetersi consecutivamente'"
                    isInvalid = true
                    break
                }
                if arr.count == 1 {
                    newText += "'invalido'"
                    isInvalid = true
                } else if arrCount > 1 && !arr[i].isEmpty {
                    newText += (i % 2 == 0) ? "'\(arr[i])'" : arr[i]
                    lastField = (i % 2 != 0) ? arr[i] : nil
                }
            }
        }
        return (newText, isInvalid)
    }
    
    // Restituisce la data e l'ora di esempio basate sul formato fornito dall'utente.
    // Permette di specificare l'uso del fuso orario UTC e della localizzazione in inglese.
    func getDate(processedFormat dateFormat: String, useUTC: Bool = false, useENLocale: Bool = false) -> String {
        dateFormatter.dateFormat = dateFormat
        dateFormatter.timeZone = useUTC ? TimeZone(secondsFromGMT: 0) : TimeZone.current
        dateFormatter.locale = useENLocale ? Locale(identifier: "en_US_POSIX") : Locale.current
        return dateFormatter.string(from: Date())
    }
    
    // Restituisce il formato della data memorizzato nelle preferenze e le relative impostazioni.
    func getDateFromPrefs() -> String {
        let dateFormat = Preferences.shared.dateFormat
        let useUTC = Preferences.shared.dateFormatUseUTC
        let useEN = Preferences.shared.dateFormatUseEN
        return getDate(processedFormat: dateFormat, useUTC: useUTC, useENLocale: useEN)
        
    }

}
