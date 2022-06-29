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
import CoreLocation

public class MapboxMapWidget: UpdatableWidget {
    public enum Tracking {
        case none
        case droneNorthUp
        case droneHeading
    }
    
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
    private var missionReengagementDroneAnnotation = MGLPointAnnotation()
    private var missionReengagementDroneAnnotationView: MGLAnnotationView?
    private var funcDroneAnnotations: [MGLPointAnnotation] = []
    private var funcMapOverlayAnnotations: [(annotation: MGLPolygon, color: UIColor?)] = []
    private var modeTargetAnnotation = MGLPointAnnotation()
    private var modeTargetAnnotationView: MGLAnnotationView?
    private var missionCentered = false
    private var currentMissionEstimateID: String?
    private var tracking = Tracking.none
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        mapView.delegate = self
        mapView.addShadow()
        mapView.styleURL = MGLStyle.satelliteStreetsStyleURL
        mapView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        mapView.attributionButtonPosition = .bottomRight
        mapView.attributionButton.isHidden = true
        mapView.logoViewPosition = .bottomRight
        mapView.logoView.isHidden = true
        mapView.compassViewPosition = .bottomRight
        mapView.showsUserLocation = true
        mapView.showsScale = false
        mapView.showsHeading = false
        mapView.allowsTilting = false
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
        mapView.addAnnotation(missionReengagementDroneAnnotation)
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
            let offset = Dronelink.shared.droneOffsets.droneCoordinate
            droneAnnotation.coordinate = droneLocation.coordinate.coordinate(bearing: offset.direction + Double.pi, distance: offset.magnitude)
            if let droneAnnotationView = droneAnnotationView {
                droneAnnotationView.transform = CGAffineTransform(rotationAngle: CGFloat((state.orientation.yaw.convertRadiansToDegrees - mapView.camera.heading).convertDegreesToRadians))
            }
            droneAnnotationView?.isHidden = false
        }
        else {
            droneAnnotationView?.isHidden = true
        }
        
        if tracking != .none {
            if let state = session?.state?.value,
               let location = state.location {
                let distance = max(20, state.altitude / 1.8)
                
                set(visibleCoordinates: [
                    location.coordinate.coordinate(bearing: 0, distance: distance),
                    location.coordinate.coordinate(bearing: Double.pi / 2, distance: distance),
                    location.coordinate.coordinate(bearing: Double.pi, distance: distance),
                    location.coordinate.coordinate(bearing: 3 * Double.pi / 2, distance: distance)
                ], direction: tracking == .droneNorthUp ? 0 : state.orientation.yaw.convertRadiansToDegrees)
            }
        }
    }

    private func set(visibleCoordinates: [CLLocationCoordinate2D], direction: CLLocationDirection? = nil) {
        if visibleCoordinates.count == 0 {
            return
        }
        
        let inset: CGFloat = 0.2
        let edgePadding = UIEdgeInsets(
            top: mapView.frame.height * (mapView.frame.height > 300 ? 0.25 : inset),
            left: mapView.frame.width * inset,
            bottom: mapView.frame.height * (mapView.frame.height > 300 ? 0.38 : inset),
            right: mapView.frame.width * inset)
        
        if let direction = direction {
            mapView.setVisibleCoordinates(
                visibleCoordinates,
                count: UInt(visibleCoordinates.count),
                edgePadding: edgePadding,
                direction: direction < 0 ? direction + 360 : direction,
                duration: 0.1,
                animationTimingFunction: nil)
        }
        else {
            mapView.setVisibleCoordinates(
                visibleCoordinates,
                count: UInt(visibleCoordinates.count),
                edgePadding: edgePadding,
                animated: true)
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
                guard let coordinatesRaw = missionExecutor?.restrictionZoneBoundaryCoordinates?[safeIndex: $0.offset], let coordinates = coordinatesRaw else {
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
        if missionExecutor?.estimate?.id == currentMissionEstimateID {
            return
        }
        currentMissionEstimateID = missionExecutor?.estimate?.id
        
        if let missionEstimateBackgroundAnnotation = missionEstimateBackgroundAnnotation {
            mapView.removeAnnotation(missionEstimateBackgroundAnnotation)
        }

        if let missionEstimateForegroundAnnotation = missionEstimateForegroundAnnotation {
            mapView.removeAnnotation(missionEstimateForegroundAnnotation)
        }

        var visibleCoordinates: [CLLocationCoordinate2D] = []
        if let estimateCoordinates = missionExecutor?.estimate?.spatials.map({ $0.coordinate.coordinate }),
           estimateCoordinates.count > 0 {
            missionEstimateBackgroundAnnotation = MGLPolyline(coordinates: estimateCoordinates, count: UInt(estimateCoordinates.count))
            mapView.addAnnotation(missionEstimateBackgroundAnnotation!)

            missionEstimateForegroundAnnotation = MGLPolyline(coordinates: estimateCoordinates, count: UInt(estimateCoordinates.count))
            mapView.addAnnotation(missionEstimateForegroundAnnotation!)

            if !missionCentered {
                visibleCoordinates.append(contentsOf: estimateCoordinates)
            }
        }
        
        if let reengagementEstimateCoordinates = updateMissionReengagementEstimate() {
            if !missionCentered {
                visibleCoordinates.append(contentsOf: reengagementEstimateCoordinates)
            }
        }

        if visibleCoordinates.count > 0 {
            missionCentered = true
            if tracking == .none || session?.state?.value.location == nil {
                set(visibleCoordinates: visibleCoordinates)
            }
        }
    }
    
    private func updateMissionReengagementEstimate() -> [CLLocationCoordinate2D]? {
        if let missionReengagementEstimateBackgroundAnnotation = missionReengagementEstimateBackgroundAnnotation {
            mapView.removeAnnotation(missionReengagementEstimateBackgroundAnnotation)
        }
        missionReengagementEstimateBackgroundAnnotation = nil

        if let missionReengagementEstimateForegroundAnnotation = missionReengagementEstimateForegroundAnnotation {
            mapView.removeAnnotation(missionReengagementEstimateForegroundAnnotation)
        }
        missionReengagementEstimateForegroundAnnotation = nil
        
        let engaged = missionExecutor?.engaged ?? false
        let reengaging = missionExecutor?.reengaging ?? false
        let reengagementEstimateCoordinates = ((reengaging ? missionExecutor?.reengagementSpatials : nil) ?? missionExecutor?.estimate?.reengagementSpatials)?.map({ $0.coordinate.coordinate })
        if reengaging,
           let reengagementEstimateCoordinates = reengagementEstimateCoordinates,
           reengagementEstimateCoordinates.count > 0 {
            missionReengagementEstimateBackgroundAnnotation = MGLPolyline(coordinates: reengagementEstimateCoordinates, count: UInt(reengagementEstimateCoordinates.count))
            mapView.addAnnotation(missionReengagementEstimateBackgroundAnnotation!)

            missionReengagementEstimateForegroundAnnotation = MGLPolyline(coordinates: reengagementEstimateCoordinates, count: UInt(reengagementEstimateCoordinates.count))
            mapView.addAnnotation(missionReengagementEstimateForegroundAnnotation!)
        }
        
        let reengagementCoordinate = reengaging ? reengagementEstimateCoordinates?.last : missionExecutor?.reengagementSpatial?.coordinate.coordinate
        if let reengagementCoordinate = reengagementCoordinate, !engaged || reengaging {
            missionReengagementDroneAnnotationView?.isHidden = false
            missionReengagementDroneAnnotation.coordinate = reengagementCoordinate
        }
        else {
            missionReengagementDroneAnnotationView?.isHidden = true
        }
        
        return reengagementEstimateCoordinates
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
        
        if tracking == .none, let visibleCoordinates = modeExecutor?.visibleCoordinates {
            set(visibleCoordinates: visibleCoordinates.map { $0.coordinate })
        }
    }
    
    private func apply(userInterfaceSettings: Kernel.UserInterfaceSettings?) {
        if let userInterfaceSettings = userInterfaceSettings {
            switch userInterfaceSettings.mapTracking {
            case .noChange:
                break
                
            case .none:
                tracking = .none
                break
                
            case .droneNorthUp:
                tracking = .droneNorthUp
                break
                
            case .droneHeading:
                tracking = .droneHeading
                break
            }
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
        
        apply(userInterfaceSettings: executor.userInterfaceSettings)
        
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
    
    public override func onMissionExecuted(executor: MissionExecutor, engagement: MissionExecutor.Engagement) {
        super.onMissionExecuted(executor: executor, engagement: engagement)
        if (missionReengagementEstimateBackgroundAnnotation == nil && executor.reengaging) || (missionReengagementEstimateBackgroundAnnotation != nil && !executor.reengaging) {
            DispatchQueue.main.async { [weak self] in
                self?.updateMissionReengagementEstimate()
            }
        }
    }
    
    public override func onMissionDisengaged(executor: MissionExecutor, engagement: Executor.Engagement, reason: Kernel.Message) {
        super.onMissionDisengaged(executor: executor, engagement: engagement, reason: reason)
        DispatchQueue.main.async { [weak self] in
            self?.updateMissionReengagementEstimate()
        }
    }
    
    public override func onMissionUpdatedDisconnected(executor: MissionExecutor, engagement: Executor.Engagement) {
        super.onMissionUpdatedDisconnected(executor: executor, engagement: engagement)
        DispatchQueue.main.async { [weak self] in
            self?.updateMissionReengagementEstimate()
        }
    }
    
    public override func onFuncLoaded(executor: FuncExecutor) {
        super.onFuncLoaded(executor: executor)
        
        apply(userInterfaceSettings: executor.userInterfaceSettings)
        
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
        
        if (annotation === missionReengagementDroneAnnotation) {
            var droneReengagement = mapView.dequeueReusableAnnotationView(withIdentifier: "drone-reengagement")
            if droneReengagement == nil {
                droneReengagement = MGLAnnotationView(reuseIdentifier: "drone-reengagement")
                droneReengagement?.addSubview(UIImageView(image: DronelinkUI.loadImage(named: "drone-reengagement", renderingMode: .alwaysOriginal)))
                droneReengagement?.frame = CGRect(x: 0, y: 0, width: 15, height: 15)
                missionReengagementDroneAnnotationView = droneReengagement
            }

            return droneReengagement
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

extension MapboxMapWidget: ConfigurableWidget {
    public var configurationActions: [UIAlertAction] {
        var actions: [UIAlertAction] = []
        
        actions.append(UIAlertAction(title: "MapboxMapWidget.reset".localized, style: .default, handler: {  [weak self] _ in
            self?.tracking = .none
        }))

        actions.append(UIAlertAction(title: "MapboxMapWidget.tracking".localized, style: tracking == .droneHeading ? .destructive : .default, handler: { [weak self] _ in
            self?.tracking = .droneHeading
        }))

        actions.append(UIAlertAction(title: "MapboxMapWidget.tracking.north.up".localized, style: tracking == .droneNorthUp ? .destructive : .default, handler: { [weak self] _ in
            self?.tracking = .droneNorthUp
        }))
        
        return actions
    }
}
