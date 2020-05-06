//
//  MicrosoftMapViewController.swift
//  DronelinkCoreUI
//
//  Created by Jim McAndrew on 4/21/20.
//  Copyright © 2020 Dronelink. All rights reserved.
//
import UIKit
import Foundation
import Mapbox
import DronelinkCore
import MaterialComponents.MaterialPalettes
import MicrosoftMaps

public class MicrosoftMapViewController: UIViewController {
    public enum Tracking {
        case none
        case thirdPersonNadir
        case thirdPersonOblique
        case firstPerson
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
    
    public static func create(droneSessionManager: DroneSessionManager, credentialsKey: String) -> MicrosoftMapViewController {
        let mapViewController = MicrosoftMapViewController()
        mapViewController.mapView.credentialsKey = credentialsKey
        mapViewController.droneSessionManager = droneSessionManager
        return mapViewController
    }
    
    private var droneSessionManager: DroneSessionManager!
    private var session: DroneSession?
    private var missionExecutor: MissionExecutor?
    private let mapView = MSMapView()
    private let droneLayer = MSMapElementLayer()
    private let droneIcon = MSMapIcon()
    private let droneHomeIcon = MSMapIcon()
    private var droneSessionPolyline: MSMapPolyline?
    private var droneSessionPositions: [MSGeoposition] = []
    private var droneMissionExecutedPolyline: MSMapPolyline?
    private var droneMissionExecutedPositions: [MSGeoposition] = []
    private let missionStaticLayer = MSMapElementLayer()
    private let missionLayer = MSMapElementLayer()
    private let updateDroneElementsInterval: TimeInterval = 0.1
    private var updateDroneElementsTimer: Timer?
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
                self.tracking = .none
                self.trackingPrevious = .none
            }
            return true
        }
        mapView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        update(style: .streets)
        mapView.projection = MSMapProjection.globe
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
        
        updateDroneElements()
    }
    
    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        updateDroneElementsTimer = Timer.scheduledTimer(timeInterval: updateDroneElementsInterval, target: self, selector: #selector(updateDroneElements), userInfo: nil, repeats: true)
        droneSessionManager.add(delegate: self)
        Dronelink.shared.add(delegate: self)
    }
    
    public override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        updateDroneElementsTimer?.invalidate()
        updateDroneElementsTimer = nil
        droneSessionManager.remove(delegate: self)
        Dronelink.shared.remove(delegate: self)
        session?.remove(delegate: self)
        missionExecutor?.remove(delegate: self)
    }
    
    public func onMore(sender: Any, actions: [UIAlertAction]? = nil) {
        let alert = UIAlertController(title: "MicrosoftMapViewController.more".localized, message: nil, preferredStyle: .actionSheet)
        alert.popoverPresentationController?.sourceView = sender as? UIView
        
        alert.addAction(UIAlertAction(title: "MicrosoftMapViewController.reset".localized, style: .default, handler: { _ in
            self.tracking = .none
            self.trackingPrevious = .none
            self.updateScene()
        }))
        
        alert.addAction(UIAlertAction(title: "MicrosoftMapViewController.follow".localized, style: tracking == .thirdPersonNadir ? .destructive : .default, handler: { _ in
            self.tracking = .thirdPersonNadir
        }))
        
        alert.addAction(UIAlertAction(title: "MicrosoftMapViewController.chase.plane".localized, style: tracking == .thirdPersonOblique ? .destructive : .default, handler: { _ in
            self.tracking = .thirdPersonOblique
        }))
        
        alert.addAction(UIAlertAction(title: "MicrosoftMapViewController.fpv".localized, style: tracking == .firstPerson ? .destructive : .default, handler: { _ in
            self.tracking = .firstPerson
        }))
        
        if style == .streets {
            alert.addAction(UIAlertAction(title: "MicrosoftMapViewController.satellite".localized, style: .default, handler: { _ in
                self.update(style: .satellite)
            }))
        }
        else {
            alert.addAction(UIAlertAction(title: "MicrosoftMapViewController.streets".localized, style: .default, handler: { _ in
                self.update(style: .streets)
            }))
        }
        
        actions?.forEach { alert.addAction($0) }

        alert.addAction(UIAlertAction(title: "dismiss".localized, style: .cancel, handler: { _ in
            
        }))

        present(alert, animated: true)
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
    
    @objc func updateDroneElements() {
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
            var rotation = Int(-state.missionOrientation.yaw.convertRadiansToDegrees) % 360
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
                            coordinate: location.coordinate.coordinate(bearing: state.missionOrientation.yaw + Double.pi, distance: 15),
                            altitude: state.altitude + 7),
                        altitudeReferenceSystem: droneTakeoffAltitudeReferenceSystem),
                    heading: state.missionOrientation.yaw.convertRadiansToDegrees,
                    pitch: 65))
                break
                
            case .firstPerson:
                trackingScene = MSMapScene(
                    camera: MSMapCamera(
                        location: MSGeopoint(
                            position: positionAboveDroneTakeoffLocation(coordinate: location.coordinate, altitude: state.altitude),
                            altitudeReferenceSystem: droneTakeoffAltitudeReferenceSystem),
                        heading: state.missionOrientation.yaw.convertRadiansToDegrees,
                        pitch: min((session?.gimbalState(channel: 0)?.value.missionOrientation.pitch.convertRadiansToDegrees ?? 0) + 90, 90)))
                break
            }
            
            if let trackingScene = trackingScene {
                mapView.setScene(trackingScene, with: trackingPrevious == tracking ? .linear : .none)
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
            polygon.fillColor = MDCPalette.orange.accent400!.withAlphaComponent(0.3)
            polygon.shapes = [
                MSGeocircle(
                    center: MSGeoposition(coordinates: requiredTakeoffArea.coordinate.coordinate),
                    radius: requiredTakeoffArea.distanceTolerance.horizontal
                )
            ]
            missionStaticLayer.elements.add(polygon)
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
                    let radius = coordinates[0].coordinate.distance(to: coordinates[1].coordinate)
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

        if let reengagementEstimateSpatials = missionExecutor?.estimate?.reengagementSpatials, reengagementEstimateSpatials.count > 0 {
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
            if lastPosition.coordinate.distance(to: position.coordinate) < 0.01 {
                position = positionAboveDroneTakeoffLocation(coordinate: coordinate.coordinate(bearing: 0, distance: 0.01), altitude: altitude)
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
            let location = Dronelink.shared.locationManager.location {
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
            mapView.setScene(MSMapScene(location: MSGeopoint(position: MSGeoposition(coordinates: center)), radius: radius), with: animation)
        }
    }
}

extension MicrosoftMapViewController: DronelinkDelegate {
    public func onRegistered(error: String?) {}
    
    public func onMissionLoaded(executor: MissionExecutor) {
        missionExecutor = executor
        executor.add(delegate: self)
        
        DispatchQueue.main.async {
            self.updateScene()
            self.updateDroneTakeoffAltitude()
            if executor.estimated {
                self.updateMissionElements()
            }
        }
    }
    
    public func onMissionUnloaded(executor: MissionExecutor) {
        droneMissionExecutedPositions.removeAll()
        missionExecutor = nil
        executor.remove(delegate: self)
        
        DispatchQueue.main.async {
            self.updateMissionElements()
        }
    }
    
    public func onFuncLoaded(executor: FuncExecutor) {}
    
    public func onFuncUnloaded(executor: FuncExecutor) {}
}

extension MicrosoftMapViewController: DroneSessionManagerDelegate {
    public func onOpened(session: DroneSession) {
        self.session = session
        session.add(delegate: self)
    }
    
    public func onClosed(session: DroneSession) {
        droneSessionPositions.removeAll()
        self.session = nil
        session.remove(delegate: self)
    }
}

extension MicrosoftMapViewController: DroneSessionDelegate {
    public func onInitialized(session: DroneSession) {}
    
    public func onLocated(session: DroneSession) {
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
    
    public func onMotorsChanged(session: DroneSession, value: Bool) {}
    
    public func onCommandExecuted(session: DroneSession, command: MissionCommand) {}
    
    public func onCommandFinished(session: DroneSession, command: MissionCommand, error: Error?) {}
    
    public func onCameraFileGenerated(session: DroneSession, file: CameraFile) {}
}

extension MicrosoftMapViewController: MissionExecutorDelegate {
    public func onMissionEstimating(executor: MissionExecutor) {}
    
    public func onMissionEstimated(executor: MissionExecutor, estimate: MissionExecutor.Estimate) {
        DispatchQueue.main.async {
            self.updateScene()
            self.updateMissionElements()
        }
    }
    
    public func onMissionEngaging(executor: MissionExecutor) {}
    
    public func onMissionEngaged(executor: MissionExecutor, engagement: MissionExecutor.Engagement) {}
    
    public func onMissionExecuted(executor: MissionExecutor, engagement: MissionExecutor.Engagement) {
        if let state = engagement.droneSession.state?.value, let location = state.location {
            addPositionAboveDroneTakeoffLocation(positions: &droneMissionExecutedPositions, coordinate: location.coordinate, altitude: state.altitude)
        }
    }
    
    public func onMissionDisengaged(executor: MissionExecutor, engagement: MissionExecutor.Engagement, reason: Mission.Message) {
        droneMissionExecutedPositions.removeAll()
    }
}

extension MSGeoposition {
    var coordinate: CLLocationCoordinate2D { CLLocationCoordinate2D(latitude: latitude, longitude: longitude) }
}
