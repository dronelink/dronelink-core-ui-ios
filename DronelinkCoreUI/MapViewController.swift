//
//  MapView.swift
//  DronelinkCoreUI
//
//  Created by Jim McAndrew on 10/28/19.
//  Copyright © 2019 Dronelink. All rights reserved.
//
import UIKit
import Foundation
import Mapbox
import DronelinkCore
import MaterialComponents.MaterialPalettes

public class MapViewController: UIViewController {
    public static func create(droneSessionManager: DroneSessionManager) -> MapViewController {
        let mapViewController = MapViewController()
        mapViewController.droneSessionManager = droneSessionManager
        return mapViewController
    }
    
    private var droneSessionManager: DroneSessionManager!
    private var session: DroneSession?
    private var missionExecutor: MissionExecutor?
    private let mapView = MGLMapView()
    private let droneHomeAnnotation = MGLPointAnnotation()
    private var droneHomeAnnotationView: MGLAnnotationView?
    private let droneAnnotation = MGLPointAnnotation()
    private var droneAnnotationView: MGLAnnotationView?
    private var userDroneAnnotation: MGLAnnotation?
    private var missionPathBackgroundAnnotation: MGLAnnotation?
    private var missionPathForegroundAnnotation: MGLAnnotation?
    private var missionTakeoffAreaAnnotation: MGLAnnotation?
    private let updateInterval: TimeInterval = 0.1
    private var updateTimer: Timer?
    private var lastUpdated = Date()
    private var visibleCoordinatesPending = false
    
    public override func viewDidLoad() {
        mapView.delegate = self
        mapView.addShadow()
        mapView.styleURL = MGLStyle.satelliteStreetsStyleURL
        mapView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        mapView.showsUserLocation = true
        mapView.showsScale = false
        mapView.showsHeading = false
        mapView.clipsToBounds = true
        mapView.attributionButton.tintColor = UIColor.white
        if let location = Dronelink.shared.locationManager.location {
            mapView.setCenter(location.coordinate, zoomLevel: 15, animated: false)
        }
        mapView.addAnnotation(droneHomeAnnotation)
        mapView.addAnnotation(droneAnnotation)
        view.addSubview(mapView)
        mapView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        update()
    }
    
    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        updateTimer = Timer.scheduledTimer(timeInterval: updateInterval, target: self, selector: #selector(update), userInfo: nil, repeats: true)
        Dronelink.shared.add(delegate: self)
        droneSessionManager.add(delegate: self)
    }
    
    public override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        updateTimer?.invalidate()
        updateTimer = nil
        Dronelink.shared.remove(delegate: self)
        droneSessionManager.remove(delegate: self)
        missionExecutor?.remove(delegate: self)
    }
    
    @objc func update() {
        if let state = session?.state?.value, let droneHomeLocation = state.homeLocation {
            droneHomeAnnotation.coordinate = droneHomeLocation.coordinate
            droneHomeAnnotationView?.isHidden = false
        }
        else {
            droneHomeAnnotationView?.isHidden = true
        }
        
        if let state = session?.state?.value, let droneLocation = state.location {
            droneAnnotation.coordinate = droneLocation.coordinate
            if let droneAnnotationView = droneAnnotationView {
                droneAnnotationView.transform = CGAffineTransform(rotationAngle: CGFloat((state.missionOrientation.yaw.convertRadiansToDegrees - mapView.camera.heading).convertDegreesToRadians))
            }
            droneAnnotationView?.isHidden = false
        }
        else {
            droneAnnotationView?.isHidden = true
        }
    }
    
    private func updateMissionEstimate() {
        if let mapMissionRequiredTakeoffAreaAnnotation = missionTakeoffAreaAnnotation {
            mapView.removeAnnotation(mapMissionRequiredTakeoffAreaAnnotation)
        }
        
        if let missionPathBackgroundAnnotation = missionPathBackgroundAnnotation {
            mapView.removeAnnotation(missionPathBackgroundAnnotation)
        }
        
        if let missionPathForegroundAnnotation = missionPathForegroundAnnotation {
            mapView.removeAnnotation(missionPathForegroundAnnotation)
        }
        
        if let requiredTakeoffArea = missionExecutor?.requiredTakeoffArea {
            let segments = 100
            let coordinates = (0...segments).map { index -> CLLocationCoordinate2D in
                let percent = Double(index) / Double(segments)
                return requiredTakeoffArea.coordinate.coordinate.coordinate(bearing: percent * Double.pi * 2, distance: requiredTakeoffArea.distanceTolerance.horizontal)
            }
            missionTakeoffAreaAnnotation = MGLPolygon(coordinates: coordinates, count: UInt(coordinates.count))
            mapView.addAnnotation(missionTakeoffAreaAnnotation!)
        }
        
        if let segments = missionExecutor?.estimateSegmentCoordinates() {
            let pathCoordinates = segments.flatMap { $0.map({ $0.coordinate }) }
            if (pathCoordinates.count > 0) {
                missionPathBackgroundAnnotation = MGLPolyline(coordinates: pathCoordinates, count: UInt(pathCoordinates.count))
                mapView.addAnnotation(missionPathBackgroundAnnotation!)
                
                missionPathForegroundAnnotation = MGLPolyline(coordinates: pathCoordinates, count: UInt(pathCoordinates.count))
                mapView.addAnnotation(missionPathForegroundAnnotation!)
                
                if (visibleCoordinatesPending) {
                    let visibleCoordinates = segments.flatMap { $0.map({ $0.coordinate }) }
//                    if let state = session?.state?.value,
//                        let droneLocation = state.location {
//                        visibleCoordinates.append(droneLocation.coordinate)
//                        if let userLocation = Dronelink.shared.locationManager.location {
//                            if (userLocation.distance(from: droneLocation) < 10000) {
//                                visibleCoordinates.append(userLocation.coordinate)
//                            }
//                        }
//                    }
                    
                    mapView.setVisibleCoordinates(
                        visibleCoordinates,
                        count: UInt(visibleCoordinates.count),
                        edgePadding: UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10), animated: false)
                    visibleCoordinatesPending = false
                }
            }
        }
    }
}

extension MapViewController: DronelinkDelegate {
    public func onRegistered(error: String?) {}
    
    public func onMissionLoaded(executor: MissionExecutor) {
        DispatchQueue.main.async {
            self.missionExecutor = executor
            self.visibleCoordinatesPending = true
            executor.add(delegate: self)
            self.updateMissionEstimate()
        }
    }
    
    public func onMissionUnloaded(executor: MissionExecutor) {
        DispatchQueue.main.async {
            self.missionExecutor = nil
            executor.remove(delegate: self)
            self.updateMissionEstimate()
        }
    }
    
    public func onFuncLoaded(executor: FuncExecutor) {
    }
    
    public func onFuncUnloaded(executor: FuncExecutor) {
    }
}

extension MapViewController: DroneSessionManagerDelegate {
    public func onOpened(session: DroneSession) {
        self.session = session
    }
    
    public func onClosed(session: DroneSession) {
        self.session = nil
    }
}

extension MapViewController: MissionExecutorDelegate {
    public func onMissionEstimated(executor: MissionExecutor, duration: TimeInterval) {
        DispatchQueue.main.async {
            self.updateMissionEstimate()
        }
    }
    
    public func onMissionEngaged(executor: MissionExecutor, engagement: MissionExecutor.Engagement) {}
    
    public func onMissionExecuted(executor: MissionExecutor, engagement: MissionExecutor.Engagement) {}
    
    public func onMissionDisengaged(executor: MissionExecutor, engagement: MissionExecutor.Engagement, reason: Mission.Message) {}
}

extension MapViewController: MGLMapViewDelegate {
    public func mapView(_ mapView: MGLMapView, viewFor annotation: MGLAnnotation) -> MGLAnnotationView? {
        if (annotation === droneHomeAnnotation) {
            var droneHome = mapView.dequeueReusableAnnotationView(withIdentifier: "drone-home")
            if droneHome == nil {
                droneHome = MGLAnnotationView(reuseIdentifier: "drone-home")
                droneHome?.addSubview(UIImageView(image: DronelinkUI.loadImage(named: "home", renderingMode: .alwaysOriginal)))
                droneHome?.frame = CGRect(x: 0, y: 0, width: 30, height: 30)
                droneHomeAnnotationView = droneHome
            }

            return droneHome
        }

        if (annotation === droneAnnotation) {
            var drone = mapView.dequeueReusableAnnotationView(withIdentifier: "drone")
            if drone == nil {
                drone = MGLAnnotationView(reuseIdentifier: "drone")
                drone?.addSubview(UIImageView(image: DronelinkUI.loadImage(named: "drone", renderingMode: .alwaysOriginal)))
                drone?.frame = CGRect(x: 0, y: 0, width: 30, height: 30)
                droneAnnotationView = drone
            }

            return drone
        }

        return nil
    }

    public func mapView(_ mapView: MGLMapView, lineWidthForPolylineAnnotation annotation: MGLPolyline) -> CGFloat {
        if (annotation === missionPathBackgroundAnnotation) {
            return 6
        }

        if (annotation === missionPathForegroundAnnotation) {
            return 2.5
        }

        return 6
    }

    public func mapView(_ mapView: MGLMapView, strokeColorForShapeAnnotation annotation: MGLShape) -> UIColor {
        if (annotation === missionTakeoffAreaAnnotation) {
            return MDCPalette.orange.accent200!
        }

        if (annotation === missionPathBackgroundAnnotation) {
            return MDCPalette.lightBlue.tint800
        }

        if (annotation === missionPathBackgroundAnnotation) {
            return MDCPalette.cyan.accent400!
        }

        return MDCPalette.cyan.accent400!
    }

    public func mapView(_ mapView: MGLMapView, fillColorForPolygonAnnotation annotation: MGLPolygon) -> UIColor {
        if (annotation === missionTakeoffAreaAnnotation) {
            return MDCPalette.orange.accent400!
        }

        return MDCPalette.cyan.accent400!
    }

    public func mapView(_ mapView: MGLMapView, alphaForShapeAnnotation annotation: MGLShape) -> CGFloat {
        if (annotation === missionTakeoffAreaAnnotation) {
            return 0.75
        }

        return 1.0
    }
}
