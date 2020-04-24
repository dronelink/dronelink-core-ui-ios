//
//  MapboxMapViewController.swift
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

public class MapboxMapViewController: UIViewController {
    public static func create(droneSessionManager: DroneSessionManager) -> MapboxMapViewController {
        let mapViewController = MapboxMapViewController()
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
    private var missionRequiredTakeoffAreaAnnotation: MGLAnnotation?
    private var missionEstimateBackgroundAnnotation: MGLAnnotation?
    private var missionEstimateForegroundAnnotation: MGLAnnotation?
    private var missionReengagementEstimateBackgroundAnnotation: MGLAnnotation?
    private var missionReengagementEstimateForegroundAnnotation: MGLAnnotation?
    private let updateInterval: TimeInterval = 0.1
    private var updateTimer: Timer?
    private var lastUpdated = Date()
    private var missionCentered = false
    
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
        droneSessionManager.add(delegate: self)
        Dronelink.shared.add(delegate: self)
    }
    
    public override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        updateTimer?.invalidate()
        updateTimer = nil
        droneSessionManager.remove(delegate: self)
        Dronelink.shared.remove(delegate: self)
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
    
    private func updateMissionRequiredTakeoffArea() {
        if let mapMissionRequiredTakeoffAreaAnnotation = missionRequiredTakeoffAreaAnnotation {
            mapView.removeAnnotation(mapMissionRequiredTakeoffAreaAnnotation)
        }

        if let requiredTakeoffArea = missionExecutor?.requiredTakeoffArea {
            let segments = 100
            let coordinates = (0...segments).map { index -> CLLocationCoordinate2D in
                let percent = Double(index) / Double(segments)
                return requiredTakeoffArea.coordinate.coordinate.coordinate(bearing: percent * Double.pi * 2, distance: requiredTakeoffArea.distanceTolerance.horizontal)
            }
            missionRequiredTakeoffAreaAnnotation = MGLPolygon(coordinates: coordinates, count: UInt(coordinates.count))
            mapView.addAnnotation(missionRequiredTakeoffAreaAnnotation!)
        }
    }
    
    private func updateMissionEstimate() {
        if let missionEstimateBackgroundAnnotation = missionEstimateBackgroundAnnotation {
            mapView.removeAnnotation(missionEstimateBackgroundAnnotation)
        }

        if let missionEstimateForegroundAnnotation = missionEstimateForegroundAnnotation {
            mapView.removeAnnotation(missionEstimateForegroundAnnotation)
        }

        if let missionReengagementEstimateBackgroundAnnotation = missionReengagementEstimateBackgroundAnnotation {
            mapView.removeAnnotation(missionReengagementEstimateBackgroundAnnotation)
        }

        if let missionReengagementEstimateForegroundAnnotation = missionReengagementEstimateForegroundAnnotation {
            mapView.removeAnnotation(missionReengagementEstimateForegroundAnnotation)
        }

        var visibleCoordinates: [CLLocationCoordinate2D] = []
        if let estimateCoordinates = missionExecutor?.estimate?.spatials.map({ $0.coordinate.coordinate }), estimateCoordinates.count > 0 {
            missionEstimateBackgroundAnnotation = MGLPolyline(coordinates: estimateCoordinates, count: UInt(estimateCoordinates.count))
            mapView.addAnnotation(missionEstimateBackgroundAnnotation!)

            missionEstimateForegroundAnnotation = MGLPolyline(coordinates: estimateCoordinates, count: UInt(estimateCoordinates.count))
            mapView.addAnnotation(missionEstimateForegroundAnnotation!)

            if !missionCentered {
                visibleCoordinates.append(contentsOf: estimateCoordinates)
            }

            if let reengagementEstimateCoordinates = missionExecutor?.estimate?.reengagementSpatials?.map({ $0.coordinate.coordinate }), reengagementEstimateCoordinates.count > 0 {
                missionReengagementEstimateBackgroundAnnotation = MGLPolyline(coordinates: reengagementEstimateCoordinates, count: UInt(reengagementEstimateCoordinates.count))
                mapView.addAnnotation(missionReengagementEstimateBackgroundAnnotation!)

                missionReengagementEstimateForegroundAnnotation = MGLPolyline(coordinates: reengagementEstimateCoordinates, count: UInt(reengagementEstimateCoordinates.count))
                mapView.addAnnotation(missionReengagementEstimateForegroundAnnotation!)

                if !missionCentered {
                    visibleCoordinates.append(contentsOf: reengagementEstimateCoordinates)
                }
            }
        }

        if (visibleCoordinates.count > 0) {
            missionCentered = true
            mapView.setVisibleCoordinates(
                visibleCoordinates,
                count: UInt(visibleCoordinates.count),
                edgePadding: UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10), animated: false)
        }
    }
}

extension MapboxMapViewController: DronelinkDelegate {
    public func onRegistered(error: String?) {}
    
    public func onMissionLoaded(executor: MissionExecutor) {
        DispatchQueue.main.async {
            self.missionExecutor = executor
            self.missionCentered = false
            executor.add(delegate: self)
            self.updateMissionRequiredTakeoffArea()
            if executor.estimated {
                self.updateMissionEstimate()
            }
        }
    }
    
    public func onMissionUnloaded(executor: MissionExecutor) {
        DispatchQueue.main.async {
            self.missionExecutor = nil
            self.missionCentered = false
            executor.remove(delegate: self)
            self.updateMissionRequiredTakeoffArea()
            self.updateMissionEstimate()
        }
    }
    
    public func onFuncLoaded(executor: FuncExecutor) {
    }
    
    public func onFuncUnloaded(executor: FuncExecutor) {
    }
}

extension MapboxMapViewController: DroneSessionManagerDelegate {
    public func onOpened(session: DroneSession) {
        self.session = session
    }
    
    public func onClosed(session: DroneSession) {
        self.session = nil
    }
}

extension MapboxMapViewController: MissionExecutorDelegate {
    public func onMissionEstimating(executor: MissionExecutor) {}
    
    public func onMissionEstimated(executor: MissionExecutor, estimate: MissionExecutor.Estimate) {
        DispatchQueue.main.async {
            self.updateMissionEstimate()
        }
    }
    
    public func onMissionEngaging(executor: MissionExecutor) {}
    
    public func onMissionEngaged(executor: MissionExecutor, engagement: MissionExecutor.Engagement) {}
    
    public func onMissionExecuted(executor: MissionExecutor, engagement: MissionExecutor.Engagement) {}
    
    public func onMissionDisengaged(executor: MissionExecutor, engagement: MissionExecutor.Engagement, reason: Mission.Message) {}
}

extension MapboxMapViewController: MGLMapViewDelegate {
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
        if (annotation === missionEstimateBackgroundAnnotation || annotation === missionReengagementEstimateBackgroundAnnotation) {
            return 6
        }

        if (annotation === missionEstimateForegroundAnnotation || annotation === missionReengagementEstimateForegroundAnnotation) {
            return 2.5
        }

        return 6
    }

    public func mapView(_ mapView: MGLMapView, strokeColorForShapeAnnotation annotation: MGLShape) -> UIColor {
        if (annotation === missionRequiredTakeoffAreaAnnotation) {
            return MDCPalette.orange.accent200!
        }

        if (annotation === missionEstimateBackgroundAnnotation) {
            return MDCPalette.lightBlue.tint800
        }

        if (annotation === missionEstimateForegroundAnnotation) {
            return MDCPalette.cyan.accent400!
        }

        if (annotation === missionReengagementEstimateBackgroundAnnotation) {
            return MDCPalette.purple.tint800
        }

        if (annotation === missionReengagementEstimateForegroundAnnotation) {
            return MDCPalette.purple.accent200!
        }

        return MDCPalette.cyan.accent400!
    }

    public func mapView(_ mapView: MGLMapView, fillColorForPolygonAnnotation annotation: MGLPolygon) -> UIColor {
        if (annotation === missionRequiredTakeoffAreaAnnotation) {
            return MDCPalette.orange.accent400!
        }

        return MDCPalette.cyan.accent400!
    }

    public func mapView(_ mapView: MGLMapView, alphaForShapeAnnotation annotation: MGLShape) -> CGFloat {
        if (annotation === missionRequiredTakeoffAreaAnnotation) {
            return 0.75
        }

        return 1.0
    }
}
