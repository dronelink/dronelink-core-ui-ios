//
//  FuncExecutorWidget.swift
//  DronelinkCoreUI
//
//  Created by Jim McAndrew on 12/7/20.
//  Copyright © 2020 Dronelink. All rights reserved.
//
import DronelinkCore
import Foundation
import UIKit
import MaterialComponents.MaterialButtons
import MaterialComponents.MaterialButtons_Theming
import MaterialComponents.MaterialTextFields
import Kingfisher
import Agrume
import IQKeyboardManager

public class FuncExecutorWidget: DelegateWidget, ExecutorWidget {
    private static var mostRecentExecuted: FuncExecutor?
    
    public var layout: ExecutorWidgetLayout = .small
    
    public var preferredSize: CGSize {
        if (portrait && tablet) {
            return CGSize(width: layout == .large ? 350 : 310, height: layout == .large ? 0 : 185)
        }
        
        return CGSize(width: portrait ? 0 : (layout == .large ? 350 : 310), height: layout == .large ? 0 : 185)
    }
    
    private let imagePlaceholder = MDCActivityIndicator()
    private let headerBackgroundView = UIView()
    private let footerBackgroundView = UIView()
    private let primaryButton = MDCRaisedButton()
    private let backButton = MDCFlatButton()
    private let nextButton = MDCRaisedButton()
    private let titleImageView = UIImageView()
    private let titleLabel = UILabel()
    private let variableNameLabel = UILabel()
    private let variableDescriptionTextView = UITextView()
    private let variableImageView = UIImageView()
    private let variableSegmentedControl = UISegmentedControl()
    private let variableTextField = MDCTextField()
    private let variablePickerView = UIPickerView()
    private let variableDroneMarkButton = MDCButton()
    private let variableDroneViewController = FuncDroneTableViewController()
    private let variableSummaryViewController = FuncSummaryTableViewController()
    private let progressLabel = UILabel()
    private let dismissButton = UIButton(type: .custom)
    private let primaryColor = MDCPalette.deepPurple.tint800
    private let funcImage = DronelinkUI.loadImage(named: "function-variant")
    private let cancelImage = DronelinkUI.loadImage(named: "baseline_close_white_36pt")
    private let droneImage = DronelinkUI.loadImage(named: "baseline_navigation_white_36pt")
    
    private let segmentedMaxOptions = 2
    private var intro = true
    private var inputIndex = 0
    private var last: Bool {
        guard let inputCount = funcExecutor?.inputCount else {
            return true
        }
        return inputIndex == inputCount
    }
    private var hasInputs: Bool { funcExecutor?.inputCount ?? 0 > 0 || funcExecutor?.dynamicInputs != nil }
    private var input: Kernel.FuncInput? { funcExecutor?.input(index: inputIndex) }
    private func valueNumberMeasurementTypeDisplay(index: Int? = nil) -> String? { funcExecutor?.readValueNumberMeasurementTypeDisplay(index: index ?? inputIndex) }
    private var executing = false
    private var value: Any?
    private let listenRCButtonsInterval: TimeInterval = 0.1
    private var listenRCButtonsTimer: Timer?
    private var c1PressedPrevious = false
    private var c2PressedPrevious = false
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        IQKeyboardManager.shared().isEnabled = true
        
        imagePlaceholder.radius = 20
        imagePlaceholder.strokeWidth = 5
        imagePlaceholder.cycleColors = [DronelinkUI.Constants.secondaryColor!]
        imagePlaceholder.startAnimating()
        
        if #available(iOS 13.0, *) {
            overrideUserInterfaceStyle = .dark
        }
        
        view.addShadow()
        view.layer.cornerRadius = DronelinkUI.Constants.cornerRadius
        view.clipsToBounds = true
        view.backgroundColor = DronelinkUI.Constants.overlayColor
        
        headerBackgroundView.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        view.addSubview(headerBackgroundView)
        
        footerBackgroundView.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        view.addSubview(footerBackgroundView)
        
        titleImageView.image = funcImage
        titleImageView.tintColor = UIColor.white
        view.addSubview(titleImageView)
        
        titleLabel.font = UIFont.boldSystemFont(ofSize: 17)
        titleLabel.textColor = UIColor.white
        titleLabel.numberOfLines = 1
        titleLabel.lineBreakMode = .byTruncatingTail
        view.addSubview(titleLabel)
        
        variableNameLabel.font = UIFont.boldSystemFont(ofSize: 14)
        variableNameLabel.textColor = UIColor.white
        variableNameLabel.numberOfLines = 1
        variableNameLabel.lineBreakMode = .byTruncatingTail
        variableNameLabel.minimumScaleFactor = 0.5
        variableNameLabel.adjustsFontSizeToFitWidth = true
        view.addSubview(variableNameLabel)
        
        variableDescriptionTextView.textContainerInset = .zero
        variableDescriptionTextView.backgroundColor = UIColor.clear
        variableDescriptionTextView.font = UIFont.boldSystemFont(ofSize: 12)
        variableDescriptionTextView.textColor = UIColor.white.withAlphaComponent(0.85)
        variableDescriptionTextView.isScrollEnabled = true
        variableDescriptionTextView.isEditable = false
        view.addSubview(variableDescriptionTextView)
        
        variableImageView.contentMode = .scaleAspectFit
        variableImageView.isUserInteractionEnabled = true
        variableImageView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(onImageView(sender:))))
        view.addSubview(variableImageView)
        
        variableSegmentedControl.tintColor = primaryColor
        view.addSubview(variableSegmentedControl)
        
        variableTextField.tintColor = UIColor.white
        variableTextField.delegate = self
        variableTextField.returnKeyType = .done
        variableTextField.textColor = UIColor.white
        view.addSubview(variableTextField)

        variablePickerView.dataSource = self
        variablePickerView.delegate = self
        view.addSubview(variablePickerView)

        let scheme = MDCContainerScheme()
        scheme.colorScheme = MDCSemanticColorScheme(defaults: .materialDark201907)
        scheme.colorScheme.primaryColor = UIColor.darkGray
        variableDroneMarkButton.applyContainedTheme(withScheme: scheme)
        variableDroneMarkButton.translatesAutoresizingMaskIntoConstraints = false
        variableDroneMarkButton.setImage(droneImage?.withRenderingMode(.alwaysTemplate), for: .normal)
        variableDroneMarkButton.imageView?.contentMode = .scaleAspectFit
        variableDroneMarkButton.setImageTintColor(.white, for: .normal)
        variableDroneMarkButton.setTitleColor(.white, for: .normal)
        variableDroneMarkButton.setTitle("FuncExecutorWidget.input.drone".localized, for: .normal)
        variableDroneMarkButton.addTarget(self, action: #selector(onDroneMark(sender:)), for: .touchUpInside)
        view.addSubview(variableDroneMarkButton)
        
        variableDroneViewController.funcExecutor = { self.funcExecutor }
        variableDroneViewController.onClear = { index in
            self.funcExecutor?.clearValue(index: self.inputIndex, arrayIndex: index)
            self.readValue()
        }
        addChild(variableDroneViewController)
        view.addSubview(variableDroneViewController.view)
        variableDroneViewController.didMove(toParent: self)
        
        variableSummaryViewController.funcExecutor = { self.funcExecutor }
        variableSummaryViewController.onSelect = backTo
        addChild(variableSummaryViewController)
        view.addSubview(variableSummaryViewController.view)
        variableSummaryViewController.didMove(toParent: self)
        
        progressLabel.font = UIFont.boldSystemFont(ofSize: 12)
        progressLabel.textColor = UIColor.white
        progressLabel.textAlignment = .center
        view.addSubview(progressLabel)
        
        backButton.translatesAutoresizingMaskIntoConstraints = false
        backButton.setTitle("back".localized, for: .normal)
        backButton.setTitleColor(UIColor.white, for: .normal)
        backButton.addTarget(self, action: #selector(onBack(sender:)), for: .touchUpInside)
        view.addSubview(backButton)
        
        nextButton.translatesAutoresizingMaskIntoConstraints = false
        nextButton.setBackgroundColor(primaryColor)
        nextButton.tintColor = UIColor.white
        nextButton.addTarget(self, action: #selector(onNext(sender:)), for: .touchUpInside)
        view.addSubview(nextButton)
        
        primaryButton.translatesAutoresizingMaskIntoConstraints = false
        primaryButton.setBackgroundColor(primaryColor)
        primaryButton.tintColor = UIColor.white
        primaryButton.addTarget(self, action: #selector(onPrimary(sender:)), for: .touchUpInside)
        view.addSubview(primaryButton)
        
        dismissButton.tintColor = UIColor.white
        dismissButton.setImage(DronelinkUI.loadImage(named: "baseline_close_white_36pt"), for: .normal)
        dismissButton.addTarget(self, action: #selector(onDismiss), for: .touchUpInside)
        view.addSubview(dismissButton)
    }
        
    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        listenRCButtonsTimer = Timer.scheduledTimer(timeInterval: listenRCButtonsInterval, target: self, selector: #selector(listenRCButtons), userInfo: nil, repeats: true)
    }
    
    public override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        listenRCButtonsTimer?.invalidate()
        listenRCButtonsTimer = nil
    }
    
    @objc func listenRCButtons() {
        if let remoteControllerState = session?.remoteControllerState(channel: 0)?.value {
            if c1PressedPrevious, !remoteControllerState.c1Button.pressed, !variableDroneMarkButton.isHidden {
                DispatchQueue.main.async {
                    self.onDroneMark(sender: self)
                }
            }
            
            if c2PressedPrevious, !remoteControllerState.c2Button.pressed, !variableDroneMarkButton.isHidden {
                DispatchQueue.main.async {
                    self.funcExecutor?.clearValue(index: self.inputIndex)
                    self.readValue()
                }
            }
        }
        
        let remoteControllerState = session?.remoteControllerState(channel: 0)?.value
        c1PressedPrevious = remoteControllerState?.c1Button.pressed ?? false
        c2PressedPrevious = remoteControllerState?.c2Button.pressed ?? false
    }
    
    public override func updateViewConstraints() {
        super.updateViewConstraints()
        
        let defaultPadding = 10
        
        headerBackgroundView.snp.remakeConstraints { make in
            make.top.equalToSuperview()
            make.left.equalToSuperview()
            make.right.equalToSuperview()
            make.height.equalTo(43)
        }
        
        footerBackgroundView.snp.remakeConstraints { make in
            make.bottom.equalToSuperview()
            make.left.equalToSuperview()
            make.right.equalToSuperview()
            make.height.equalTo(52)
        }
        
        titleImageView.snp.remakeConstraints { make in
            make.height.equalTo(24)
            make.width.equalTo(titleImageView.snp.height)
            make.top.equalToSuperview().offset(defaultPadding)
            make.left.equalToSuperview().offset(defaultPadding)
        }
        
        titleLabel.snp.remakeConstraints { make in
            make.height.equalTo(25)
            make.left.equalTo(titleImageView.snp.right).offset(defaultPadding)
            make.right.equalTo(dismissButton.snp.left).offset(-defaultPadding)
            make.top.equalTo(titleImageView.snp.top)
        }
        
        dismissButton.snp.remakeConstraints { make in
            make.height.equalTo(24)
            make.width.equalTo(dismissButton.snp.height)
            make.top.equalToSuperview().offset(defaultPadding)
            make.right.equalToSuperview().offset(-defaultPadding)
        }
        
        variableNameLabel.snp.remakeConstraints { make in
            make.left.equalToSuperview().offset(defaultPadding)
            make.right.equalTo(dismissButton.snp.left).offset(-defaultPadding)
            make.top.equalToSuperview().offset(defaultPadding)
            make.height.equalTo(25)
        }
        
        variableDescriptionTextView.snp.remakeConstraints { make in
            make.top.equalToSuperview().offset(52)
            make.left.equalTo(variableNameLabel.snp.left)
            make.right.equalToSuperview().offset(-defaultPadding)
            make.height.equalTo(28)
        }
        
        variableImageView.snp.remakeConstraints { make in
            make.top.equalToSuperview().offset(45)
            make.left.equalToSuperview().offset(defaultPadding)
            make.right.equalToSuperview().offset(-defaultPadding)
            if intro, !(funcExecutor?.introImageUrl?.isEmpty ?? true) {
                make.bottom.equalToSuperview().offset(tablet ? -50 : -45)
            }
            else {
                switch input?.variable.valueType ?? .null {
                case .null:
                    make.bottom.equalToSuperview().offset(tablet ? -120 : -115)
                    break
                case .boolean, .number, .string:
                    make.bottom.equalToSuperview().offset(tablet ? -155 : -125)
                    break
                case .drone:
                    make.bottom.equalToSuperview().offset(tablet ? -205 : -160)
                    break
                }
            }
        }
        
        var expanded = false
        var variableTopControl: UIView = variableNameLabel
        if !intro, let imageUrl = input?.imageUrl, !imageUrl.isEmpty {
            expanded = true
            variableTopControl = variableImageView
        }
        else if intro, !(funcExecutor?.introImageUrl?.isEmpty ?? true) {
            expanded = true
            variableTopControl = variableImageView
        }
        else if !(input?.descriptors.description?.isEmpty ?? true) {
            variableTopControl = variableDescriptionTextView
        }
        
        let variableBottomControl = backButton
        let buttonHeight = 32
        
        backButton.snp.remakeConstraints { make in
            make.left.equalToSuperview().offset(defaultPadding)
            make.bottom.equalToSuperview().offset(-defaultPadding)
            make.height.equalTo(buttonHeight)
            make.width.equalTo(85)
        }

        progressLabel.snp.remakeConstraints { make in
            make.left.equalTo(backButton.snp.right).offset(defaultPadding)
            make.right.equalTo(nextButton.snp.left).offset(-defaultPadding)
            make.top.equalTo(variableBottomControl)
            make.bottom.equalTo(variableBottomControl)
        }

        nextButton.snp.remakeConstraints { make in
            make.right.equalToSuperview().offset(-defaultPadding)
            make.height.equalTo(buttonHeight)
            make.width.equalTo(last ? 200 : 85)
            make.bottom.equalTo(variableBottomControl)
        }
        
        primaryButton.snp.remakeConstraints { make in
            make.height.equalTo(buttonHeight)
            make.left.equalToSuperview().offset(defaultPadding)
            make.right.equalToSuperview().offset(-defaultPadding)
            make.bottom.equalToSuperview().offset(-defaultPadding)
        }
        
        variableSummaryViewController.view.snp.remakeConstraints { make in
            make.top.equalToSuperview().offset(50)
            make.left.equalToSuperview().offset(5)
            make.right.equalToSuperview().offset(-defaultPadding)
            make.bottom.equalTo(variableBottomControl.snp.top).offset(-15)
        }

        let additionalBottomOffset: CGFloat = variableTopControl == variableNameLabel ? -20 : 0

        variableSegmentedControl.snp.remakeConstraints { make in
            make.left.equalToSuperview().offset(defaultPadding)
            make.right.equalToSuperview().offset(-defaultPadding)
            make.bottom.equalTo(variableBottomControl.snp.top).offset(-26 + additionalBottomOffset)
            make.height.equalTo(tablet ? 30 : 28)
        }
        
        variableTextField.snp.remakeConstraints { make in
            make.left.equalToSuperview().offset(15)
            make.right.equalToSuperview().offset(-15)
            make.bottom.equalTo(variableBottomControl.snp.top).offset(-28 + additionalBottomOffset)
            make.height.equalTo(40)
        }

        variablePickerView.snp.remakeConstraints { make in
            make.left.equalToSuperview().offset(defaultPadding)
            make.right.equalToSuperview().offset(-defaultPadding)
            make.bottom.equalTo(variableBottomControl.snp.top).offset(15 + (variableTopControl == variableNameLabel ? -35 : 0))
            make.height.equalTo(80)
        }

        variableDroneMarkButton.snp.remakeConstraints { make in
            make.left.equalToSuperview().offset(defaultPadding * 2)
            if expanded {
                make.right.equalToSuperview().offset(-defaultPadding * 2)
                make.bottom.equalTo(variableBottomControl.snp.top).offset((tablet ? -30 : -25) + additionalBottomOffset)
            }
            else {
                make.width.equalTo(115)
                make.bottom.equalTo(variableBottomControl.snp.top).offset(-25 + (variableTopControl == variableNameLabel ? -35 : 0))
            }
            make.height.equalTo(buttonHeight)
        }

        variableDroneViewController.view.snp.remakeConstraints { make in
            if expanded {
                make.left.equalToSuperview().offset(defaultPadding)
                make.right.equalToSuperview().offset(-defaultPadding * 2)
                make.top.equalTo(variableTopControl.snp.bottom).offset(3)
                make.bottom.equalTo(variableDroneMarkButton.snp.top).offset(-5)
            }
            else {
                make.left.equalTo(variableDroneMarkButton.snp.right)
                make.right.equalToSuperview().offset(-5)
                make.top.equalTo(variableDroneMarkButton).offset(-5)
                make.bottom.equalTo(variableBottomControl.snp.top).offset(-15)
            }
        }
        
        update()
    }
    
    override public func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        view.setNeedsUpdateConstraints()
    }
    
    @objc func onPrimary(sender: Any) {
        guard let funcExecutor = funcExecutor else {
            return
        }
        
        if (intro && hasInputs) {
            let finish = {
                self.intro = false
                if funcExecutor.inputCount == 0 {
                    self.addNextDynamicInput()
                }
                self.readValue()
                self.view.setNeedsUpdateConstraints()
            }
            
            if let mostRecentExecuted = FuncExecutorWidget.mostRecentExecuted,
                mostRecentExecuted.id == funcExecutor.id {
                DronelinkUI.shared.showDialog(
                    title: "FuncExecutorWidget.cachedInputs.title".localized,
                    details: "FuncExecutorWidget.cachedInputs.message".localized,
                    actions: [
                        MDCAlertAction(title: "FuncExecutorWidget.cachedInputs.action.new".localized, emphasis: .high, handler: { action in
                            finish()
                        }),
                        MDCAlertAction(title: "FuncExecutorWidget.cachedInputs.action.previous".localized, handler: { action in
                            funcExecutor.addCachedInputs(funcExecutor: mostRecentExecuted)
                            finish()
                        })
                    ])
            }
            else {
                finish()
            }
            return
        }
        
        if (!executing) {
            executing = true
            view.setNeedsUpdateConstraints()
            funcExecutor.execute(droneSession: session) { error in
                DispatchQueue.main.async {
                    DronelinkUI.shared.showSnackbar(text: error)
                    self.executing = false
                    self.view.setNeedsUpdateConstraints()
                }
            }
        }
    }
    
    @objc func onBack(sender: Any) {
        backTo(index: inputIndex -  1)
    }
    
    func backTo(index: Int) {
        inputIndex = index
        if inputIndex < (funcExecutor?.inputCount ?? 0) - 1 {
            funcExecutor?.removeLastDynamicInput()
        }
        readValue()
        view.setNeedsUpdateConstraints()
    }
    
    @objc func onNext(sender: Any) {
        if last {
            onPrimary(sender: sender)
            return
        }
        
        if (!writeValue(next: true)) {
            return
        }
        
        inputIndex += 1
        variableTextField.resignFirstResponder()
        addNextDynamicInput()
        readValue()
        view.setNeedsUpdateConstraints()
    }
    
    @objc func onImageView(sender: Any) {
        guard let imageUrl = input?.imageUrl, !imageUrl.isEmpty else {
            return
        }

        let doneButton = UIBarButtonItem(barButtonSystemItem: .done, target: nil, action: nil)
        doneButton.tintColor = .white
        let agrume = Agrume(
            url: URL(string: imageUrl)!,
            background: .blurred(.dark),
            dismissal: .withButton(doneButton))
        agrume.statusBarStyle = .lightContent
        agrume.show(from: self)
    }
    
    @objc func onDroneMark(sender: Any) {
        guard let session = self.session else {
            DronelinkUI.shared.showSnackbar(text: "FuncExecutorWidget.input.drone.unavailable".localized)
            return
        }
        
        if session.state?.value.location == nil {
            DronelinkUI.shared.showSnackbar(text: "FuncExecutorWidget.input.location.unavailable".localized)
            return
        }
        
        if input?.extensions?.droneOffsetsCoordinateReference ?? false {
            Dronelink.shared.droneOffsets.droneCoordinateReference = session.state?.value.location?.coordinate
        }
        
        writeValue()
        readValue()
    }
    
    @objc func onDismiss() {
        Dronelink.shared.unloadFunc()
    }
    
    func addNextDynamicInput() {
        funcExecutor?.addNextDynamicInput(droneSession: session) { error in
             DispatchQueue.main.async {
                DronelinkUI.shared.showSnackbar(text: error)
                self.inputIndex -= 1
                if self.inputIndex < 0 {
                    self.inputIndex = 0
                    self.intro = true
                }
                else {
                    self.readValue()
                }
                self.view.setNeedsUpdateConstraints()
            }
        }
    }
    
    @discardableResult
    func writeValue(next: Bool = false) -> Bool {
        guard let input = input else {
            return false
        }
        
        var value: Any? = nil
        switch input.variable.valueType {
            case .null:
                break
            
            case .boolean:
                if (variableSegmentedControl.selectedSegmentIndex != UISegmentedControl.noSegment) {
                    value = variableSegmentedControl.selectedSegmentIndex == 0
                }
                break
                
            case .number:
                if let text = variableTextField.text, !text.isEmpty {
                    value = Double(text)
                }
                break
                
            case .string:
                if let enumValues = input.enumValues {
                    if enumValues.count <= segmentedMaxOptions {
                        if (variableSegmentedControl.selectedSegmentIndex != UISegmentedControl.noSegment) {
                            value = enumValues[variableSegmentedControl.selectedSegmentIndex]
                        }
                    }
                    else {
                        let index = variablePickerView.selectedRow(inComponent: 0) - 1
                        if index >= 0 {
                            value = enumValues[index]
                        }
                    }
                }
                else {
                    if let text = variableTextField.text, !text.isEmpty {
                        value = text
                    }
                }
                break
                
            case .drone:
                if next {
                    if funcExecutor?.readValue(inputIndex: inputIndex) == nil && !input.optional {
                        DronelinkUI.shared.showSnackbar(text: "FuncExecutorWidget.input.required".localized)
                        return false
                    }
                    return true
                }
                
                value = session
                break
        }
        
        if !input.optional && value == nil && input.variable.valueType != .null {
            DronelinkUI.shared.showSnackbar(text: "FuncExecutorWidget.input.required".localized)
            return false
        }
        
        funcExecutor?.writeValue(index: inputIndex, value: value)
        return true
    }
    
    func readValue() {
        variableTextField.text = ""
        variableSegmentedControl.selectedSegmentIndex = UISegmentedControl.noSegment
        variableSegmentedControl.removeAllSegments()
        variablePickerView.reloadAllComponents()
        variableDroneViewController.inputIndex = inputIndex
        
        guard let input = input else {
            self.value = nil
            update()
            return
        }
        
        if input.variable.valueType == .boolean {
            variableSegmentedControl.insertSegment(withTitle: "yes".localized, at: 0, animated: false)
            variableSegmentedControl.insertSegment(withTitle: "no".localized, at: 1, animated: false)
            
        }
        else if let enumValues = input.enumValues {
            enumValues.enumerated().forEach { (index, enumValue) in
                variableSegmentedControl.insertSegment(withTitle: enumValue, at: index, animated: false)
            }
        }
        
        guard let value = funcExecutor?.readValue(inputIndex: inputIndex) else {
            self.value = nil
            variableDroneViewController.refresh()
            update()
            return
        }
        self.value = value
        update()
        
        if input.variable.valueType == .drone {
            variableDroneViewController.refresh()
            return
        }
        
        if let valueBoolean = value as? Bool {
            variableSegmentedControl.selectedSegmentIndex = valueBoolean ? 0 : 1
        }
        
        if let valueDouble = value as? Double {
            variableTextField.text = "\(valueDouble)"
        }
        
        if let valueString = value as? String {
            variableTextField.text = valueString
            input.enumValues?.enumerated().forEach { (index, enumValue) in
                if enumValue == valueString {
                    self.variableSegmentedControl.selectedSegmentIndex = index
                    self.variablePickerView.selectRow(index + 1, inComponent: 0, animated: false)
                }
            }
        }
    }
    
    private func update() {
        guard let funcExecutor = funcExecutor else {
            return
        }

        titleImageView.isHidden = true
        titleLabel.isHidden = true
        variableNameLabel.isHidden = true
        variableDescriptionTextView.isHidden = true
        variableImageView.isHidden = true
        variableSegmentedControl.isHidden = true
        variableTextField.isHidden = true
        variablePickerView.isHidden = true
        variableDroneMarkButton.isHidden = true
        variableDroneViewController.view.isHidden = true
        variableSummaryViewController.view.isHidden = true
        footerBackgroundView.isHidden = intro
        
        if intro {
            titleImageView.isHidden = false
            titleLabel.isHidden = false
            backButton.isHidden = true
            nextButton.isHidden = true
            progressLabel.isHidden = true
            primaryButton.isHidden = false

            titleLabel.text = funcExecutor.descriptors.name
            primaryButton.setTitle((executing ? "FuncExecutorWidget.primary.executing" : hasInputs ? "FuncExecutorWidget.primary.intro" : "FuncExecutorWidget.primary.execute").localized, for: .normal)
            
            if let introImageUrl = funcExecutor.introImageUrl, !introImageUrl.isEmpty {
                variableImageView.isHidden = false
                variableImageView.image = nil
                variableImageView.kf.setImage(with: URL(string: introImageUrl), placeholder: imagePlaceholder)
            }
            else {
                variableDescriptionTextView.isHidden = false
                variableDescriptionTextView.text = funcExecutor.descriptors.description
            }
            
            return
        }

        primaryButton.isHidden = true
        backButton.isHidden = false
        backButton.isEnabled = inputIndex > 0
        nextButton.isHidden = false
        nextButton.setTitle((last ? "FuncExecutorWidget.primary.execute" : "next").localized, for: .normal)
        progressLabel.isHidden = last
        progressLabel.text = inputIndex + 1 == funcExecutor.inputCount ? "\(inputIndex + 1)" : "\(inputIndex + 1) / \(funcExecutor.inputCount)"
        
        if let input = input {
            variableNameLabel.isHidden = false
            var name = input.descriptors.name ?? ""
            if let valueNumberMeasurementTypeDisplay = self.valueNumberMeasurementTypeDisplay() {
                name = "\(name) (\(valueNumberMeasurementTypeDisplay))"
            }
            
            if !input.optional && input.variable.valueType != .null {
                name = "\(name) *"
            }
            variableNameLabel.text = name
            
            if let imageUrl = input.imageUrl, !imageUrl.isEmpty {
                variableImageView.image = nil
                variableImageView.kf.setImage(with: URL(string: imageUrl), placeholder: imagePlaceholder)
                variableImageView.isHidden = false
            }
            else if !(input.descriptors.description?.isEmpty ?? true) {
                variableDescriptionTextView.isHidden = false
                variableDescriptionTextView.text = input.descriptors.description
            }

            switch input.variable.valueType {
            case .null:
                break
                
            case .boolean:
                variableSegmentedControl.isHidden = false
                break
                
            case .number:
                variableTextField.isHidden = false
                variableTextField.keyboardType = .decimalPad
                break
                
            case .string:
                if let enumsValues = input.enumValues {
                    variablePickerView.isHidden = enumsValues.count <= segmentedMaxOptions
                    variableSegmentedControl.isHidden = !variablePickerView.isHidden
                }
                else {
                    variableTextField.isHidden = false
                    variableTextField.keyboardType = .default
                }
                break
                
            case .drone:
                variableDroneMarkButton.isHidden = false
                variableDroneViewController.view.isHidden = false
                break
            }

            layout = (input.imageUrl?.isEmpty ?? true) ? .small : .large
            view.superview?.setNeedsUpdateConstraints()
            return
        }
        
        if last {
            variableNameLabel.isHidden = false
            variableNameLabel.text = "FuncExecutorWidget.input.summary".localized
            variableSummaryViewController.view.isHidden = false
            variableSummaryViewController.refresh()
            layout = funcExecutor.inputCount > 3 ? .large : .small
            view.superview?.setNeedsUpdateConstraints()
            return
        }
    }
    
    open override func onFuncLoaded(executor: FuncExecutor) {
        super.onFuncLoaded(executor: executor)
        
        self.inputIndex = 0
        self.intro = true
        if let urls = executor.urls {
            DronelinkUI.shared.cacheImages(urls: urls)
        }
    }
    
    open override func onFuncExecuted(executor: FuncExecutor) {
        super.onFuncExecuted(executor: executor)
        
        FuncExecutorWidget.mostRecentExecuted = executor
    }
}

extension FuncExecutorWidget: UIPickerViewDataSource, UIPickerViewDelegate {
    public func numberOfComponents(in pickerView: UIPickerView) -> Int {
        guard let input = input, input.enumValues != nil else {
            return 0
        }
        return 1
    }

    public func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        guard let input = input else {
            return 0
        }
        return (input.enumValues?.count ?? 0) + 1
    }

    public func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        guard let input = input else {
            return ""
        }
        
        if row == 0 {
            return "FuncExecutorWidget.input.choose".localized
        }
        return input.enumValues?[safeIndex: row - 1] ?? ""
    }
}

extension FuncExecutorWidget: UITextFieldDelegate {
    public func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}

class FuncDroneTableViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    var funcExecutor: (() -> FuncExecutor?)?
    var inputIndex: Int = 0
    var onClear: ((Int) -> ())?
    
    private let tableView = UITableView()
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        tableView.register(DroneTableViewCell.self, forCellReuseIdentifier: "drone")
        tableView.dataSource = self
        tableView.delegate = self
        tableView.backgroundColor = UIColor.clear
        tableView.allowsSelection = false
        tableView.setEditing(true, animated: false)
        view.addSubview(tableView)
        tableView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }
    
    func refresh() {
        DispatchQueue.main.async {
            self.tableView.reloadData()
        }
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return funcExecutor == nil ? 0 : 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if let value = funcExecutor?()?.readValue(inputIndex: inputIndex) {
            if let array = value as? [Any] {
                return array.count
            }
            return 1
        }
        return 0
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "drone", for: indexPath) as UITableViewCell
        cell.textLabel?.text = nil
        cell.detailTextLabel?.text = nil
        if let funcExecutor = funcExecutor?(), let value = funcExecutor.readValue(inputIndex: inputIndex) {
            let count = (value as? [Any])?.count ?? 0
            let variableValueIndex = count == 0 ? 0 : count - indexPath.row - 1
            let value = funcExecutor.readValue(inputIndex: inputIndex, variableValueIndex: variableValueIndex, formatted: true) as? String
            cell.textLabel?.text = value
            cell.detailTextLabel?.text = count > 0 ? "\(variableValueIndex + 1)" : nil
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 37
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            onClear?(tableView.numberOfRows(inSection: 0) - indexPath.row - 1)
        }
    }
    
//    func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
//        return (funcExecutor?()?.readValue(inputIndex: inputIndex) as? [Any])?.count ?? 0 > 0
//    }
//
//    func tableView(_ tableView: UITableView, moveRowAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
//
//    }
    
    private class DroneTableViewCell: UITableViewCell {
        override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
            super.init(style: .value1, reuseIdentifier: reuseIdentifier)
            backgroundColor = .clear
            textLabel?.font = UIFont.boldSystemFont(ofSize: 14)
            detailTextLabel?.font = UIFont.boldSystemFont(ofSize: 12)
        }

        required init?(coder aDecoder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
    }
}

class FuncSummaryTableViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    var funcExecutor: (() -> FuncExecutor?)?
    var onSelect: ((Int) -> ())?
    
    private let tableView = UITableView()
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        tableView.register(InputTableViewCell.self, forCellReuseIdentifier: "input")
        tableView.dataSource = self
        tableView.delegate = self
        tableView.backgroundColor = UIColor.clear
        view.addSubview(tableView)
        tableView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }
    
    func refresh() {
        DispatchQueue.main.async {
            self.tableView.reloadData()
        }
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return funcExecutor == nil ? 0 : 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return funcExecutor?()?.inputCount ?? 0
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "input", for: indexPath) as UITableViewCell
        if let funcExecutor = funcExecutor?(), let input = funcExecutor.input(index: indexPath.row) {
            var name = input.descriptors.name ?? ""
            if let valueNumberMeasurementTypeDisplay = funcExecutor.readValueNumberMeasurementTypeDisplay(index: indexPath.row) {
                name = "\(name) (\(valueNumberMeasurementTypeDisplay))"
            }
            var details = "FuncExecutorWidget.input.none".localized
            if let value = funcExecutor.readValue(inputIndex: indexPath.row, formatted: true) as? String {
                details = value
            }
            
            cell.textLabel?.text = "\(indexPath.row + 1). \(name)"
            cell.detailTextLabel?.text = details
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        onSelect?(indexPath.row)
    }
    
    private class InputTableViewCell: UITableViewCell {
        override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
            super.init(style: .subtitle, reuseIdentifier: reuseIdentifier)
            backgroundColor = UIColor.clear
            accessoryType = .disclosureIndicator
            textLabel?.font = UIFont.boldSystemFont(ofSize: 14)
            textLabel?.textColor = UIColor.white.withAlphaComponent(0.55)
            detailTextLabel?.font = UIFont.boldSystemFont(ofSize: 14)
        }

        required init?(coder aDecoder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
    }
}
