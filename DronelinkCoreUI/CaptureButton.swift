//
//  CaptureButton.swift
//  DronelinkDJIUI
//
//  Created by Nicolas Torres on 1/12/20.
//  Copyright © 2020 Dronelink. All rights reserved.
//

import Foundation
import UIKit

public protocol CaptureButtonProtocol : class {
    func captureButtonTapped(_ sender: CaptureButton)
}

public class CaptureButton: UIButton {
    
    public weak var delegate: CaptureButtonProtocol?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        configeBtn()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        configeBtn()
    }
    
    func configeBtn() {
        self.addTarget(self, action: #selector(btnClicked(_:)), for: .touchUpInside)
    }
    
    @objc func btnClicked (_ sender:UIButton) {
        delegate?.captureButtonTapped(self)
    }
    
}
