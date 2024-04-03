//
//  InfoWKViewController.swift
//  Gpx Tracker
//
//  Sviluppato da Andrea Piani a La Palma - 18 01 2024
//

import UIKit
import WebKit

/// Controller per visualizzare la pagina "About" (Informazioni).
///
/// Si tratta internamente di un WKWebView che mostra il file di risorsa about.html.
///
class AboutViewController: UIViewController {
    
    /// Browser web incorporato nel controller.
    var webView: WKWebView?
    
    /// Inizializzatore. Chiama solo il costruttore della superclasse.
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    /// Inizializzatore. Chiama solo il costruttore della superclasse.
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }
    
    /// Configura la vista. Esegue le seguenti azioni:
    ///
    /// 1. Imposta il titolo della pagina su "Informazioni".
    /// 2. Aggiunge il pulsante "Fatto" alla barra di navigazione.
    /// 3. Aggiunge il WebView che carica il file about.html dal bundle dell'app.
    ///
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Imposta il titolo della vista
        self.title = NSLocalizedString("ABOUT", comment: "Titolo della pagina Informazioni")
        
        // Aggiunge il pulsante "Fatto" alla barra di navigazione
        let shareItem = UIBarButtonItem(title: NSLocalizedString("DONE", comment: "Testo del pulsante Fatto"),
                                        style: UIBarButtonItem.Style.plain, target: self,
                                        action: #selector(AboutViewController.closeViewController))
        self.navigationItem.rightBarButtonItems = [shareItem]
  
        // Configura e aggiunge il WebView alla vista
        self.webView = WKWebView(frame: self.view.frame, configuration: WKWebViewConfiguration())
        self.webView?.navigationDelegate = self
        let path = Bundle.main.path(forResource: "about", ofType: "html")
        let text = try? String(contentsOfFile: path!, encoding: String.Encoding.utf8)
        webView?.loadHTMLString(text!, baseURL: nil)
        webView?.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        self.view.addSubview(webView!)
    }
    
    /// Chiude il ViewController. Attivato premendo il pulsante "Fatto" nella barra di navigazione.
    @objc func closeViewController() {
        self.dismiss(animated: true, completion: nil)
    }
    
}

/// Gestisce la navigazione per il WebView.
extension AboutViewController: WKNavigationDelegate {
    
    /// Apre Safari quando l'utente clicca su un link nella pagina Informazioni.
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction,
                 decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        print("AboutViewController: decidePolicyForNavigationAction")
        
        if navigationAction.navigationType == .linkActivated {
            if let url = navigationAction.request.url {
                if #available(iOS 10, *) {
                    UIApplication.shared.open(url)
                } else {
                    UIApplication.shared.openURL(url)
                }
                print("AboutViewController: link esterno inviato a Safari")
                decisionHandler(.cancel)
            } else {
                decisionHandler(.allow)
            }
        } else {
            decisionHandler(.allow)
        }
    }
}
