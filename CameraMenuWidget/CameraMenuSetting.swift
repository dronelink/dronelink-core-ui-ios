//
//  CameraMenuSetting.swift
//  DronelinkCoreUI
//
//  Created by santiago on 8/4/21.
//

import Foundation
import DronelinkCore

public enum CameraMenuSettingStyle {
    case options
    case toggle
    case action
}

public enum CameraMenuSetting {
    case photoMode
    case imageSize
    case imageFormat
    case whiteBalance
    case videoSize
    case videoFormat
    case ntscPal
    
    public var settingStyle: CameraMenuSettingStyle {
        switch self {
        case .photoMode,
             .imageSize,
             .imageFormat,
             .whiteBalance,
             .videoSize,
             .videoFormat,
             .ntscPal:
            return .options
        default: return .action
        }
    }
    
    public var options: [CameraMenuOption] {
        switch self {
        case .photoMode: return Kernel.CameraPhotoMode.allCases
        case .imageSize: return Kernel.CameraPhotoAspectRatio.allCases
        case .imageFormat: return Kernel.CameraPhotoFileFormat.allCases
        case .whiteBalance: return Kernel.CameraWhiteBalancePreset.allCases
        case .videoSize: return Kernel.CameraVideoResolution.allCases
        case .videoFormat: return Kernel.CameraVideoFileFormat.allCases
        case .ntscPal: return Kernel.CameraVideoStandard.allCases
        default: return []
        }
    }
    
    public var displayName: String {
        switch self {
        case .photoMode: return "CameraMenuSetting.photoMode".localized
        case .imageSize: return "CameraMenuSetting.imageSize".localized
        case .imageFormat: return "CameraMenuSetting.imageFormat".localized
        case .whiteBalance: return "CameraMenuSetting.whiteBalance".localized
        case .videoSize: return "CameraMenuSetting.videoSize".localized
        case .videoFormat: return "CameraMenuSetting.videoFormat".localized
        case .ntscPal: return "CameraMenuSetting.ntscPal".localized
        }
    }
}

public protocol CameraMenuOption {
    var displayName: String { get }
}

extension Kernel.CameraPhotoMode: CameraMenuOption {
    public var displayName: String {
        switch self {
        case .single: return "CameraPhotoMode.single".localized
        case .hdr: return "CameraPhotoMode.hdr".localized
        case .burst: return "CameraPhotoMode.burst".localized
        case .aeb: return "CameraPhotoMode.aeb".localized
        case .interval: return "CameraPhotoMode.interval".localized
        case .timeLapse: return "CameraPhotoMode.timeLapse".localized
        case .rawBurst: return "CameraPhotoMode.rawBurst".localized
        case .shallowFocus: return "CameraPhotoMode.shallowFocus".localized
        case .panorama: return "CameraPhotoMode.panorama".localized
        case .ehdr: return "CameraPhotoMode.ehdr".localized
        case .hyperLight: return "CameraPhotoMode.hyperLight".localized
        case .highResolution: return "CameraPhotoMode.highResolution".localized
        case .smart: return "CameraPhotoMode.smart".localized
        case .internalAISpotChecking: return "CameraPhotoMode.internalAISpotChecking".localized
        case .unknown: return "CameraPhotoMode.unknown".localized
        }
    }
}

extension Kernel.CameraPhotoAspectRatio: CameraMenuOption {
    public var displayName: String {
        switch self {
        case ._4x3: return "CameraPhotoAspectRatio._4x3".localized
        case ._16x9: return "CameraPhotoAspectRatio._16x9".localized
        case ._3x2: return "CameraPhotoAspectRatio._3x2".localized
        case .unknown: return "CameraPhotoAspectRatio.unknown".localized
        }
    }
}

extension Kernel.CameraPhotoFileFormat: CameraMenuOption {
    public var displayName: String {
        switch self {
        case .raw: return "CameraPhotoFileFormat.raw".localized
        case .jpeg: return "CameraPhotoFileFormat.jpeg".localized
        case .rawAndJpeg: return "CameraPhotoFileFormat.raw+jpeg".localized
        case .tiff14bit: return "CameraPhotoFileFormat.tiff14bit".localized
        case .radiometricJpeg: return "CameraPhotoFileFormat.radiometricJpeg".localized
        case .tiff14bitLinearLowTempResolution: return "CameraPhotoFileFormat.tiff14bitLinearLowTempResolution".localized
        case .tiff14bitLinearHighTempResolution: return "CameraPhotoFileFormat.tiff14bitLinearHighTempResolution".localized
        case .unknown: return "CameraPhotoFileFormat.unknown".localized
        }
    }
}

extension Kernel.CameraWhiteBalancePreset: CameraMenuOption {
    public var displayName: String {
        switch self {
        case .auto: return "CameraWhiteBalancePreset.auto".localized
        case .sunny: return "CameraWhiteBalancePreset.sunny".localized
        case .cloudy: return "CameraWhiteBalancePreset.cloudy".localized
        case .waterSurface: return "CameraWhiteBalancePreset.waterSurface".localized
        case .indoorIncandescent: return "CameraWhiteBalancePreset.indoorIncandescent".localized
        case .indoorFluorescent: return "CameraWhiteBalancePreset.indoorFluorescent".localized
        case .custom: return "CameraWhiteBalancePreset.custom".localized
        case .neutral: return "CameraWhiteBalancePreset.neutral".localized
        case .unknown: return "CameraWhiteBalancePreset.unknown".localized
        }
    }
}

extension Kernel.CameraVideoResolution: CameraMenuOption {
    public var displayName: String {
        switch self {
        case ._336x256: return "CameraVideoResolution.336x256".localized
        case ._640x360: return "CameraVideoResolution.640x360".localized
        case ._640x480: return "CameraVideoResolution.640x480".localized
        case ._640x512: return "CameraVideoResolution.640x512".localized
        case ._1280x720: return "CameraVideoResolution.1280x720".localized
        case ._1920x1080: return "CameraVideoResolution.1920x1080".localized
        case ._2048x1080: return "CameraVideoResolution.2048x1080".localized
        case ._2688x1512: return "CameraVideoResolution.2688x1512".localized
        case ._2704x1520: return "CameraVideoResolution.2704x1520".localized
        case ._2720x1530: return "CameraVideoResolution.2720x1530".localized
        case ._3712x2088: return "CameraVideoResolution.3712x2088".localized
        case ._3840x1572: return "CameraVideoResolution.3840x1572".localized
        case ._3840x2160: return "CameraVideoResolution.3840x2160".localized
        case ._3944x2088: return "CameraVideoResolution.3944x2088".localized
        case ._4096x2160: return "CameraVideoResolution.4096x2160".localized
        case ._4608x2160: return "CameraVideoResolution.4608x2160".localized
        case ._4608x2592: return "CameraVideoResolution.4608x2592".localized
        case ._5280x2160: return "CameraVideoResolution.5280x2160".localized
        case ._5280x2972: return "CameraVideoResolution.5280x2972".localized
        case ._5760x3240: return "CameraVideoResolution.5760x3240".localized
        case ._6016x3200: return "CameraVideoResolution.6016x3200".localized
        case .max: return "CameraVideoResolution.max".localized
        case .noSSDVideo: return "CameraVideoResolution.noSSDVideo".localized
        case .unknown: return "CameraVideoResolution.unknown".localized
        }
    }
}

extension Kernel.CameraVideoFileFormat: CameraMenuOption {
    public var displayName: String {
        switch self {
        case .mov: return "CameraVideoFileFormat.mov".localized
        case .mp4: return "CameraVideoFileFormat.mp4".localized
        case .tiffSequence: return "CameraVideoFileFormat.tiffSequence".localized
        case .seq: return "CameraVideoFileFormat.seq".localized
        case .unknown: return "CameraVideoFileFormat.unknown".localized
        }
    }
}

extension Kernel.CameraVideoStandard: CameraMenuOption {
    public var displayName: String {
        switch self {
        case .pal: return "CameraVideoStandard.pal".localized
        case .ntsc: return "CameraVideoStandard.ntsc".localized
        case .unknown: return "CameraVideoStandard.unknown".localized
        }
    }
}
