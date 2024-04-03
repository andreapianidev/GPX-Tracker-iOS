//
//  OpenGpxTracker
//
//  Sviluppato da Andrea Piani a La Palma - 18 01 2024
//

import MapKit
import UIKit

extension MKMapView {
    
    /// Aggiunge un overlay in cima a tutti gli altri.
    ///
    /// Se la mappa ha già degli overlay, questo metodo aggiunge il nuovo overlay sopra l'ultimo.
    /// Altrimenti, se è il primo overlay, lo aggiunge semplicemente alla mappa.
    func addOverlayOnTop(_ overlay: MKOverlay) {
        if let last = self.overlays.last {                 // Non è il primo overlay
            self.insertOverlay(overlay, above: last)       // Assicurati di aggiungerlo sopra a tutti
        } else {                                           // È il primo overlay
            self.addOverlay(overlay)                       // Aggiungilo semplicemente
        }
    }
    
    /// Aggiunge un overlay in fondo a tutti gli altri.
    ///
    /// Se la mappa ha già degli overlay, questo metodo aggiunge il nuovo overlay sotto il primo.
    /// Altrimenti, se è il primo overlay, lo aggiunge alla mappa con un livello specifico.
    func addOverlayOnBottom(_ overlay: MKOverlay) {
        if let first = self.overlays.first {                // È il primo overlay
            self.insertOverlay(overlay, above: first)       // Assicurati di aggiungerlo sotto a tutti
        } else {                                            // È il primo overlay
            self.addOverlay(overlay, level: .aboveLabels)   // Aggiungilo semplicemente con un livello specifico
        }
    }
}
