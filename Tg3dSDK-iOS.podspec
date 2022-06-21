Pod::Spec.new do |s|
  s.name             = 'Tg3dMobileScanSDK-iOS'
  s.version          = '1.0.1'
  s.summary          = 'SDK for developing mobile-scan app with TG3DS ScanAPIs.'
  s.description      = 'SDK for developing mobile-scan app with TG3DS ScanAPIs.'
  s.homepage         = 'https://github.com/TG3Ds/Tg3dMobileScanSDK-iOS'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'tg3ddeveloper' => 'tg3ddeveloper@tg3ds.com' }
  s.platforms        = { :ios => "12.0" }
  s.source           = { :git => 'https://github.com/TG3Ds/Tg3dMobileScanSDK-iOS.git', :tag => s.version.to_s }

  s.ios.deployment_target = '12.0'

  s.source_files = 'Tg3dSDK-iOS/Classes/**/*'

end
