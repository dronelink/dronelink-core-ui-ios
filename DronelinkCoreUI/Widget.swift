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
    open override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        Dronelink.shared.add(delegate: self)
    }
    
    override open func viewDidDisappear(_ animated: Bool) {
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
    
    open func onCameraFocusCalibrationRequested(value: Kernel.CameraFocusCalibration) {}
    
    open func onCameraFocusCalibrationUpdated(value: Kernel.CameraFocusCalibration) {}
    
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
    
    open func onVideoFeedSourceUpdated(session: DroneSession, channel: UInt?) {}
    
    open func onMissionEstimating(executor: MissionExecutor) {}
    
    open func onMissionEstimated(executor: MissionExecutor, estimate: MissionExecutor.Estimate) {}
    
    open func missionEngageDisallowedReasons(executor: MissionExecutor) -> [Kernel.Message]? { nil }
    
    open func onMissionEngaging(executor: MissionExecutor) {}
    
    open func onMissionEngaged(executor: MissionExecutor, engagement: Executor.Engagement) {}
    
    open func onMissionExecuted(executor: MissionExecutor, engagement: Executor.Engagement) {}
    
    open func onMissionDisengaged(executor: MissionExecutor, engagement: Executor.Engagement, reason: Kernel.Message) {}
    
    open func onMissionUpdatedDisconnected(executor: MissionExecutor, engagement: Executor.Engagement) {}
    
    open func modeEngageDisallowedReasons(executor: ModeExecutor) -> [Kernel.Message]? { nil }
    
    open func onModeEngaging(executor: ModeExecutor) {}
    
    open func onModeEngaged(executor: ModeExecutor, engagement: Executor.Engagement) {}
    
    open func onModeExecuted(executor: ModeExecutor, engagement: Executor.Engagement) {}
    
    open func onModeDisengaged(executor: ModeExecutor, engagement: Executor.Engagement, reason: Kernel.Message) {}
    
    open func onFuncInputsChanged(executor: FuncExecutor) {}
    
    open func onFuncExecuted(executor: FuncExecutor) {}
}

extension UIView {
    public func createWidget(shadow: Bool = false) -> Widget {
        let widget = Widget()
        widget.view.addSubview(self)
        snp.makeConstraints { [weak self] make in
            make.edges.equalToSuperview()
        }
        
        if shadow {
            widget.view.addShadow()
        }
        
        return widget
    }
    
    public func createWidget(shadow: Bool = false, channel: UInt?) -> ChannelWidget {
        let widget = DefaultChannelWidget()
        widget.channel = channel
        widget.view.addSubview(self)
        snp.makeConstraints { [weak self] make in
            make.edges.equalToSuperview()
        }
        
        if shadow {
            widget.view.addShadow()
        }
        
        return widget
    }
}

open class ViewControllerWidget: Widget {
    private var _viewController: UIViewController?
    
    public var viewController: UIViewController? {
        get { _viewController }
        set {
            if let viewController = newValue {
                viewController.install(inParent: self)
                viewController.view.snp.makeConstraints { [weak self] make in
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

open class ChannelViewControllerWidget: ViewControllerWidget, ChannelWidget {
    public var channel: UInt? { get { _channel } set { _channel = newValue } }
    private var _channel: UInt?
    public var channelResolved: UInt { channel ?? session?.drone.cameraChannel(videoFeedChannel: nil) ?? 0 }
}

extension UIViewController {
    public func createWidget() -> ViewControllerWidget {
        let widget = ViewControllerWidget()
        widget.viewController = self
        return widget
    }
    
    public func createWidget(channel: UInt?) -> ChannelViewControllerWidget {
        let widget = ChannelViewControllerWidget()
        widget.viewController = self
        widget.channel = channel
        return widget
    }
}

open class UpdatableWidget: DelegateWidget {
    open var updateInterval: TimeInterval { 1.0 }
    public var updateTimer: Timer?
    
    override open func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        update()
        updateTimer = Timer.scheduledTimer(timeInterval: updateInterval, target: self, selector: #selector(update), userInfo: nil, repeats: true)
    }
    
    override open func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        updateTimer?.invalidate()
        updateTimer = nil
    }
    
    override open func updateViewConstraints() {
        super.updateViewConstraints()
        update()
    }
    
    @objc open func update() {}
}

public protocol ChannelWidget: Widget {
    var channel: UInt? { get set }
    var channelResolved: UInt { get }
}

open class DefaultChannelWidget: Widget, ChannelWidget {
    public var channel: UInt? { get { _channel } set { _channel = newValue } }
    private var _channel: UInt?
    public var channelResolved: UInt { channel ?? session?.drone.cameraChannel(videoFeedChannel: nil) ?? 0 }
}

open class UpdatableChannelWidget: UpdatableWidget, ChannelWidget {
    public var channel: UInt? { get { _channel } set { _channel = newValue } }
    private var _channel: UInt?
    public var channelResolved: UInt { channel ?? session?.drone.cameraChannel(videoFeedChannel: nil) ?? 0 }
}

open class CameraWidget: UpdatableChannelWidget {
    public var state: CameraStateAdapter? { session?.cameraState(channel: channelResolved)?.value }
}

open class GimbalWidget: UpdatableChannelWidget {
    public var state: GimbalStateAdapter? { session?.gimbalState(channel: channelResolved)?.value }
}

public enum DynamicSizeWidgetLayout: String {
    case small = "small",
         medium = "medium",
         large = "large"
}

public protocol DynamicSizeWidget: Widget {
    var layout: DynamicSizeWidgetLayout { get }
    var preferredSize: CGSize { get }
}

public protocol ConfigurableWidget {
    var configurationActions: [UIAlertAction] { get }
}

public protocol ExecutorWidget: DynamicSizeWidget {}

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
    open func videoFeedWidgetEnabled(channel: UInt?) -> Bool { false }
    open func createVideoFeedWidget(channel: UInt? = nil, current: Widget? = nil, overlays: Bool = true) -> Widget? { nil }
    open func createMainMenuWidget(current: Widget? = nil) -> Widget? { nil }
    open func createStatusBackgroundWidget(current: Widget? = nil) -> Widget? { (current as? StatusGradientWidget) ?? StatusGradientWidget() }
    open func createStatusForegroundWidget(current: Widget? = nil) -> Widget?  { (current as? StatusLabelWidget) ?? StatusLabelWidget() }
    open func createRemainingFlightTimeWidget(current: Widget? = nil) -> Widget? { nil }
    open func createFlightModeWidget(current: Widget? = nil) -> Widget? { (current as? FlightModeWidget) ?? FlightModeWidget() }
    open func createGPSWidget(current: Widget? = nil) -> Widget? { (current as? GPSWidget) ?? GPSWidget() }
    open func createVisionWidget(current: Widget? = nil) -> Widget? { nil }
    open func createUplinkWidget(current: Widget? = nil) -> Widget? { (current as? UplinkWidget) ?? UplinkWidget() }
    open func createDownlinkWidget(current: Widget? = nil) -> Widget? { (current as? DownlinkWidget) ?? DownlinkWidget() }
    open func createBatteryWidget(current: Widget? = nil) -> Widget? { (current as? BatteryWidget) ?? BatteryWidget() }
    open func createDistanceWidget(current: Widget? = nil) -> Widget? { (current as? DistanceWidget) ?? DistanceWidget()  }
    open func createDistanceHomeWidget(current: Widget? = nil) -> Widget? { (current as? DistanceHomeWidget) ?? DistanceHomeWidget() }
    open func createDistanceUserWidget(current: Widget? = nil) -> Widget? { (current as? DistanceUserWidget) ?? DistanceUserWidget() }
    open func createAltitudeWidget(current: Widget? = nil) -> Widget? { (current as? AltitudeWidget) ?? AltitudeWidget() }
    open func createHorizontalSpeedWidget(current: Widget? = nil) -> Widget? { (current as? HorizontalSpeedWidget) ?? HorizontalSpeedWidget() }
    open func createVerticalSpeedWidget(current: Widget? = nil) -> Widget? { (current as? VerticalSpeedWidget) ?? VerticalSpeedWidget() }
    open func createTelemetryWidget(current: Widget? = nil) -> Widget? { (current as? TelemetryWidget) ?? TelemetryWidget() }
    open func cameraMenuWidgetEnabled(channel: UInt? = nil) -> Bool { false }
    open func createDefaultIndicatorsWidget(channel: UInt? = nil, current: ChannelWidget? = nil) -> ChannelWidget? { channelWidget(channel: channel, widget: (current as? DefaultIndicatorsWidget) ?? DefaultIndicatorsWidget()) }
    open func createCameraMenuWidget(channel: UInt? = nil, current: ChannelWidget? = nil) -> ChannelWidget? { nil }
    open func createCameraExposureWidget(channel: UInt? = nil, current: ChannelWidget? = nil) -> ChannelWidget? { channelWidget(channel: channel, widget: (current as? CameraExposureWidget) ?? CameraExposureWidget()) }
    open func createCameraISOWidget(channel: UInt? = nil, current: ChannelWidget? = nil) -> ChannelWidget? { channelWidget(channel: channel, widget: (current as? CameraISOWidget) ?? CameraISOWidget()) }
    open func createCameraShutterWidget(channel: UInt? = nil, current: ChannelWidget? = nil) -> ChannelWidget? { channelWidget(channel: channel, widget: (current as? CameraShutterWidget) ?? CameraShutterWidget()) }
    open func createCameraApertureWidget(channel: UInt? = nil, current: ChannelWidget? = nil) -> ChannelWidget? { channelWidget(channel: channel, widget: (current as? CameraApertureWidget) ?? CameraApertureWidget()) }
    open func createCameraExposureCompensationWidget(channel: UInt? = nil, current: ChannelWidget? = nil) -> ChannelWidget? { channelWidget(channel: channel, widget: (current as? CameraExposureCompensationWidget) ?? CameraExposureCompensationWidget()) }
    open func createCameraWhiteBalanceWidget(channel: UInt? = nil, current: ChannelWidget? = nil) -> ChannelWidget? { channelWidget(channel: channel, widget: (current as? CameraWhiteBalanceWidget) ?? CameraWhiteBalanceWidget()) }
    open func createCameraFocusRingWidget(channel: UInt? = nil, current: ChannelWidget? = nil) -> ChannelWidget? { channelWidget(channel: channel, widget: (current as? CameraFocusRingWidget) ?? CameraFocusRingWidget()) }
    open func createCameraStorageWidget(channel: UInt? = nil, current: ChannelWidget? = nil) -> ChannelWidget? { nil }
    open func createCameraAutoExposureWidget(channel: UInt? = nil, current: ChannelWidget? = nil) -> ChannelWidget? { nil }
    open func createCameraExposureFocusWidget(channel: UInt? = nil, current: ChannelWidget? = nil) -> ChannelWidget? { nil }
    open func createCameraFocusModeWidget(channel: UInt? = nil, current: ChannelWidget? = nil) -> ChannelWidget? { nil }
    open func createCameraModeWidget(channel: UInt? = nil, current: ChannelWidget? = nil) -> ChannelWidget? { channelWidget(channel: channel, widget: (current as? CameraModeWidget) ?? CameraModeWidget()) }
    open func createCameraCaptureWidget(channel: UInt? = nil, current: ChannelWidget? = nil) -> ChannelWidget?  { channelWidget(channel: channel, widget: (current as? CameraCaptureWidget) ?? CameraCaptureWidget()) }
    open func createCameraVideoStreamSourceWidget(channel: UInt? = nil, current: ChannelWidget? = nil) -> ChannelWidget? { nil }
    open func createCameraFocusCalibrationWidget(channel: UInt? = nil, current: ChannelWidget? = nil, calibration: Kernel.CameraFocusCalibration) -> ChannelWidget? {
        if let widget = current as? CameraFocusCalibrationWidget {
            return widget
        }
        
        let widget = CameraFocusCalibrationWidget()
        widget.calibration = calibration
        return widget
    }
    open func cameraExposureMenuWidgetEnabled(channel: UInt? = nil) -> Bool { false }
    open func createCameraExposureMenuWidget(channel: UInt? = nil, current: ChannelWidget? = nil) -> ChannelWidget? { nil }
    open func createGimbalOrientationWidget(channel: UInt? = nil, current: ChannelWidget? = nil) -> ChannelWidget? { channelWidget(channel: channel, widget: (current as? GimbalOrientationWidget) ?? GimbalOrientationWidget()) }
    open func createCompassWidget(current: Widget? = nil) -> Widget? { nil }
    open func createRTKStatusWidget(current: Widget? = nil) -> Widget? { nil }
    open func createRTKMenuWidget(current: Widget? = nil) -> Widget? { nil }
    
    open func channelWidget(channel: UInt? = nil, widget: ChannelWidget) -> ChannelWidget {
        widget.channel = channel
        return widget
    }
}
