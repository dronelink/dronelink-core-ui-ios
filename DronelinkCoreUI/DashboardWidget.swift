//
//  DashboardWidget.swift
//  DronelinkCoreUI
//
//  Created by Jim McAndrew on 12/2/20.
//  Copyright © 2020 Dronelink. All rights reserved.
//
import UIKit
import Foundation
import DronelinkCore
import SwiftyUserDefaults
import MaterialComponents

extension DefaultsKeys {
    var dronelinkDashboardWidgetContentView1Source: DefaultsKey<String> { .init("dronelinkDashboardWidget.contentView1.source", defaultValue: ContentViewSource.videoFeed0.rawValue) }
    var dronelinkDashboardWidgetContentView2Source: DefaultsKey<String> { .init("dronelinkDashboardWidget.contentView2.source", defaultValue: ContentViewSource.map.rawValue) }
    var dronelinkDashboardWidgetContentView3Source: DefaultsKey<String> { .init("dronelinkDashboardWidget.contentView3.source", defaultValue: ContentViewSource.videoFeed1.rawValue) }
    var dronelinkDashboardWidgetMapStyle: DefaultsKey<String> { .init("dronelinkDashboardWidget.mapStyle", defaultValue: MapStyle.mapbox.rawValue) }
}


extension DashboardWidget {
    private var contentView1Source: ContentViewSource {
        get { (ContentViewSource(rawValue: Defaults[\.dronelinkDashboardWidgetContentView1Source]) ?? .videoFeed0) }
        set { Defaults[\.dronelinkDashboardWidgetContentView1Source] = newValue.rawValue }
    }
    
    private var contentView2Source: ContentViewSource {
        get { (ContentViewSource(rawValue: Defaults[\.dronelinkDashboardWidgetContentView2Source]) ?? .map) }
        set { Defaults[\.dronelinkDashboardWidgetContentView2Source] = newValue.rawValue }
    }
    
    private var contentView3Source: ContentViewSource {
        get { (ContentViewSource(rawValue: Defaults[\.dronelinkDashboardWidgetContentView3Source]) ?? .videoFeed1) }
        set { Defaults[\.dronelinkDashboardWidgetContentView3Source] = newValue.rawValue }
    }
    
    private var mapStyle: MapStyle {
        get { MapStyle(rawValue: Defaults[\.dronelinkDashboardWidgetMapStyle]) ?? .mapbox }
        set { Defaults[\.dronelinkDashboardWidgetMapStyle] = newValue.rawValue }
    }
}

private enum ContentViewSource: String {
    case videoFeed0 = "videoFeed0",
         videoFeed1 = "videoFeed1",
         map = "map",
         none = "none"
}

private enum MapStyle: String {
    case mapbox = "mapbox",
         microsoft = "microsoft",
         none = "none"
}

public class DashboardWidget: DelegateWidget {
    public static func create(microsoftMapCredentialsKey: String? = nil) -> DashboardWidget {
        let dashboardViewController = DashboardWidget()
        dashboardViewController.microsoftMapCredentialsKey = microsoftMapCredentialsKey
        dashboardViewController.modalPresentationStyle = .fullScreen
        return dashboardViewController
    }
    
    private var statusWidgetHeight: CGFloat { return tablet ? 50 : 40 }
    
    private var microsoftMapCredentialsKey: String?
    
    private let _dismissButton = UIButton(type: .custom)
    public var dismissButton: UIButton { _dismissButton }
    
    private let topBarView = UIView()
    private let reticleImageView = UIImageView()
    private let contentViewHideImage = DronelinkUI.loadImage(named: "eye-off")
    private let contentView2ShowImage = DronelinkUI.loadImage(named: "baseline_map_white_36pt")
    private let contentView3ShowImage = DronelinkUI.loadImage(named: "camera-plus-outline")
    private let contentView2SettingsButton = UIButton(type: .custom)
    private let contentView2VisibilityButton = UIButton(type: .custom)
    private let contentView2SourceButton = UIButton(type: .custom)
    private let contentView3SettingsButton = UIButton(type: .custom)
    private let contentView3VisibilityButton = UIButton(type: .custom)
    private let contentView3SourceButton = UIButton(type: .custom)
    private let contentView1 = UIView()
    private let contentView2 = UIView()
    private let contentView3 = UIView()
    private let cameraControlsView = UIView()
    private let cameraMenuButton = UIButton(type: .custom)
    private let cameraExposureMenuButton = UIButton(type: .custom)
    private let offsetsButton = UIButton(type: .custom)
    private var offsetsButtonEnabled = false
    private var overlayViewController: UIViewController?
    private let hideOverlayButton = UIButton(type: .custom)
    private let disconnectedImageView = UIImageView()
    private var videoFeed0Widget: Widget?
    private var videoFeed1Widget: Widget?
    private var mapWidget: Widget?
    private var videoFeed0ContentView: UIView? {
        get {
            if portrait && contentView1Source == .map {
                return contentView1
            }
            
            return contentView(source: .videoFeed0)
        }
    }
    private var videoFeed1ContentView: UIView? {
        get {
            if portrait && contentView1Source == .map {
                return contentView2
            }
            return contentView(source: .videoFeed1)
        }
    }
    private var mapContentView: UIView? { get { portrait ? contentView2 : contentView(source: .map) } }
    private func contentView(source: ContentViewSource) -> UIView? {
        if contentView1Source == source {
            return contentView1
        }
        
        if contentView2Source == source {
            return contentView2
        }
        
        if contentView3Source == source {
            return contentView3
        }
        
        return nil
    }
    private var cameraChannel: UInt? {
        if !widgetFactory.videoFeedWidgetEnabled(channel: 1) {
            return nil
        }
        
        return session?.drone.cameraChannel(videoFeedChannel: contentView(source: .videoFeed1) == contentView1 ? 1 : 0)
    }
    private var statusBackgroundWidget: Widget?
    private var statusForegroundWidget: Widget?
    private var remainingFlightTimeWidget: Widget?
    private var flightModeWidget: Widget?
    private var gpsWidget: Widget?
    private var visionWidget: Widget?
    private var uplinkWidget: Widget?
    private var downlinkWidget: Widget?
    private var batteryWidget: Widget?
    private var primaryIndicatorWidgets: [(widget: Widget, widthRatio: CGFloat)] {
        var widgets: [(widget: Widget, widthRatio: CGFloat)] = []
        if let widget = flightModeWidget { widgets.append((widget: widget, widthRatio: 4)) }
        if let widget = gpsWidget { widgets.append((widget: widget, widthRatio: 2.5)) }
        if let widget = visionWidget { widgets.append((widget: widget, widthRatio: 1.35)) }
        if let widget = uplinkWidget { widgets.append((widget: widget, widthRatio: 2.5)) }
        if let widget = downlinkWidget { widgets.append((widget: widget, widthRatio: 2.5)) }
        if let widget = batteryWidget { widgets.append((widget: widget, widthRatio: 3.4)) }
        return widgets
    }
    private var cameraAutoExposureWidget: ChannelWidget?
    private var cameraExposureFocusWidget: ChannelWidget?
    private var cameraFocusModeWidget: ChannelWidget?
    private var cameraFocusRingWidget: ChannelWidget?
    private var cameraStorageWidget: ChannelWidget?
    private var defaultIndicatorsWidget: ChannelWidget?
    private var indicatorWidgets: [(widget: ChannelWidget, width: Bool)] {
        var widgets: [(widget: ChannelWidget, width: Bool)] = []
        if let widget = cameraFocusRingWidget { widgets.append((widget: widget, width: false)) }
        if let widget = defaultIndicatorsWidget { widgets.append((widget: widget, width: false)) }
        if let widget = cameraStorageWidget { widgets.append((widget: widget, width: false)) }
        if let widget = cameraAutoExposureWidget { widgets.append((widget: widget, width: true)) }
        if let widget = cameraExposureFocusWidget { widgets.append((widget: widget, width: true)) }
        if let widget = cameraFocusModeWidget { widgets.append((widget: widget, width: true)) }
        return widgets
    }
    private var cameraModeWidget: ChannelWidget?
    private var cameraCaptureWidget: ChannelWidget?
    private var cameraVideoStreamSourceWidget: ChannelWidget?
    private var compassWidget: Widget?
    private var telemetryWidget: Widget?
    private var executorWidget: ExecutorWidget?
    private var cameraFocusCalibrationWidget: (ChannelWidget & DynamicSizeWidget)?
    private var activityWidget: DynamicSizeWidget? { cameraFocusCalibrationWidget ?? executorWidget }
    private var activityWidgetLayout: DynamicSizeWidgetLayout { activityWidget?.layout ?? .small }
    private var droneOffsetsWidget1: Widget?
    private var droneOffsetsWidget2: Widget?
    private var cameraOffsetsWidget: Widget?
    private var rtkStatusWidget: Widget?
    private var debugWidget: Widget?
    
    public override func viewDidLoad() {
        super.viewDidLoad()

        if #available(iOS 13.0, *) {
            overrideUserInterfaceStyle = .dark
        }

        view.backgroundColor = UIColor.black
        
        hideOverlayButton.addTarget(self, action: #selector(onHideOverlay(sender:)), for: .touchUpInside)
        view.addSubview(hideOverlayButton)
        hideOverlayButton.snp.makeConstraints { [weak self] make in
            make.edges.equalToSuperview()
        }

        view.addSubview(contentView1)
        
        reticleImageView.isUserInteractionEnabled = false
        reticleImageView.contentMode = .scaleAspectFit
        view.addSubview(reticleImageView)
        reticleImageView.snp.makeConstraints { [weak self] make in
            make.center.equalTo(contentView1)
            make.height.equalTo(contentView1)
        }
        
        contentView2.addShadow()
        view.addSubview(contentView2)
        
        contentView3.addShadow()
        view.addSubview(contentView3)
        
        disconnectedImageView.setImage(DronelinkUI.loadImage(named: "baseline_usb_white_48pt")!)
        disconnectedImageView.tintColor = UIColor.white
        disconnectedImageView.alpha = 0.5
        disconnectedImageView.contentMode = .center
        contentView1.addSubview(disconnectedImageView)
        disconnectedImageView.snp.makeConstraints { [weak self] make in
            make.edges.equalToSuperview()
        }
        
        contentView2SettingsButton.addShadow()
        contentView2SettingsButton.tintColor = UIColor.white
        contentView2SettingsButton.setImage(DronelinkUI.loadImage(named: "baseline_settings_white_36pt"), for: .normal)
        contentView2SettingsButton.addTarget(self, action: #selector(onContentView2Settings(sender:)), for: .touchUpInside)
        view.addSubview(contentView2SettingsButton)
        contentView2SettingsButton.snp.remakeConstraints { [weak self] make in
            make.left.equalTo(contentView2.snp.left).offset(defaultPadding)
            make.top.equalTo(contentView2.snp.top).offset(defaultPadding)
            make.width.equalTo(30)
            make.height.equalTo(contentView2SettingsButton.snp.width)
        }

        contentView2VisibilityButton.addShadow()
        contentView2VisibilityButton.tintColor = UIColor.white
        contentView2VisibilityButton.setImage(contentView2ShowImage, for: .normal)
        contentView2VisibilityButton.addTarget(self, action: #selector(onContentView2Visibility(sender:)), for: .touchUpInside)
        view.addSubview(contentView2VisibilityButton)
        contentView2VisibilityButton.snp.remakeConstraints { [weak self] make in
            make.left.equalTo(contentView2.snp.left).offset(defaultPadding)
            make.bottom.equalTo(contentView2.snp.bottom).offset(-defaultPadding)
            make.width.equalTo(30)
            make.height.equalTo(contentView2VisibilityButton.snp.width)
        }
        
        contentView2SourceButton.addShadow()
        contentView2SourceButton.tintColor = UIColor.white
        contentView2SourceButton.setImage(DronelinkUI.loadImage(named: "vector-arrange-below"), for: .normal)
        contentView2SourceButton.addTarget(self, action: #selector(onContentView2Source(sender:)), for: .touchUpInside)
        view.addSubview(contentView2SourceButton)
        contentView2SourceButton.snp.remakeConstraints { [weak self] make in
            make.right.equalTo(contentView2.snp.right).offset(-defaultPadding)
            make.top.equalTo(contentView2.snp.top).offset(defaultPadding)
            make.width.equalTo(30)
            make.height.equalTo(contentView2SourceButton.snp.width)
        }

        view.addSubview(cameraControlsView)
        
        contentView3SettingsButton.addShadow()
        contentView3SettingsButton.tintColor = UIColor.white
        contentView3SettingsButton.setImage(DronelinkUI.loadImage(named: "baseline_settings_white_36pt"), for: .normal)
        contentView3SettingsButton.addTarget(self, action: #selector(onContentView3Settings(sender:)), for: .touchUpInside)
        view.addSubview(contentView3SettingsButton)
        contentView3SettingsButton.snp.remakeConstraints { [weak self] make in
            make.right.equalTo(contentView3.snp.right).offset(-defaultPadding)
            make.top.equalTo(contentView3.snp.top).offset(defaultPadding)
            make.width.equalTo(30)
            make.height.equalTo(contentView3SettingsButton.snp.width)
        }

        contentView3VisibilityButton.addShadow()
        contentView3VisibilityButton.tintColor = UIColor.white
        contentView3VisibilityButton.setImage(contentView3ShowImage, for: .normal)
        contentView3VisibilityButton.addTarget(self, action: #selector(onContentView3Visibility(sender:)), for: .touchUpInside)
        view.addSubview(contentView3VisibilityButton)
        
        contentView3SourceButton.addShadow()
        contentView3SourceButton.tintColor = UIColor.white
        contentView3SourceButton.setImage(DronelinkUI.loadImage(named: "vector-arrange-below"), for: .normal)
        contentView3SourceButton.addTarget(self, action: #selector(onContentView3Source(sender:)), for: .touchUpInside)
        view.addSubview(contentView3SourceButton)
        contentView3SourceButton.snp.remakeConstraints { [weak self] make in
            make.left.equalTo(contentView3.snp.left).offset(defaultPadding)
            make.top.equalTo(contentView3.snp.top).offset(defaultPadding)
            make.width.equalTo(30)
            make.height.equalTo(contentView3SourceButton.snp.width)
        }

        view.addSubview(cameraControlsView)
        
        cameraMenuButton.addShadow()
        cameraMenuButton.setTitle("DashboardWidget.cameraMenu".localized, for: .normal)
        cameraMenuButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: 13)
        cameraMenuButton.addTarget(self, action: #selector(onCameraMenu(sender:)), for: .touchUpInside)
        cameraControlsView.addSubview(cameraMenuButton)
        cameraMenuButton.snp.makeConstraints { [weak self] make in
            make.top.equalTo(0)
            make.centerX.equalToSuperview()
            make.height.equalTo(48)
            make.width.equalTo(48)
        }
        
        cameraExposureMenuButton.addShadow()
        cameraExposureMenuButton.tintColor = UIColor.white
        cameraExposureMenuButton.setImage(DronelinkUI.loadImage(named: "baseline_tune_white_36pt"), for: .normal)
        cameraExposureMenuButton.addTarget(self, action: #selector(onCameraExposureMenu(sender:)), for: .touchUpInside)
        cameraControlsView.addSubview(cameraExposureMenuButton)
        cameraExposureMenuButton.snp.makeConstraints { [weak self] make in
            make.bottom.equalToSuperview().offset(-12)
            make.centerX.equalToSuperview()
            make.height.equalTo(28)
            make.width.equalTo(28)
        }
        
        offsetsButton.addShadow()
        offsetsButton.setImage(DronelinkUI.loadImage(named: "baseline_control_camera_white_36pt"), for: .normal)
        offsetsButton.addTarget(self, action: #selector(onOffsets(sender:)), for: .touchUpInside)
        view.addSubview(offsetsButton)
        offsetsButton.snp.makeConstraints { [weak self] make in
            make.top.equalTo(cameraControlsView.snp.bottom).offset(15)
            make.centerX.equalTo(cameraControlsView.snp.centerX)
            make.height.equalTo(28)
            make.width.equalTo(28)
        }
        
        let droneOffsetsWidget = DroneOffsetsWidget()
        droneOffsetsWidget.styles = tablet ? [.position] : [.altYaw, .position]
        droneOffsetsWidget.view.isHidden = true
        droneOffsetsWidget.install(inParent: self)
        self.droneOffsetsWidget1 = droneOffsetsWidget
        
        if tablet {
            let droneOffsetsWidget = DroneOffsetsWidget()
            droneOffsetsWidget.styles = [.altYaw]
            droneOffsetsWidget.view.isHidden = true
            droneOffsetsWidget.install(inParent: self)
            self.droneOffsetsWidget2 = droneOffsetsWidget
        }
        
        let cameraOffsetsWidget = CameraOffsetsWidget()
        cameraOffsetsWidget.install(inParent: self)
        self.cameraOffsetsWidget = cameraOffsetsWidget
        
        droneOffsetsWidget1?.view.isHidden = true
        droneOffsetsWidget2?.view.isHidden = true
        cameraOffsetsWidget.view.isHidden = true

        view.addSubview(topBarView)
        topBarView.snp.makeConstraints { [weak self] make in
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top)
            make.left.equalToSuperview()
            make.right.equalToSuperview()
            make.height.equalTo(statusWidgetHeight)
        }

        dismissButton.addShadow()
        dismissButton.tintColor = UIColor.white
        dismissButton.setImage(DronelinkUI.loadImage(named: "dronelink-logo"), for: .normal)
        dismissButton.imageView?.contentMode = .scaleAspectFit
        dismissButton.imageEdgeInsets = UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8)
        dismissButton.addTarget(self, action: #selector(onDismiss(sender:)), for: .touchUpInside)
        view.addSubview(dismissButton)
        dismissButton.snp.makeConstraints { [weak self] make in
            make.left.equalTo(view.safeAreaLayoutGuide.snp.left)
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top)
            make.width.equalTo(statusWidgetHeight * 1.25)
            make.height.equalTo(statusWidgetHeight)
        }
    }
    
    var debug = false
    var previousDebugTap = Date()
    var consecutiveDebugTaps = 0
    @objc func debugTapHandler(gesture: UITapGestureRecognizer) {
        if -previousDebugTap.timeIntervalSinceNow < 0.5 {
            consecutiveDebugTaps += 1
            NSLog("Debug taps \(consecutiveDebugTaps)")
            if consecutiveDebugTaps >= 7 {
                debug = !debug
                consecutiveDebugTaps = 0
                view.setNeedsUpdateConstraints()
            }
        }
        else {
            consecutiveDebugTaps = 1
        }
        previousDebugTap = Date()
    }
    
    override public func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        view.setNeedsUpdateConstraints()
    }
    
    override public func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        view.setNeedsUpdateConstraints()
    }
    
    func onMainMenu() {
        if let widget = widgetFactory.createMainMenuWidget(current: nil) {
            if let wrapperWidget = widget as? ViewControllerWidget {
                wrapperWidget.viewController?.modalPresentationStyle = .formSheet
            }
            present(widget, animated: true, completion: nil)
        }
    }
    
    @objc func onCameraMenu(sender: Any) {
        if let widget = widgetFactory.createCameraMenuWidget(channel: cameraChannel) {
            showOverlay(viewController: widget)
        }
    }
    
    @objc func onCameraExposureMenu(sender: Any) {
        if let widget = widgetFactory.createCameraExposureMenuWidget(channel: cameraChannel) {
            showOverlay(viewController: widget)
        }
    }
    
    @objc func onOffsets(sender: Any) {
        toggleOffsets(visible: droneOffsetsWidget1?.view.isHidden ?? false)
    }
    
    private func toggleOffsets(visible: Bool?) {
        if let visible = visible {
            droneOffsetsWidget1?.view.isHidden = !visible
            droneOffsetsWidget2?.view.isHidden = !visible
            cameraOffsetsWidget?.view.isHidden = !visible
            view.setNeedsUpdateConstraints()
        }
    }
    
    private func showOverlay(viewController: UIViewController) {
        overlayViewController = viewController
        addChild(viewController)
        view.addSubview(viewController.view)
        viewController.didMove(toParent: self)
        viewController.view.addShadow()
        
        view.bringSubviewToFront(hideOverlayButton)
        if let overlayView = overlayViewController?.view {
            view.bringSubviewToFront(overlayView)
            overlayView.snp.remakeConstraints { [weak self] make in
                let bounds = UIScreen.main.bounds
                let width = min(bounds.width - 30, max(bounds.width / 2, 400))
                make.centerX.equalToSuperview()
                make.centerY.equalToSuperview()
                make.width.equalTo(width)
                make.height.equalTo(min(bounds.height - 125, width))
            }
        }
        
        hideOverlayButton.isHidden = false
    }
    
    @objc func onHideOverlay(sender: Any!) {
        overlayViewController?.removeFromParent()
        overlayViewController?.view.removeFromSuperview()
        overlayViewController = nil
        hideOverlayButton.isHidden = true
    }
    
    @objc func onContentView2Settings(sender: Any) {
        let alert = UIAlertController(title: "DashboardWidget.contentView2.settings".localized, message: nil, preferredStyle: .actionSheet)
        alert.popoverPresentationController?.sourceView = sender as? UIView
        
        if mapWidget is MicrosoftMapWidget {
            alert.addAction(UIAlertAction(title: "DashboardWidget.map.mapbox".localized, style: .default, handler: { [weak self] _ in
                self?.mapStyle = .mapbox
                self?.view.setNeedsUpdateConstraints()
            }))
        }
        else if mapWidget is MapboxMapWidget {
            alert.addAction(UIAlertAction(title: "DashboardWidget.map.microsoft".localized, style: .default, handler: { [weak self] _ in
                self?.mapStyle = .microsoft
                self?.view.setNeedsUpdateConstraints()
            }))
        }

        (mapWidget as? ConfigurableWidget)?.configurationActions.forEach { alert.addAction($0) }

        alert.addAction(UIAlertAction(title: "dismiss".localized, style: .cancel, handler: { _ in

        }))

        present(alert, animated: true)
    }
    
    @objc func onContentView2Visibility(sender: Any) {
        contentView2Source = contentView2Source == .none ? .map : .none
        if contentView1Source == .map {
            contentView1Source = contentView3Source == .videoFeed1 ? .videoFeed0 : .videoFeed1
        }
        view.setNeedsUpdateConstraints()
    }
    
    @objc func onContentView2Source(sender: Any) {
        if contentView2Source == .map {
            contentView1Source = .map
            contentView2Source = .videoFeed0
            contentView3Source = .videoFeed1
        }
        else {
            contentView1Source = .videoFeed0
            contentView2Source = .map
            contentView3Source = .videoFeed1
        }
        view.setNeedsUpdateConstraints()
    }
    
    @objc func onContentView3Settings(sender: Any) {
        let alert = UIAlertController(title: "DashboardWidget.contentView3.settings".localized, message: nil, preferredStyle: .actionSheet)
        alert.popoverPresentationController?.sourceView = sender as? UIView
        
        (videoFeed1Widget as? ConfigurableWidget)?.configurationActions.forEach { alert.addAction($0) }

        alert.addAction(UIAlertAction(title: "dismiss".localized, style: .cancel, handler: { _ in

        }))

        present(alert, animated: true)
    }
    
    @objc func onContentView3Visibility(sender: Any) {
        if contentView3Source == .none {
            contentView3Source = contentView1Source == .videoFeed0 ? .videoFeed1 : .videoFeed0
        }
        else {
            contentView3Source = .none
        }
        view.setNeedsUpdateConstraints()
    }
    
    @objc func onContentView3Source(sender: Any) {
        if contentView1Source == .map {
            contentView1Source = contentView3Source
            contentView2Source = .map
            contentView3Source = contentView1Source == .videoFeed0 ? .videoFeed1 : .videoFeed0
        }
        
        let source1 = contentView1Source
        let source2 = contentView2Source
        contentView1Source = contentView3Source
        if source1 == .map {
            contentView2Source = .map
            contentView3Source = source2
        }
        else {
            contentView3Source = source1
        }
        view.setNeedsUpdateConstraints()
        
        updateRemoteControllerTargetGimbalChannel()
    }
    
    @objc func onDismiss(sender: Any) {
        Dronelink.shared.unload()
        dismiss(animated: true)
    }
    
    open override func onCameraFocusCalibrationRequested(value: Kernel.CameraFocusCalibration) {
        super.onCameraFocusCalibrationRequested(value: value)
        
        DispatchQueue.main.async { [weak self] in
            self?.cameraFocusCalibrationWidget = self?.refreshWidget(current: self?.cameraFocusCalibrationWidget, next: self?.widgetFactory.createCameraFocusCalibrationWidget(channel: self?.cameraChannel, calibration: value)) as? (ChannelWidget & DynamicSizeWidget)
            self?.view.setNeedsUpdateConstraints()
        }
    }
    
    open override func onCameraFocusCalibrationUpdated(value: Kernel.CameraFocusCalibration) {
        super.onCameraFocusCalibrationUpdated(value: value)
        
        DispatchQueue.main.async { [weak self] in
            self?.cameraFocusCalibrationWidget = self?.refreshWidget(current: self?.cameraFocusCalibrationWidget, next: nil) as? (ChannelWidget & DynamicSizeWidget)
            self?.view.setNeedsUpdateConstraints()
        }
    }
    
    open override func onOpened(session: DroneSession) {
        super.onOpened(session: session)
        DispatchQueue.main.async { [weak self] in self?.view.setNeedsUpdateConstraints() }
    }
    
    open override func onClosed(session: DroneSession) {
        super.onClosed(session: session)
        DispatchQueue.main.async { [weak self] in self?.view.setNeedsUpdateConstraints() }
    }
    
    open override func onInitialized(session: DroneSession) {
        super.onInitialized(session: session)
        
        if let cameraState = session.cameraState(channel: 0), !cameraState.value.isSDCardInserted {
            DronelinkUI.shared.showDialog(title: "DashboardWidget.camera.noSDCard.title".localized, details: "DashboardWidget.camera.noSDCard.details".localized)
        }
    }
    
    open override func onMissionLoaded(executor: MissionExecutor) {
        super.onMissionLoaded(executor: executor)
        DispatchQueue.main.async { [weak self] in self?.apply(userInterfaceSettings: executor.userInterfaceSettings) }
    }
    
    open override func onMissionUnloaded(executor: MissionExecutor) {
        super.onMissionUnloaded(executor: executor)
        DispatchQueue.main.async { [weak self] in self?.apply(userInterfaceSettings: nil) }
    }
    
    open override func onMissionEngaging(executor: MissionExecutor) {
        super.onMissionEngaging(executor: executor)
        DispatchQueue.main.async { [weak self] in
            self?.updateDismissButton()
            self?.view.setNeedsUpdateConstraints()
        }
    }
    
    open override func onMissionEngaged(executor: MissionExecutor, engagement: Executor.Engagement) {
        super.onMissionEngaged(executor: executor, engagement: engagement)
        DispatchQueue.main.async { [weak self] in
            self?.updateDismissButton()
            self?.view.setNeedsUpdateConstraints()
        }
    }
    
    open override func onMissionDisengaged(executor: MissionExecutor, engagement: Executor.Engagement, reason: Kernel.Message) {
        super.onMissionDisengaged(executor: executor, engagement: engagement, reason: reason)
        DispatchQueue.main.async { [weak self] in
            self?.updateDismissButton()
            self?.view.setNeedsUpdateConstraints()
        }
    }
    
    open override func onModeLoaded(executor: ModeExecutor) {
        super.onModeLoaded(executor: executor)
        DispatchQueue.main.async { [weak self] in self?.apply(userInterfaceSettings: executor.userInterfaceSettings) }
    }
    
    open override func onModeUnloaded(executor: ModeExecutor) {
        super.onModeUnloaded(executor: executor)
        DispatchQueue.main.async { [weak self] in self?.apply(userInterfaceSettings: nil) }
    }
    
    open override func onModeEngaging(executor: ModeExecutor) {
        super.onModeEngaging(executor: executor)
        DispatchQueue.main.async { [weak self] in self?.updateDismissButton() }
    }
    
    open override func onModeEngaged(executor: ModeExecutor, engagement: Executor.Engagement) {
        super.onModeEngaged(executor: executor, engagement: engagement)
        DispatchQueue.main.async { [weak self] in self?.updateDismissButton() }
    }
    
    open override func onModeDisengaged(executor: ModeExecutor, engagement: Executor.Engagement, reason: Kernel.Message) {
        super.onModeDisengaged(executor: executor, engagement: engagement, reason: reason)
        DispatchQueue.main.async { [weak self] in self?.updateDismissButton() }
    }
    
    open override func onFuncLoaded(executor: FuncExecutor) {
        super.onFuncLoaded(executor: executor)
        DispatchQueue.main.async { [weak self] in self?.apply(userInterfaceSettings: executor.userInterfaceSettings) }
    }
    
    open override func onFuncUnloaded(executor: FuncExecutor) {
        super.onFuncUnloaded(executor: executor)
        DispatchQueue.main.async { [weak self] in
            if Dronelink.shared.executor == nil {
                self?.apply(userInterfaceSettings: nil)
            }
            else {
                self?.view.setNeedsUpdateConstraints()
            }
        }
    }
    
    private func refreshWidget<W: Widget>(current: W? = nil, next: W? = nil, subview: UIView? = nil) -> W? {
        let subview: UIView = subview ?? view
        if current != next {
            current?.uninstallFromParent()
            next?.install(inParent: self, insideSubview: subview)
        }
        
        if let next = next {
            if next.view.superview != subview {
                next.view.removeFromSuperview()
                subview.addSubview(next.view)
            }
        }
        
        return next
    }
    
    private func apply(userInterfaceSettings: Kernel.UserInterfaceSettings?) {
        reticleImageView.image = nil
        if let reticleImageUrl = userInterfaceSettings?.reticleImageUrl {
            reticleImageView.kf.setImage(with: URL(string: reticleImageUrl))
        }
        
        if let droneOffsetsVisible = userInterfaceSettings?.droneOffsetsVisible {
            offsetsButtonEnabled = droneOffsetsVisible
            toggleOffsets(visible: droneOffsetsVisible)
        }
        else {
            offsetsButtonEnabled = false
            toggleOffsets(visible: false)
        }
        
        view.setNeedsUpdateConstraints()
    }
    
    private func refreshWidgets() {
        if let videoFeed0ContentView = videoFeed0ContentView {
            videoFeed0Widget = refreshWidget(current: videoFeed0Widget, next: widgetFactory.createVideoFeedWidget(channel: 0, current: videoFeed0Widget), subview: videoFeed0ContentView)
        }
        else {
            videoFeed0Widget = refreshWidget(current: videoFeed0Widget, next: nil)
        }
        videoFeed0Widget?.view.snp.remakeConstraints { [weak self] make in
            make.edges.equalToSuperview()
        }
        
        if let mapContentView = mapContentView, mapStyle != .none {
            switch mapStyle {
            case .mapbox:
                mapWidget = refreshWidget(current: mapWidget, next: (mapWidget as? MapboxMapWidget) ?? MapboxMapWidget(), subview: mapContentView)
                break

            case .microsoft:
                mapWidget = refreshWidget(current: mapWidget, next: (mapWidget as? MicrosoftMapWidget) ?? MicrosoftMapWidget(), subview: mapContentView)
                (mapWidget as? MicrosoftMapWidget)?.mapView.credentialsKey = microsoftMapCredentialsKey ?? ""
                break

            case .none:
                break
            }
        }
        else {
            mapWidget = refreshWidget(current: mapWidget, next: nil)
        }
        mapWidget?.view.snp.remakeConstraints { [weak self] make in
            make.edges.equalToSuperview()
        }
        
        if let videoFeed1ContentView = videoFeed1ContentView {
            videoFeed1Widget = refreshWidget(current: videoFeed1Widget, next: widgetFactory.createVideoFeedWidget(channel: 1, current: videoFeed1Widget), subview: videoFeed1ContentView)
        }
        else {
            videoFeed1Widget = refreshWidget(current: videoFeed1Widget, next: nil)
        }
        videoFeed1Widget?.view.snp.remakeConstraints { [weak self] make in
            make.edges.equalToSuperview()
        }

        remainingFlightTimeWidget = refreshWidget(current: remainingFlightTimeWidget, next: widgetFactory.createRemainingFlightTimeWidget(current: remainingFlightTimeWidget))
        remainingFlightTimeWidget?.view.snp.remakeConstraints { [weak self] make in
            let topOffset = -9
            if portrait, !tablet, let videoFeedView = videoFeed0Widget?.view {
                make.top.equalTo(videoFeedView.snp.top).offset(topOffset)
            }
            else {
                make.top.equalTo(topBarView.snp.bottom).offset(topOffset)
            }
            make.left.equalTo(topBarView.snp.left)
            make.right.equalTo(topBarView.snp.right)
        }
        
        flightModeWidget = refreshWidget(current: flightModeWidget, next: widgetFactory.createFlightModeWidget(current: flightModeWidget))
        gpsWidget = refreshWidget(current: gpsWidget, next: widgetFactory.createGPSWidget(current: gpsWidget))
        visionWidget = refreshWidget(current: visionWidget, next: widgetFactory.createVisionWidget(current: visionWidget))
        uplinkWidget = refreshWidget(current: uplinkWidget, next: widgetFactory.createUplinkWidget(current: uplinkWidget))
        downlinkWidget = refreshWidget(current: downlinkWidget, next: widgetFactory.createDownlinkWidget(current: downlinkWidget))
        batteryWidget = refreshWidget(current: batteryWidget, next: widgetFactory.createBatteryWidget(current: batteryWidget))
        
        var primaryIndicatorWidgetPrevious: Widget?
        primaryIndicatorWidgets.reversed().forEach { item in
            item.widget.view.snp.remakeConstraints { [weak self] make in
                let paddingRight: CGFloat = tablet ? 9 : 7
                if let widgetPrevious = primaryIndicatorWidgetPrevious {
                    make.right.equalTo(widgetPrevious.view.snp.left).offset(-paddingRight)
                }
                else {
                    make.right.equalTo(view.safeAreaLayoutGuide.snp.right).offset(-paddingRight)
                }
                let topPadding: CGFloat = 0.25
                make.top.equalTo(topBarView.snp.top).offset((portrait && !tablet ? statusWidgetHeight : 0) + (statusWidgetHeight * topPadding))
                let height = statusWidgetHeight * (1 - (2 * topPadding))
                make.height.equalTo(height)
                make.width.equalTo(item.widget.view.snp.height).multipliedBy(item.widthRatio)
                
            }
            primaryIndicatorWidgetPrevious = item.widget
        }
        
        statusBackgroundWidget = refreshWidget(current: statusBackgroundWidget, next: widgetFactory.createStatusBackgroundWidget(current: statusBackgroundWidget), subview: topBarView)
        statusBackgroundWidget?.view.snp.remakeConstraints { [weak self] make in
            make.edges.equalToSuperview()
        }

        statusForegroundWidget = refreshWidget(current: statusForegroundWidget, next: widgetFactory.createStatusForegroundWidget(current: statusForegroundWidget), subview: topBarView)
        statusForegroundWidget?.view.snp.remakeConstraints {  [weak self] make in
            let constrainTo: UIView = statusBackgroundWidget?.view ?? view
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top)
            make.left.equalTo(dismissButton.snp.right).offset(5)
            if (portrait && !tablet) {
                make.right.equalTo(view.safeAreaLayoutGuide.snp.right)
            }
            else {
                make.right.equalTo(primaryIndicatorWidgetPrevious?.view.snp.left ?? constrainTo.snp.right).offset(-defaultPadding)
            }
            make.height.equalTo(statusWidgetHeight)
        }
        (statusForegroundWidget as? StatusLabelWidget)?.onTapped = { [weak self] in self?.onMainMenu() }
        
        //cameraFocusRingWidget = refreshWidget(current: cameraFocusRingWidget, next: widgetFactory.createCameraFocusRingWidget(channel: cameraChannel, current: cameraFocusRingWidget)) as? ChannelWidget
        
        defaultIndicatorsWidget = refreshWidget(current: defaultIndicatorsWidget, next: widgetFactory.createDefaultIndicatorsWidget(channel: cameraChannel, current: defaultIndicatorsWidget)) as? ChannelWidget
        
        cameraStorageWidget = refreshWidget(current: cameraStorageWidget, next: widgetFactory.createCameraStorageWidget(channel: cameraChannel, current: cameraStorageWidget)) as? ChannelWidget
        
        cameraAutoExposureWidget = refreshWidget(current: cameraAutoExposureWidget, next: widgetFactory.createCameraAutoExposureWidget(channel: cameraChannel, current: cameraAutoExposureWidget)) as? ChannelWidget
        
        cameraExposureFocusWidget = refreshWidget(current: cameraExposureFocusWidget, next: widgetFactory.createCameraExposureFocusWidget(channel: cameraChannel, current: cameraExposureFocusWidget)) as? ChannelWidget
        
        cameraFocusModeWidget = refreshWidget(current: cameraFocusModeWidget, next: widgetFactory.createCameraFocusModeWidget(channel: cameraChannel, current: cameraFocusModeWidget)) as? ChannelWidget
        
        let cameraWidgetSize = statusWidgetHeight * 0.65
        var indicatorWidgetPrevious: Widget?
        indicatorWidgets.reversed().forEach { item in
            item.widget.view.snp.remakeConstraints {  [weak self] make in
                if let previousWidget = indicatorWidgetPrevious {
                    make.top.equalTo(previousWidget.view.snp.top)
                    make.right.equalTo(previousWidget.view.snp.left).offset(-defaultPadding / 2)
                }
                else {
                    make.top.equalTo((primaryIndicatorWidgetPrevious?.view ?? topBarView).snp.bottom).offset(portrait && !tablet ? 14 : 20)
                    make.right.equalToSuperview().offset(portrait && !tablet ? -5 : -defaultPadding)
                }
                make.height.equalTo(cameraWidgetSize)
                if item.width {
                    make.width.equalTo(cameraWidgetSize)
                }
            }
            
            indicatorWidgetPrevious = item.widget
        }
        
        cameraModeWidget = refreshWidget(current: cameraModeWidget, next: widgetFactory.createCameraModeWidget(channel: cameraChannel, current: cameraModeWidget), subview: cameraControlsView) as? ChannelWidget
        cameraModeWidget?.view.snp.remakeConstraints { [weak self] make in
            make.top.equalTo(cameraMenuButton.snp.bottom).offset(-13)
            make.left.equalToSuperview().offset(3)
            make.height.equalTo(cameraModeWidget!.view.snp.width)
            make.right.equalToSuperview().offset(-3)
        }

        cameraCaptureWidget = refreshWidget(current: cameraCaptureWidget, next: widgetFactory.createCameraCaptureWidget(channel: cameraChannel, current: cameraCaptureWidget), subview: cameraControlsView) as? ChannelWidget
        cameraCaptureWidget?.view.snp.remakeConstraints {  [weak self] make in
            make.left.equalToSuperview().offset(defaultPadding)
            make.right.equalToSuperview().offset(-defaultPadding)
            make.height.equalTo(cameraCaptureWidget!.view.snp.width).offset(20)
            make.bottom.equalTo(cameraExposureMenuButton.snp.top).offset(-5)
        }
        
        cameraVideoStreamSourceWidget = refreshWidget(current: cameraVideoStreamSourceWidget, next: widgetFactory.createCameraVideoStreamSourceWidget(channel: cameraChannel, current: cameraVideoStreamSourceWidget)) as? ChannelWidget
        cameraVideoStreamSourceWidget?.view.snp.remakeConstraints { [weak self] make in
            make.bottom.equalTo(cameraControlsView.snp.top).offset(4)
            make.centerX.equalTo(cameraControlsView.snp.centerX)
            make.height.equalTo(25)
            make.width.equalTo(25)
        }

        compassWidget = refreshWidget(current: compassWidget, next: widgetFactory.createCompassWidget(current: compassWidget))
       
        telemetryWidget = refreshWidget(current: telemetryWidget, next: widgetFactory.createTelemetryWidget(current: telemetryWidget))
        if telemetryWidget?.view.gestureRecognizers == nil {
            let debugGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(debugTapHandler))
            telemetryWidget?.view.addGestureRecognizer(debugGestureRecognizer)
        }
        
        executorWidget = refreshWidget(current: executorWidget, next: widgetFactory.createExecutorWidget(current: executorWidget)) as? ExecutorWidget
        
        rtkStatusWidget = refreshWidget(current: rtkStatusWidget, next: widgetFactory.createRTKStatusWidget(current: rtkStatusWidget))
        rtkStatusWidget?.view.snp.remakeConstraints { [weak self] make in
            if let telemetryWidget = telemetryWidget {
                make.bottom.equalTo(telemetryWidget.view.snp.top).offset(-defaultPadding)
                make.left.equalTo(telemetryWidget.view.snp.left)
            }
            else {
                make.bottom.equalTo(contentView2.snp.bottom)
                make.left.equalTo(contentView2.snp.right).offset(defaultPadding)
            }
            make.height.equalTo(cameraWidgetSize)
            make.width.equalTo(100)
        }
        
        debugWidget = refreshWidget(current: debugWidget, next: debug ? DebugWidget() : nil)
        
        if let widget = droneOffsetsWidget1 {
            view.bringSubviewToFront(widget.view)
        }
        
        if let widget = droneOffsetsWidget2 {
            view.bringSubviewToFront(widget.view)
        }
        
        if let widget = cameraOffsetsWidget {
            view.bringSubviewToFront(widget.view)
        }
    }
    
    func updateDismissButton() {
        dismissButton.isEnabled = !(Dronelink.shared.engaged || Dronelink.shared.missionExecutor?.engaging ?? false || Dronelink.shared.modeExecutor?.engaging ?? false)
    }
    
    public override func updateViewConstraints() {
        super.updateViewConstraints()

        refreshWidgets()
        
        disconnectedImageView.isHidden = true //session != nil

        let darkBackground = UIColor(red: 20, green: 20, blue: 20)
        let darkerBackground = UIColor(red: 10, green: 10, blue: 10)
        contentView1.backgroundColor = contentView1 == mapContentView ? darkBackground : darkerBackground
        contentView1.snp.remakeConstraints { [weak self] make in
            if (portrait && !tablet) {
                make.top.equalTo(topBarView.safeAreaLayoutGuide.snp.bottom).offset(statusWidgetHeight * 2)
            }
            else {
                make.top.equalTo(view.safeAreaLayoutGuide.snp.top)
            }

            if (portrait) {
                make.left.equalToSuperview()
                make.right.equalToSuperview()
                make.height.equalTo(UIScreen.main.bounds.width * 2/3)
            }
            else {
                make.left.equalToSuperview()
                make.right.equalToSuperview()
                make.bottom.equalToSuperview()
            }
        }

        contentView2.isHidden = contentView2Source == .none
        contentView2.backgroundColor = contentView1 == videoFeed0Widget?.view ? darkBackground : darkerBackground
        contentView2.snp.remakeConstraints { [weak self] make in
            if (portrait) {
                make.top.equalTo(contentView1.snp.bottom).offset(tablet ? 0 : statusWidgetHeight * 2)
                make.right.equalToSuperview()
                make.left.equalToSuperview()
                make.bottom.equalToSuperview()
            }
            else {
                if tablet {
                    make.width.equalTo(view.snp.width).multipliedBy(activityWidgetLayout == .large ? 0.30 : 0.4)
                }
                else {
                    make.width.equalTo(view.snp.width).multipliedBy(activityWidgetLayout == .large ? 0.18 : 0.28)
                }

                make.height.equalTo(contentView2.snp.width).multipliedBy(0.5)
                make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom).offset(-defaultPadding)
                if !portrait, activityWidgetLayout == .large, let activityWidget = activityWidget {
                    make.left.equalTo(activityWidget.view.snp.right).offset(defaultPadding)
                }
                else {
                    make.left.equalTo(view.safeAreaLayoutGuide.snp.left).offset(defaultPadding)
                }
            }
        }
        
        contentView2SettingsButton.isHidden = contentView2.isHidden || mapContentView != contentView2
        contentView2VisibilityButton.isHidden = portrait
        contentView2VisibilityButton.setImage(contentView2Source == .none ? contentView2ShowImage : contentViewHideImage, for: .normal)
        contentView2SourceButton.isHidden = portrait || contentView2.isHidden
        
        contentView3.isHidden = session == nil || contentView3Source == .none || (contentView3Source == .videoFeed1 && !widgetFactory.videoFeedWidgetEnabled(channel: 1))
        contentView3.backgroundColor = contentView3Source == .videoFeed0 ? darkBackground : darkerBackground
        contentView3.snp.remakeConstraints { [weak self] make in
            if (portrait) {
                make.right.equalTo(view.safeAreaLayoutGuide.snp.right).offset(-defaultPadding)
                make.top.equalTo(contentView2.snp.top).offset(defaultPadding)
                make.height.equalTo(contentView2.snp.height).multipliedBy(0.3)
            }
            else {
                make.bottom.equalTo(contentView2.snp.bottom)
                make.height.equalTo(contentView2.snp.height).multipliedBy(0.75)
                if tablet {
                    make.right.equalTo(view.safeAreaLayoutGuide.snp.right).offset(-defaultPadding)
                }
                else {
                    make.right.equalTo(cameraExposureMenuButton.snp.left).offset(-defaultPadding)
                }
            }
            make.width.equalTo(contentView3.snp.height).multipliedBy(1.5)
        }
        
        contentView3SettingsButton.isHidden = contentView3.isHidden
        contentView3VisibilityButton.isHidden = !widgetFactory.videoFeedWidgetEnabled(channel: 1)
        contentView3VisibilityButton.setImage(contentView3Source == .none ? contentView3ShowImage : contentViewHideImage, for: .normal)
        contentView3VisibilityButton.snp.remakeConstraints { [weak self] make in
            if contentView3.isHidden {
                make.left.equalTo(compassWidget?.view.snp.left ?? view.safeAreaLayoutGuide.snp.left).offset(-20)
                make.bottom.equalTo(compassWidget?.view.snp.bottom ?? view.safeAreaLayoutGuide.snp.bottom)
            }
            else {
                make.left.equalTo(contentView3.snp.left).offset(defaultPadding)
                make.bottom.equalTo(contentView3.snp.bottom).offset(-defaultPadding)
            }
            make.width.equalTo(30)
            make.height.equalTo(contentView3VisibilityButton.snp.width)
        }
        contentView3SourceButton.isHidden = contentView3.isHidden
        
        cameraMenuButton.isHidden = !widgetFactory.videoFeedWidgetEnabled(channel: cameraChannel)
        cameraExposureMenuButton.isHidden = !widgetFactory.cameraExposureMenuWidgetEnabled(channel: cameraChannel)

        cameraControlsView.snp.remakeConstraints { [weak self] make in
            make.centerY.equalTo(contentView1.snp.centerY)
            if (portrait || tablet) {
                make.right.equalTo(view.safeAreaLayoutGuide.snp.right).offset(-defaultPadding)
            }
            else {
                make.right.equalTo(view.safeAreaLayoutGuide.snp.right)
            }
            make.height.equalTo(205)
            make.width.equalTo(70)
        }

        compassWidget?.view.snp.remakeConstraints { [weak self] make in
            if (portrait && tablet) {
                make.bottom.equalTo(contentView2.snp.top).offset(-defaultPadding)
                make.height.equalTo(contentView1.snp.width).multipliedBy(0.15)
                make.right.equalTo(cameraControlsView.snp.right)
                make.width.equalTo(compassWidget!.view.snp.height)
                return
            }

            if (portrait) {
                make.bottom.equalTo(contentView2.snp.top).offset(-5)
                make.height.equalTo(compassWidget!.view.snp.width)
                make.centerX.equalTo(cameraControlsView.snp.centerX)
                make.width.equalTo(cameraControlsView.snp.width)
                return
            }
            
            if contentView3.isHidden {
                make.bottom.equalTo(contentView2.snp.bottom)
                make.right.equalTo(tablet ? cameraControlsView.snp.right : cameraControlsView.snp.left)
            }
            else {
                make.bottom.equalTo(contentView3.snp.top).offset(-defaultPadding)
                if tablet {
                    make.right.equalTo(offsetsButton.snp.left).offset(-defaultPadding / 2)
                }
                else {
                    make.right.equalTo(cameraControlsView.snp.left)
                }
            }
            
            make.height.equalTo(contentView1.snp.width).multipliedBy(!contentView3.isHidden ? 0.07 : tablet ? 0.12 : 0.09)
            make.width.equalTo(compassWidget!.view.snp.height)
        }
        
        offsetsButton.isHidden = !offsetsButtonEnabled
        offsetsButton.tintColor = droneOffsetsWidget1?.view.isHidden ?? false ? UIColor.white : DronelinkUI.Constants.secondaryColor
        
        telemetryWidget?.view.snp.remakeConstraints { [weak self] make in
            if (portrait) {
                make.bottom.equalTo(contentView2.snp.top).offset(tablet ? -defaultPadding : -2)
                make.left.equalTo(view.safeAreaLayoutGuide.snp.left).offset(defaultPadding)
            }
            else {
                make.bottom.equalTo(contentView2.snp.bottom)
                make.left.equalTo((contentView2.isHidden ? contentView2VisibilityButton : contentView2).snp.right).offset(defaultPadding)
            }
            make.height.equalTo(tablet ? 85 : 75)
            make.width.equalTo(tablet ? 350 : 275)
        }
        
        if let telemetryWidget = telemetryWidget {
            debugWidget?.view.snp.remakeConstraints { [weak self] make in
                make.width.equalTo(telemetryWidget.view.snp.width)
                make.height.equalTo(100)
                make.left.equalTo(telemetryWidget.view.snp.left)
                make.bottom.equalTo(telemetryWidget.view.snp.top).offset(-defaultPadding)
            }
        }
        
        if let droneOffsetsWidget1 = droneOffsetsWidget1 {
            droneOffsetsWidget1.view.snp.remakeConstraints { [weak self] make in
                make.height.equalTo(240)
                make.width.equalTo(200)
                if portrait {
                    make.right.equalTo(view.safeAreaLayoutGuide.snp.right).offset(-defaultPadding)
                    make.top.equalTo(contentView2.snp.top).offset(defaultPadding)
                }
                else {
                    make.right.equalTo(cameraControlsView.snp.left).offset(-defaultPadding)
                    make.top.equalTo(topBarView.snp.bottom).offset(45)
                }
            }
            
            if let droneOffsetsWidget2 = droneOffsetsWidget2 {
                droneOffsetsWidget2.view.snp.remakeConstraints { [weak self] make in
                    make.height.equalTo(droneOffsetsWidget1.view)
                    make.width.equalTo(droneOffsetsWidget1.view)
                    make.right.equalTo(droneOffsetsWidget1.view)
                    make.top.equalTo(droneOffsetsWidget1.view.snp.bottom).offset(defaultPadding)
                }
            }
            
            if let cameraOffsetsWidget = cameraOffsetsWidget {
                cameraOffsetsWidget.view.snp.remakeConstraints { [weak self] make in
                    make.height.equalTo(65)
                    make.width.equalTo(droneOffsetsWidget1.view)
                    make.right.equalTo(droneOffsetsWidget1.view)
                    make.top.equalTo((droneOffsetsWidget2 ?? droneOffsetsWidget1).view.snp.bottom).offset(defaultPadding)
                }
            }
        }
        
        executorWidget?.view.isHidden = executorWidget !== activityWidget
        cameraFocusCalibrationWidget?.view.isHidden = cameraFocusCalibrationWidget !== activityWidget
        
        activityWidget?.view.snp.remakeConstraints { [weak self] make in
            let preferredSize = activityWidget?.preferredSize ?? CGSize(width: 0, height: 0)
            if (activityWidget is FuncExecutorWidget) {
                let large = tablet || portrait
                if (activityWidgetLayout == .large) {
                    if (portrait) {
                        make.height.equalTo(tablet ? 550 : 300)
                    }
                    else {
                        make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom).offset(-defaultPadding)
                    }
                }
                else {
                    make.height.equalTo(185)
                }
                
                if (portrait && tablet) {
                    make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom).offset(-defaultPadding)
                    make.left.equalTo(view.safeAreaLayoutGuide.snp.left).offset(defaultPadding)
                    make.width.equalTo(large ? 350 : 310)
                    return
                }
                
                if (portrait) {
                    make.right.equalToSuperview()
                    make.left.equalToSuperview()
                    make.top.equalTo(contentView2.snp.top)
                    return
                }
                
                make.top.equalTo(topBarView.snp.bottom).offset(defaultPadding)
                make.left.equalTo(view.safeAreaLayoutGuide.snp.left).offset(defaultPadding)
                make.width.equalTo(large ? 350 : 310)
                return
            }
            
            if (portrait && tablet) {
                make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom).offset(-defaultPadding)
                make.left.equalTo(view.safeAreaLayoutGuide.snp.left).offset(defaultPadding)
                make.width.equalToSuperview().multipliedBy(0.35)
                if (activityWidgetLayout == .small) {
                    make.height.equalTo(preferredSize.height)
                }
                else {
                    make.top.equalTo(contentView2.snp.top).offset(defaultPadding)
                }
                return
            }
            
            if (portrait) {
                make.right.equalToSuperview()
                make.left.equalToSuperview()
                make.bottom.equalToSuperview()
                if (activityWidgetLayout == .small) {
                    make.height.equalTo(preferredSize.height)
                }
                else {
                    make.height.equalTo(contentView2.snp.height).multipliedBy(0.5)
                }
                return
            }
            
            make.top.equalTo(topBarView.snp.bottom).offset(defaultPadding)
            make.left.equalTo(view.safeAreaLayoutGuide.snp.left).offset(defaultPadding)
            if (tablet) {
                make.width.equalTo(preferredSize.width)
            }
            else {
                make.width.equalToSuperview().multipliedBy(0.4)
            }
            
            if (activityWidgetLayout == .small) {
                make.height.equalTo(preferredSize.height)
            }
            else {
                if (tablet) {
                    make.height.equalTo(preferredSize.height)
                }
                else {
                    make.bottom.equalTo(contentView2.snp.top).offset(-Double(defaultPadding) * 1.5)
                }
            }
        }
    }
    
    //work-around for this: https://github.com/flutter/flutter/issues/35784
    override public func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {}
    override public func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {}
    override public func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {}
    override public func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {}
    
    public override func onVideoFeedSourceUpdated(session: DroneSession, channel: UInt?) {
        DispatchQueue.main.async { [weak self] in
            self?.updateViewConstraints()
        }
        
        updateRemoteControllerTargetGimbalChannel()
    }
    
    private func updateRemoteControllerTargetGimbalChannel() {
        try? session?.add(command: Kernel.TargetGimbalChannelRemoteControllerCommand(channel: 0, targetGimbalChannel: cameraChannel ?? session?.drone.cameraChannel(videoFeedChannel: nil) ?? 0))
    }
}
