import CoreLocation

public class LocationService: NSObject, CLLocationManagerDelegate {
    private let locationManager = CLLocationManager()
    private var onLocationUpdate: ((CLLocationCoordinate2D) -> Void)?

    public override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
    }

    public func requestLocation(completion: @escaping (CLLocationCoordinate2D) -> Void) {
        self.onLocationUpdate = completion

        let status = locationManager.authorizationStatus
        if status == .notDetermined {
            locationManager.requestWhenInUseAuthorization()
        } else if status == .authorizedWhenInUse || status == .authorizedAlways {
            locationManager.requestLocation()
        } else {
            InngageLogger.log("❌ Localização não autorizada")
        }
    }

    public func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.first else { return }
        onLocationUpdate?(location.coordinate)
        onLocationUpdate = nil
    }

    public func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        InngageLogger.log("❌ Falha ao obter localização: \(error.localizedDescription)")
    }
}
