import UIKit
import MapKit
import Combine

class MapViewController: UIViewController {
    private let mapView = MKMapView()
    private let datePicker = UIDatePicker()
    private let trackingButton = UIButton(type: .system)
    private let viewModel: MapViewModel
    private var cancellables = Set<AnyCancellable>()
    
    init(viewModel: MapViewModel = MapViewModel()) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupMapView()
        setupDatePicker()
        setupTrackingButton()
        setupBindings()
        requestLocationPermission()
    }
    
    private func setupUI() {
        view.backgroundColor = .systemBackground
        title = "我的足迹"
        
        // 设置地图视图
        mapView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(mapView)
        
        // 设置日期选择器
        datePicker.translatesAutoresizingMaskIntoConstraints = false
        datePicker.datePickerMode = .date
        datePicker.preferredDatePickerStyle = .compact
        datePicker.addTarget(self, action: #selector(dateChanged), for: .valueChanged)
        view.addSubview(datePicker)
        
        // 设置追踪按钮
        trackingButton.translatesAutoresizingMaskIntoConstraints = false
        trackingButton.setTitle("开始追踪", for: .normal)
        trackingButton.addTarget(self, action: #selector(trackingButtonTapped), for: .touchUpInside)
        view.addSubview(trackingButton)
        
        NSLayoutConstraint.activate([
            mapView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            mapView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            mapView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            mapView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            datePicker.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
            datePicker.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            
            trackingButton.topAnchor.constraint(equalTo: datePicker.bottomAnchor, constant: 8),
            trackingButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16)
        ])
    }
    
    private func setupMapView() {
        mapView.delegate = self
        mapView.showsUserLocation = true
        mapView.userTrackingMode = .follow
    }
    
    private func setupDatePicker() {
        datePicker.date = Date()
    }
    
    private func setupTrackingButton() {
        updateTrackingButtonState()
    }
    
    private func setupBindings() {
        // 监听状态变化
        viewModel.$state
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state in
                self?.updateUI(with: state)
            }
            .store(in: &cancellables)
    }
    
    private func updateUI(with state: MapState) {
        // 更新地图标记和路线
        mapView.removeAnnotations(mapView.annotations)
        mapView.removeOverlays(mapView.overlays)
        
        let annotations = state.locations.map { location -> MKPointAnnotation in
            let annotation = MKPointAnnotation()
            annotation.coordinate = location.coordinate
            annotation.title = location.title
            annotation.subtitle = location.subtitle
            return annotation
        }
        mapView.addAnnotations(annotations)
        
        if state.locations.count > 1 {
            let coordinates = state.locations.map { $0.coordinate }
            let polyline = MKPolyline(coordinates: coordinates, count: coordinates.count)
            mapView.addOverlay(polyline)
        }
        
        // 更新地图区域
        if let region = state.region {
            mapView.setRegion(region, animated: true)
        }
        
        // 更新追踪按钮状态
        updateTrackingButtonState()
        
        // 显示错误信息
        if let error = state.error {
            showError(error)
        }
    }
    
    private func updateTrackingButtonState() {
        let title = viewModel.state.isTracking ? "停止追踪" : "开始追踪"
        trackingButton.setTitle(title, for: .normal)
    }
    
    private func showError(_ message: String) {
        let alert = UIAlertController(title: "错误", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "确定", style: .default))
        present(alert, animated: true)
    }
    
    private func requestLocationPermission() {
        LocationManager.shared.requestLocationPermission()
    }
    
    @objc private func dateChanged() {
        viewModel.handleIntent(.dateSelected(datePicker.date))
    }
    
    @objc private func trackingButtonTapped() {
        if viewModel.state.isTracking {
            viewModel.handleIntent(.stopTracking)
        } else {
            viewModel.handleIntent(.startTracking)
        }
    }
}

extension MapViewController: MKMapViewDelegate {
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        if let polyline = overlay as? MKPolyline {
            let renderer = MKPolylineRenderer(polyline: polyline)
            renderer.strokeColor = .systemBlue
            renderer.lineWidth = 3
            return renderer
        }
        return MKOverlayRenderer(overlay: overlay)
    }
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        guard !annotation.isKind(of: MKUserLocation.self) else { return nil }
        
        let identifier = "LocationPin"
        var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier)
        
        if annotationView == nil {
            annotationView = MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: identifier)
            annotationView?.canShowCallout = true
        } else {
            annotationView?.annotation = annotation
        }
        
        return annotationView
    }
} 