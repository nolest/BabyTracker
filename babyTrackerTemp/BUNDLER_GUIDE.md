# 使用Bundler管理CocoaPods版本的說明

為了解決CocoaPods版本兼容性問題，我們使用Bundler來隔離和管理特定版本的CocoaPods。這樣可以在不影響系統全局CocoaPods版本的情況下，為項目使用兼容的1.11.3版本。

## 安裝步驟

1. **安裝Bundler**（如果尚未安裝）：
   ```
   gem install bundler
   ```

2. **安裝指定版本的CocoaPods**：
   在項目根目錄（包含Gemfile的目錄）執行：
   ```
   bundle install
   ```

3. **使用Bundler執行CocoaPods命令**：
   不要直接使用`pod install`，而是使用：
   ```
   bundle exec pod install
   ```

4. **清理CocoaPods緩存**（如果遇到問題）：
   ```
   bundle exec pod cache clean --all
   ```

## 故障排除

如果仍然遇到問題，可以嘗試：

1. 刪除Pods目錄和.xcworkspace文件：
   ```
   rm -rf Pods
   rm -rf *.xcworkspace
   ```

2. 重新執行安裝：
   ```
   bundle exec pod install
   ```

3. 如果問題持續，可以考慮使用更簡單的項目結構或切換到Swift Package Manager。
