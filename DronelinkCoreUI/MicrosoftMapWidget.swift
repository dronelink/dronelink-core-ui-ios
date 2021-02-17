//
//  MicrosoftMapWidget.swift
//  DronelinkCoreUI
//
//  Created by Jim McAndrew on 12/4/20.
//  Copyright © 2020 Dronelink. All rights reserved.
//
import UIKit
import Foundation
import Mapbox
import DronelinkCore
import MaterialComponents.MaterialPalettes
import MicrosoftMaps

public class MicrosoftMapWidget: UpdatableWidget {
    public enum Tracking {
        case none
        case thirdPersonNadir //follow
        case thirdPersonOblique //chase plane
        case firstPerson //fpv
    }
    
    public enum Style {
        case streets
        case satellite
    }

    private struct SceneElements: OptionSet {
        let rawValue: Int

        static let user = SceneElements(rawValue: 1 << 0)
        static let droneCurrent = SceneElements(rawValue: 1 << 1)
        static let droneHome = SceneElements(rawValue: 1 << 2)
        static let droneTakeoff = SceneElements(rawValue: 1 << 3)
        static let missionReengagement = SceneElements(rawValue: 1 << 4)
        static let missionMain = SceneElements(rawValue: 1 << 5)
        static let missionTakeoff = SceneElements(rawValue: 1 << 6)

        static let all: SceneElements = [.user, .droneCurrent, .droneHome, .droneTakeoff, .missionTakeoff, .missionMain, .missionReengagement]
        static let standard: SceneElements = [.droneCurrent, .droneHome, .droneTakeoff, .missionTakeoff, .missionMain, .missionReengagement]
    }

    public override var updateInterval: TimeInterval { 0.1 }

    public let mapView = MSMapView()
    private let droneLayer = MSMapElementLayer()
    private let droneIcon = MSMapIcon()
    private let droneHomeIcon = MSMapIcon()
    private var droneSessionPolyline: MSMapPolyline?
    private var droneSessionPositions: [MSGeoposition] = []
    private var droneMissionExecutedPolyline: MSMapPolyline?
    private var droneMissionExecutedPositions: [MSGeoposition] = []
    private let missionLayer = MSMapElementLayer()
    private let funcLayer = MSMapElementLayer()
    private var funcInputDroneIcons: [MSMapIcon] = []
    private let funcInputDroneImage = MSMapImage(uiImage: DronelinkUI.loadImage(named: "func-input-drone", renderingMode: .alwaysOriginal)!)
    private let modeLayer = MSMapElementLayer()
    private let modeTargetIcon = MSMapIcon()
    private var droneTakeoffAltitude: Double?
    private var droneTakeoffAltitudeReferenceSystem: MSMapAltitudeReferenceSystem { droneTakeoffAltitude == nil ? .surface : .geoid }
    private var style = Style.streets
    private var tracking = Tracking.none
    private var trackingPrevious = Tracking.none

    public override func viewDidLoad() {
        mapView.addShadow()
        mapView.clipsToBounds = true
        mapView.addCameraDidChangeHandler { (reason, camera) -> Bool in
            if reason == .userInteraction {
                switch self.tracking {
                case .thirdPersonNadir:
                    self.tracking = .none
                    self.trackingPrevious = .none
                    break

                case .none, .thirdPersonOblique, .firstPerson:
                    break
                }
            }
            return true
        }
        mapView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        update(style: .streets)
        mapView.projection = .globe
        mapView.businessLandmarksVisible = false
        mapView.buildingsVisible = true
        mapView.transitFeaturesVisible = false
        mapView.userInterfaceOptions.compassButtonVisible = false
        mapView.userInterfaceOptions.tiltButtonVisible = false
        mapView.userInterfaceOptions.zoomButtonsVisible = false
        mapView.backgroundColor = UIColor.black
        view.addSubview(mapView)
        mapView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        updateScene(elements: .user, animation: .none)

        droneLayer.zIndex = 10
        droneHomeIcon.image = MSMapImage(uiImage: DronelinkUI.loadImage(named: "home", renderingMode: .alwaysOriginal)!)
        droneHomeIcon.flat = true
        droneHomeIcon.desiredCollisionBehavior = .remainVisible
        droneLayer.elements.add(droneHomeIcon)
        droneIcon.image = MSMapImage(uiImage: DronelinkUI.loadImage(named: "drone", renderingMode: .alwaysOriginal)!)
        droneIcon.flat = true
        droneIcon.desiredCollisionBehavior = .remainVisible
        droneLayer.elements.add(droneIcon)
        mapView.layers.add(droneLayer)

        missionLayer.zIndex = 1
        mapView.layers.add(missionLayer)

        funcLayer.zIndex = 1
        mapView.layers.add(funcLayer)

        modeLayer.zIndex = 1
        modeTargetIcon.image = MSMapImage(uiImage: DronelinkUI.loadImage(named: "drone", renderingMode: .alwaysOriginal)!)
        modeTargetIcon.flat = true
        modeTargetIcon.opacity = 0.5
        modeTargetIcon.desiredCollisionBehavior = .remainVisible
        modeLayer.elements.add(modeTargetIcon)
        mapView.layers.add(modeLayer)

        update()
    }

    func update(style: Style) {
        self.style = style
        switch (style) {
        case .streets:
            mapView.setStyleSheet(MSMapStyleSheets.roadDark())
            break

        case .satellite:
            mapView.setStyleSheet(MSMapStyleSheets.aerialWithOverlay())
            break
        }
    }

    @objc open override func update() {
        super.update()

        if session?.located ?? false, let state = session?.state?.value, let droneHomeLocation = state.homeLocation {
            var rotation = Int(-mapView.camera.heading) % 360
            if (rotation < 0) {
                rotation += 360;
            }
            droneHomeIcon.rotation = Float(rotation)
            droneHomeIcon.location = MSGeopoint(latitude: droneHomeLocation.coordinate.latitude, longitude: droneHomeLocation.coordinate.longitude)
        }

        let engaged = missionExecutor?.engaged ?? false
        if droneTakeoffAltitude != nil, session?.located ?? false, let state = session?.state?.value, let location = state.location {
            var rotation = Int(-state.orientation.yaw.convertRadiansToDegrees) % 360
            if (rotation < 0) {
                rotation += 360;
            }
            droneIcon.rotation = Float(rotation)
            droneIcon.location = MSGeopoint(position: positionAboveDroneTakeoffLocation(coordinate: location.coordinate, altitude: state.altitude), altitudeReferenceSystem: droneTakeoffAltitudeReferenceSystem)
            addPositionAboveDroneTakeoffLocation(positions: &droneSessionPositions, coordinate: location.coordinate, altitude: state.altitude)
        }

        if engaged || droneSessionPositions.count == 0 {
            if let droneSessionPolyline = droneSessionPolyline {
                droneLayer.elements.remove(droneSessionPolyline)
            }
            droneSessionPolyline = nil
        }
        else {
            if droneSessionPolyline == nil {
                let droneSessionPolyline = MSMapPolyline()
                droneSessionPolyline.strokeColor = UIColor.white.withAlphaComponent(0.95)
                droneSessionPolyline.strokeWidth = 1
                droneLayer.elements.add(droneSessionPolyline)
                self.droneSessionPolyline = droneSessionPolyline
            }

            if droneSessionPolyline?.path.size ?? 0 != droneSessionPositions.count {
                droneSessionPolyline?.path = MSGeopath(positions: droneSessionPositions, altitudeReferenceSystem: droneTakeoffAltitudeReferenceSystem)
            }
        }

        if droneMissionExecutedPositions.count == 0 {
            if let droneMissionExecutedPolyline = droneMissionExecutedPolyline {
                droneLayer.elements.remove(droneMissionExecutedPolyline)
            }
            droneMissionExecutedPolyline = nil
        }
        else {
            if droneMissionExecutedPolyline == nil {
                let droneMissionExecutedPolyline = MSMapPolyline()
                droneMissionExecutedPolyline.strokeColor = MDCPalette.pink.accent400!
                droneMissionExecutedPolyline.strokeWidth = 2
                droneLayer.elements.add(droneMissionExecutedPolyline)
                self.droneMissionExecutedPolyline = droneMissionExecutedPolyline
            }

            if droneMissionExecutedPolyline?.path.size ?? 0 != droneMissionExecutedPositions.count {
                droneMissionExecutedPolyline?.path = MSGeopath(positions: droneMissionExecutedPositions, altitudeReferenceSystem: droneTakeoffAltitudeReferenceSystem)
            }
        }

        if session?.located ?? false, let state = session?.state?.value, let location = state.location {
            var trackingScene: MSMapScene?
            switch (tracking) {
            case .none:
                break

            case .thirdPersonNadir:
                trackingScene = MSMapScene(
                    location: MSGeopoint(latitude: location.coordinate.latitude, longitude: location.coordinate.longitude),
                    radius: max(20, state.altitude / 1.5))
                break

            case .thirdPersonOblique:
                trackingScene = MSMapScene(camera: MSMapCamera(
                    location: MSGeopoint(
                        position: positionAboveDroneTakeoffLocation(
                            coordinate: location.coordinate.coordinate(bearing: state.orientation.yaw + Double.pi, distance: 15),
                            altitude: state.altitude + 14),
                        altitudeReferenceSystem: droneTakeoffAltitudeReferenceSystem),
                    heading: state.orientation.yaw.convertRadiansToDegrees,
                    pitch: 45))
                break

            case .firstPerson:
                trackingScene = MSMapScene(
                    camera: MSMapCamera(
                        location: MSGeopoint(
                            position: positionAboveDroneTakeoffLocation(coordinate: location.coordinate, altitude: state.altitude),
                            altitudeReferenceSystem: droneTakeoffAltitudeReferenceSystem),
                        heading: state.orientation.yaw.convertRadiansToDegrees,
                        pitch: min((session?.gimbalState(channel: 0)?.value.orientation.pitch.convertRadiansToDegrees ?? 0) + 90, 90)))
                break
            }

            if let trackingScene = trackingScene {
                //linear causes a memory leak right now:
                //https://stackoverflow.com/questions/10122570/replace-a-fragment-programmatically
                //mapView.setScene(trackingScene, with: trackingPrevious == tracking ? .linear : .none)
                mapView.setScene(trackingScene, with: .none)
                trackingPrevious = tracking
            }
        }
    }

    private func updateMissionElements() {
        missionLayer.elements.clear()

        if let requiredTakeoffArea = missionExecutor?.requiredTakeoffArea {
            let polygon = MSMapPolygon()
            polygon.strokeColor = MDCPalette.orange.accent200!.withAlphaComponent(0.5)
            polygon.strokeWidth = 1
            polygon.fillColor = MDCPalette.orange.accent400!.withAlphaComponent(0.25)
            polygon.shapes = [
                MSGeocircle(
                    center: MSGeoposition(coordinates: requiredTakeoffArea.coordinate.coordinate),
                    radius: requiredTakeoffArea.distanceTolerance.horizontal
                )
            ]
            missionLayer.elements.add(polygon)
        }

        if let restrictionZones = missionExecutor?.restrictionZones {
            restrictionZones.enumerated().forEach {
                guard let coordinates = missionExecutor?.restrictionZoneBoundaryCoordinates(index: $0.offset) else {
                    return
                }

                let polygon = MSMapPolygon()
                polygon.strokeColor = MDCPalette.red.accent400!.withAlphaComponent(0.7)
                polygon.strokeWidth = 2
                polygon.fillColor = MDCPalette.red.accent400!.withAlphaComponent(0.5)

                let restrictionZone = $0.element
                switch restrictionZone.zone.shape {
                case .circle:
                    let center = coordinates[0].coordinate
                    let radius = center.distance(to: coordinates[1].coordinate)
                    polygon.shapes = [
                        MSGeocircle(
                            center: positionAboveDroneTakeoffLocation(coordinate: center, altitude: restrictionZone.zone.minAltitude.value),
                            radius: radius,
                            altitudeReference: droneTakeoffAltitudeReferenceSystem
                        )//, TODO microsoft is ignoring z!
                        //MSGeocircle(
                        //    center: positionAboveDroneTakeoffLocation(coordinate: center, altitude: restrictionZone.zone.maxAltitude.value),
                        //    radius: radius,
                        //    altitudeReference: droneTakeoffAltitudeReferenceSystem
                        //)
                    ]
                    break

                case .polygon:
                    polygon.paths = [
                        MSGeopath(
                            positions: coordinates.map { positionAboveDroneTakeoffLocation(coordinate: $0.coordinate, altitude: restrictionZone.zone.minAltitude.value) },
                            altitudeReferenceSystem: droneTakeoffAltitudeReferenceSystem
                        )//,
                        //MSGeopath(
                        //    positions: coordinates.map { positionAboveDroneTakeoffLocation(coordinate: $0.coordinate, altitude: restrictionZone.zone.maxAltitude.value) },
                        //    altitudeReferenceSystem: droneTakeoffAltitudeReferenceSystem
                        //)
                    ]
                    break
                }

                missionLayer.elements.add(polygon)
            }
        }

        if let estimateSpatials = missionExecutor?.estimate?.spatials, estimateSpatials.count > 0 {
            var positions: [MSGeoposition] = []
            estimateSpatials.forEach { addPositionAboveDroneTakeoffLocation(positions: &positions, coordinate: $0.coordinate.coordinate, altitude: $0.altitude.value, tolerance: 0.1) }
            let path = MSGeopath(positions: positions, altitudeReferenceSystem: droneTakeoffAltitudeReferenceSystem)

            let polyline = MSMapPolyline()
            polyline.strokeColor = MDCPalette.cyan.accent400!.withAlphaComponent(0.73)
            polyline.strokeWidth = 1
            polyline.path = path
            missionLayer.elements.add(polyline)
        }

        if missionExecutor?.engaged ?? false {
            if let reengagementEstimateSpatials = missionExecutor?.estimate?.reengagementSpatials, reengagementEstimateSpatials.count > 0 {
                if let reengagementEstimateSpatial = reengagementEstimateSpatials.last {
                    let reengagementIcon = MSMapIcon()
                    reengagementIcon.image = MSMapImage(uiImage: DronelinkUI.loadImage(named: "reengagement", renderingMode: .alwaysOriginal)!)
                    reengagementIcon.flat = true
                    reengagementIcon.desiredCollisionBehavior = .remainVisible
                    reengagementIcon.location = MSGeopoint(position: positionAboveDroneTakeoffLocation(coordinate: reengagementEstimateSpatial.coordinate.coordinate, altitude: reengagementEstimateSpatial.altitude.value), altitudeReferenceSystem: droneTakeoffAltitudeReferenceSystem)
                    missionLayer.elements.add(reengagementIcon)
                }

                var positions: [MSGeoposition] = []
                reengagementEstimateSpatials.forEach { addPositionAboveDroneTakeoffLocation(positions: &positions, coordinate: $0.coordinate.coordinate, altitude: $0.altitude.value, tolerance: 0.1) }
                let path = MSGeopath(positions: positions, altitudeReferenceSystem: droneTakeoffAltitudeReferenceSystem)

                let polyline = MSMapPolyline()
                polyline.strokeColor = MDCPalette.purple.accent200!
                polyline.strokeWidth = 1
                polyline.path = path
                missionLayer.elements.add(polyline)
            }
        }
    }

    private func updateFuncElements() {
        var iconIndex = 0
        var inputIndex = 0
        while let input = funcExecutor?.input(index: inputIndex) {
            if input.variable.valueType == .drone {
                if let value = funcExecutor?.readValue(inputIndex: inputIndex) {
                    var spatials: [Kernel.GeoSpatial] = []
                    if let array = value as? [Kernel.GeoSpatial?] {
                        array.forEach { spatial in
                            if let spatial = spatial {
                                spatials.append(spatial)
                            }
                        }
                    }
                    else if let spatial = value as? Kernel.GeoSpatial {
                        spatials.append(spatial)
                    }

                    spatials.enumerated().forEach { (variableValueIndex, spatial) in
                        var inputIcon = funcInputDroneIcons[safeIndex: iconIndex]
                        if inputIcon == nil {
                            inputIcon = MSMapIcon()
                            inputIcon?.image = funcInputDroneImage
                            inputIcon?.flat = true
                            inputIcon?.desiredCollisionBehavior = .remainVisible
                            inputIcon?.flyout = MSMapFlyout()
                            funcInputDroneIcons.append(inputIcon!)
                        }

                        inputIcon?.location = MSGeopoint(position: positionAboveDroneTakeoffLocation(coordinate: spatial.coordinate.coordinate, altitude: spatial.altitude.value), altitudeReferenceSystem: droneTakeoffAltitudeReferenceSystem)
                        inputIcon?.flyout?.title = "\(inputIndex + 1). \(input.descriptors.name ?? "")"
                        if let valueFormatted = funcExecutor?.readValue(inputIndex: inputIndex, variableValueIndex: variableValueIndex, formatted: true) as? String {
                            inputIcon?.flyout?.description = "\(valueFormatted)\(((value as? [Kernel.GeoSpatial?])?.count ?? 0) > 1 ? " (\(variableValueIndex + 1))" : "")"
                        }
                        else {
                            inputIcon?.flyout?.description = nil
                        }
                        iconIndex += 1
                    }
                }
            }
            inputIndex += 1
        }

        while iconIndex < funcInputDroneIcons.count {
            funcInputDroneIcons.removeLast()
        }

        while funcLayer.elements.count > funcInputDroneIcons.count {
            funcLayer.elements.removeMapElement(at: funcLayer.elements.count - 1)
        }

        while funcLayer.elements.count < funcInputDroneIcons.count {
            funcLayer.elements.add(funcInputDroneIcons[Int(funcLayer.elements.count)])
        }
    }

    private func updateModeElements() {
        guard modeExecutor?.engaged ?? false else {
            modeTargetIcon.visible = false
            return
        }

        if let modeTarget = modeExecutor?.target {
            var rotation = Int(-modeTarget.orientation.yaw.convertRadiansToDegrees) % 360
            if (rotation < 0) {
                rotation += 360;
            }
            modeTargetIcon.rotation = Float(rotation)
            modeTargetIcon.location = MSGeopoint(latitude: modeTarget.coordinate.latitude, longitude: modeTarget.coordinate.longitude)
            modeTargetIcon.visible = true
        }
        else {
            modeTargetIcon.visible = false
        }

        if let visibleCoordinates = modeExecutor?.visibleCoordinates, visibleCoordinates.count > 0 {
            tracking = .none
            let boundingBox = MSGeoboundingBox(positions: visibleCoordinates.map { MSGeoposition(coordinates: $0.coordinate) })
            let radius = boundingBox.northWestCorner.coordinate.distance(to: boundingBox.southEastCorner.coordinate) * 0.5
            let center = boundingBox.northWestCorner.coordinate.coordinate(
                bearing: boundingBox.northWestCorner.coordinate.bearing(to: boundingBox.southEastCorner.coordinate),
                distance: radius)
            //using the bounding box directly isn't great
            mapView.setScene(MSMapScene(location: MSGeopoint(latitude: center.latitude, longitude: center.longitude), radius: radius * 2.0, heading: 0, pitch: 0), with: .none)
        }
    }

    private func updateDroneTakeoffAltitude() {
        var point: MSGeopoint?
        if let takeoffLocation = session?.state?.value.takeoffLocation {
            point = MSGeopoint(latitude: takeoffLocation.coordinate.latitude, longitude: takeoffLocation.coordinate.longitude)
        }
        else if let takeoffCoordinate = missionExecutor?.takeoffCoordinate {
            point = MSGeopoint(latitude: takeoffCoordinate.latitude, longitude: takeoffCoordinate.longitude)
        }

        guard let pointValid = point else {
            droneTakeoffAltitude = nil
            return
        }

        droneTakeoffAltitude = -pointValid.toAltitudeReferenceSystem(.geoid, map: mapView).position.altitude
    }

    private func positionAboveDroneTakeoffLocation(coordinate: CLLocationCoordinate2D, altitude: Double) -> MSGeoposition {
        MSGeoposition(latitude: coordinate.latitude, longitude: coordinate.longitude, altitude: (droneTakeoffAltitude ?? 0) + altitude)
    }

    @discardableResult
    private func addPositionAboveDroneTakeoffLocation(positions: inout [MSGeoposition], coordinate: CLLocationCoordinate2D, altitude: Double, tolerance: Double = 0.5) -> MSGeoposition {
        var position = positionAboveDroneTakeoffLocation(coordinate: coordinate, altitude: altitude)
        if let lastPosition = positions.last {
            if abs(lastPosition.altitude - position.altitude) < tolerance && lastPosition.coordinate.distance(to: position.coordinate) < tolerance {
                return lastPosition
            }

            //kluge: microsoft maps has a bug / optimization that refuses to render coordinates that are very close, even if the altitude is different, so trick it
            if lastPosition.coordinate.distance(to: position.coordinate) <= 0.01 {
                position = positionAboveDroneTakeoffLocation(coordinate: coordinate.coordinate(bearing: 0, distance: 0.011), altitude: altitude)
            }
        }

        positions.append(position)
        return position
    }

    private func updateScene(elements: SceneElements = .standard, animation: MSMapAnimationKind = .linear) {
        if tracking != .none {
            return
        }

        var positions: [MSGeoposition] = []
        if elements.contains(.user),
            let location = Dronelink.shared.location?.value {
            positions.append(MSGeoposition(coordinates: location.coordinate))
        }

        if elements.contains(.droneCurrent),
            session?.located ?? false,
            let location = session?.state?.value.location {
            positions.append(MSGeoposition(coordinates: location.coordinate))
        }

        if elements.contains(.droneHome),
            session?.located ?? false,
            let location = session?.state?.value.homeLocation {
            positions.append(MSGeoposition(coordinates: location.coordinate))
        }

        if elements.contains(.droneTakeoff),
            session?.located ?? false,
            let location = session?.state?.value.takeoffLocation {
            positions.append(MSGeoposition(coordinates: location.coordinate))
        }

        if elements.contains(.missionTakeoff) {
            if let coordinate = missionExecutor?.takeoffCoordinate {
                positions.append(MSGeoposition(coordinates: coordinate.coordinate))
            }
        }

        if elements.contains(.missionMain) {
            missionExecutor?.estimate?.spatials.forEach {
                positions.append(MSGeoposition(coordinates: $0.coordinate.coordinate))
            }
        }

        if elements.contains(.missionReengagement) {
            missionExecutor?.estimate?.reengagementSpatials?.forEach {
                positions.append(MSGeoposition(coordinates: $0.coordinate.coordinate))
            }
        }

        if positions.count > 0 {
            let boundingBox = MSGeoboundingBox(positions: positions)
            var radius = boundingBox.northWestCorner.coordinate.distance(to: boundingBox.southEastCorner.coordinate) * 0.5
            let center = boundingBox.northWestCorner.coordinate.coordinate(
                bearing: boundingBox.northWestCorner.coordinate.bearing(to: boundingBox.southEastCorner.coordinate),
                distance: radius)
            if positions.count < 10 && radius < 100 {
                radius = 100
            }

            //using the bounding box directly isn't great
            let bottom = center.coordinate(bearing: 0, distance: radius * 3.15)
            mapView.setScene(MSMapScene(location: MSGeopoint(latitude: bottom.latitude, longitude: bottom.longitude), radius: radius * 2.0, heading: 0, pitch: 65), with: .none)
            //ignoring animation because of mem leak
            //mapView.setScene(MSMapScene(locations: positions.map({ MSGeopoint(position: $0) }), heading: 0, pitch: 45), with: .none)
        }
    }

    public override func onMissionLoaded(executor: MissionExecutor) {
        super.onMissionLoaded(executor: executor)
        
        DispatchQueue.main.async {
            self.updateScene()
            self.updateDroneTakeoffAltitude()
            if executor.estimated {
                self.updateMissionElements()
            }
        }
    }

    public override func onMissionUnloaded(executor: MissionExecutor) {
        super.onMissionUnloaded(executor: executor)
        
        droneMissionExecutedPositions.removeAll()
        DispatchQueue.main.async {
            self.updateMissionElements()
        }
    }

    public override func onFuncLoaded(executor: FuncExecutor) {
        super.onFuncLoaded(executor: executor)
        
        DispatchQueue.main.async {
            self.updateFuncElements()
        }
    }

    public override func onFuncUnloaded(executor: FuncExecutor) {
        super.onFuncUnloaded(executor: executor)
        
        DispatchQueue.main.async {
            self.updateFuncElements()
        }
    }

    public override func onClosed(session: DroneSession) {
        super.onClosed(session: session)
        
        droneSessionPositions.removeAll()
    }

    public override func onLocated(session: DroneSession) {
        super.onLocated(session: session)
        
        if missionExecutor?.estimating ?? false {
            return
        }

        DispatchQueue.main.async {
            self.updateScene()
            //wait 2 seconds to give the map time to load the elevation data
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                self.updateDroneTakeoffAltitude()
                self.updateMissionElements()
            }
        }
    }


    public override func onMissionEstimated(executor: MissionExecutor, estimate: MissionExecutor.Estimate) {
        super.onMissionEstimated(executor: executor, estimate: estimate)
        
        DispatchQueue.main.async {
            self.updateScene()
            self.updateMissionElements()
        }
    }

    public override func onMissionExecuted(executor: MissionExecutor, engagement: MissionExecutor.Engagement) {
        super.onMissionExecuted(executor: executor, engagement: engagement)
        
        if let state = engagement.droneSession.state?.value, let location = state.location {
            addPositionAboveDroneTakeoffLocation(positions: &droneMissionExecutedPositions, coordinate: location.coordinate, altitude: state.altitude)
        }
    }

    public override func onMissionDisengaged(executor: MissionExecutor, engagement: MissionExecutor.Engagement, reason: Kernel.Message) {
        super.onMissionDisengaged(executor: executor, engagement: engagement, reason: reason)
        
        droneMissionExecutedPositions.removeAll()
        DispatchQueue.main.async {
            self.updateMissionElements()
        }
    }

    public override func onFuncInputsChanged(executor: FuncExecutor) {
        super.onFuncInputsChanged(executor: executor)
        
        DispatchQueue.main.async {
            self.updateFuncElements()
        }
    }

    public override func onModeExecuted(executor: ModeExecutor, engagement: Executor.Engagement) {
        super.onModeExecuted(executor: executor, engagement: engagement)
        
        DispatchQueue.main.async {
            self.updateModeElements()
        }
    }

    public override func onModeDisengaged(executor: ModeExecutor, engagement: Executor.Engagement, reason: Kernel.Message) {
        super.onModeDisengaged(executor: executor, engagement: engagement, reason: reason)
        
        DispatchQueue.main.async {
            self.updateModeElements()
        }
    }
}

extension MicrosoftMapWidget: ConfigurableWidget {
    public var configurationActions: [UIAlertAction] {
        var actions: [UIAlertAction] = []
        
        actions.append(UIAlertAction(title: "MicrosoftMapWidget.reset".localized, style: .default, handler: { _ in
            self.tracking = .none
            self.trackingPrevious = .none
            self.updateScene()
        }))

        actions.append(UIAlertAction(title: "MicrosoftMapWidget.follow".localized, style: tracking == .thirdPersonNadir ? .destructive : .default, handler: { _ in
            self.tracking = .thirdPersonNadir
        }))

        actions.append(UIAlertAction(title: "MicrosoftMapWidget.chase.plane".localized, style: tracking == .thirdPersonOblique ? .destructive : .default, handler: { _ in
            self.tracking = .thirdPersonOblique
        }))

        actions.append(UIAlertAction(title: "MicrosoftMapWidget.fpv".localized, style: tracking == .firstPerson ? .destructive : .default, handler: { _ in
            self.tracking = .firstPerson
        }))

//        if tracking == .none {
//            if style == .streets {
//                actions.append(UIAlertAction(title: "MicrosoftMapWidget.satellite".localized, style: .default, handler: { _ in
//                    self.update(style: .satellite)
//                }))
//            }
//            else {
//                actions.append(UIAlertAction(title: "MicrosoftMapWidget.streets".localized, style: .default, handler: { _ in
//                    self.update(style: .streets)
//                }))
//            }
//        }
        
        return actions
    }
}

extension MSGeoposition {
    var coordinate: CLLocationCoordinate2D { CLLocationCoordinate2D(latitude: latitude, longitude: longitude) }
}
