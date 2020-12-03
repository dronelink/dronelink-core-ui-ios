//
//  Widget.swift
//  DronelinkCoreUI
//
//  Created by Jim McAndrew on 12/1/20.
//  Copyright © 2020 Dronelink. All rights reserved.
//
import UIKit
import Foundation
import DronelinkCore

public class Widget: UIViewController {
    public var droneSessionManager: DroneSessionManager?
    
    internal var primaryDroneSessionManager: DroneSessionManager? {
        if let droneSessionManager = droneSessionManager {
            return droneSessionManager
        }
        
        for droneSessionManager in Dronelink.shared.droneSessionManagers {
            if droneSessionManager.session != nil {
                return droneSessionManager
            }
        }
        
        return Dronelink.shared.droneSessionManagers.first
    }
    
    internal var session: DroneSession? { primaryDroneSessionManager?.session }
    internal var missionExecutor: MissionExecutor? { Dronelink.shared.missionExecutor }
    internal var modeExecutor: ModeExecutor? { Dronelink.shared.modeExecutor }
    internal var funcExecutor: FuncExecutor? { Dronelink.shared.funcExecutor }
    internal var widgetFactory: WidgetFactory { primaryDroneSessionManager as? WidgetFactory ?? GenericWidgetFactory.shared }
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        view.clipsToBounds = true
    }
}

public class DelegateWidget: Widget, DronelinkDelegate, DroneSessionManagerDelegate, DroneSessionDelegate, MissionExecutorDelegate, ModeExecutorDelegate, FuncExecutorDelegate {
    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        Dronelink.shared.add(delegate: self)
    }
    
    override public func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        Dronelink.shared.remove(delegate: self)
        Dronelink.shared.missionExecutor?.remove(delegate: self)
        Dronelink.shared.modeExecutor?.remove(delegate: self)
        Dronelink.shared.funcExecutor?.remove(delegate: self)
        Dronelink.shared.droneSessionManagers.forEach {
            $0.remove(delegate: self)
            $0.session?.remove(delegate: self)
        }
    }

    public func onRegistered(error: String?) {}
    
    public func onDroneSessionManagerAdded(manager: DroneSessionManager) {
        manager.add(delegate: self)
    }
    
    public func onMissionLoaded(executor: MissionExecutor) {
        executor.add(delegate: self)
    }
    
    public func onMissionUnloaded(executor: MissionExecutor) {
        executor.remove(delegate: self)
    }
    
    public func onFuncLoaded(executor: FuncExecutor) {
        executor.add(delegate: self)
    }
    
    public func onFuncUnloaded(executor: FuncExecutor) {
        executor.remove(delegate: self)
    }
    
    public func onModeLoaded(executor: ModeExecutor) {
        executor.add(delegate: self)
    }
    
    public func onModeUnloaded(executor: ModeExecutor) {
        executor.remove(delegate: self)
    }

    public func onOpened(session: DroneSession) {
        session.add(delegate: self)
    }
    
    public func onClosed(session: DroneSession) {
        session.remove(delegate: self)
    }
    
    public func onInitialized(session: DroneSession) {}
    
    public func onLocated(session: DroneSession) {}
    
    public func onMotorsChanged(session: DroneSession, value: Bool) {}
    
    public func onCommandExecuted(session: DroneSession, command: KernelCommand) {}
    
    public func onCommandFinished(session: DroneSession, command: KernelCommand, error: Error?) {}
    
    public func onCameraFileGenerated(session: DroneSession, file: CameraFile) {}
    
    public func onMissionEstimating(executor: MissionExecutor) {}
    
    public func onMissionEstimated(executor: MissionExecutor, estimate: MissionExecutor.Estimate) {}
    
    public func onMissionEngaging(executor: MissionExecutor) {}
    
    public func onMissionEngaged(executor: MissionExecutor, engagement: Executor.Engagement) {}
    
    public func onMissionExecuted(executor: MissionExecutor, engagement: Executor.Engagement) {}
    
    public func onMissionDisengaged(executor: MissionExecutor, engagement: Executor.Engagement, reason: Kernel.Message) {}
    
    public func onModeEngaging(executor: ModeExecutor) {}
    
    public func onModeEngaged(executor: ModeExecutor, engagement: Executor.Engagement) {}
    
    public func onModeExecuted(executor: ModeExecutor, engagement: Executor.Engagement) {}
    
    public func onModeDisengaged(executor: ModeExecutor, engagement: Executor.Engagement, reason: Kernel.Message) {}
    
    public func onFuncInputsChanged(executor: FuncExecutor) {}
    
    public func onFuncExecuted(executor: FuncExecutor) {}
}

extension UIView {
    public func createWidget() -> Widget {
        let widget = Widget()
        widget.view.addSubview(self)
        snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        return widget
    }
}

public class WrapperWidget: Widget {
    private var _viewController: UIViewController?
    
    public var viewController: UIViewController? {
        get { _viewController }
        set {
            if let viewController = newValue {
                viewController.install(inParent: self)
                viewController.view.snp.makeConstraints { make in
                    make.edges.equalToSuperview()
                }
                _viewController = viewController
            }
            else {
                _viewController?.uninstallFromParent()
                _viewController = nil
            }
        }
    }
}

extension UIViewController {
    public func createWidget() -> WrapperWidget {
        let widget = WrapperWidget()
        widget.viewController = self
        return widget
    }
}

public class UpdatableWidget: DelegateWidget {
    internal var updateInterval: TimeInterval { 1.0 }
    internal var updateTimer: Timer?
    
    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        update()
        updateTimer = Timer.scheduledTimer(timeInterval: updateInterval, target: self, selector: #selector(update), userInfo: nil, repeats: true)
    }
    
    override public func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        updateTimer?.invalidate()
        updateTimer = nil
    }
    
    public override func updateViewConstraints() {
        super.updateViewConstraints()
        update()
    }
    
    @objc func update() {}
}

public protocol WidgetFactory {
    func createMainMenuWidget(current: Widget?) -> Widget?
    func createCameraFeedWidget(current: Widget?, primary: Bool) -> Widget?
    func createStatusBackgroundWidget(current: Widget?) -> Widget?
    func createStatusForegroundWidget(current: Widget?) -> Widget?
    func createRemainingFlightTimeWidget(current: Widget?) -> Widget?
    func createFlightModeWidget(current: Widget?) -> Widget?
    func createGPSWidget(current: Widget?) -> Widget?
    func createVisionWidget(current: Widget?) -> Widget?
    func createUplinkWidget(current: Widget?) -> Widget?
    func createDownlinkWidget(current: Widget?) -> Widget?
    func createBatteryWidget(current: Widget?) -> Widget?
    func createDistanceUserWidget(current: Widget?) -> Widget?
    func createDistanceHomeWidget(current: Widget?) -> Widget?
    func createAltitudeWidget(current: Widget?) -> Widget?
    func createHorizontalSpeedWidget(current: Widget?) -> Widget?
    func createVerticalSpeedWidget(current: Widget?) -> Widget?
    func createCameraGeneralSettingsWidget(current: Widget?) -> Widget?
    func createCameraModeWidget(current: Widget?) -> Widget?
    func createCameraCaptureWidget(current: Widget?) -> Widget?
    func createCameraExposureSettingsWidget(current: Widget?) -> Widget?
    func createCompassWidget(current: Widget?) -> Widget?
}

public class GenericWidgetFactory: WidgetFactory {
    public static let shared = GenericWidgetFactory()
    
    public func createMainMenuWidget(current: Widget? = nil) -> Widget? { nil }
    public func createCameraFeedWidget(current: Widget? = nil, primary: Bool = true) -> Widget? { nil }
    public func createStatusBackgroundWidget(current: Widget? = nil) -> Widget? { (current as? StatusGradientWidget) ?? StatusGradientWidget() }
    public func createStatusForegroundWidget(current: Widget? = nil) -> Widget?  { (current as? StatusLabelWidget) ?? StatusLabelWidget() }
    public func createRemainingFlightTimeWidget(current: Widget? = nil) -> Widget? { nil }
    public func createFlightModeWidget(current: Widget? = nil) -> Widget? { nil }
    public func createGPSWidget(current: Widget? = nil) -> Widget? { nil }
    public func createVisionWidget(current: Widget? = nil) -> Widget? { nil }
    public func createUplinkWidget(current: Widget? = nil) -> Widget? { nil }
    public func createDownlinkWidget(current: Widget? = nil) -> Widget? { nil }
    public func createBatteryWidget(current: Widget? = nil) -> Widget? { nil }
    public func createDistanceUserWidget(current: Widget? = nil) -> Widget? { nil }
    public func createDistanceHomeWidget(current: Widget? = nil) -> Widget? { nil }
    public func createAltitudeWidget(current: Widget? = nil) -> Widget? { nil }
    public func createHorizontalSpeedWidget(current: Widget? = nil) -> Widget? { nil }
    public func createVerticalSpeedWidget(current: Widget? = nil) -> Widget? { nil }
    public func createCameraGeneralSettingsWidget(current: Widget? = nil) -> Widget? { nil }
    public func createCameraModeWidget(current: Widget? = nil) -> Widget? { nil }
    public func createCameraCaptureWidget(current: Widget? = nil) -> Widget? { nil }
    public func createCameraExposureSettingsWidget(current: Widget? = nil) -> Widget? { nil }
    public func createCompassWidget(current: Widget? = nil) -> Widget? { nil }
}
