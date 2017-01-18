Pod::Spec.new do |s|
  s.name         = "ZZProgressHUD"
  s.version      = "0.0.1"
  s.summary      = "ZZProgressHUD, a swift version of MBProgressHUD for iOS9 and later  "
  s.description  = <<-DESC
a swift version of MBProgressHUD for iOS9 and later. you can use this instead if you want to develop in a pure swift environment
                   DESC

  s.homepage     = "https://github.com/zerozheng/ZZProgressHUD"
  s.license      = { :type => "MIT", :file => "LICENSE" }
  s.author    = "zero"
  s.platform     = :ios, "9.0"
  s.source       = { :git => "https://github.com/zerozheng/ZZProgressHUD.git", :tag => s.version }
  s.source_files  = "sources", "sources/**/*.{h,m}"
  s.resources = "sources/ProgressHUD.bundle/**/*.png"
  s.framework  = "UIKit"
  s.pod_target_xcconfig = { 'swift-version' => '3.0' }

end
