//
//  MapboxMapWidget.swift
//  DronelinkCoreUI
//
//  Created by Jim McAndrew on 10/28/19.
//  Copyright © 2019 Dronelink. All rights reserved.
//
import UIKit
import Foundation
import MapboxMaps
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
    
    private var mapView: MapView?

    private var pointAnnotationManager: PointAnnotationManager?
    private var polygonAnnotationManager: PolygonAnnotationManager?
    private var polylineAnnotationManager: PolylineAnnotationManager?
    
    private var droneView: UIView?
    private var missionReferenceView: UIView?
    private var modeTargetView: UIView?
    
    private var missionCentered = false
    private var currentMissionEstimateID: String?
    private var tracking = Tracking.none
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        let resourceOptions = ResourceOptions(accessToken: DronelinkUI.mapboxMapCredentialsKey ?? "")
        let mapInitOptions = MapInitOptions(resourceOptions: resourceOptions, styleURI: .satelliteStreets)
        mapView = MapView(frame: view.bounds, mapInitOptions: mapInitOptions)
        
        if let mapView = mapView {
            mapView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            mapView.addShadow()
            mapView.location.options.puckType = .puck2D(Puck2DConfiguration(pulsing: Puck2DConfiguration.Pulsing()))
            mapView.ornaments.scaleBarView.isHidden = true
            mapView.ornaments.compassView.isHidden = true
            mapView.clipsToBounds = true
            mapView.ornaments.attributionButton.tintColor = .white
            
            if let location = Dronelink.shared.location?.value {
                let cameraOptions = CameraOptions(center: location.coordinate, zoom: 17)
                mapView.mapboxMap.setCamera(to: cameraOptions)
            }
            
            polylineAnnotationManager = mapView.annotations.makePolylineAnnotationManager()
            polygonAnnotationManager = mapView.annotations.makePolygonAnnotationManager()
            pointAnnotationManager = mapView.annotations.makePointAnnotationManager()
            
            view.addSubview(mapView)
            
            mapView.snp.makeConstraints { [weak self] make in
                make.edges.equalToSuperview()
            }
            
        }
        
        update()
    }
    
    @objc open override func update() {
        super.update()
        
        guard let mapView = mapView else {
            return
        }
        
        if let pointAnnotationManager = pointAnnotationManager {
            if let state = session?.state?.value, let droneHomeLocation = state.homeLocation {
                var droneHomeAnnotation = PointAnnotation(id: "drone-home", coordinate: droneHomeLocation.coordinate)
                if let droneHomeAnnotationImage = DronelinkUI.loadImage(named: "home", renderingMode: .alwaysOriginal) {
                    droneHomeAnnotation.image = .init(image: droneHomeAnnotationImage, name: "home")
                }
                
                if let index = pointAnnotationManager.annotations.firstIndex(where: { $0.id == "drone-home" }) {
                    pointAnnotationManager.annotations.replaceSubrange(index..<index+1, with: [droneHomeAnnotation])
                } else {
                    pointAnnotationManager.annotations.append(droneHomeAnnotation)
                }
            } else {
                pointAnnotationManager.annotations.removeAll { $0.id == "drone-home" }
            }
        }
        
        if let state = session?.state?.value, let droneLocation = state.location {
            let offset = Dronelink.shared.droneOffsets.droneCoordinate
            let droneViewOptions = ViewAnnotationOptions(geometry: Point(droneLocation.coordinate.coordinate(bearing: offset.direction + Double.pi, distance: offset.magnitude)), allowOverlap: true, visible: true)

            if let droneView = droneView {
                droneView.subviews.first?.transform = CGAffineTransform(rotationAngle: CGFloat((state.orientation.yaw.convertRadiansToDegrees - mapView.cameraState.bearing).convertDegreesToRadians))
                do {
                    try mapView.viewAnnotations.update(droneView, options: droneViewOptions)
                } catch let error {
                    NSLog("MapboxMapWidget Error: \(error)")
                }
            } else {
                droneView = createUiView(imageName: "drone", viewSize: CGSize(width: 30, height: 30), alpha: 1.0, rotationAngle: CGFloat((state.orientation.yaw.convertRadiansToDegrees - mapView.cameraState.bearing).convertDegreesToRadians))
                if let droneView = droneView {
                    do {
                        try mapView.viewAnnotations.add(droneView, id: "drone", options: droneViewOptions)
                    } catch let error {
                        NSLog("MapboxMapWidget Error: \(error)")
                    }
                }
            }
        } else if let droneView = droneView {
            do {
                try mapView.viewAnnotations.update(droneView, options: ViewAnnotationOptions(visible: false))
            } catch let error {
                NSLog("MapboxMapWidget Error: \(error)")
            }
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
    
    private func createUiView(imageName: String, viewSize: CGSize, alpha: CGFloat, rotationAngle: CGFloat) -> UIView {
        let uiView = UIView()
        uiView.frame = CGRect(x: 0, y: 0, width: viewSize.width, height: viewSize.height)
        let uiImageView = UIImageView(image: DronelinkUI.loadImage(named: imageName, renderingMode: .alwaysOriginal))
        uiImageView.frame = uiView.bounds
        uiImageView.contentMode = .scaleAspectFit
        uiImageView.alpha = alpha
        uiImageView.transform = CGAffineTransform(rotationAngle: rotationAngle)
        uiView.transform = .identity
        uiView.addSubview(uiImageView)
        return uiView
    }

    private func set(visibleCoordinates: [CLLocationCoordinate2D], direction: CLLocationDirection? = nil) {
        
        guard let mapView = mapView, visibleCoordinates.count > 0 else {
            return
        }
        
        let inset: CGFloat = 0.2
        let edgePadding = UIEdgeInsets(
            top: mapView.frame.height * (mapView.frame.height > 300 ? 0.25 : inset),
            left: mapView.frame.width * inset,
            bottom: mapView.frame.height * (mapView.frame.height > 300 ? 0.38 : inset),
            right: mapView.frame.width * inset)
        
        var updatedDirection : Double = 0
        if let direction = direction {
            updatedDirection = direction < 0 ? direction + 360 : direction
        }

        let cameraOptions = mapView.mapboxMap.camera(for: visibleCoordinates, padding: edgePadding, bearing: direction == nil ? nil : updatedDirection, pitch: nil)
        mapView.camera.ease(to: cameraOptions, duration: 0.5)
    }

    private func updateMissionRequiredTakeoffArea() {
        if let polygonAnnotationManager = polygonAnnotationManager {
            polygonAnnotationManager.annotations.removeAll { $0.id == "mission-required-takeoff-area" }
        }

        if let requiredTakeoffArea = missionExecutor?.requiredTakeoffArea {
            let segments = 100
            let coordinates = (0...segments).map { index -> CLLocationCoordinate2D in
                let percent = Double(index) / Double(segments)
                return requiredTakeoffArea.coordinate.coordinate.coordinate(bearing: percent * Double.pi * 2, distance: requiredTakeoffArea.distanceTolerance.horizontal)
            }
            
            var missionRequiredTakeoffAreaAnnotation = PolygonAnnotation(id: "mission-required-takeoff-area", polygon: Polygon([coordinates]))
            missionRequiredTakeoffAreaAnnotation.fillColor = StyleColor(MDCPalette.orange.accent400!.withAlphaComponent(0.25))
            missionRequiredTakeoffAreaAnnotation.fillOutlineColor = StyleColor(MDCPalette.orange.accent200!.withAlphaComponent(0.25))
            if let polygonAnnotationManager = polygonAnnotationManager {
                polygonAnnotationManager.annotations.append(missionRequiredTakeoffAreaAnnotation)
                
            }
        }
    }
    
    private func updateMissionRestrictionZones() {
        if let polygonAnnotationManager = polygonAnnotationManager {
            polygonAnnotationManager.annotations.removeAll { $0.id == "mission-restriction-zone" }
        }

        if let restrictionZones = missionExecutor?.restrictionZones {
            restrictionZones.enumerated().forEach {
                guard let coordinatesRaw = missionExecutor?.restrictionZoneBoundaryCoordinates?[safeIndex: $0.offset], let coordinates = coordinatesRaw else {
                    return
                }

                let restrictionZone = $0.element
                let color = UIColor(hex: restrictionZone.zone.color, defaultAlpha: 0.5)
                var missionRestrictionZoneAnnotation: PolygonAnnotation?
                switch restrictionZone.zone.shape {
                case .circle:
                    let center = CLLocation(latitude: coordinates[0].latitude, longitude: coordinates[0].longitude)
                    let radius = center.distance(from: CLLocation(latitude: coordinates[1].latitude, longitude: coordinates[1].longitude))
                    let segments = 100
                    let points = (0...segments).map { index -> CLLocationCoordinate2D in
                        let percent = Double(index) / Double(segments)
                        return center.coordinate.coordinate(bearing: percent * Double.pi * 2, distance: radius)
                    }
                    missionRestrictionZoneAnnotation = PolygonAnnotation(id: "mission-restriction-zone", polygon: Polygon([points]))
                    break

                case .polygon:
                    missionRestrictionZoneAnnotation = PolygonAnnotation(id: "mission-restriction-zone", polygon: Polygon([coordinates.map { $0.coordinate }]))
                    break
                }

                if let polygonAnnotationManager = polygonAnnotationManager {
                    missionRestrictionZoneAnnotation?.fillColor = StyleColor(color?.withAlphaComponent(color?.rgba.alpha ?? 0.5) ?? MDCPalette.pink.accent400!.withAlphaComponent(color?.rgba.alpha ?? 0.5))
                    
                    missionRestrictionZoneAnnotation?.fillOutlineColor = StyleColor(color?.withAlphaComponent(color?.rgba.alpha ?? 0.5) ?? MDCPalette.pink.accent400!.withAlphaComponent(color?.rgba.alpha ?? 0.5))
                    
                    if let missionRestrictionZoneAnnotation = missionRestrictionZoneAnnotation {
                        polygonAnnotationManager.annotations.append(missionRestrictionZoneAnnotation)
                    }
                }
            }
        }
    }

    private func updateMissionEstimate() {
        if missionExecutor?.estimate?.id == currentMissionEstimateID {
            return
        }
        currentMissionEstimateID = missionExecutor?.estimate?.id
        
        if let polylineAnnotationManager = polylineAnnotationManager {
            polylineAnnotationManager.annotations.removeAll { $0.id == "mission-estimate-background" || $0.id == "mission-estimate-foreground" }
        }

        var visibleCoordinates: [CLLocationCoordinate2D] = []
        if let estimateCoordinates = missionExecutor?.estimate?.spatials.map({ $0.coordinate.coordinate }),
           estimateCoordinates.count > 0 {
            
            var missionEstimateBackgroundAnnotation = PolylineAnnotation(id: "mission-estimate-background", lineCoordinates: estimateCoordinates)
            missionEstimateBackgroundAnnotation.lineWidth = 6
            missionEstimateBackgroundAnnotation.lineColor = StyleColor(MDCPalette.lightBlue.tint800)
            
            var missionEstimateForegroundAnnotation = PolylineAnnotation(id: "mission-estimate-foreground", lineCoordinates: estimateCoordinates)
            missionEstimateForegroundAnnotation.lineWidth = 2.5
            missionEstimateForegroundAnnotation.lineColor = StyleColor(MDCPalette.cyan.accent400!)
            
            if let polylineAnnotationManager = polylineAnnotationManager {
                polylineAnnotationManager.annotations.append(missionEstimateBackgroundAnnotation)
                polylineAnnotationManager.annotations.append(missionEstimateForegroundAnnotation)
            }

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
        if let polylineAnnotationManager = polylineAnnotationManager {
            polylineAnnotationManager.annotations.removeAll { $0.id == "mission-reengagement-estimate-background" || $0.id == "mission-reengagement-estimate-foreground" }
        }
        
        let engaged = missionExecutor?.engaged ?? false
        let reengaging = missionExecutor?.reengaging ?? false
        let reengagementEstimateCoordinates = ((reengaging ? missionExecutor?.reengagementSpatials : nil) ?? missionExecutor?.estimate?.reengagementSpatials)?.map({ $0.coordinate.coordinate })
        if reengaging,
           let reengagementEstimateCoordinates = reengagementEstimateCoordinates,
           reengagementEstimateCoordinates.count > 0 {
            
            var missionReengagementEstimateBackgroundAnnotation = PolylineAnnotation(id: "mission-reengagement-estimate-background", lineCoordinates: reengagementEstimateCoordinates)
            missionReengagementEstimateBackgroundAnnotation.lineWidth = 6
            missionReengagementEstimateBackgroundAnnotation.lineColor = StyleColor(MDCPalette.purple.tint800)
            
            var missionReengagementEstimateForegroundAnnotation = PolylineAnnotation(id: "mission-reengagement-estimate-foreground", lineCoordinates: reengagementEstimateCoordinates)
            missionReengagementEstimateForegroundAnnotation.lineWidth = 2.5
            missionReengagementEstimateForegroundAnnotation.lineColor = StyleColor(MDCPalette.purple.accent200!)
            
            if let polylineAnnotationManager = polylineAnnotationManager {
                polylineAnnotationManager.annotations.append(missionReengagementEstimateBackgroundAnnotation)
                polylineAnnotationManager.annotations.append(missionReengagementEstimateForegroundAnnotation)
            }
        }
        
        let reengagementCoordinate = reengaging ? reengagementEstimateCoordinates?.last : missionExecutor?.reengagementSpatial?.coordinate.coordinate
        if let pointAnnotationManager = pointAnnotationManager {
            if let reengagementCoordinate = reengagementCoordinate, !engaged || reengaging {

                var missionReengagementDroneAnnotation = PointAnnotation(id: "drone-reengagement", coordinate: reengagementCoordinate)
                if let missionReengagementDroneAnnotationImage = DronelinkUI.loadImage(named: "drone-reengagement", renderingMode: .alwaysOriginal) {
                    let renderer = UIGraphicsImageRenderer(size: CGSize(width: 22, height: 22))
                    let rect = CGRect(x: 0, y: 0, width: 22, height: 22)
                    let resizedImage = renderer.image { (_) in
                        missionReengagementDroneAnnotationImage.draw(in: rect)
                    }
                    missionReengagementDroneAnnotation.image = .init(image: resizedImage, name: "drone-reengagement")
                }
                
                if let index = pointAnnotationManager.annotations.firstIndex(where: { $0.id == "drone-reengagement" }) {
                    pointAnnotationManager.annotations.replaceSubrange(index..<index+1, with: [missionReengagementDroneAnnotation])
                } else {
                    pointAnnotationManager.annotations.append(missionReengagementDroneAnnotation)
                }
            } else {
                pointAnnotationManager.annotations.removeAll { $0.id == "drone-reengagement" }
            }
        }
        
        return reengagementEstimateCoordinates
    }
    
    private func updateFuncElements() {
        
        guard let mapView = mapView else {
            return
        }
        
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

        if let pointAnnotationManager = pointAnnotationManager {
            pointAnnotationManager.annotations.removeAll { $0.id == "func-drone" }
            spatials.enumerated().forEach {
                var funcDroneAnnotation = PointAnnotation(id: "func-drone", coordinate: $0.element.coordinate.coordinate)

                if let funcDroneAnnotationImage = DronelinkUI.loadImage(named: "func-input-drone", renderingMode: .alwaysOriginal) {
                    funcDroneAnnotation.image = .init(image: funcDroneAnnotationImage, name: "func-input-drone")
                    pointAnnotationManager.annotations.append(funcDroneAnnotation)
                }
            }

        }
 
        if let mapCenterSpatial = mapCenterSpatial {
            let cameraOptions = CameraOptions(center: mapCenterSpatial.coordinate.coordinate, zoom: 19.25)
            mapView.camera.ease(to: cameraOptions, duration: 0.5)
        }
        
        if let polygonAnnotationManager = polygonAnnotationManager {
            polygonAnnotationManager.annotations.removeAll { $0.id == "func-map-overlay" }
            
            if let mapOverlays = funcExecutor?.mapOverlays(droneSession: session, error: { _ in
            }) {
                mapOverlays.enumerated().forEach {
                    let mapOverlay = $0.element
                    let color = UIColor(hex: mapOverlay.color, defaultAlpha: 0.5)
                    var funcMapOverlayAnnotation = PolygonAnnotation(id: "func-map-overlay", polygon: Polygon([mapOverlay.coordinates.map { $0.coordinate }]))

                    funcMapOverlayAnnotation.fillColor = StyleColor(color?.withAlphaComponent(color?.rgba.alpha ?? 0.5) ?? MDCPalette.pink.accent400!.withAlphaComponent(0.5))
                    funcMapOverlayAnnotation.fillOutlineColor = StyleColor(color?.withAlphaComponent(color?.rgba.alpha ?? 0.5) ?? MDCPalette.pink.accent400!.withAlphaComponent(0.5))
                    polygonAnnotationManager.annotations.append(funcMapOverlayAnnotation)
                }
            }
        }
    }
    
    private func updateModeElements() {
        
        guard let mapView = mapView else {
            return
        }
        
        guard modeExecutor?.engaged ?? false else {
            if let modeTargetView = modeTargetView {
                do {
                    try mapView.viewAnnotations.update(modeTargetView, options: ViewAnnotationOptions(visible: false))
                } catch let error {
                    NSLog("MapboxMapWidget Error: \(error)")
                }
            }
            return
        }
        
        if let modeTarget = modeExecutor?.target {
            let modeTargetOptions = ViewAnnotationOptions(geometry: Point(modeTarget.coordinate.coordinate), allowOverlap: true, visible: true)

            if let modeTargetView = modeTargetView {
                modeTargetView.subviews.first?.transform = CGAffineTransform(rotationAngle: CGFloat((modeTarget.orientation.yaw.convertRadiansToDegrees - mapView.cameraState.bearing).convertDegreesToRadians))
                do {
                    try mapView.viewAnnotations.update(modeTargetView, options: modeTargetOptions)
                } catch let error {
                    NSLog("MapboxMapWidget Error: \(error)")
                
                }
            } else {
                modeTargetView = createUiView(imageName: "drone", viewSize: CGSize(width: 30, height: 30), alpha: 0.5, rotationAngle: CGFloat((modeTarget.orientation.yaw.convertRadiansToDegrees - mapView.cameraState.bearing).convertDegreesToRadians))
                if let modeTargetView = modeTargetView {
                    do {
                        try mapView.viewAnnotations.add(modeTargetView, options: modeTargetOptions)
                    } catch let error {
                        NSLog("MapboxMapWidget Error: \(error)")
                    
                    }
                }
            }
            
        } else if let modeTargetView = modeTargetView {
            do {
                try mapView.viewAnnotations.update(modeTargetView, options: ViewAnnotationOptions(visible: false))
            } catch let error {
                NSLog("MapboxMapWidget Error: \(error)")
            }
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
                let cameraOptions = CameraOptions(center: location.coordinate, zoom: 18.5)
                self?.mapView?.camera.ease(to: cameraOptions, duration: 0.5)
            }
        }
    }

    public override func onMissionLoaded(executor: MissionExecutor) {
        super.onMissionLoaded(executor: executor)
        
        currentMissionEstimateID = nil
        apply(userInterfaceSettings: executor.userInterfaceSettings)
        
        DispatchQueue.main.async { [weak self] in
            if (executor.userInterfaceSettings?.droneOffsetsVisible ?? false) {
                
                if let mapView = self?.mapView {
                    let missionReferenceViewOptions = ViewAnnotationOptions(geometry: Point(executor.referenceCoordinate.coordinate), visible: true, offsetY: 19, selected: true)
                    if let missionReferenceView = self?.missionReferenceView {
                        do {
                            try mapView.viewAnnotations.update(missionReferenceView, options: missionReferenceViewOptions)
                        } catch let error {
                            NSLog("MapboxMapWidget Error: \(error)")
                        }
                    } else {
                        self?.missionReferenceView = self?.createUiView(imageName: "mission-reference", viewSize: CGSize(width: 38, height: 38), alpha: 1, rotationAngle: 0)
                        if let missionReferenceView = self?.missionReferenceView {
                            do {
                                try mapView.viewAnnotations.add(missionReferenceView, id: "mission-reference", options: missionReferenceViewOptions)
                            } catch let error {
                                NSLog("MapboxMapWidget Error: \(error)")
                            }
                        }
                    }
                }
            }
            
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
            
            if let missionReferenceView = self?.missionReferenceView, let mapView = self?.mapView {
                do {
                    try mapView.viewAnnotations.remove(missionReferenceView)
                } catch let error {
                    NSLog("MapboxMapWidget Error: \(error)")
                }
            }
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
        let missionReengagementEstimateBackgroundAnnotationExists = polylineAnnotationManager?.annotations.contains(where: { $0.id == "mission-reengagement-estimate-background" }) ?? false
        if (!missionReengagementEstimateBackgroundAnnotationExists && executor.reengaging) || (missionReengagementEstimateBackgroundAnnotationExists && !executor.reengaging) {
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
