//
//  ViewController.swift
//  OpenGpxTracker
//
//  Developed by Andrea Piani in La Palma - 18 01 2024
//

import UIKit
import CoreLocation
import MapKit
import CoreGPX
import GoogleMobileAds

// swiftlint:disable line_length

// Titolo dell'app
let kAppTitle: String = "GPX Tracker"

// Colore viola per lo sfondo dei pulsanti
let kPurpleButtonBackgroundColor: UIColor = UIColor(red: 146.0/255.0, green: 166.0/255.0, blue: 218.0/255.0, alpha: 0.90)

// Colore verde per lo sfondo dei pulsanti
let kGreenButtonBackgroundColor: UIColor = UIColor(red: 142.0/255.0, green: 224.0/255.0, blue: 102.0/255.0, alpha: 0.90)

// Colore rosso per lo sfondo dei pulsanti
let kRedButtonBackgroundColor: UIColor = UIColor(red: 244.0/255.0, green: 94.0/255.0, blue: 94.0/255.0, alpha: 0.90)

// Colore blu per lo sfondo dei pulsanti
let kBlueButtonBackgroundColor: UIColor = UIColor(red: 74.0/255.0, green: 144.0/255.0, blue: 226.0/255.0, alpha: 0.90)

// Colore blu per lo sfondo dei pulsanti disabilitati
let kDisabledBlueButtonBackgroundColor: UIColor = UIColor(red: 74.0/255.0, green: 144.0/255.0, blue: 226.0/255.0, alpha: 0.10)

// Colore rosso per lo sfondo dei pulsanti disabilitati
let kDisabledRedButtonBackgroundColor: UIColor = UIColor(red: 244.0/255.0, green: 94.0/255.0, blue: 94.0/255.0, alpha: 0.10)

// Colore bianco per lo sfondo dei pulsanti
let kWhiteBackgroundColor: UIColor = UIColor(red: 254.0/255.0, green: 254.0/255.0, blue: 254.0/255.0, alpha: 0.90)

// Tag per il pulsante di eliminazione di un waypoint, utilizzato in una bolla di waypoint
let kDeleteWaypointAccesoryButtonTag = 666

// Tag per il pulsante di modifica di un waypoint, utilizzato in una bolla di waypoint
let kEditWaypointAccesoryButtonTag = 333

// Testo da visualizzare quando il sistema non fornisce coordinate
let kNotGettingLocationText = NSLocalizedString("NO_LOCATION", comment: "Nessun commento")

// Testo da visualizzare per l'accuratezza sconosciuta
let kUnknownAccuracyText = "±···"

// Testo da visualizzare per la velocità sconosciuta
let kUnknownSpeedText = "·.··"

// Dimensione per i pulsanti piccoli
let kButtonSmallSize: CGFloat = 48.0

// Dimensione per i pulsanti grandi
let kButtonLargeSize: CGFloat = 96.0

// Separazione tra i pulsanti
let kButtonSeparation: CGFloat = 6.0

// Soglia limite superiore (in metri) per l'accuratezza del segnale.
let kSignalAccuracy6 = 6.0
let kSignalAccuracy5 = 11.0
let kSignalAccuracy4 = 31.0
let kSignalAccuracy3 = 51.0
let kSignalAccuracy2 = 101.0
let kSignalAccuracy1 = 201.0


///
/// Main View Controller of the Application. It is loaded when the application is launched
///
/// Displays a map and a set the buttons to control the tracking
///
///
/// Controller principale dell'applicazione. Viene caricato all'avvio dell'app.
///
/// Visualizza una mappa e imposta i pulsanti per il controllo del tracciamento.
///
class ViewController: UIViewController, UIGestureRecognizerDelegate, GADFullScreenContentDelegate {
    
    private var interstitial: GADInterstitialAd?
    var bannerView: GADBannerView!
    /// Dovrebbe la mappa essere centrata sulla posizione corrente dell'utente?
    /// Se sì, ogni volta che l'utente si muove, anche il centro della mappa viene aggiornato.
    var followUser: Bool = true {
        didSet {
            if followUser {
                print("followUser=true")
                followUserButton.setImage(UIImage(named: "follow_user_high"), for: UIControl.State())
                map.setCenter(map.userLocation.coordinate, animated: true)
                
            } else {
                print("followUser=false")
                followUserButton.setImage(UIImage(named: "follow_user"), for: UIControl.State())
            }
        }
    }
    
    /// Ancora da determinare (attualmente non utilizzato)
    var followUserBeforePinchGesture = true

    /// Configurazione dell'istanza del gestore delle posizioni
    let locationManager: CLLocationManager = {
        let manager = CLLocationManager()
        manager.requestAlwaysAuthorization()
        manager.activityType = CLActivityType(rawValue: Preferences.shared.locationActivityTypeInt)!
        print("Tipo di attività CL scelta: \(manager.activityType.name)")
        manager.desiredAccuracy = kCLLocationAccuracyBest
        manager.distanceFilter = 2 // metri
        manager.headingFilter = 3 // gradi (1 è il valore predefinito)
        manager.pausesLocationUpdatesAutomatically = false
        if #available(iOS 9.0, *) {
            manager.allowsBackgroundLocationUpdates = true
        }
        return manager
    }()
    
    /// Vista mappa
    var map: GPXMapView
    
    /// Delegato della vista mappa
    let mapViewDelegate = MapViewDelegate()
    
    /// Cronometro per il controllo del tempo trascorso
    var stopWatch = StopWatch()
    
    /// Nome dell'ultimo file salvato (senza estensione)
    var lastGpxFilename: String = "" {
        didSet {
            if lastGpxFilename == "" {
                appTitleLabel.text = kAppTitle
            } else {
                // Se il nome è troppo lungo, viene troncato in modo arbitrario
                var displayedName = lastGpxFilename
                if lastGpxFilename.count > 20 {
                    displayedName = String(lastGpxFilename.prefix(10)) + "..." + String(lastGpxFilename.suffix(3))
                }
                appTitleLabel.text = "  " + displayedName + ".gpx"
            }
        }
    }
    
    /// Variabile di stato che indica se l'app è stata inviata in background.
    var wasSentToBackground: Bool = false
    
    /// Variabile di stato che indica se l'autorizzazione al servizio di localizzazione è stata negata.
    var isDisplayingLocationServicesDenied: Bool = false
    
    /// Ha la mappa dei punti di interesse?
    var hasWaypoints: Bool = false {
        /// Ogni volta che viene aggiornato, se ci sono dei punti di interesse imposta i pulsanti Salva e Reset
        didSet {
            if hasWaypoints {
                saveButton.backgroundColor = kBlueButtonBackgroundColor
                resetButton.backgroundColor = kRedButtonBackgroundColor
            }
        }
    }

    /// Definisce i diversi stati relativi al tracciamento della posizione corrente dell'utente.
    enum GpxTrackingStatus {
        
        /// Il tracciamento non è iniziato o la mappa è stata resettata
        case notStarted
        
        /// Il tracciamento è in corso
        case tracking
        
        /// Il tracciamento è in pausa (la mappa contiene alcuni dati)
        case paused
    }


    
    /// Indica lo stato corrente dell'istanza della mappa.
    var gpxTrackingStatus: GpxTrackingStatus = GpxTrackingStatus.notStarted {
        didSet {
            print("gpxTrackingStatus cambiato in \(gpxTrackingStatus)")
            switch gpxTrackingStatus {
            case .notStarted:
                print("passato a non iniziato")
                // Imposta il pulsante del tracciamento per abilitare l'Inizio
                trackerButton.setTitle(NSLocalizedString("START_TRACKING", comment: "Inizia il tracciamento"), for: UIControl.State())
                trackerButton.backgroundColor = kGreenButtonBackgroundColor
                // Imposta i pulsanti Salva e Reset a trasparente.
                saveButton.backgroundColor = kDisabledBlueButtonBackgroundColor
                resetButton.backgroundColor = kDisabledRedButtonBackgroundColor
                // Resetta l'orologio
                stopWatch.reset()
                timeLabel.text = stopWatch.elapsedTimeString
                
                map.clearMap()        // Pulisce la mappa
                lastGpxFilename = "" // Azzera l'ultimo nome del file, così quando si salva appare un campo vuoto

                map.coreDataHelper.clearAll()
                map.coreDataHelper.coreDataDeleteAll(of: CDRoot.self) // Elimina CDRoot da CoreData
                
                totalTrackedDistanceLabel.distance = (map.session.totalTrackedDistance)
                currentSegmentDistanceLabel.distance = (map.session.currentSegmentDistance)
                
                /*
                // XXX Lasciato qui per riferimento
                UIView.animateWithDuration(0.2, delay: 0.0, options: UIViewAnimationOptions.CurveLinear, animations: { () -> Void in
                    self.trackerButton.hidden = true
                    self.pauseButton.hidden = false
                    }, completion: {(f: Bool) -> Void in
                        println("animazione di inizio tracciamento completata")
                })
                */
                
            case .tracking:
                print("passato alla modalità tracciamento")
                // Imposta trackerButton per abilitare la Pausa
                trackerButton.setTitle(NSLocalizedString("PAUSE", comment: "Metti in pausa"), for: UIControl.State())
                trackerButton.backgroundColor = kPurpleButtonBackgroundColor
                // Attiva i pulsanti Salva e Reset
                saveButton.backgroundColor = kBlueButtonBackgroundColor
                resetButton.backgroundColor = kRedButtonBackgroundColor
                // Avvia l'orologio
                self.stopWatch.start()
                
            case .paused:
                print("passato alla modalità pausa")
                // Imposta trackerButton per abilitare la Ripresa
                self.trackerButton.setTitle(NSLocalizedString("RESUME", comment: "Riprendi"), for: UIControl.State())
                self.trackerButton.backgroundColor = kGreenButtonBackgroundColor
                // Attiva i pulsanti Salva e Reset (nel caso si passi da .NotStarted)
                saveButton.backgroundColor = kBlueButtonBackgroundColor
                resetButton.backgroundColor = kRedButtonBackgroundColor
                // Mette in pausa l'orologio
                self.stopWatch.stop()
                // Inizia un nuovo segmento di tracciamento
                self.map.startNewTrackSegment()
            }
        }
    }

    /// Riferimento temporale dell'ultimo Waypoint modificato
    var lastLocation: CLLocation? // Ultimo punto del segmento corrente.

    // UI
    /// Etichetta con il titolo dell'app
    var appTitleLabel: UILabel

    /// Immagine che indica il segnale GPS
    var signalImageView: UIImageView

    /// Testo dell'accuratezza attuale del segnale GPS (basato sulle costanti kSignalAccuracyX)
    var signalAccuracyLabel: UILabel

    /// Etichetta che mostra la latitudine e longitudine correnti (lat,long)
    var coordsLabel: UILabel

    /// Visualizza il tempo trascorso corrente (00:00)
    var timeLabel: UILabel

    /// Etichetta che mostra l'ultima velocità nota (in km/h)
    var speedLabel: UILabel

    /// Distanza dei segmenti totali tracciati
    var totalTrackedDistanceLabel: DistanceLabel

    /// Distanza del segmento corrente in tracciamento (da quando è stato premuto l'ultimo pulsante Tracker)
    var currentSegmentDistanceLabel: DistanceLabel

    /// Utilizzato per mostrare in sistema imperiale (piede, miglia, mph) o metrico (m, km, km/h)
    var useImperial = false

    /// Pulsante per seguire l'utente (barra inferiore)
    var followUserButton: UIButton

    /// Pulsante per aggiungere un nuovo pin (barra inferiore)
    var newPinButton: UIButton

    /// Pulsante per visualizzare i file GPX
    var folderButton: UIButton

    /// Pulsante per visualizzare informazioni sull'app
    var aboutButton: UIButton

    /// Pulsante per visualizzare le preferenze
    var preferencesButton: UIButton

    /// Pulsante per condividere il file gpx corrente
    var shareButton: UIButton

    /// Indicatore di attività rotante per il pulsante di condivisione
    let shareActivityIndicator: UIActivityIndicatorView

    /// Colore dell'indicatore di attività rotante
    var shareActivityColor = UIColor(red: 0, green: 0.61, blue: 0.86, alpha: 1)

    /// Pulsante per resettare la mappa (barra inferiore)
    var resetButton: UIButton

    /// Pulsante per iniziare/mettere in pausa il tracciamento (barra inferiore)
    var trackerButton: UIButton

    /// Pulsante per salvare il tracciamento corrente in un file GPX
    var saveButton: UIButton

    /// Verifica se il dispositivo è un telefono con notch
    var isIPhoneX = false

    
    // Signal accuracy images
    /// GPS signal image. Level 0 (no signal)
    let signalImage0 = UIImage(named: "signal0")
    /// GPS signal image. Level 1
    let signalImage1 = UIImage(named: "signal1")
    /// GPS signal image. Level 2
    let signalImage2 = UIImage(named: "signal2")
    /// GPS signal image. Level 3
    let signalImage3 = UIImage(named: "signal3")
    /// GPS signal image. Level 4
    let signalImage4 = UIImage(named: "signal4")
    /// GPS signal image. Level 5
    let signalImage5 = UIImage(named: "signal5")
    /// GPS signal image. Level 6
    let signalImage6 = UIImage(named: "signal6")
 
    /// Initializer. Just initializes the class vars/const
    required init(coder aDecoder: NSCoder) {
        self.map = GPXMapView(coder: aDecoder)!
        
        self.appTitleLabel = UILabel(coder: aDecoder)!
        self.signalImageView = UIImageView(coder: aDecoder)!
        self.signalAccuracyLabel = UILabel(coder: aDecoder)!
        self.coordsLabel = UILabel(coder: aDecoder)!
        
        self.timeLabel = UILabel(coder: aDecoder)!
        self.speedLabel = UILabel(coder: aDecoder)!
        self.totalTrackedDistanceLabel = DistanceLabel(coder: aDecoder)!
        self.currentSegmentDistanceLabel = DistanceLabel(coder: aDecoder)!
        
        self.followUserButton = UIButton(coder: aDecoder)!
        self.newPinButton = UIButton(coder: aDecoder)!
        self.folderButton = UIButton(coder: aDecoder)!
        self.resetButton = UIButton(coder: aDecoder)!
        self.aboutButton = UIButton(coder: aDecoder)!
        self.preferencesButton = UIButton(coder: aDecoder)!
        self.shareButton = UIButton(coder: aDecoder)!
        
        self.trackerButton = UIButton(coder: aDecoder)!
        self.saveButton = UIButton(coder: aDecoder)!
        
        self.shareActivityIndicator = UIActivityIndicatorView(coder: aDecoder)
        
        super.init(coder: aDecoder)!
    }
    
    ///
    /// De initalize the ViewController.
    ///
    /// Current implementation removes notification observers
    ///
    deinit {
        print("*** deinit")
        NotificationCenter.default.removeObserver(self)
    }
   
    /// Handles status bar color as a result from iOS 13 appearance changes
    override var preferredStatusBarStyle: UIStatusBarStyle {
        if #available(iOS 13, *) {
            if !isIPhoneX {
                if self.traitCollection.userInterfaceStyle == .dark && map.tileServer == .apple {
                    self.view.backgroundColor = .black
                    return .lightContent
                } else {
                    self.view.backgroundColor = .white
                    return .darkContent
                }
            } else { // > iPhone X has no opaque status bar
                // if is > iP X status bar can be white when map is dark
                return map.tileServer == .apple ? .default : .darkContent
            }
        } else { // < iOS 13
            return .default
        }
    }
    
    func addBannerViewToView(_ bannerView: GADBannerView) {
        bannerView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(bannerView)
        view.addConstraints(
          [NSLayoutConstraint(item: bannerView,
                              attribute: .bottom,
                              relatedBy: .equal,
                              toItem: view.safeAreaLayoutGuide,
                              attribute: .bottom,
                              multiplier: 1,
                              constant: 0),
           NSLayoutConstraint(item: bannerView,
                              attribute: .centerX,
                              relatedBy: .equal,
                              toItem: view,
                              attribute: .centerX,
                              multiplier: 1,
                              constant: 0)
          ])
       }
    
    func addBannerViewAtBottom(_ bannerView: GADBannerView){
        bannerView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(bannerView)

        // Imposta i vincoli per posizionare il banner in basso
        if #available(iOS 11.0, *) {
            // Per dispositivi con iOS 11 o versioni successive, usa le guide dell'area di sicurezza
            let guide = view.safeAreaLayoutGuide
            NSLayoutConstraint.activate([
                bannerView.bottomAnchor.constraint(equalTo: guide.bottomAnchor),
                bannerView.centerXAnchor.constraint(equalTo: guide.centerXAnchor)
            ])
        } else {
            // Per versioni precedenti, allinea il banner al bordo inferiore della vista
            NSLayoutConstraint.activate([
                bannerView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
                bannerView.centerXAnchor.constraint(equalTo: view.centerXAnchor)
            ])
        }
    }
    ///
    /// Initializes the view. It adds the UI elements to the view.
    ///
    /// All the UI is built programatically on this method. Interface builder is not used.
    ///
    override func viewDidLoad() {
        super.viewDidLoad()

        // In this case, we instantiate the banner with desired ad size.
           bannerView = GADBannerView(adSize: GADAdSizeBanner)
        bannerView.adUnitID = "ca-app-pub-1193280742171051~6597343103"
         bannerView.rootViewController = self
        addBannerViewToView(bannerView)
        addBannerViewAtBottom(bannerView)
        let request = GADRequest()
           GADInterstitialAd.load(withAdUnitID: "ca-app-pub-1193280742171051~6597343103",
                                       request: request,
                             completionHandler: { [self] ad, error in
                               if let error = error {
                                 print("Failed to load interstitial ad with error: \(error.localizedDescription)")
                                 return
                               }
                               interstitial = ad
                             }
           )
        
        
         
        // Imposta il delegato per lo stopwatch
        stopWatch.delegate = self
        
        // Recupera i dati da CoreData
        map.coreDataHelper.retrieveFromCoreData()
        
        // Controllo del layout per iPhone X* a causa dei bordi arrotondati.
        // Controlla se il dispositivo corrente è un iPhone X
        if UIDevice.current.userInterfaceIdiom == .phone, #available(iOS 11, *) {
            self.isIPhoneX = UIApplication.shared.delegate?.window??.safeAreaInsets.top ?? 0 > 40
        }
        
        // Configurazione dell'auto-ridimensionamento della mappa
        map.autoresizesSubviews = true
        map.autoresizingMask = [.flexibleHeight, .flexibleWidth]
        self.view.autoresizesSubviews = true
        self.view.autoresizingMask = [.flexibleHeight, .flexibleWidth]

        // Configurazione della mappa
        map.delegate = mapViewDelegate
        map.showsUserLocation = true
        let mapH: CGFloat = self.view.bounds.size.height - (isIPhoneX ? 0.0 : 20.0)
        map.frame = CGRect(x: 0.0, y: (isIPhoneX ? 0.0 : 20.0), width: self.view.bounds.size.width, height: mapH)
        map.isZoomEnabled = true
        map.isRotateEnabled = true
        // Imposta la posizione della bussola
        map.compassRect = CGRect(x: map.frame.width/2 - 18, y: isIPhoneX ? 105.0 : 70.0, width: 36, height: 36)
        
        // Aggiunta di un Pin (waypoint) sulla mappa tramite long press
        map.addGestureRecognizer(
            UILongPressGestureRecognizer(target: self, action: #selector(ViewController.addPinAtTappedLocation(_:)))
        )
        
        // Se l'utente sposta la mappa, interrompe il tracciamento della sua posizione
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(ViewController.stopFollowingUser(_:)))
        panGesture.delegate = self
        map.addGestureRecognizer(panGesture)
        
        // Configurazione del locationManager
        locationManager.delegate = self
        locationManager.startUpdatingLocation()
        locationManager.startUpdatingHeading()
        
        // Preferenze
        map.tileServer = Preferences.shared.tileServer
        map.useCache = Preferences.shared.useCache
        useImperial = Preferences.shared.useImperial
        // LocationManager.activityType = Preferences.shared.locationActivityType
        
        // Configurazione dell'interfaccia utente
        
        // Impostazione dello zoom di default
        let center = locationManager.location?.coordinate ?? CLLocationCoordinate2D(latitude: 8.90, longitude: -79.50)
        let span = MKCoordinateSpan(latitudeDelta: 0.005, longitudeDelta: 0.005)
        let region = MKCoordinateRegion(center: center, span: span)
        map.setRegion(region, animated: true)
        self.view.addSubview(map)
        
        // Aggiunge gli observer per le notifiche
        addNotificationObservers()

        
        //
        // ---------------------- Costruzione dell'Area dell'Interfaccia -----------------------------
        //

        // HEADER: Definizione di vari tipi di font utilizzati nell'interfaccia
        let font36 = UIFont(name: "DinCondensed-Bold", size: 36.0)
        let font18 = UIFont(name: "DinAlternate-Bold", size: 18.0)
        let font12 = UIFont(name: "DinAlternate-Bold", size: 12.0)

        // Aggiunta del titolo dell'app come etichetta (Branding, branding, branding!)
        appTitleLabel.text = kAppTitle
        appTitleLabel.textAlignment = .left
        appTitleLabel.font = UIFont.boldSystemFont(ofSize: 10)
        appTitleLabel.textColor = UIColor.yellow
        appTitleLabel.backgroundColor = UIColor(red: 58.0/255.0, green: 57.0/255.0, blue: 54.0/255.0, alpha: 0.80)
        self.view.addSubview(appTitleLabel)

        // Configurazione dell'etichetta delle coordinate
        coordsLabel.textAlignment = .right
        coordsLabel.font = font12
        coordsLabel.textColor = UIColor.white
        coordsLabel.text = kNotGettingLocationText
        self.view.addSubview(coordsLabel)

        // Differenza di layout specifica per iPhone X
        let iPhoneXdiff: CGFloat  = isIPhoneX ? 40 : 0

        // Configurazione dell'etichetta del tempo
        timeLabel.textAlignment = .right
        timeLabel.font = font36
        timeLabel.text = "00:00"
        map.addSubview(timeLabel)

        // Configurazione dell'etichetta della velocità
        speedLabel.textAlignment = .right
        speedLabel.font = font18
        speedLabel.text = 0.00.toSpeed(useImperial: useImperial)
        map.addSubview(speedLabel)

        // Configurazione dell'etichetta della distanza totale tracciata
        totalTrackedDistanceLabel.textAlignment = .right
        totalTrackedDistanceLabel.font = font36
        totalTrackedDistanceLabel.useImperial = useImperial
        totalTrackedDistanceLabel.distance = 0.00
        totalTrackedDistanceLabel.autoresizingMask = [.flexibleWidth, .flexibleLeftMargin, .flexibleRightMargin]
        map.addSubview(totalTrackedDistanceLabel)

        // Configurazione dell'etichetta della distanza del segmento corrente
        currentSegmentDistanceLabel.textAlignment = .right
        currentSegmentDistanceLabel.font = font18
        currentSegmentDistanceLabel.useImperial = useImperial
        currentSegmentDistanceLabel.distance = 0.00
        currentSegmentDistanceLabel.autoresizingMask = [.flexibleWidth, .flexibleLeftMargin, .flexibleRightMargin]
        map.addSubview(currentSegmentDistanceLabel)

        // Configurazione del pulsante Informazioni
                aboutButton.frame = CGRect(x: 10, y: 100, width: 32, height: 32)
                aboutButton.setImage(UIImage(named: "info"), for: .normal)
                aboutButton.setImage(UIImage(named: "info_high"), for: .highlighted)
                aboutButton.addTarget(self, action: #selector(openAboutViewController), for: .touchUpInside)
                view.addSubview(aboutButton)

                // Configurazione del pulsante Preferenze
                preferencesButton.frame = CGRect(x: 10, y: 142, width: 32, height: 32)
                preferencesButton.setImage(UIImage(named: "prefs"), for: .normal)
                preferencesButton.setImage(UIImage(named: "prefs_high"), for: .highlighted)
                preferencesButton.addTarget(self, action: #selector(openPreferencesTableViewController), for: .touchUpInside)
                view.addSubview(preferencesButton)

                // Configurazione del pulsante Condividi
                shareButton.frame = CGRect(x: 10, y: 184, width: 32, height: 32)
                shareButton.setImage(UIImage(named: "share"), for: .normal)
                shareButton.setImage(UIImage(named: "share_high"), for: .highlighted)
                shareButton.addTarget(self, action: #selector(openShare), for: .touchUpInside)
                view.addSubview(shareButton)

                // Configurazione del pulsante Cartella
                folderButton.frame = CGRect(x: 10, y: 226, width: 32, height: 32)
                folderButton.setImage(UIImage(named: "folder"), for: .normal)
                folderButton.setImage(UIImage(named: "folderHigh"), for: .highlighted)
                folderButton.addTarget(self, action: #selector(openFolderViewController), for: .touchUpInside)
                view.addSubview(folderButton)

        // Aggiunta delle immagini e delle etichette per la precisione del segnale
        signalImageView.image = signalImage0
        signalImageView.frame = CGRect(x: self.view.frame.width/2 - 25.0, y: 14 + 5 + iPhoneXdiff, width: 50, height: 30)
        map.addSubview(signalImageView)
        signalAccuracyLabel.frame = CGRect(x: self.view.frame.width/2 - 25.0, y: 14 + 5 + 30 + iPhoneXdiff, width: 50, height: 12)
        signalAccuracyLabel.font = font12
        signalAccuracyLabel.text = kUnknownAccuracyText
        signalAccuracyLabel.textAlignment = .center
        map.addSubview(signalAccuracyLabel)


        //
        // Barra dei Pulsanti
        //
        // Layout dei pulsanti: [ Piccolo ] [ Piccolo ] [ Grande (tracker) ] [ Piccolo ] [ Piccolo ]

        // Pulsante Inizio/Pausa (Tracker)
        trackerButton.layer.cornerRadius = kButtonLargeSize/2 // Arrotonda i bordi
        trackerButton.setTitle(NSLocalizedString("START_TRACKING", comment: "nessun commento"), for: UIControl.State()) // Imposta il testo
        trackerButton.backgroundColor = kGreenButtonBackgroundColor // Imposta il colore di sfondo
        trackerButton.addTarget(self, action: #selector(ViewController.trackerButtonTapped), for: .touchUpInside) // Imposta l'azione al tap
        trackerButton.isHidden = false // Il pulsante è visibile
        trackerButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: 16) // Imposta il font del titolo
        trackerButton.titleLabel?.numberOfLines = 2 // Il titolo può occupare due linee
        trackerButton.titleLabel?.textAlignment = .center // Allineamento del testo al centro
        map.addSubview(trackerButton) // Aggiunge il pulsante alla mappa

        // Pulsante Aggiungi Pin (a sinistra del pulsante tracker)
        newPinButton.layer.cornerRadius = kButtonSmallSize/2
        newPinButton.backgroundColor = kWhiteBackgroundColor
        newPinButton.setImage(UIImage(named: "addPin"), for: UIControl.State())
        newPinButton.setImage(UIImage(named: "addPinHigh"), for: .highlighted)
        newPinButton.addTarget(self, action: #selector(ViewController.addPinAtMyLocation), for: .touchUpInside)
        map.addSubview(newPinButton)

        // Pulsante Segui Utente
        followUserButton.layer.cornerRadius = kButtonSmallSize/2
        followUserButton.backgroundColor = kWhiteBackgroundColor
        followUserButton.setImage(UIImage(named: "follow_user_high"), for: UIControl.State())
        followUserButton.setImage(UIImage(named: "follow_user_high"), for: .highlighted)
        followUserButton.addTarget(self, action: #selector(ViewController.followButtonTroggler), for: .touchUpInside)
        map.addSubview(followUserButton)

        // Pulsante Salva
        saveButton.layer.cornerRadius = kButtonSmallSize/2
        saveButton.setTitle(NSLocalizedString("SAVE", comment: "nessun commento"), for: UIControl.State())
        saveButton.backgroundColor = kDisabledBlueButtonBackgroundColor
        saveButton.addTarget(self, action: #selector(ViewController.saveButtonTapped), for: .touchUpInside)
        saveButton.isHidden = false
        saveButton.titleLabel?.textAlignment = .center
        saveButton.titleLabel?.adjustsFontSizeToFitWidth = true
        map.addSubview(saveButton)

        // Pulsante Reset
        resetButton.layer.cornerRadius = kButtonSmallSize/2
        resetButton.setTitle(NSLocalizedString("RESET", comment: "nessun commento"), for: UIControl.State())
        resetButton.backgroundColor = kDisabledRedButtonBackgroundColor
        resetButton.addTarget(self, action: #selector(ViewController.resetButtonTapped), for: .touchUpInside)
        resetButton.isHidden = false
        resetButton.titleLabel?.textAlignment = .center
        resetButton.titleLabel?.adjustsFontSizeToFitWidth = true
        map.addSubview(resetButton)

        // Aggiunta di vincoli (constraints) specifici per iPhone X, se necessario
        addConstraints(isIPhoneX)

        // Delegato per la gestione della rotazione della mappa
        map.rotationGesture.delegate = self

        // Aggiornamento dell'aspetto in base alle preferenze o allo stato corrente
        updateAppearance()

        
        if #available(iOS 13, *) {
            shareActivityColor = .mainUIColor
        }
        
        if #available(iOS 11, *) {
            let compassButton = MKCompassButton(mapView: map)
            self.view.addSubview(compassButton)
            compassButton.translatesAutoresizingMaskIntoConstraints = false
            addConstraintsToCompassView(compassButton)
        }
        
        self.textColorAdaptations()
    }
    
    /// Tells the delegate that the ad failed to present full screen content.
      func ad(_ ad: GADFullScreenPresentingAd, didFailToPresentFullScreenContentWithError error: Error) {
        print("Ad did fail to present full screen content.")
      }

      /// Tells the delegate that the ad will present full screen content.
      func adWillPresentFullScreenContent(_ ad: GADFullScreenPresentingAd) {
        print("Ad will present full screen content.")
      }

      /// Tells the delegate that the ad dismissed full screen content.
      func adDidDismissFullScreenContent(_ ad: GADFullScreenPresentingAd) {
        print("Ad did dismiss full screen content.")
      }
    
    // MARK: - Aggiungi Vincoli (Constraints) per le viste
    /// Aggiunge vincoli (Constraints) alle sotto-viste
    ///
    /// I vincoli assicurano che le sotto-viste siano posizionate correttamente, in caso di cambiamenti dell'orientamento dello schermo o variazioni della larghezza della visualizzazione split su iPad.
    ///
    /// - Parametri:
    ///     - isIPhoneX: se il dispositivo è >= iPhone X, lo spazio inferiore sarà zero
    func addConstraints(_ isIPhoneX: Bool) {
        // Aggiunge vincoli alla barra del titolo dell'app
        addConstraintsToAppTitleBar()
        // Aggiunge vincoli agli elementi interattivi nella parte superiore
        addConstraintsToTopInteractableElements()
        // Aggiunge vincoli alla barra dei pulsanti, considerando se è iPhone X o superiore
        addConstraintsToButtonBar(isIPhoneX)
    }

    
    /// Aggiunge vincoli (constraints) alle subview che formano la barra del titolo dell'app (barra superiore)
    func addConstraintsToAppTitleBar() {
        // MARK: Barra del Titolo dell'App
        
        // Disattiva la traduzione automatica delle dimensioni in vincoli per appTitleLabel e coordsLabel
        appTitleLabel.translatesAutoresizingMaskIntoConstraints = false
        coordsLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // Riferimenti per l'area sicura e gli insetti (margini) dell'area sicura della vista
        let safeAreaGuide = self.view.safeAreaLayoutGuide
        let safeAreaInsets = self.view.safeAreaInsets
        
        // Aggiunge un vincolo per posizionare l'estremità destra dell'etichetta delle coordinate (coordsLabel) vicino al bordo destro della vista, con un margine di -5
        NSLayoutConstraint(item: coordsLabel, attribute: .trailing, relatedBy: .equal, toItem: self.view, attribute: .trailing, multiplier: 1, constant: -5).isActive = true

        // Aggiunge un vincolo per posizionare la parte superiore dell'etichetta del titolo dell'app (appTitleLabel) all'inizio dell'area sicura superiore, tenendo conto degli insetti dell'area sicura
        NSLayoutConstraint(item: appTitleLabel, attribute: .top, relatedBy: .equal, toItem: safeAreaGuide, attribute: .top, multiplier: 1, constant: safeAreaInsets.top).isActive = true
        
        // Allinea la linea di base dell'etichetta del titolo dell'app con quella dell'etichetta delle coordinate
        NSLayoutConstraint(item: appTitleLabel, attribute: .lastBaseline, relatedBy: .equal, toItem: coordsLabel, attribute: .lastBaseline, multiplier: 1, constant: 0).isActive = true
        
        // Imposta la distanza tra l'estremità destra dell'etichetta del titolo dell'app e quella delle coordinate a 5 punti
        NSLayoutConstraint(item: appTitleLabel, attribute: .trailing, relatedBy: .equal, toItem: coordsLabel, attribute: .trailing, multiplier: 1, constant: 5).isActive = true
        
        // Allinea il bordo sinistro dell'etichetta del titolo dell'app con quello dell'etichetta delle coordinate
        NSLayoutConstraint(item: appTitleLabel, attribute: .leading, relatedBy: .equal, toItem: coordsLabel, attribute: .leading, multiplier: 1, constant: 0).isActive = true
        
        // Allinea il bordo sinistro dell'etichetta del titolo dell'app con il bordo sinistro della vista
        NSLayoutConstraint(item: appTitleLabel, attribute: .leading, relatedBy: .equal, toItem: self.view, attribute: .leading, multiplier: 1, constant: 0).isActive = true
    }

    
    /// Aggiunge vincoli (constraints) agli elementi interattivi nella parte superiore, per formare le etichette informative (lato destro; ad es. etichette di velocità, tempo trascorso)
    func addConstraintsToTopInteractableElements() {
        // MARK: Etichette informative (sul lato destro)
        
        /// Offset dal centro, per evitare l'ostruzione della vista del segnale
        let kSignalViewOffset: CGFloat = 25
        
        // Disattiva la traduzione automatica delle dimensioni per tutte le etichette
        timeLabel.translatesAutoresizingMaskIntoConstraints = false
        speedLabel.translatesAutoresizingMaskIntoConstraints = false
        totalTrackedDistanceLabel.translatesAutoresizingMaskIntoConstraints = false
        currentSegmentDistanceLabel.translatesAutoresizingMaskIntoConstraints = false
        
        let safeAreaGuide = self.view.safeAreaLayoutGuide
        
        // Configura i vincoli (constraints) per la timeLabel
        NSLayoutConstraint(item: timeLabel, attribute: .trailing, relatedBy: .equal, toItem: self.view, attribute: .trailing, multiplier: 1, constant: -7).isActive = true
        NSLayoutConstraint(item: timeLabel, attribute: .leading, relatedBy: .equal, toItem: self.view, attribute: .centerX, multiplier: 1, constant: kSignalViewOffset).isActive = true
        // Gestisce l'area sicura per iPhone X, iPhoneXdiff non necessario
        NSLayoutConstraint(item: timeLabel, attribute: .top, relatedBy: .equal, toItem: self.appTitleLabel, attribute: .top, multiplier: 1, constant: 20).isActive = true
        
        // Configura i vincoli per la speedLabel
        NSLayoutConstraint(item: speedLabel, attribute: .trailing, relatedBy: .equal, toItem: self.view, attribute: .trailing, multiplier: 1, constant: -7).isActive = true
        NSLayoutConstraint(item: speedLabel, attribute: .leading, relatedBy: .equal, toItem: self.view, attribute: .centerX, multiplier: 1, constant: kSignalViewOffset).isActive = true
        NSLayoutConstraint(item: speedLabel, attribute: .top, relatedBy: .equal, toItem: timeLabel, attribute: .bottom, multiplier: 1, constant: -5).isActive = true
        
        // Configura i vincoli per la totalTrackedDistanceLabel
        NSLayoutConstraint(item: totalTrackedDistanceLabel, attribute: .trailing, relatedBy: .equal, toItem: self.view, attribute: .trailing, multiplier: 1, constant: -7).isActive = true
        NSLayoutConstraint(item: totalTrackedDistanceLabel, attribute: .leading, relatedBy: .equal, toItem: self.view, attribute: .centerX, multiplier: 1, constant: kSignalViewOffset).isActive = true
        NSLayoutConstraint(item: totalTrackedDistanceLabel, attribute: .top, relatedBy: .equal, toItem: speedLabel, attribute: .bottom, multiplier: 1, constant: 5).isActive = true
        
        // Configura i vincoli per la currentSegmentDistanceLabel
        NSLayoutConstraint(item: currentSegmentDistanceLabel, attribute: .trailing, relatedBy: .equal, toItem: self.view, attribute: .trailing, multiplier: 1, constant: -7).isActive = true
        NSLayoutConstraint(item: currentSegmentDistanceLabel, attribute: .leading, relatedBy: .equal, toItem: self.view, attribute: .centerX, multiplier: 1, constant: kSignalViewOffset).isActive = true
        NSLayoutConstraint(item: currentSegmentDistanceLabel, attribute: .top, relatedBy: .equal, toItem: totalTrackedDistanceLabel, attribute: .bottom, multiplier: 1, constant: 0).isActive = true
        
        // MARK: Grafico e etichetta del segnale (al centro)
        
        // Configura i vincoli per la signalImageView
        signalImageView.translatesAutoresizingMaskIntoConstraints = false
        signalAccuracyLabel.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint(item: signalImageView, attribute: .centerX, relatedBy: .equal, toItem: safeAreaGuide, attribute: .centerX, multiplier: 1, constant: 0).isActive = true
        NSLayoutConstraint(item: signalImageView, attribute: .top, relatedBy: .equal, toItem: self.appTitleLabel, attribute: .bottom, multiplier: 1, constant: 5).isActive = true
        NSLayoutConstraint(item: signalImageView, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .width, multiplier: 1, constant: 50).isActive = true
        NSLayoutConstraint(item: signalImageView, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .height, multiplier: 1, constant: 30).isActive = true
        NSLayoutConstraint(item: signalAccuracyLabel, attribute: .centerX, relatedBy: .equal, toItem: safeAreaGuide, attribute: .centerX, multiplier: 1, constant: 0).isActive = true
        NSLayoutConstraint(item: signalAccuracyLabel, attribute: .top, relatedBy: .equal, toItem: signalImageView, attribute: .bottom, multiplier: 1, constant: 2).isActive = true
        
        // MARK: Pulsanti (sulla sinistra)
        
        // Configura i vincoli per i pulsanti sulla sinistra
        folderButton.translatesAutoresizingMaskIntoConstraints = false
        preferencesButton.translatesAutoresizingMaskIntoConstraints = false
        shareButton.translatesAutoresizingMaskIntoConstraints = false
        aboutButton.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint(item: folderButton, attribute: .leading, relatedBy: .equal, toItem: self.view, attribute: .leading, multiplier: 1, constant: 5).isActive = true
        NSLayoutConstraint(item: folderButton, attribute: .top, relatedBy: .equal, toItem: appTitleLabel, attribute: .bottom, multiplier: 1, constant: 5).isActive = true
        NSLayoutConstraint(item: folderButton, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .width, multiplier: 1, constant: kButtonSmallSize).isActive = true
        NSLayoutConstraint(item: folderButton, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .height, multiplier: 1, constant: kButtonSmallSize).isActive = true
        
        NSLayoutConstraint(item: preferencesButton, attribute: .centerY, relatedBy: .equal, toItem: folderButton, attribute: .centerY, multiplier: 1, constant: 0).isActive = true
        NSLayoutConstraint(item: preferencesButton, attribute: .leading, relatedBy: .equal, toItem: folderButton, attribute: .trailing, multiplier: 1, constant: 10).isActive = true
        NSLayoutConstraint(item: preferencesButton, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .width, multiplier: 1, constant: 32).isActive = true
        NSLayoutConstraint(item: preferencesButton, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .height, multiplier: 1, constant: 32).isActive = true
        
        NSLayoutConstraint(item: shareButton, attribute: .centerY, relatedBy: .equal, toItem: folderButton, attribute: .centerY, multiplier: 1, constant: 0).isActive = true
        NSLayoutConstraint(item: shareButton, attribute: .leading, relatedBy: .equal, toItem: preferencesButton, attribute: .trailing, multiplier: 1, constant: 10).isActive = true
        NSLayoutConstraint(item: shareButton, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .width, multiplier: 1, constant: 32).isActive = true
        NSLayoutConstraint(item: shareButton, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .height, multiplier: 1, constant: 32).isActive = true
        
        NSLayoutConstraint(item: aboutButton, attribute: .top, relatedBy: .equal, toItem: folderButton, attribute: .bottom, multiplier: 1, constant: 5).isActive = true
        NSLayoutConstraint(item: aboutButton, attribute: .centerX, relatedBy: .equal, toItem: folderButton, attribute: .centerX, multiplier: 1, constant: 0).isActive = true
        NSLayoutConstraint(item: aboutButton, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .width, multiplier: 1, constant: 32).isActive = true
        NSLayoutConstraint(item: aboutButton, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .height, multiplier: 1, constant: 32).isActive = true
    }

    /// Aggiunge vincoli alle sotto-viste che formano la barra dei pulsanti (barra dei controlli di sessione in basso)
    func addConstraintsToButtonBar(_ isIPhoneX: Bool) {
        // MARK: Barra dei Pulsanti
        
        // costanti
        let kBottomGap: CGFloat = isIPhoneX ? 0 : 15  // Distanza dal basso, 0 per iPhone X altrimenti 15
        let kBottomDistance: CGFloat = kBottomGap + 24
        
        // Disattiva la traduzione automatica delle dimensioni per tutti i pulsanti
        trackerButton.translatesAutoresizingMaskIntoConstraints = false
        newPinButton.translatesAutoresizingMaskIntoConstraints = false
        followUserButton.translatesAutoresizingMaskIntoConstraints = false
        saveButton.translatesAutoresizingMaskIntoConstraints = false
        resetButton.translatesAutoresizingMaskIntoConstraints = false
        
        let safeAreaGuide = self.view.safeAreaLayoutGuide
        
        // posiziona trackerButton al centro orizzontale della vista
        NSLayoutConstraint(item: trackerButton, attribute: .centerX, relatedBy: .equal, toItem: map, attribute: .centerX, multiplier: 1, constant: 0).isActive = true
        
        // distanza di separazione tra ciascun pulsante
        NSLayoutConstraint(item: trackerButton, attribute: .leading, relatedBy: .equal, toItem: newPinButton, attribute: .trailing, multiplier: 1, constant: kButtonSeparation).isActive = true
        NSLayoutConstraint(item: newPinButton, attribute: .leading, relatedBy: .equal, toItem: followUserButton, attribute: .trailing, multiplier: 1, constant: kButtonSeparation).isActive = true
        NSLayoutConstraint(item: saveButton, attribute: .leading, relatedBy: .equal, toItem: trackerButton, attribute: .trailing, multiplier: 1, constant: kButtonSeparation).isActive = true
        NSLayoutConstraint(item: resetButton, attribute: .leading, relatedBy: .equal, toItem: saveButton, attribute: .trailing, multiplier: 1, constant: kButtonSeparation).isActive = true

        // distanza di separazione tra i pulsanti e il fondo della vista
        NSLayoutConstraint(item: safeAreaGuide, attribute: .bottom, relatedBy: .equal, toItem: followUserButton, attribute: .bottom, multiplier: 1, constant: kBottomDistance).isActive = true
        NSLayoutConstraint(item: safeAreaGuide, attribute: .bottom, relatedBy: .equal, toItem: newPinButton, attribute: .bottom, multiplier: 1, constant: kBottomDistance).isActive = true
        NSLayoutConstraint(item: safeAreaGuide, attribute: .bottom, relatedBy: .equal, toItem: trackerButton, attribute: .bottom, multiplier: 1, constant: kBottomGap).isActive = true
        NSLayoutConstraint(item: safeAreaGuide, attribute: .bottom, relatedBy: .equal, toItem: saveButton, attribute: .bottom, multiplier: 1, constant: kBottomDistance).isActive = true
        NSLayoutConstraint(item: safeAreaGuide, attribute: .bottom, relatedBy: .equal, toItem: resetButton, attribute: .bottom, multiplier: 1, constant: kBottomDistance).isActive = true
        
        // dimensioni fisse per tutti i pulsanti
        NSLayoutConstraint(item: followUserButton, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: kButtonSmallSize).isActive = true
        NSLayoutConstraint(item: followUserButton, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: kButtonSmallSize).isActive = true
        NSLayoutConstraint(item: newPinButton, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: kButtonSmallSize).isActive = true
        NSLayoutConstraint(item: newPinButton, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: kButtonSmallSize).isActive = true
        NSLayoutConstraint(item: trackerButton, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: kButtonLargeSize).isActive = true
        NSLayoutConstraint(item: trackerButton, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: kButtonLargeSize).isActive = true
        NSLayoutConstraint(item: saveButton, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: kButtonSmallSize).isActive = true
        NSLayoutConstraint(item: saveButton, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: kButtonSmallSize).isActive = true
        NSLayoutConstraint(item: resetButton, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: kButtonSmallSize).isActive = true
        NSLayoutConstraint(item: resetButton, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: kButtonSmallSize).isActive = true
    }

    
    @available(iOS 11, *)
    func addConstraintsToCompassView(_ view: MKCompassButton) {
        NSLayoutConstraint(item: view, attribute: .top, relatedBy: .equal, toItem: self.signalAccuracyLabel, attribute: .bottom, multiplier: 1, constant: 8).isActive = true
        
        NSLayoutConstraint(item: view, attribute: .centerX, relatedBy: .equal, toItem: self.view, attribute: .centerX, multiplier: 1, constant: 0).isActive = true
    }
    
    /// For handling compass location changes when orientation is switched.
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        
        DispatchQueue.main.async {
            // set the new position of the compass.
            self.map.compassRect = CGRect(x: size.width/2 - 18, y: 70.0, width: 36, height: 36)
            // update compass frame location
            self.map.layoutSubviews()
        }
        
    }
    
    /// Will update polyline color when invoked
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        updatePolylineColor()
    }
    
    /// Updates polyline color
    func updatePolylineColor() {
        
        for overlay in map.overlays where overlay is MKPolyline {
            map.removeOverlay(overlay)
            map.addOverlayOnTop(overlay)
        }
    }
    
    ///
    /// Richiede al sistema di notificare l'app per alcuni eventi
    ///
    /// L'implementazione attuale richiede al sistema di notificare l'app:
    ///
    ///  1. ogni volta che entra in background
    ///  2. ogni volta che diventa attiva
    ///  3. poco prima della sua terminazione
    ///  4. ogni volta che riceve un file dall'Apple Watch
    ///  5. quando deve caricare un file dal meccanismo di recupero di Core Data
    ///
    func addNotificationObservers() {
        let notificationCenter = NotificationCenter.default
        
        // Registra per ricevere notifiche quando l'app entra in background
        notificationCenter.addObserver(self, selector: #selector(ViewController.didEnterBackground),
            name: UIApplication.didEnterBackgroundNotification, object: nil)
        
        // Registra per ricevere notifiche quando l'app diventa attiva
        notificationCenter.addObserver(self, selector: #selector(applicationDidBecomeActive), name: UIApplication.didBecomeActiveNotification, object: nil)

        // Registra per ricevere notifiche quando l'app sta per terminare
        notificationCenter.addObserver(self, selector: #selector(applicationWillTerminate), name: UIApplication.willTerminateNotification, object: nil)

        // Registra per ricevere file dall'Apple Watch
        notificationCenter.addObserver(self, selector: #selector(presentReceivedFile(_:)), name: .didReceiveFileFromAppleWatch, object: nil)

        // Registra per caricare file dal meccanismo di recupero di Core Data
        notificationCenter.addObserver(self, selector: #selector(loadRecoveredFile(_:)), name: .loadRecoveredFile, object: nil)
        
        // Registra per aggiornare l'aspetto dell'app quando richiesto dalla mapView
        notificationCenter.addObserver(self, selector: #selector(updateAppearance), name: .updateAppearance, object: nil)
    }

    /// Aggiorna l'aspetto dell'app su richiesta della mapView
    @objc func updateAppearance() {
        if #available(iOS 13, *) {
            setNeedsStatusBarAppearanceUpdate()
            updatePolylineColor()
        }
    }

    ///
    /// Presenta un alert quando riceve un file dall'Apple Watch
    ///
    @objc func presentReceivedFile(_ notification: Notification) {
        DispatchQueue.main.async {
            guard let fileName = notification.userInfo?["fileName"] as? String? else { return }
            // Alert per notificare all'utente che è stato ricevuto un file
            let alertTitle = NSLocalizedString("WATCH_FILE_RECEIVED_TITLE", comment: "Titolo alert ricezione file da Apple Watch")
            let alertMessage = NSLocalizedString("WATCH_FILE_RECEIVED_MESSAGE", comment: "Messaggio alert ricezione file da Apple Watch")
            let controller = UIAlertController(title: alertTitle, message: String(format: alertMessage, fileName ?? ""), preferredStyle: .alert)
            let action = UIAlertAction(title: NSLocalizedString("DONE", comment: "Fatto"), style: .default) { _ in
                print("ViewController:: Messaggio di file ricevuto presentato dalla Sessione di WatchConnectivity")
            }
            
            controller.addAction(action)
            self.present(controller, animated: true, completion: nil)
        }
    }

    /// Restituisce una stringa con il formato della data corrente dd-MMM-yyyy-HHmm' (20-Giu-2018-1133)
    ///
    func defaultFilename() -> String {
        let defaultDate = DefaultDateFormat()
        let dateStr = defaultDate.getDateFromPrefs()
        print("fileName:" + dateStr)
        return dateStr
    }

    
    @objc func loadRecoveredFile(_ notification: Notification) {
        guard let root = notification.userInfo?["recoveredRoot"] as? GPXRoot else {
            return
        }
        guard let fileName = notification.userInfo?["fileName"] as? String else {
            return
        }

        lastGpxFilename = fileName
        // Adds last file name to core data as well
        self.map.coreDataHelper.add(toCoreData: fileName, willContinueAfterSave: false)
        // Force reset timer just in case reset does not do it
        self.stopWatch.reset()
        // Load data
        self.map.continueFromGPXRoot(root)
        // Stop following user
        self.followUser = false
        // Center map in GPX data
        self.map.regionToGPXExtent()
        self.gpxTrackingStatus = .paused
        
        self.totalTrackedDistanceLabel.distance = self.map.session.totalTrackedDistance
    }
    
    ///
    /// Called when the application Becomes active (background -> foreground) this function verifies if
    /// it has permissions to get the location.
    ///
    @objc func applicationDidBecomeActive() {
        DispatchQueue.global().async {
            print("viewController:: applicationDidBecomeActive wasSentToBackground: \(self.wasSentToBackground) locationServices: \(CLLocationManager.locationServicesEnabled())")
        }

        // If the app was never sent to background do nothing
        if !wasSentToBackground {
            return
        }
        locationManager.startUpdatingLocation()
        locationManager.startUpdatingHeading()
    }
    
    ///
    /// Actions to do in case the app entered in background
    ///
    /// In current implementation if the app is not tracking it requests the OS to stop
    /// sharing the location to save battery.
    ///
    ///
    @objc func didEnterBackground() {
        wasSentToBackground = true // flag the application was sent to background
        print("viewController:: didEnterBackground")
        if gpxTrackingStatus != .tracking {
            locationManager.stopUpdatingLocation()
        }
    }
    
    ///
    /// Actions to do when the app will terminate
    ///
    /// In current implementation it removes all the temporary files that may have been created
    @objc func applicationWillTerminate() {
        print("viewController:: applicationWillTerminate")
        GPXFileManager.removeTemporaryFiles()
        if gpxTrackingStatus == .notStarted {
            map.coreDataHelper.coreDataDeleteAll(of: CDTrackpoint.self)
            map.coreDataHelper.coreDataDeleteAll(of: CDWaypoint.self)
        }
    }
    
    ///
    /// Displays the view controller with the list of GPX Files.
    ///
    @objc func openFolderViewController() {
        print("openFolderViewController")
        let vc = GPXFilesTableViewController(nibName: nil, bundle: nil)
        vc.delegate = self
        let navController = UINavigationController(rootViewController: vc)
        self.present(navController, animated: true) { () -> Void in }
        showInterstitialAd()
    }
    
    ///
    /// Displays the view controller with the About information.
    ///
    @objc func openAboutViewController() {
        let vc = AboutViewController(nibName: nil, bundle: nil)
        let navController = UINavigationController(rootViewController: vc)
        self.present(navController, animated: true) { () -> Void in }
        showInterstitialAd()
    }
    
    ///
    /// Opens Preferences table view controller
    ///
    @objc func openPreferencesTableViewController() {
        print("openPreferencesTableViewController")
        let vc = PreferencesTableViewController(style: .grouped)
        vc.delegate = self
        let navController = UINavigationController(rootViewController: vc)
        self.present(navController, animated: true) { () -> Void in }
        showInterstitialAd()
    }
    
    /// Opens an Activity View Controller to share the file
    @objc func openShare() {
        print("ViewController: Share Button tapped")
        showInterstitialAd()
        // async such that process is done in background
        DispatchQueue.global(qos: .utility).async {
            // UI code
            DispatchQueue.main.sync {
                self.shouldShowShareActivityIndicator(true)
            }
            
            // Create a temporary file
            let filename =  self.lastGpxFilename.isEmpty ? self.defaultFilename() : self.lastGpxFilename
            let gpxString: String = self.map.exportToGPXString()
            let tmpFile = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("\(filename).gpx")
            GPXFileManager.saveToURL(tmpFile, gpxContents: gpxString)
            // Add it to the list of tmpFiles.
            // Note: it may add more than once the same file to the list.
            
            // UI code
            DispatchQueue.main.sync {
                // Call Share activity View controller
                let activityViewController = UIActivityViewController(activityItems: [tmpFile], applicationActivities: nil)
                activityViewController.popoverPresentationController?.sourceView = self.shareButton
                activityViewController.popoverPresentationController?.sourceRect = self.shareButton.bounds
                self.present(activityViewController, animated: true, completion: nil)
                self.shouldShowShareActivityIndicator(false)
            }
            
        }
    }
    
    /// Displays spinning activity indicator for share button when true
    func shouldShowShareActivityIndicator(_ isTrue: Bool) {
        // setup
        shareActivityIndicator.color = shareActivityColor
        shareActivityIndicator.frame = CGRect(x: 0, y: 0, width: 32, height: 32)
        shareActivityIndicator.transform = CGAffineTransform(scaleX: 1.3, y: 1.3)
        
        if isTrue {
            // cross dissolve from button to indicator
            UIView.transition(with: self.shareButton, duration: 0.35, options: [.transitionCrossDissolve], animations: {
                self.shareButton.addSubview(self.shareActivityIndicator)
            }, completion: nil)
            
            shareActivityIndicator.startAnimating()
            shareButton.setImage(nil, for: UIControl.State())
            shareButton.isUserInteractionEnabled = false
        } else {
            // cross dissolve from indicator to button
            UIView.transition(with: self.shareButton, duration: 0.35, options: [.transitionCrossDissolve], animations: {
                self.shareActivityIndicator.removeFromSuperview()
            }, completion: nil)
            
            shareActivityIndicator.stopAnimating()
            shareButton.setImage(UIImage(named: "share"), for: UIControl.State())
            shareButton.isUserInteractionEnabled = true
        }
    }
    
    ///
    /// After invoking this fuction, the map will not be centered on current user position.
    ///
    @objc func stopFollowingUser(_ gesture: UIPanGestureRecognizer) {
        if self.followUser {
            self.followUser = false
        }
    }
    
    ///
    /// UIGestureRecognizerDelegate required for stopFollowingUser
    ///
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer,
                           shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
   
    ///
    /// If user long presses the map for a while a Pin (Waypoint/Annotation) will be dropped at that point.
    ///
    @objc func addPinAtTappedLocation(_ gesture: UILongPressGestureRecognizer) {
        if  gesture.state == UIGestureRecognizer.State.began {
            print("Adding Pin map Long Press Gesture")
            let point: CGPoint = gesture.location(in: self.map)
            map.addWaypointAtViewPoint(point)
            // Allows save and reset
            self.hasWaypoints = true
        }
    }
    
    /// Does nothing in current implementation.
    func pinchGesture(_ gesture: UIPinchGestureRecognizer) {
        print("pinchGesture")
    }
    
    ///
    /// It adds a Pin (Waypoint/Annotation) to current user location.
    ///
    @objc func addPinAtMyLocation() {
        print("Adding Pin at my location")
        let altitude = locationManager.location?.altitude
        let waypoint = GPXWaypoint(coordinate: locationManager.location?.coordinate ?? map.userLocation.coordinate, altitude: altitude)
        map.addWaypoint(waypoint)
        map.coreDataHelper.add(toCoreData: waypoint)
        self.hasWaypoints = true
    }
    
    ///
    /// Triggered when follow Button is taped.
    ///
    /// Trogles between following or not following the user, that is, automatically centering the map
    ///  in current user´s position.
    ///
    @objc func followButtonTroggler() {
        self.followUser = !self.followUser
    }
    
    ///
    /// Triggered when reset button was tapped.
    ///
    /// It sets map to status .notStarted which clears the map.
    ///
    @objc func resetButtonTapped() {
        
        let sheet = UIAlertController(title: nil, message: NSLocalizedString("SELECT_OPTION", comment: "no comment"), preferredStyle: .actionSheet)
          
        let cancelOption = UIAlertAction(title: NSLocalizedString("CANCEL", comment: "no comment"), style: .cancel) { _ in
        }
        
        let saveAndStartOption = UIAlertAction(title: NSLocalizedString("SAVE_START_NEW", comment: "no comment"), style: .default) { _ in
            // Save
            self.saveButtonTapped(withReset: true)
        }
       
        let deleteOption = UIAlertAction(title: NSLocalizedString("RESET", comment: "no comment"), style: .destructive) { _ in
            self.gpxTrackingStatus = .notStarted
        }
        
        sheet.addAction(cancelOption)
        sheet.addAction(saveAndStartOption)
        sheet.addAction(deleteOption)
        
        self.present(sheet, animated: true) {
            print("Loaded actionSheet")
        }
    }

    ///
    /// Main Start/Pause Button was tapped.
    ///
    /// It sets the status to tracking or paused.
    ///
    @objc func trackerButtonTapped() {
        print("startGpxTracking::")
        showInterstitialAd()
        switch gpxTrackingStatus {
        case .notStarted:
            gpxTrackingStatus = .tracking
        case .tracking:
            gpxTrackingStatus = .paused
        case .paused:
            gpxTrackingStatus = .tracking
        }
    }
    
    ///
    /// Triggered when user taps on save Button
    ///
    /// It prompts the user to set a name of the file.
    ///
    @objc func saveButtonTapped(withReset: Bool = false) {
        print("save Button tapped")
        // ignore the save button if there is nothing to save.
        if (gpxTrackingStatus == .notStarted) && !self.hasWaypoints {
            return
        }
        
        // save alert configuration and presentation
        let alertController = UIAlertController(title: NSLocalizedString("SAVE_AS", comment: "no comment"), message: NSLocalizedString("ENTER_SESSION_NAME", comment: "no comment"), preferredStyle: .alert)
        
        alertController.addTextField(configurationHandler: { (textField) in
            textField.clearButtonMode = .always
            textField.text = self.lastGpxFilename.isEmpty ? self.defaultFilename() : self.lastGpxFilename
        })
        
        let saveAction = UIAlertAction(title: NSLocalizedString("SAVE", comment: "no comment"), style: .default) { _ in
            let filename = (alertController.textFields?[0].text!.utf16.count == 0) ? self.defaultFilename() : alertController.textFields?[0].text
            print("Save File \(String(describing: filename))")
            // Export to a file
            let gpxString = self.map.exportToGPXString()
            GPXFileManager.save(filename!, gpxContents: gpxString)
            self.lastGpxFilename = filename!
            self.map.coreDataHelper.coreDataDeleteAll(of: CDRoot.self)
            self.map.coreDataHelper.clearAllExceptWaypoints()
            self.map.coreDataHelper.add(toCoreData: filename!, willContinueAfterSave: true)
            if withReset {
                self.gpxTrackingStatus = .notStarted
            }
        }
        let cancelAction = UIAlertAction(title: NSLocalizedString("CANCEL", comment: "no comment"), style: .cancel) { _ in }
        
        alertController.addAction(saveAction)
        alertController.addAction(cancelAction)
        
        
        present(alertController, animated: true)
        showInterstitialAd()
       }
    
    ///
    /// There was a memory warning. Right now, it does nothing but to log a line.
    ///
    ///
    func showInterstitialAd() {
           if let interstitial = interstitial {
               interstitial.present(fromRootViewController: self)
           } else {
               print("Ad wasn't ready")
           }
       }
    
    override func didReceiveMemoryWarning() {
        print("didReceiveMemoryWarning")
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    ///
    /// Checks the location services status
    /// - Are location services enabled (access to location device wide)? If not => displays an alert
    /// - Are location services allowed to this app? If not => displays an alert
    ///
    /// - Seealso: displayLocationServicesDisabledAlert, displayLocationServicesDeniedAlert
    ///
    func checkLocationServicesStatus() {
        let authorizationStatus = CLLocationManager.authorizationStatus()
        
        // Has the user already made a permission choice?
        guard authorizationStatus != .notDetermined else {
            // We should take no action until the user has made a choice
            // Note that we request location permission as part of the property `locationManager` init
            return
        }
        
        // Does the app have permissions to use the location servies?
        guard [.authorizedAlways, .authorizedWhenInUse ].contains(authorizationStatus) else {
            displayLocationServicesDeniedAlert()
            return
        }
        
        // Are location services enabled?
        guard CLLocationManager.locationServicesEnabled() else {
            displayLocationServicesDisabledAlert()
            return
        }
    }
    ///
    /// Displays an alert that informs the user that location services are disabled.
    ///
    /// When location services are disabled is for all applications, not only this one.
    ///
    func displayLocationServicesDisabledAlert() {
        
        let alertController = UIAlertController(title: NSLocalizedString("LOCATION_SERVICES_DISABLED", comment: "no comment"), message: NSLocalizedString("ENABLE_LOCATION_SERVICES", comment: "no comment"), preferredStyle: .alert)
        let settingsAction = UIAlertAction(title: NSLocalizedString("SETTINGS", comment: "no comment"), style: .default) { _ in
            if let url = URL(string: UIApplication.openSettingsURLString) {
                if #available(iOS 10, *) {
                    UIApplication.shared.open(url)
                } else {
                    UIApplication.shared.openURL(url)
                }
            }
        }
        let cancelAction = UIAlertAction(title: NSLocalizedString("CANCEL", comment: "no comment"), style: .cancel) { _ in }
        
        alertController.addAction(settingsAction)
        alertController.addAction(cancelAction)
        
        present(alertController, animated: true)

    }

    ///
    /// Displays an alert that informs the user that access to location was denied for this app (other apps may have access).
    /// It also dispays a button allows the user to go to settings to activate the location.
    ///
    func displayLocationServicesDeniedAlert() {
        if isDisplayingLocationServicesDenied {
            return // display it only once.
        }
        let alertController = UIAlertController(title: NSLocalizedString("ACCESS_TO_LOCATION_DENIED", comment: "no comment"),
                                                message: NSLocalizedString("ALLOW_LOCATION", comment: "no comment"),
                                                preferredStyle: .alert)
        let settingsAction = UIAlertAction(title: NSLocalizedString("SETTINGS", comment: "no comment"),
                                           style: .default) { _ in
            if let url = URL(string: UIApplication.openSettingsURLString) {
                if #available(iOS 10, *) {
                    UIApplication.shared.open(url)
                } else {
                    UIApplication.shared.openURL(url)
                }
            }
        }
        let cancelAction = UIAlertAction(title: NSLocalizedString("CANCEL",
                                                                  comment: "no comment"),
                                         style: .cancel) { _ in }
        
        alertController.addAction(settingsAction)
        alertController.addAction(cancelAction)
        
        present(alertController, animated: true)
        isDisplayingLocationServicesDenied = false
    }
    
    /// force dark mode (i.e. white text, if map content is known to be dark)
    func textColorAdaptations() {
        let needForceDarkMode = self.map.tileServer.needForceDarkMode
        self.signalAccuracyLabel.textColor = needForceDarkMode ? .white : nil
        self.timeLabel.textColor = needForceDarkMode ? .white : nil
        self.speedLabel.textColor = needForceDarkMode ? .white : nil
        self.totalTrackedDistanceLabel.textColor = needForceDarkMode ? .white : nil
        self.currentSegmentDistanceLabel.textColor = needForceDarkMode ? .white : nil
    }

}

// MARK: StopWatchDelegate

///
/// Updates the `timeLabel` with the `stopWatch` elapsedTime.
/// In the main ViewController there is a label that holds the elapsed time, that is, the time that
/// user has been tracking his position.
///
///
extension ViewController: StopWatchDelegate {
    func stopWatch(_ stropWatch: StopWatch, didUpdateElapsedTimeString elapsedTimeString: String) {
        timeLabel.text = elapsedTimeString
    }
}
// MARK: PreferencesTableViewControllerDelegate

extension ViewController: PreferencesTableViewControllerDelegate {
    
    /// Aggiorna il tipo di attività che viene utilizzato dal gestore della posizione (location manager).
    ///
    /// Quando l'utente cambia il tipo di attività nelle preferenze, questa funzione viene invocata per aggiornare il tipo di attività del gestore della posizione.
    ///
    func didUpdateActivityType(_ newActivityType: Int) {
        print("PreferencesTableViewControllerDelegate:: didUpdateActivityType: \(newActivityType)")
        // Imposta il nuovo tipo di attività sul location manager
        self.locationManager.activityType = CLActivityType(rawValue: newActivityType)!
    }
    
    ///
    /// Aggiorna il `tileServer` che la mappa sta utilizzando.
    ///
    /// Se l'utente modifica nelle preferenze il `tileServer` che desidera utilizzare,
    /// la mappa nel `ViewController` principale deve essere aggiornata di conseguenza.
    ///
    /// `PreferencesTableViewController` informa il `ViewController` principale tramite questo delegato.
    ///
    func didUpdateTileServer(_ newGpxTileServer: Int) {
        print("PreferencesTableViewControllerDelegate:: didUpdateTileServer: \(newGpxTileServer)")
        // Aggiorna il tile server della mappa
        let newTileServer = GPXTileServer(rawValue: newGpxTileServer)!
        self.map.tileServer = newTileServer
        // Adatta il colore del testo in base al nuovo tile server
        self.textColorAdaptations()
    }
    
    ///
    /// Se l'utente ha cambiato l'impostazione dell'uso della cache, tramite questo delegato, il `ViewController` principale
    /// informa la mappa di comportarsi di conseguenza.
    ///
    func didUpdateUseCache(_ newUseCache: Bool) {
        print("PreferencesTableViewControllerDelegate:: didUpdateUseCache: \(newUseCache)")
        // Imposta l'uso della cache sulla mappa
        self.map.useCache = newUseCache
    }
    
    /// L'utente ha cambiato l'impostazione per l'uso delle unità imperiali.
    func didUpdateUseImperial(_ newUseImperial: Bool) {
        print("PreferencesTableViewControllerDelegate:: didUpdateUseImperial: \(newUseImperial)")
        // Aggiorna l'uso delle unità imperiali
        useImperial = newUseImperial
        totalTrackedDistanceLabel.useImperial = useImperial
        currentSegmentDistanceLabel.useImperial = useImperial
        // Imposta la velocità e l'accuratezza del segnale come sconosciute, in attesa di un aggiornamento
        speedLabel.text = kUnknownSpeedText
        signalAccuracyLabel.text = kUnknownAccuracyText
    }
}


/// Estende `ViewController` per supportare la funzione `GPXFilesTableViewControllerDelegate`
/// che carica sulla mappa il file selezionato dall'utente.
extension ViewController: GPXFilesTableViewControllerDelegate {
    ///
    /// Carica il file GPX selezionato sulla mappa.
    ///
    /// Reimposta lo stato precedente, qualunque esso sia.
    ///
    func didLoadGPXFileWithName(_ gpxFilename: String, gpxRoot: GPXRoot) {
        // Simula un tap sul pulsante di reset
        self.resetButtonTapped()
        // println("File GPX caricato", gpx.gpx())
        lastGpxFilename = gpxFilename
        // Aggiunge anche l'ultimo nome del file a Core Data
        self.map.coreDataHelper.add(toCoreData: gpxFilename, willContinueAfterSave: false)
        // Forza il reset del timer nel caso il reset non lo faccia
        self.stopWatch.reset()
        // Carica i dati
        self.map.importFromGPXRoot(gpxRoot)
        // Smette di seguire l'utente
        self.followUser = false
        // Centra la mappa sui dati GPX
        self.map.regionToGPXExtent()
        self.gpxTrackingStatus = .paused
        
        // Aggiorna la distanza totale tracciata visualizzata
        self.totalTrackedDistanceLabel.distance = self.map.session.totalTrackedDistance
    }
}


// MARK: CLLocationManagerDelegate

// Estende il ViewController per supportare il protocollo delegato di CLLocationManager
extension ViewController: CLLocationManagerDelegate {

    /// Viene chiamata dal Location Manager per informare di un errore.
    ///
    /// Esegue le seguenti azioni:
    ///  - Imposta coordsLabel con `kNotGettingLocationText`, l'accuratezza del segnale con
    ///    kUnknownAccuracyText e signalImageView con signalImage0.
    ///  - Se il codice di errore è `CLError.denied`, chiama `checkLocationServicesStatus`
    ///
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("didFailWithError \(error)")
        // Aggiorna l'interfaccia utente in caso di errore nella localizzazione
        coordsLabel.text = kNotGettingLocationText
        signalAccuracyLabel.text = kUnknownAccuracyText
        signalImageView.image = signalImage0
        let locationError = error as? CLError
        switch locationError?.code {
        case CLError.locationUnknown:
            print("Errore: Localizzazione sconosciuta")
        case CLError.denied:
            print("Accesso ai servizi di localizzazione negato. Mostra messaggio")
            // Verifica lo stato dei servizi di localizzazione
            checkLocationServicesStatus()
        case CLError.headingFailure:
            print("Errore di direzione")
        default:
            print("Errore generico")
        }
    }

    
    ///
    /// Aggiorna l'accuratezza della posizione e le informazioni sulla mappa quando l'utente si trova in una nuova posizione
    ///
    ///
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        // Aggiorna l'immagine del segnale in base all'accuratezza
        let newLocation = locations.first!
        // Aggiorna l'accuratezza orizzontale
        let hAcc = newLocation.horizontalAccuracy
        signalAccuracyLabel.text = hAcc.toAccuracy(useImperial: useImperial)
        // Assegna l'immagine del segnale in base all'accuratezza orizzontale
        if hAcc < kSignalAccuracy6 {
            self.signalImageView.image = signalImage6
        } else if hAcc < kSignalAccuracy5 {
            self.signalImageView.image = signalImage5
        } else if hAcc < kSignalAccuracy4 {
            self.signalImageView.image = signalImage4
        } else if hAcc < kSignalAccuracy3 {
            self.signalImageView.image = signalImage3
        } else if hAcc < kSignalAccuracy2 {
            self.signalImageView.image = signalImage2
        } else if hAcc < kSignalAccuracy1 {
            self.signalImageView.image = signalImage1
        } else {
            self.signalImageView.image = signalImage0
        }
        
        // Aggiorna coordsLabel con le coordinate e l'altitudine
        let latFormat = String(format: "%.6f", newLocation.coordinate.latitude)
        let lonFormat = String(format: "%.6f", newLocation.coordinate.longitude)
        let altitude = newLocation.altitude.toAltitude(useImperial: useImperial)
        coordsLabel.text = String(format: NSLocalizedString("COORDS_LABEL", comment: "Etichetta delle coordinate"), latFormat, lonFormat, altitude)
        
        // Aggiorna la velocità
        speedLabel.text = (newLocation.speed < 0) ? kUnknownSpeedText : newLocation.speed.toSpeed(useImperial: useImperial)
        
        // Aggiorna il centro della mappa e il tracciato se l'utente è seguito
        if followUser {
            map.setCenter(newLocation.coordinate, animated: true)
        }
        if gpxTrackingStatus == .tracking {
            print("didUpdateLocation: aggiunta punto al segmento del tracciamento (\(newLocation.coordinate.latitude),\(newLocation.coordinate.longitude))")
            // Aggiunge punto al segmento di tracciamento corrente
            map.addPointToCurrentTrackSegmentAtLocation(newLocation)
            // Aggiorna le etichette delle distanze tracciate
            totalTrackedDistanceLabel.distance = map.session.totalTrackedDistance
            currentSegmentDistanceLabel.distance = map.session.currentSegmentDistance
        }
    }


    ///
    /// Quando c'è un cambiamento nella direzione (orientamento del dispositivo), richiede alla mappa
    /// di aggiornare l'indicatore di direzione (una piccola freccia vicino al punto di posizione dell'utente)
    ///
    func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        print("ViewController::didUpdateHeading vero: \(newHeading.trueHeading) magnetico: \(newHeading.magneticHeading)")
        print("mkMapcamera direzione=\(map.camera.heading)")
        // Aggiorna la variabile dell'orientamento con i nuovi dati
        map.heading = newHeading
        // Aggiorna la rotazione della vista dell'orientamento
        map.updateHeading()
            
    }

    ///
    /// Chiamata dal sistema quando `CLLocationManager` viene creato e quando l'utente fa una scelta sui permessi
    ///
    /// Gestiamo questa callback del delegato per controllare se l'utente ha concesso l'accesso alla posizione; in caso contrario, mostriamo un avviso
    ///
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        // Controlla lo stato dei servizi di localizzazione
        checkLocationServicesStatus()
    }

}

extension Notification.Name {
    static let loadRecoveredFile = Notification.Name("loadRecoveredFile")
    static let updateAppearance = Notification.Name("updateAppearance")
    // swiftlint:disable file_length
}

// swiftlint:enable line_length
