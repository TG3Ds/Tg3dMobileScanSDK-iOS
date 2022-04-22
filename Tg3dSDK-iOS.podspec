Pod::Spec.new do |s|
  s.name             = 'Tg3dSDK-iOS'
  s.version          = '0.1.0'
  s.summary          = 'SDK for developing mobile-scan with Tg3d APIs.'
  s.description      = 'SDK for developing mobile-scan with Tg3d APIs.'
  s.homepage         = 'https://github.com/Wukon Hsieh/Tg3dSDK-iOS'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'tg3ddeveloper' => 'tg3ddeveloper@tg3ds.com' }
  s.platforms        = { :ios => "12.0" }
  s.source           = { :git => 'https://github.com/tg3ddeveloper/Tg3dSDK-iOS.git', :tag => s.version.to_s }

  s.ios.deployment_target = '12.0'

  s.source_files = 'Tg3dSDK-iOS/Classes/**/*'

  # s.dependency 'I3DRecorder', :git => 'https://github.com/in3D-io/in3D-iOS-SDK.git', :commit => 'c502760'

  # s.resource_bundles = {
  #   'Tg3dSDK-iOS' => ['Tg3dSDK-iOS/Assets/*.png']
  # }

  # s.public_header_files = 'Pod/Classes/**/*.h'
  # s.frameworks = 'UIKit', 'MapKit'
  # s.dependency 'AFNetworking', '~> 2.3'
end
