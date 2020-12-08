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

open class Widget: UIViewController {
    public var droneSessionManager: DroneSessionManager?
    
    public var targetDroneSessionManager: DroneSessionManager? {
        droneSessionManager ?? Dronelink.shared.targetDroneSessionManager
    }
    
    public var session: DroneSession? { targetDroneSessionManager?.session }
    public var missionExecutor: MissionExecutor? { Dronelink.shared.missionExecutor }
    public var modeExecutor: ModeExecutor? { Dronelink.shared.modeExecutor }
    public var funcExecutor: FuncExecutor? { Dronelink.shared.funcExecutor }
    public var widgetFactory: WidgetFactory { (targetDroneSessionManager as? WidgetFactoryProvider)?.widgetFactory ?? WidgetFactory.shared }
    public var portrait: Bool { return UIScreen.main.bounds.width < UIScreen.main.bounds.height }
    public var tablet: Bool { return UIDevice.current.userInterfaceIdiom == .pad }
    public let defaultPadding: CGFloat = 10
}

open class DelegateWidget: Widget, DronelinkDelegate, DroneSessionManagerDelegate, DroneSessionDelegate, MissionExecutorDelegate, ModeExecutorDelegate, FuncExecutorDelegate {
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

    open func onRegistered(error: String?) {}
    
    open func onDroneSessionManagerAdded(manager: DroneSessionManager) {
        manager.add(delegate: self)
    }
    
    open func onMissionLoaded(executor: MissionExecutor) {
        executor.add(delegate: self)
    }
    
    open func onMissionUnloaded(executor: MissionExecutor) {
        executor.remove(delegate: self)
    }
    
    open func onFuncLoaded(executor: FuncExecutor) {
        executor.add(delegate: self)
    }
    
    open func onFuncUnloaded(executor: FuncExecutor) {
        executor.remove(delegate: self)
    }
    
    open func onModeLoaded(executor: ModeExecutor) {
        executor.add(delegate: self)
    }
    
    open func onModeUnloaded(executor: ModeExecutor) {
        executor.remove(delegate: self)
    }

    open func onOpened(session: DroneSession) {
        session.add(delegate: self)
    }
    
    open func onClosed(session: DroneSession) {
        session.remove(delegate: self)
    }
    
    open func onInitialized(session: DroneSession) {}
    
    open func onLocated(session: DroneSession) {}
    
    open func onMotorsChanged(session: DroneSession, value: Bool) {}
    
    open func onCommandExecuted(session: DroneSession, command: KernelCommand) {}
    
    open func onCommandFinished(session: DroneSession, command: KernelCommand, error: Error?) {}
    
    open func onCameraFileGenerated(session: DroneSession, file: CameraFile) {}
    
    open func onMissionEstimating(executor: MissionExecutor) {}
    
    open func onMissionEstimated(executor: MissionExecutor, estimate: MissionExecutor.Estimate) {}
    
    open func onMissionEngaging(executor: MissionExecutor) {}
    
    open func onMissionEngaged(executor: MissionExecutor, engagement: Executor.Engagement) {}
    
    open func onMissionExecuted(executor: MissionExecutor, engagement: Executor.Engagement) {}
    
    open func onMissionDisengaged(executor: MissionExecutor, engagement: Executor.Engagement, reason: Kernel.Message) {}
    
    open func onModeEngaging(executor: ModeExecutor) {}
    
    open func onModeEngaged(executor: ModeExecutor, engagement: Executor.Engagement) {}
    
    open func onModeExecuted(executor: ModeExecutor, engagement: Executor.Engagement) {}
    
    open func onModeDisengaged(executor: ModeExecutor, engagement: Executor.Engagement, reason: Kernel.Message) {}
    
    open func onFuncInputsChanged(executor: FuncExecutor) {}
    
    open func onFuncExecuted(executor: FuncExecutor) {}
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

open class WrapperWidget: Widget {
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

open class UpdatableWidget: DelegateWidget {
    public var updateInterval: TimeInterval { 1.0 }
    public var updateTimer: Timer?
    
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
    
    @objc open func update() {}
}

public enum ExecutorWidgetLayout: String {
    case small = "small",
         medium = "medium",
         large = "large"
}

public protocol ExecutorWidget: Widget {
    var layout: ExecutorWidgetLayout { get }
    var preferredSize: CGSize { get }
}

public protocol ConfigurableWidget {
    var configurationActions: [UIAlertAction] { get }
}

public protocol WidgetFactoryProvider {
    var widgetFactory: WidgetFactory? { get }
}

open class WidgetFactory {
    public static let shared = WidgetFactory()
    
    public let session: DroneSession?
    
    public init(session: DroneSession? = nil) {
        self.session = session
    }
    
    open func createExecutorWidget(current: ExecutorWidget? = nil) -> ExecutorWidget? {
        if Dronelink.shared.executor is MissionExecutor {
            return (current as? MissionExecutorWidget) ?? MissionExecutorWidget()
        }
        
        if Dronelink.shared.executor is ModeExecutor {
            return (current as? ModeExecutorWidget) ?? ModeExecutorWidget()
        }

        if Dronelink.shared.executor is FuncExecutor {
            return (current as? FuncExecutorWidget) ?? FuncExecutorWidget()
        }
        
        return nil
    }
    open func createMainMenuWidget(current: Widget? = nil) -> Widget? { nil }
    open func createCameraFeedWidget(current: Widget? = nil, primary: Bool = true) -> Widget? { nil }
    open func createStatusBackgroundWidget(current: Widget? = nil) -> Widget? { (current as? StatusGradientWidget) ?? StatusGradientWidget() }
    open func createStatusForegroundWidget(current: Widget? = nil) -> Widget?  { (current as? StatusLabelWidget) ?? StatusLabelWidget() }
    open func createRemainingFlightTimeWidget(current: Widget? = nil) -> Widget? { nil }
    open func createFlightModeWidget(current: Widget? = nil) -> Widget? { nil }
    open func createGPSWidget(current: Widget? = nil) -> Widget? { nil }
    open func createVisionWidget(current: Widget? = nil) -> Widget? { nil }
    open func createUplinkWidget(current: Widget? = nil) -> Widget? { nil }
    open func createDownlinkWidget(current: Widget? = nil) -> Widget? { nil }
    open func createBatteryWidget(current: Widget? = nil) -> Widget? { nil }
    open func createDistanceWidget(current: Widget? = nil) -> Widget? { (current as? DistanceWidget) ?? DistanceWidget()  }
    open func createDistanceHomeWidget(current: Widget? = nil) -> Widget? { (current as? DistanceHomeWidget) ?? DistanceHomeWidget() }
    open func createDistanceUserWidget(current: Widget? = nil) -> Widget? { (current as? DistanceUserWidget) ?? DistanceUserWidget() }
    open func createAltitudeWidget(current: Widget? = nil) -> Widget? { (current as? AltitudeWidget) ?? AltitudeWidget() }
    open func createHorizontalSpeedWidget(current: Widget? = nil) -> Widget? { (current as? HorizontalSpeedWidget) ?? HorizontalSpeedWidget() }
    open func createVerticalSpeedWidget(current: Widget? = nil) -> Widget? { (current as? VerticalSpeedWidget) ?? VerticalSpeedWidget() }
    open func createTelemetryWidget(current: Widget? = nil) -> Widget? { (current as? TelemetryWidget) ?? TelemetryWidget() }
    open func createCameraGeneralSettingsWidget(current: Widget? = nil) -> Widget? { nil }
    open func createCameraExposureWidget(current: Widget? = nil) -> Widget? { nil }
    open func createCameraStorageWidget(current: Widget? = nil) -> Widget? { nil }
    open func createCameraAutoExposureWidget(current: Widget? = nil) -> Widget? { nil }
    open func createCameraExposureFocusWidget(current: Widget? = nil) -> Widget? { nil }
    open func createCameraFocusModeWidget(current: Widget? = nil) -> Widget? { nil }
    open func createCameraModeWidget(current: Widget? = nil) -> Widget? { nil }
    open func createCameraCaptureWidget(current: Widget? = nil) -> Widget? { nil }
    open func createCameraExposureSettingsWidget(current: Widget? = nil) -> Widget? { nil }
    open func createCompassWidget(current: Widget? = nil) -> Widget? { nil }
    open func createRTKStatusWidget(current: Widget? = nil) -> Widget? { nil }
    open func createRTKSettingsWidget(current: Widget? = nil) -> Widget? { nil }
}
