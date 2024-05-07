//
//  MapViewController.swift
//  GrainChainCD2
//
//  Created by Daniela Ciciliano on 06/05/24.
//

import UIKit
import GoogleMaps
import SwiftUI
import CoreLocationUI
import CoreData

class MapViewController: UIViewController, CLLocationManagerDelegate, UITableViewDelegate, UITableViewDataSource {
    
    //instancia del mapa
    private var mapView: GMSMapView!
    private var isRecording = false
    private var hasRecorded = false
    //Propiedad para el administrador de ubicaciones
    private let locationManager = CLLocationManager()
    private var locations: [CLLocation] = []
    private let saveButton = UIButton(type: .system)
    private let button = UIButton(type: .system)
    private var routeDetails = [RouteDB]()
    private var starRecordingDate: Date = .now
    private var endRecordingDate: Date = .now
    //TableView
    let tableView = UITableView()
    //CoreData
    let context = PersistenceController.shared.container.viewContext
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupMapView()
        setupRecordingButton()
        setuplocationManager()
        setupListView()
        
        retrieveValues()
        
        tableView.reloadData()
    }
    private func setupMapView() {
        let camera: GMSCameraPosition = GMSCameraPosition.camera(withLatitude: 19.639689, longitude: -99.098656, zoom: 12)
        mapView = GMSMapView(frame: CGRect(x: 0, y: 0, width: view.frame.width, height: view.frame.height / 2), camera: camera)
        view.addSubview(mapView)
        
    }
    
    private func setupListView() {
        tableView.register(RouteTableViewCell.self, forCellReuseIdentifier: "RouteCell")
        tableView.frame = CGRect(x: 0, y: view.frame.height / 2, width: view.frame.width, height: view.frame.height / 2)
        tableView.backgroundColor = .white
        tableView.dataSource = self
        tableView.delegate = self
        view.addSubview(tableView)
        
    }
    
    //BOTON RECORDING
    func setupRecordingButton() {
        button.setTitle("Record Route", for: .normal)
        button.addTarget(self, action: #selector(recordButtonTapped), for: .touchUpInside)
        view.addSubview(button)
        button.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(button)
        
        NSLayoutConstraint.activate([
            button.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            button.bottomAnchor.constraint(equalTo: view.centerYAnchor, constant: -15)
        ])
    }
    
    
    @objc private func recordButtonTapped() {
        isRecording.toggle()
        let buttonTitle = isRecording ? "Stop Recording" : "Start Recording"
        button.setTitle(buttonTitle, for: .normal)
        if isRecording {
            startRecording()
        } else {
            stopRecording()
        }
    }
    
    private func startRecording() {
        starRecordingDate = .now
        let location = locationManager.location
        if let currentLocation = location {
            addMarker(at: currentLocation)
        } else {
        }
    }
    
    private func stopRecording() {
        endRecordingDate = .now
        let location = locationManager.location
        if let currentLocation = location {
            addMarker(at: currentLocation)
            hasRecorded = true
            saveRoute()
        } else {
        }
    }
    //Func para limpar mapa
    func clearPreviousRoute(){
        mapView.clear()
        locations.removeAll()
    }
    
    //Función del marcador
    private func addMarker(at coordinate: CLLocation) {
        var marker = GMSMarker()
        marker.position = coordinate.coordinate
        marker.map = mapView
    }
    
    //Dibuja la linea de la ruta
    private func updatePolyline(at coordinate: CLLocation) {
        let path = GMSMutablePath()
        for coordinate in locations {
            path.add(coordinate.coordinate)
        }
        let polyline = GMSPolyline(path: path)
        polyline.strokeColor = .blue
        polyline.strokeWidth = 5
        polyline.geodesic = true
        polyline.map = mapView
        let mapBounds = GMSCoordinateBounds(path: path)
        let cameraUpdate = GMSCameraUpdate.fit(mapBounds)
        mapView.animate(with: cameraUpdate)
        mapView.animate(toZoom: 17)
    }
    
    //Alerta para guardar la ruta recorrida
    func saveRoute() {
        let alertController = UIAlertController(title: "Save Route", message: "Add a name for the Route", preferredStyle: .alert)
        alertController.addTextField { TextField in
            TextField.placeholder = "Name of the Route"
        }
        let saveAction = UIAlertAction(title: "Save Route", style: .default) { _ in
            if let userRouteName = alertController.textFields?.first?.text, !userRouteName.isEmpty {
                // Despues de la validación, el usuario ingresa el nombre de la ruta
                self.save(routeName: userRouteName)
            } else {
                self.showAlert(message: "Please, add a name for the Route.")
            }
        }
        let cancelAction = UIAlertAction(title: "Cancell", style: .cancel, handler: nil)
        
        alertController.addAction(saveAction)
        alertController.addAction(cancelAction)
        
        present(alertController, animated: true, completion: nil)
    }
    func showAlert(message: String) {
        let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        present(alert, animated: true, completion: nil)
    }
    
    func routeDistance(points: [CLLocation]) -> Double{
        let firstCoordinate = points.first
        guard let secondCoordinate = points.last else { return 0.0 }
        guard let distanceInMeters = firstCoordinate?.distance(from: secondCoordinate) else { return 0.0 } // result is in meters
        
        return distanceInMeters
        
    }
    //Funciones Location
    
    //Configuración para acceder a la ubicación del usuario
    func setuplocationManager() {
        locationManager.delegate = self
        locationManager.requestWhenInUseAuthorization() //permisos de ubicación
        locationManager.startUpdatingLocation() //inicializa la ubi del usuario
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else {
            return }
        if isRecording {
            addLocationToPath(location)
            updatePolyline(at: location)
        }
    }
    private func addLocationToPath(_ coordinate: CLLocation) {
        self.locations.append(coordinate)
        
        let camera = GMSCameraPosition.camera(withLatitude: coordinate.coordinate.latitude, longitude: coordinate.coordinate.longitude, zoom: 17)
        mapView.animate(to: camera)
    }
    
    //TABLEVIEW
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return routeDetails.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "RouteCell", for: indexPath) as! RouteTableViewCell
        let route = routeDetails[indexPath.row]
        cell.routeNameLabel.text = route.routeNameData
        let distanceInKM = route.distanceData / 1000
        cell.distanceLabel.text = "\(String(format: "%.3f", distanceInKM))KM"
        return cell
    }
    
    func save(routeName: String) {
        guard !locations.isEmpty else {return}
        let newRoute = RouteDB(context: context)
        newRoute.routeNameData = routeName
        newRoute.distanceData = routeDistance(points: locations)
        
        do {
            try context.save()
            print("Saved: \(routeName)")
        } catch {
            print("Saving Error")
        }
        routeDetails.append(newRoute)
        clearPreviousRoute()
        showAlert(message: "The route have been saved as \(routeName)")
        tableView.reloadData()
        showAlert(message: "The route have been saved as \(routeName)")
        print(routeDetails)
    }
    
    func retrieveValues() {
        do {
            routeDetails = try context.fetch(RouteDB.fetchRequest())
            tableView.reloadData()
        } catch {
            print("Could not retrieve")
        }
    }
    
}


//Configuración de la celda
class RouteTableViewCell: UITableViewCell {
    var routeNameLabel: UILabel!
    var distanceLabel: UILabel!
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupViews()
    }
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupViews()
    }
    private func setupViews() {
        routeNameLabel = UILabel()
        routeNameLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(routeNameLabel)
        
        distanceLabel = UILabel()
        distanceLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(distanceLabel)
        NSLayoutConstraint.activate([
            routeNameLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            routeNameLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            
            distanceLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            distanceLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor)
        ])
    }
    
}

struct MapViewControllerBridge: UIViewControllerRepresentable {
    typealias UIViewType = MapViewController
    
    func makeUIViewController(context: Context) -> MapViewController {
        
        return MapViewController()
    }
    func updateUIViewController(_ uiViewController: MapViewController, context: Context) {
        
        
        
    }
}


#Preview {
    MapViewControllerBridge()
}


