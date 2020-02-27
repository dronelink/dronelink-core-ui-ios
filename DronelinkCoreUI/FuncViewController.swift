//
//  FuncViewController.swift
//  DronelinkCoreUI
//
//  Created by Jim McAndrew on 1/30/20.
//  Copyright © 2020 Dronelink. All rights reserved.
//
import DronelinkCore
import Foundation
import UIKit
import MaterialComponents.MaterialButtons
import MaterialComponents.MaterialButtons_Theming
import MaterialComponents.MaterialTextFields

public class FuncViewController: UIViewController {
    public static func create(droneSessionManager: DroneSessionManager) -> FuncViewController {
        let funcViewController = FuncViewController()
        funcViewController.droneSessionManager = droneSessionManager
        return funcViewController
    }
    
    private var droneSessionManager: DroneSessionManager!
    private var session: DroneSession?
    private var funcExecutor: FuncExecutor?
    private let blurEffectView = UIVisualEffectView(effect: UIBlurEffect(style: .dark))
    private let primaryButton = MDCRaisedButton()
    private let backButton = MDCFlatButton()
    private let nextButton = MDCRaisedButton()
    private let titleImageView = UIImageView()
    private let titleLabel = UILabel()
    private let variableNameLabel = UILabel()
    private let variableDescriptionLabel = UILabel()
    private let variableSegmentedControl = UISegmentedControl()
    private let variableTextField = MDCTextField()
    private let variablePickerView = UIPickerView()
    private let variableDroneMarkButton = MDCButton()
    private let variableDroneTextView = UITextView()
    private let variableDroneClearButton = UIButton(type: .custom)
    private let variableSummaryTextView = UITextView()
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
    private var hasInputs: Bool { funcExecutor?.inputCount ?? 0 > 0 }
    private var input: Mission.FuncInput? { funcExecutor?.input(index: inputIndex) }
    private func valueNumberMeasurementTypeDisplay(index: Int? = nil) -> String? { funcExecutor?.readValueNumberMeasurementTypeDisplay(index: index ?? inputIndex) }
    private var executing = false
    private var value: Any?
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        if #available(iOS 13.0, *) {
            overrideUserInterfaceStyle = .dark
        }
        
        blurEffectView.frame = view.bounds
        blurEffectView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        blurEffectView.layer.cornerRadius = DronelinkUI.Constants.cornerRadius
        blurEffectView.clipsToBounds = true
        view.addSubview(blurEffectView)
        
        view.addShadow()
        view.layer.cornerRadius = DronelinkUI.Constants.cornerRadius
        
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
        
        variableDescriptionLabel.font = UIFont.boldSystemFont(ofSize: 12)
        variableDescriptionLabel.textColor = UIColor.white.withAlphaComponent(0.85)
        variableDescriptionLabel.numberOfLines = 2
        variableDescriptionLabel.lineBreakMode = .byTruncatingTail
        variableDescriptionLabel.minimumScaleFactor = 0.5
        variableDescriptionLabel.adjustsFontSizeToFitWidth = true
        view.addSubview(variableDescriptionLabel)
        
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
        scheme.colorScheme.primaryColor = .white
        variableDroneMarkButton.applyOutlinedTheme(withScheme: scheme)
        variableDroneMarkButton.translatesAutoresizingMaskIntoConstraints = false
        variableDroneMarkButton.setImage(droneImage?.withRenderingMode(.alwaysTemplate), for: .normal)
        variableDroneMarkButton.imageView?.contentMode = .scaleAspectFit
        variableDroneMarkButton.tintColor = UIColor.white
        variableDroneMarkButton.setTitle("FuncViewController.input.drone".localized, for: .normal)
        variableDroneMarkButton.addTarget(self, action: #selector(onDroneMark(sender:)), for: .touchUpInside)
        view.addSubview(variableDroneMarkButton)
        
        variableDroneTextView.textContainerInset = .zero
        variableDroneTextView.backgroundColor = UIColor.clear
        variableDroneTextView.font = UIFont.boldSystemFont(ofSize: 10)
        variableDroneTextView.textColor = UIColor.white.withAlphaComponent(0.85)
        variableDroneTextView.isScrollEnabled = true
        variableDroneTextView.isEditable = false
        view.addSubview(variableDroneTextView)
        
        variableDroneClearButton.tintColor = UIColor.white.withAlphaComponent(0.85)
        variableDroneClearButton.setImage(DronelinkUI.loadImage(named: "baseline_cancel_white_36pt"), for: .normal)
        variableDroneClearButton.addTarget(self, action: #selector(onDroneClear), for: .touchUpInside)
        view.addSubview(variableDroneClearButton)
        
        variableSummaryTextView.textContainerInset = .zero
        variableSummaryTextView.backgroundColor = UIColor.clear
        variableSummaryTextView.font = UIFont.boldSystemFont(ofSize: 12)
        variableSummaryTextView.textColor = UIColor.white.withAlphaComponent(0.85)
        variableSummaryTextView.isScrollEnabled = true
        variableSummaryTextView.isEditable = false
        view.addSubview(variableSummaryTextView)
        
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
        Dronelink.shared.add(delegate: self)
        droneSessionManager.add(delegate: self)
        update()
    }
    
    public override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        Dronelink.shared.remove(delegate: self)
        droneSessionManager.remove(delegate: self)
        funcExecutor?.remove(delegate: self)
    }
    
    public override func updateViewConstraints() {
        super.updateViewConstraints()
        
        let defaultPadding = 10
        
        blurEffectView.snp.remakeConstraints { make in
            make.edges.equalToSuperview()
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
        
        variableDescriptionLabel.snp.remakeConstraints { make in
            make.left.equalTo(variableNameLabel.snp.left)
            make.right.equalToSuperview().offset(-defaultPadding)
            if intro {
                make.top.equalTo(titleLabel.snp.bottom).offset(defaultPadding)
            }
            else {
                make.top.equalTo(variableNameLabel.snp.bottom).offset(4)
            }
        }
        
        let variableControl = !intro && (input?.descriptors.description?.isEmpty ?? true) ? variableNameLabel : variableDescriptionLabel
        
        variableSegmentedControl.snp.remakeConstraints { make in
            make.left.equalToSuperview().offset(defaultPadding)
            make.right.equalToSuperview().offset(-defaultPadding)
            make.top.equalTo(variableControl.snp.bottom).offset(defaultPadding)
            make.height.equalTo(30)
        }
        
        variableTextField.snp.remakeConstraints { make in
            make.left.equalToSuperview().offset(defaultPadding)
            make.right.equalToSuperview().offset(-defaultPadding)
            make.top.equalTo(variableControl.snp.bottom).offset(-5)
            make.height.equalTo(40)
        }
        
        variablePickerView.snp.remakeConstraints { make in
            make.left.equalToSuperview().offset(defaultPadding)
            make.right.equalToSuperview().offset(-defaultPadding)
            make.top.equalTo(variableControl.snp.bottom).offset(-5)
            make.height.equalTo(80)
        }
        
        variableDroneMarkButton.snp.remakeConstraints { make in
            make.left.equalToSuperview().offset(defaultPadding)
            make.width.equalTo(110)
            make.top.equalTo(variableControl.snp.bottom).offset(defaultPadding)
            make.height.equalTo(40)
        }
        
        variableDroneClearButton.snp.remakeConstraints { make in
            make.height.equalTo(25)
            make.width.equalTo(variableDroneClearButton.snp.height)
            make.right.equalToSuperview().offset(-defaultPadding)
            make.top.equalTo(variableDroneMarkButton)
        }
        
        variableDroneTextView.snp.remakeConstraints { make in
            make.left.equalTo(variableDroneMarkButton.snp.right).offset(5)
            make.right.equalTo(variableDroneClearButton.snp.left).offset(5)
            make.top.equalTo(variableDroneMarkButton)
            make.bottom.equalTo(backButton.snp.top).offset(-defaultPadding)
        }
        
        variableSummaryTextView.snp.remakeConstraints { make in
            make.left.equalTo(variableDescriptionLabel)
            make.right.equalTo(variableDescriptionLabel)
            make.top.equalTo(variableNameLabel.snp.bottom).offset(defaultPadding)
            make.bottom.equalTo(backButton.snp.top).offset(-defaultPadding)
        }
        
        backButton.snp.remakeConstraints { make in
            make.left.equalToSuperview().offset(defaultPadding)
            make.bottom.equalToSuperview().offset(-defaultPadding)
            make.height.equalTo(35)
            make.width.equalTo(85)
        }
        
        progressLabel.snp.remakeConstraints { make in
            make.left.equalTo(backButton.snp.right).offset(defaultPadding)
            make.right.equalTo(nextButton.snp.left).offset(-defaultPadding)
            make.top.equalTo(backButton)
            make.bottom.equalTo(backButton)
        }
        
        nextButton.snp.remakeConstraints { make in
            make.right.equalToSuperview().offset(-defaultPadding)
            make.height.equalTo(backButton)
            make.width.equalTo(last ? 200 : 85)
            make.bottom.equalTo(backButton)
        }
        
        primaryButton.snp.remakeConstraints { make in
            make.height.equalTo(35)
            make.left.equalToSuperview().offset(defaultPadding)
            make.right.equalToSuperview().offset(-defaultPadding)
            make.bottom.equalToSuperview().offset(-defaultPadding)
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
            intro = false
            readValue()
            view.setNeedsUpdateConstraints()
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
        inputIndex -= 1
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
        
        funcExecutor?.addNextDynamicInput(droneSession: session) { error in
            DispatchQueue.main.async {
                DronelinkUI.shared.showSnackbar(text: error)
                self.inputIndex -= 1
                self.readValue()
                self.view.setNeedsUpdateConstraints()
           }
       }
        
        inputIndex += 1
        variableTextField.resignFirstResponder()
        readValue()
        view.setNeedsUpdateConstraints()
    }
    
    @objc func onDroneMark(sender: Any) {
        if session == nil {
            DronelinkUI.shared.showSnackbar(text: "FuncViewController.input.drone.unavailable".localized)
            return
        }
        
        writeValue()
        readValue()
    }
    
    @objc func onDroneClear(sender: Any) {
        funcExecutor?.clearValue(index: inputIndex)
        readValue()
    }
    
    @objc func onDismiss() {
        Dronelink.shared.unloadFunc()
    }
    
    @discardableResult
    func writeValue(next: Bool = false) -> Bool {
        guard let input = input else {
            return false
        }
        
        var value: Any? = nil
        switch input.variable.valueType {
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
                    if funcExecutor?.readValue(index: inputIndex) == nil && !input.optional {
                        DronelinkUI.shared.showSnackbar(text: "FuncViewController.input.required".localized)
                        return false
                    }
                    return true
                }
                value = session
                break
            
            @unknown default:
                break
        }
        
        if !input.optional && value == nil {
            DronelinkUI.shared.showSnackbar(text: "FuncViewController.input.required".localized)
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
        variableDroneTextView.text = ""
        
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
        
        guard let value = funcExecutor?.readValue(index: inputIndex) else {
            self.value = nil
            update()
            return
        }
        self.value = value
        update()
        
        if input.variable.valueType == .drone {
            if let valueString = value as? String {
                variableDroneTextView.text = valueString
            }
            
            if let valueArray = value as? [Any] {
                let valueArrayStrings = valueArray.reversed().enumerated().map { value -> String in
                    if let valueString = value.element as? String {
                        return "\(valueArray.count - value.offset). \(valueString)"
                    }
                    return ""
                }
                
                variableDroneTextView.text = valueArrayStrings.joined(separator: "\n")
            }
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
    
    var summary: String {
        guard let funcExecutor = funcExecutor else {
            return ""
        }
        
        var summary: [String] = []
        for index in 0..<funcExecutor.inputCount {
            if let input = funcExecutor.input(index: index) {
                var details = "FuncViewController.input.none".localized
                if let value = funcExecutor.readValue(index: index, formatted: true) as? String {
                    details = value
                }
                
                var name = input.descriptors.name ?? ""
                if let valueNumberMeasurementTypeDisplay = self.valueNumberMeasurementTypeDisplay(index: index) {
                    name = "\(name) (\(valueNumberMeasurementTypeDisplay))"
                }
                
                summary.append("\(index + 1). \(name)\n\(details)")
            }
        }
        
        return summary.joined(separator: "\n\n")
    }
    
    func update() {
        guard let funcExecutor = funcExecutor else {
            return
        }

        titleImageView.isHidden = true
        titleLabel.isHidden = true
        variableNameLabel.isHidden = true
        variableDescriptionLabel.isHidden = true
        variableSegmentedControl.isHidden = true
        variableTextField.isHidden = true
        variablePickerView.isHidden = true
        variableDroneMarkButton.isHidden = true
        variableDroneClearButton.isHidden = true
        variableDroneTextView.isHidden = true
        variableSummaryTextView.isHidden = true
        
        if intro {
            titleImageView.isHidden = false
            titleLabel.isHidden = false
            variableDescriptionLabel.isHidden = false
            backButton.isHidden = true
            nextButton.isHidden = true
            progressLabel.isHidden = true
            primaryButton.isHidden = false

            titleLabel.text = funcExecutor.descriptors.name
            primaryButton.setTitle((executing ? "FuncViewController.primary.executing" : hasInputs ? "FuncViewController.primary.intro" : "FuncViewController.primary.execute").localized, for: .normal)
            variableDescriptionLabel.text = funcExecutor.descriptors.description
            return
        }

        primaryButton.isHidden = true
        backButton.isHidden = false
        backButton.isEnabled = inputIndex > 0
        nextButton.isHidden = false
        nextButton.setTitle((last ? "FuncViewController.primary.execute" : "next").localized, for: .normal)
        progressLabel.isHidden = last
        progressLabel.text = "\(inputIndex + 1) / \(funcExecutor.inputCount)"
        
        if let input = input {
            variableNameLabel.isHidden = false
            var name = input.descriptors.name ?? ""
            if let valueNumberMeasurementTypeDisplay = self.valueNumberMeasurementTypeDisplay() {
                name = "\(name) (\(valueNumberMeasurementTypeDisplay))"
            }
            
            if !input.optional {
                name = "\(name) *"
            }
            variableNameLabel.text = name
            
            if !(input.descriptors.description?.isEmpty ?? true) {
                variableDescriptionLabel.isHidden = false
                variableDescriptionLabel.text = input.descriptors.description
            }

            switch input.variable.valueType {
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
                variableDroneTextView.isHidden = false
                variableDroneClearButton.isHidden = value == nil
                break
            
            @unknown default:
                break
            }
            return
        }
        
        if last {
            variableNameLabel.isHidden = false
            variableNameLabel.text = "FuncViewController.input.summary".localized
            variableSummaryTextView.isHidden = false
            variableSummaryTextView.text = summary
            return
        }
    }
}

extension FuncViewController: UIPickerViewDataSource, UIPickerViewDelegate {
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
            return "FuncViewController.input.choose".localized
        }
        return input.enumValues?[safeIndex: row - 1] ?? ""
    }
}

extension FuncViewController: DronelinkDelegate {
    public func onRegistered(error: String?) {}
    
    public func onMissionLoaded(executor: MissionExecutor) {
        Dronelink.shared.unloadFunc()
    }
    
    public func onMissionUnloaded(executor: MissionExecutor) {
    }
    
    public func onFuncLoaded(executor: FuncExecutor) {
        funcExecutor = executor
        executor.add(delegate: self)
        DispatchQueue.main.async {
            self.inputIndex = 0
            if !self.hasInputs {
                executor.addNextDynamicInput(droneSession: self.session) { error in
                     DispatchQueue.main.async {
                         DronelinkUI.shared.showSnackbar(text: error)
                    }
                }
            }
            
            self.intro = true
            self.view.setNeedsUpdateConstraints()
        }
    }
    
    public func onFuncUnloaded(executor: FuncExecutor) {
        funcExecutor = nil
        executor.remove(delegate: self)
        DispatchQueue.main.async {
            self.view.setNeedsUpdateConstraints()
        }
    }
}

extension FuncViewController: DroneSessionManagerDelegate {
    public func onOpened(session: DroneSession) {
        self.session = session
        DispatchQueue.main.async {
            self.view.setNeedsUpdateConstraints()
        }
    }
    
    public func onClosed(session: DroneSession) {
        self.session = nil
        DispatchQueue.main.async {
            self.view.setNeedsUpdateConstraints()
        }
    }
}

extension FuncViewController: FuncExecutorDelegate {
    public func onFuncExecuted(executor: FuncExecutor) {
    }
}

extension FuncViewController: UITextFieldDelegate {
    public func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}
