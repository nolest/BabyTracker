# Podfile
platform :ios, '15.0'

target 'BabyTracker' do
  use_frameworks!

  # 網絡請求
  pod 'Alamofire', '~> 5.6'
  
  # 圖片加載
  pod 'Kingfisher', '~> 7.0'
  
  # 可能需要的其他庫
  pod 'SwiftLint', '~> 0.47'
  
  target 'BabyTrackerTests' do
    inherit! :search_paths
  end

  target 'BabyTrackerUITests' do
    inherit! :search_paths
  end
end