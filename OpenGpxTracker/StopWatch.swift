//
//  OpenGpxTracker
//
//  Developed by Andrea Piani in La Palma - 18 01 2024
//

import Foundation

/// Stati possibili del cronometro
enum StopWatchStatus {
    case started  // È in conteggio
    case stopped  // Non è in conteggio
}

/// Classe per gestire la logica di un cronometro
/// Ha due stati: avviato o fermato. Quando avviato, conta il tempo.
class StopWatch: NSObject {
    var tmpElapsedTime: TimeInterval = 0.0
    var startedDate: Date?  // Data di avvio del cronometro
    var status: StopWatchStatus
    var timeInterval: TimeInterval = 1.00
    var timer = Timer()
    weak var delegate: StopWatchDelegate?
    
    override init() {
        self.status = .stopped
        super.init()
    }
    
    /// Avvia il conteggio del tempo
    func start() {
        self.status = .started
        self.startedDate = Date()
        timer = Timer.scheduledTimer(timeInterval: timeInterval, target: self, selector: #selector(updateElapsedTime), userInfo: nil, repeats: true)
    }
    
    /// Ferma il conteggio del tempo
    func stop() {
        self.status = .stopped
        if let startedDate = self.startedDate {
            let diff = Date().timeIntervalSince(startedDate)
            tmpElapsedTime += diff
        }
        timer.invalidate()
    }
 
    /// Resetta il cronometro
    func reset() {
        timer.invalidate()
        self.tmpElapsedTime = 0.0
        self.startedDate = nil
        self.status = .stopped
    }
    
    /// Tempo trascorso corrente
    var elapsedTime: TimeInterval {
        guard status == .started, let startedDate = self.startedDate else {
            return self.tmpElapsedTime
        }
        return tmpElapsedTime + Date().timeIntervalSince(startedDate)
    }
    
    /// Restituisce il tempo trascorso come stringa nel formato `MM:SS` o `HhMM:SS`
    var elapsedTimeString: String {
        let hours = UInt32(elapsedTime / 3600)
        let minutes = UInt32((elapsedTime / 60).truncatingRemainder(dividingBy: 60))
        let seconds = UInt32(elapsedTime.truncatingRemainder(dividingBy: 60))

        let strHours = hours > 0 ? String(hours) + "h" : ""
        let strMinutes = String(format: "%02d", minutes)
        let strSeconds = String(format: "%02d", seconds)

        return "\(strHours)\(strMinutes):\(strSeconds)"
    }
    
    /// Informa il delegato dell'aggiornamento del tempo trascorso
    @objc func updateElapsedTime() {
        delegate?.stopWatch(self, didUpdateElapsedTimeString: elapsedTimeString)
    }
}
