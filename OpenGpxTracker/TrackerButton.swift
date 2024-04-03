import UIKit

/// Crea un pulsante con angoli arrotondati.
///
/// Se la larghezza e l'altezza sono uguali, il pulsante è un cerchio.
///
/// Di default, viene assegnato un colore di sfondo bianco.
///
class TrackerButton: UIButton {
    
    /// Chiama semplicemente `super()` e imposta il colore di sfondo come bianco
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        backgroundColor = kWhiteBackgroundColor // Imposta il colore di sfondo del pulsante a bianco
    }
    
    /// Sovrascrittura per assegnare il raggio del pulsante a metà dell'altezza
    override func layoutSubviews() {
        super.layoutSubviews() // Chiama la funzione superiore per mantenere il layout standard
        layer.cornerRadius = frame.height / 2 // Imposta il raggio dell'angolo arrotondato a metà dell'altezza del pulsante
    }
}
