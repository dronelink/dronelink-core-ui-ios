//
//  MapboxMapWidget.swift
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

public class MapboxMapWidget: UpdatableWidget {
    public override var updateInterval: TimeInterval { 0.1 }
    
    private let mapView = MGLMapView()
    private let droneHomeAnnotation = MGLPointAnnotation()
    private var droneHomeAnnotationView: MGLAnnotationView?
    private let droneAnnotation = MGLPointAnnotation()
    private var droneAnnotationView: MGLAnnotationView?
    private var userDroneAnnotation: MGLAnnotation?
    private var missionRequiredTakeoffAreaAnnotation: MGLAnnotation?
    private var missionRestrictionZoneAnnotations: [(annotation: MGLPolygon, color: UIColor?)] = []
    private var missionEstimateBackgroundAnnotation: MGLAnnotation?
    private var missionEstimateForegroundAnnotation: MGLAnnotation?
    private var missionReengagementEstimateBackgroundAnnotation: MGLAnnotation?
    private var missionReengagementEstimateForegroundAnnotation: MGLAnnotation?
    private var funcDroneAnnotations: [MGLPointAnnotation] = []
    private var funcMapOverlayAnnotations: [(annotation: MGLPolygon, color: UIColor?)] = []
    private var modeTargetAnnotation = MGLPointAnnotation()
    private var modeTargetAnnotationView: MGLAnnotationView?
    private var missionCentered = false
    
    public override func viewDidLoad() {
        mapView.delegate = self
        mapView.addShadow()
        mapView.styleURL = MGLStyle.satelliteStreetsStyleURL
        mapView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        mapView.attributionButtonPosition = .bottomRight
        mapView.logoViewPosition = .bottomRight
        mapView.showsUserLocation = true
        mapView.showsScale = false
        mapView.showsHeading = false
        mapView.clipsToBounds = true
        mapView.attributionButton.tintColor = UIColor.white
        if let location = Dronelink.shared.location?.value {
            mapView.setCenter(location.coordinate, zoomLevel: 17, animated: false)
        }
        mapView.addAnnotation(droneHomeAnnotation)
        mapView.addAnnotation(droneAnnotation)
        view.addSubview(mapView)
        mapView.snp.makeConstraints { [weak self] make in
            make.edges.equalToSuperview()
        }
        mapView.addAnnotation(modeTargetAnnotation)
        update()
    }
    
    @objc open override func update() {
        super.update()
        
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
                droneAnnotationView.transform = CGAffineTransform(rotationAngle: CGFloat((state.orientation.yaw.convertRadiansToDegrees - mapView.camera.heading).convertDegreesToRadians))
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
    
    private func updateMissionRestrictionZones() {
        missionRestrictionZoneAnnotations.forEach {
            mapView.removeAnnotation($0.annotation)
        }
        missionRestrictionZoneAnnotations.removeAll()

        if let restrictionZones = missionExecutor?.restrictionZones {
            restrictionZones.enumerated().forEach {
                guard let coordinates = missionExecutor?.restrictionZoneBoundaryCoordinates(index: $0.offset) else {
                    return
                }

                let restrictionZone = $0.element
                let color = UIColor(hex: restrictionZone.zone.color, defaultAlpha: 0.5)
                switch restrictionZone.zone.shape {
                case .circle:
                    let center = coordinates[0].coordinate
                    let radius = center.distance(to: coordinates[1].coordinate)
                    let segments = 100
                    let points = (0...segments).map { index -> CLLocationCoordinate2D in
                        let percent = Double(index) / Double(segments)
                        return center.coordinate(bearing: percent * Double.pi * 2, distance: radius)
                    }
                    let missionRestrictionZoneAnnotation = MGLPolygon(coordinates: points, count: UInt(points.count))
                    missionRestrictionZoneAnnotations.append((annotation: missionRestrictionZoneAnnotation, color: color))
                    mapView.addAnnotation(missionRestrictionZoneAnnotation)
                    break

                case .polygon:
                    let missionRestrictionZoneAnnotation = MGLPolygon(coordinates: coordinates.map { $0.coordinate }, count: UInt(coordinates.count))
                    missionRestrictionZoneAnnotations.append((annotation: missionRestrictionZoneAnnotation, color: color))
                    mapView.addAnnotation(missionRestrictionZoneAnnotation)
                    break
                }
            }
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
    
    private func updateFuncElements() {
        var inputIndex = 0
        var spatials: [Kernel.GeoSpatial] = []
        var mapCenterSpatial: Kernel.GeoSpatial?
        while let input = funcExecutor?.input(index: inputIndex) {
            if input.variable.valueType == .drone {
                if let value = funcExecutor?.readValue(inputIndex: inputIndex) {
                    if let array = value as? [Kernel.GeoSpatial?] {
                        array.forEach { spatial in
                            if let spatial = spatial {
                                spatials.append(spatial)
                                mapCenterSpatial = spatial
                            }
                        }
                    }
                    else if let spatial = value as? Kernel.GeoSpatial {
                        spatials.append(spatial)
                        mapCenterSpatial = spatial
                    }
                }
            }
            else {
                mapCenterSpatial = nil
            }
            inputIndex += 1
        }

        while funcDroneAnnotations.count > spatials.count {
            mapView.removeAnnotation(funcDroneAnnotations.removeLast())
        }

        while funcDroneAnnotations.count < spatials.count {
            let funcDroneAnnotation = MGLPointAnnotation()
            funcDroneAnnotations.append(funcDroneAnnotation)
            mapView.addAnnotation(funcDroneAnnotation)
        }
        
        spatials.enumerated().forEach {
            funcDroneAnnotations[$0.offset].coordinate = $0.element.coordinate.coordinate
        }
        
        if let mapCenterSpatial = mapCenterSpatial {
            mapView.setCenter(mapCenterSpatial.coordinate.coordinate, zoomLevel: 19.25, animated: true)
        }
        
        funcMapOverlayAnnotations.forEach {
            mapView.removeAnnotation($0.annotation)
        }
        funcMapOverlayAnnotations.removeAll()

        if let mapOverlays = funcExecutor?.mapOverlays(droneSession: session, error: { error in
            DispatchQueue.main.async {
               DronelinkUI.shared.showSnackbar(text: error)
           }
        }) {
            mapOverlays.enumerated().forEach {
                let mapOverlay = $0.element
                let color = UIColor(hex: mapOverlay.color, defaultAlpha: 0.5)
                let funcMapOverlayAnnotation = MGLPolygon(coordinates: mapOverlay.coordinates.map { $0.coordinate }, count: UInt($0.element.coordinates.count))
                funcMapOverlayAnnotations.append((annotation: funcMapOverlayAnnotation, color: color))
                mapView.addAnnotation(funcMapOverlayAnnotation)
            }
        }
    }
    
    private func updateModeElements() {
        guard modeExecutor?.engaged ?? false else {
            modeTargetAnnotationView?.isHidden = true
            return
        }
        
        if let modeTarget = modeExecutor?.target {
            modeTargetAnnotation.coordinate = modeTarget.coordinate.coordinate
            if let modeTargetAnnotationView = modeTargetAnnotationView {
                modeTargetAnnotationView.transform = CGAffineTransform(rotationAngle: CGFloat((modeTarget.orientation.yaw.convertRadiansToDegrees - mapView.camera.heading).convertDegreesToRadians))
            }
            modeTargetAnnotationView?.isHidden = false
        }
        else {
            modeTargetAnnotationView?.isHidden = true
        }
        
        if let visibleCoordinates = modeExecutor?.visibleCoordinates, visibleCoordinates.count > 0 {
            let inset: CGFloat = 0.2
            mapView.setVisibleCoordinates(
                visibleCoordinates.map { $0.coordinate },
                count: UInt(visibleCoordinates.count),
                edgePadding: UIEdgeInsets(
                    top: mapView.frame.height * (mapView.frame.height > 300 ? 0.25 : inset),
                    left: mapView.frame.width * inset,
                    bottom: mapView.frame.height * (mapView.frame.height > 300 ? 0.38 : inset),
                    right: mapView.frame.width * inset),
                animated: true)
        }
    }
    
    public override func onLocated(session: DroneSession) {
        super.onLocated(session: session)
        
        if let location = session.state?.value.location {
            DispatchQueue.main.async { [weak self] in
                self?.mapView.setCenter(location.coordinate, zoomLevel: 18.5, animated: true)
            }
        }
    }

    public override func onMissionLoaded(executor: MissionExecutor) {
        super.onMissionLoaded(executor: executor)
        
        DispatchQueue.main.async { [weak self] in
            self?.missionCentered = false
            self?.updateMissionRequiredTakeoffArea()
            self?.updateMissionRestrictionZones()
            if executor.estimated {
                self?.updateMissionEstimate()
            }
        }
    }
    
    public override func onMissionUnloaded(executor: MissionExecutor) {
        super.onMissionUnloaded(executor: executor)
        
        DispatchQueue.main.async { [weak self] in
            self?.missionCentered = false
            self?.updateMissionRequiredTakeoffArea()
            self?.updateMissionRestrictionZones()
            self?.updateMissionEstimate()
        }
    }

    public override func onMissionEstimated(executor: MissionExecutor, estimate: MissionExecutor.Estimate) {
        super.onMissionEstimated(executor: executor, estimate: estimate)
        
        DispatchQueue.main.async { [weak self] in
            self?.updateMissionEstimate()
        }
    }
    
    public override func onFuncLoaded(executor: FuncExecutor) {
        super.onFuncLoaded(executor: executor)
        
        DispatchQueue.main.async { [weak self] in
            self?.updateFuncElements()
        }
    }

    public override func onFuncUnloaded(executor: FuncExecutor) {
        super.onFuncUnloaded(executor: executor)
        
        DispatchQueue.main.async { [weak self] in
            self?.updateFuncElements()
        }
    }
    
    public override func onFuncInputsChanged(executor: FuncExecutor) {
        super.onFuncInputsChanged(executor: executor)
        
        DispatchQueue.main.async { [weak self] in
            self?.updateFuncElements()
        }
    }

    public override func onModeExecuted(executor: ModeExecutor, engagement: Executor.Engagement) {
        super.onModeExecuted(executor: executor, engagement: engagement)
        
        DispatchQueue.main.async { [weak self] in
            self?.updateModeElements()
        }
    }
    
    public override func onModeDisengaged(executor: ModeExecutor, engagement: Executor.Engagement, reason: Kernel.Message) {
        super.onModeDisengaged(executor: executor, engagement: engagement, reason: reason)
        
        DispatchQueue.main.async { [weak self] in
            self?.updateModeElements()
        }
    }
}

extension MapboxMapWidget: MGLMapViewDelegate {
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
        
        if (annotation === modeTargetAnnotation) {
            var modeTarget = mapView.dequeueReusableAnnotationView(withIdentifier: "mode-target")
            if modeTarget == nil {
                modeTarget = MGLAnnotationView(reuseIdentifier: "mode-target")
                modeTarget?.addSubview(UIImageView(image: DronelinkUI.loadImage(named: "drone", renderingMode: .alwaysOriginal)))
                modeTarget?.frame = CGRect(x: 0, y: 0, width: 30, height: 30)
                modeTarget?.alpha = 0.5
                modeTargetAnnotationView = modeTarget
            }

            return modeTarget
        }
        
        for funcDroneAnnotation in funcDroneAnnotations {
            if funcDroneAnnotation === annotation {
                var funcDrone = mapView.dequeueReusableAnnotationView(withIdentifier: "func-drone")
                if funcDrone == nil {
                    funcDrone = MGLAnnotationView(reuseIdentifier: "func-drone")
                    funcDrone?.addSubview(UIImageView(image: DronelinkUI.loadImage(named: "func-input-drone", renderingMode: .alwaysOriginal)))
                    funcDrone?.frame = CGRect(x: 0, y: 0, width: 15, height: 15)
                }
                return funcDrone
            }
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
        
        for missionRestrictionZoneAnnotation in missionRestrictionZoneAnnotations {
            if (annotation === missionRestrictionZoneAnnotation.annotation) {
                return missionRestrictionZoneAnnotation.color ?? MDCPalette.pink.accent400!
            }
        }
        
        for funcMapOverlayAnnotation in funcMapOverlayAnnotations {
            if (annotation === funcMapOverlayAnnotation.annotation) {
                return funcMapOverlayAnnotation.color ?? MDCPalette.pink.accent400!
            }
        }

        return MDCPalette.cyan.accent400!
    }

    public func mapView(_ mapView: MGLMapView, fillColorForPolygonAnnotation annotation: MGLPolygon) -> UIColor {
        if (annotation === missionRequiredTakeoffAreaAnnotation) {
            return MDCPalette.orange.accent400!
        }
        
        for missionRestrictionZoneAnnotation in missionRestrictionZoneAnnotations {
            if (annotation === missionRestrictionZoneAnnotation.annotation) {
                return missionRestrictionZoneAnnotation.color ?? MDCPalette.pink.accent400!
            }
        }
        
        for funcMapOverlayAnnotation in funcMapOverlayAnnotations {
            if (annotation === funcMapOverlayAnnotation.annotation) {
                return funcMapOverlayAnnotation.color ?? MDCPalette.pink.accent400!
            }
        }

        return MDCPalette.cyan.accent400!
    }

    public func mapView(_ mapView: MGLMapView, alphaForShapeAnnotation annotation: MGLShape) -> CGFloat {
        if (annotation === missionRequiredTakeoffAreaAnnotation) {
            return 0.25
        }
        
        for missionRestrictionZoneAnnotation in missionRestrictionZoneAnnotations {
            if (annotation === missionRestrictionZoneAnnotation.annotation) {
                return missionRestrictionZoneAnnotation.color?.rgba.alpha ?? 0.5
            }
        }
        
        for funcMapOverlayAnnotation in funcMapOverlayAnnotations {
            if (annotation === funcMapOverlayAnnotation.annotation) {
                return funcMapOverlayAnnotation.color?.rgba.alpha ?? 0.5
            }
        }

        return 1.0
    }
}
