Pod::Spec.new do |s|
  s.name = "DronelinkCoreUI"
  s.version = "1.5.0"
  s.summary = "Dronelink core UI components"
  s.homepage = "https://dronelink.com/"
  s.license = { :type => "MIT", :file => "LICENSE" }
  s.author = { "Dronelink" => "dev@dronelink.com" }
  s.swift_version = "5.0"
  s.platform = :ios
  s.ios.deployment_target  = "12.0"
  s.source = { :git => "https://github.com/dronelink/dronelink-core-ui-ios.git", :tag => "#{s.version}" }
  s.source_files  = "DronelinkCoreUI/**/*.swift"
  s.resources = "DronelinkCoreUI/**/*.{strings,xcassets}"

  s.dependency "DronelinkCore", "~> 1.7.0"
  s.dependency "SnapKit", "~> 5.0.1"
  s.dependency "MicrosoftMapsSDK", "~> 1.1.4"
  s.dependency "Mapbox-iOS-SDK", "~> 5.9.0"
  s.dependency "MaterialComponents/Palettes", "~> 115.0.0"
  s.dependency "MaterialComponents/Buttons", "~> 115.0.0"
  s.dependency "MaterialComponents/Buttons+Theming", "~> 115.0.0"
  s.dependency "MaterialComponents/TextFields", "~> 115.0.0"
  s.dependency "MaterialComponents/ProgressView", "~> 115.0.0"
  s.dependency "MaterialComponents/Dialogs", "~> 115.0.0"
  s.dependency "MaterialComponents/Dialogs+Theming", "~> 115.0.0"
  s.dependency "MaterialComponents/Snackbar", "~> 115.0.0"
  s.dependency "MaterialComponents/ActivityIndicator", "~> 115.0.0"
  s.dependency "Kingfisher", "~> 5.15.0"
  s.dependency "Agrume", "~> 5.6.9"
  s.dependency "IQKeyboardManager", "~> 6.5.6"
end
