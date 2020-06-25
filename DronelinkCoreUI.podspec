Pod::Spec.new do |s|
  s.name = "DronelinkCoreUI"
  s.version = "1.4.1"
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

  s.dependency "DronelinkCore", "~> 1.6.1"
  s.dependency "SnapKit", "~> 5.0.1"
  s.dependency "MicrosoftMapsSDK", "~> 1.1.4"
  s.dependency "Mapbox-iOS-SDK", "~> 5.9.0"
  s.dependency "MaterialComponents/Palettes", "~> 109.7.0"
  s.dependency "MaterialComponents/Buttons", "~> 109.7.0"
  s.dependency "MaterialComponents/Buttons+Theming", "~> 109.7.0"
  s.dependency "MaterialComponents/TextFields", "~> 109.7.0"
  s.dependency "MaterialComponents/ProgressView", "~> 109.7.0"
  s.dependency "MaterialComponents/Dialogs", "~> 109.7.0"
  s.dependency "MaterialComponents/Dialogs+Theming", "~> 109.7.0"
  s.dependency "MaterialComponents/Snackbar", "~> 109.7.0"
  s.dependency "MaterialComponents/ActivityIndicator", "~> 109.7.0"
  s.dependency "Kingfisher", "~> 5.14.0"
  s.dependency "Agrume", "~> 5.6.8"
  s.dependency "IQKeyboardManager", "~> 6.5.5"
end
