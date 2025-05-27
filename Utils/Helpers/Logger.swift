import Foundation
import os.log

/// 日誌工具類
class Logger {
    // MARK: - 日誌類別
    
    /// 日誌類別
    enum Category: String {
        /// 應用
        case app = "App"
        
        /// 網絡
        case network = "Network"
        
        /// 數據庫
        case database = "Database"
        
        /// UI
        case ui = "UI"
        
        /// AI
        case ai = "AI"
        
        /// 雲端
        case cloud = "Cloud"
        
        /// 安全
        case security = "Security"
    }
    
    // MARK: - 日誌級別
    
    /// 日誌級別
    enum Level {
        /// 調試
        case debug
        
        /// 信息
        case info
        
        /// 警告
        case warning
        
        /// 錯誤
        case error
        
        /// 嚴重錯誤
        case fatal
        
        /// 獲取OSLog類型
        var osLogType: OSLogType {
            switch self {
            case .debug:
                return .debug
            case .info:
                return .info
            case .warning:
                return .default
            case .error:
                return .error
            case .fatal:
                return .fault
            }
        }
        
        /// 獲取前綴
        var prefix: String {
            switch self {
            case .debug:
                return "🔍 DEBUG"
            case .info:
                return "ℹ️ INFO"
            case .warning:
                return "⚠️ WARNING"
            case .error:
                return "❌ ERROR"
            case .fatal:
                return "🔥 FATAL"
            }
        }
    }
    
    // MARK: - 屬性
    
    /// 是否啟用控制台日誌
    static var isConsoleLoggingEnabled = true
    
    /// 是否啟用文件日誌
    static var isFileLoggingEnabled = false
    
    /// 最低日誌級別
    static var minimumLogLevel: Level = .debug
    
    /// 日誌文件URL
    private static var logFileURL: URL? = {
        guard let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return nil
        }
        
        return documentsDirectory.appendingPathComponent("BabyTracker.log")
    }()
    
    // MARK: - 日誌方法
    
    /// 記錄調試日誌
    /// - Parameters:
    ///   - message: 消息
    ///   - category: 類別
    ///   - file: 文件
    ///   - function: 函數
    ///   - line: 行號
    static func debug(_ message: String, category: Category = .app, file: String = #file, function: String = #function, line: Int = #line) {
        log(message, level: .debug, category: category, file: file, function: function, line: line)
    }
    
    /// 記錄信息日誌
    /// - Parameters:
    ///   - message: 消息
    ///   - category: 類別
    ///   - file: 文件
    ///   - function: 函數
    ///   - line: 行號
    static func info(_ message: String, category: Category = .app, file: String = #file, function: String = #function, line: Int = #line) {
        log(message, level: .info, category: category, file: file, function: function, line: line)
    }
    
    /// 記錄警告日誌
    /// - Parameters:
    ///   - message: 消息
    ///   - category: 類別
    ///   - file: 文件
    ///   - function: 函數
    ///   - line: 行號
    static func warning(_ message: String, category: Category = .app, file: String = #file, function: String = #function, line: Int = #line) {
        log(message, level: .warning, category: category, file: file, function: function, line: line)
    }
    
    /// 記錄錯誤日誌
    /// - Parameters:
    ///   - message: 消息
    ///   - category: 類別
    ///   - file: 文件
    ///   - function: 函數
    ///   - line: 行號
    static func error(_ message: String, category: Category = .app, file: String = #file, function: String = #function, line: Int = #line) {
        log(message, level: .error, category: category, file: file, function: function, line: line)
    }
    
    /// 記錄嚴重錯誤日誌
    /// - Parameters:
    ///   - message: 消息
    ///   - category: 類別
    ///   - file: 文件
    ///   - function: 函數
    ///   - line: 行號
    static func fatal(_ message: String, category: Category = .app, file: String = #file, function: String = #function, line: Int = #line) {
        log(message, level: .fatal, category: category, file: file, function: function, line: line)
    }
    
    /// 記錄日誌
    /// - Parameters:
    ///   - message: 消息
    ///   - level: 級別
    ///   - category: 類別
    ///   - file: 文件
    ///   - function: 函數
    ///   - line: 行號
    private static func log(_ message: String, level: Level, category: Category, file: String, function: String, line: Int) {
        // 檢查日誌級別
        guard level.osLogType.rawValue >= minimumLogLevel.osLogType.rawValue else {
            return
        }
        
        // 獲取文件名
        let fileName = (file as NSString).lastPathComponent
        
        // 格式化日誌消息
        let logMessage = "\(level.prefix) [\(category.rawValue)] \(fileName):\(line) \(function) - \(message)"
        
        // 控制台日誌
        if isConsoleLoggingEnabled {
            let log = OSLog(subsystem: Bundle.main.bundleIdentifier ?? "com.babytracker", category: category.rawValue)
            os_log("%{public}@", log: log, type: level.osLogType, logMessage)
        }
        
        // 文件日誌
        if isFileLoggingEnabled {
            writeToLogFile(logMessage)
        }
    }
    
    /// 寫入日誌文件
    /// - Parameter message: 消息
    private static func writeToLogFile(_ message: String) {
        guard let logFileURL = logFileURL else {
            return
        }
        
        // 獲取當前時間
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS"
        let timestamp = dateFormatter.string(from: Date())
        
        // 格式化日誌消息
        let logMessage = "\(timestamp) \(message)\n"
        
        // 寫入文件
        do {
            let fileHandle: FileHandle
            
            // 檢查文件是否存在
            if FileManager.default.fileExists(atPath: logFileURL.path) {
                // 打開文件
                fileHandle = try FileHandle(forWritingTo: logFileURL)
                // 移動到文件末尾
                fileHandle.seekToEndOfFile()
            } else {
                // 創建文件
                try logMessage.write(to: logFileURL, atomically: true, encoding: .utf8)
                return
            }
            
            // 寫入日誌
            if let data = logMessage.data(using: .utf8) {
                fileHandle.write(data)
            }
            
            // 關閉文件
            fileHandle.closeFile()
        } catch {
            print("無法寫入日誌文件: \(error)")
        }
    }
    
    /// 清除日誌文件
    static func clearLogFile() {
        guard let logFileURL = logFileURL else {
            return
        }
        
        do {
            try "".write(to: logFileURL, atomically: true, encoding: .utf8)
        } catch {
            print("無法清除日誌文件: \(error)")
        }
    }
    
    /// 獲取日誌文件內容
    /// - Returns: 日誌文件內容
    static func getLogFileContents() -> String? {
        guard let logFileURL = logFileURL else {
            return nil
        }
        
        do {
            return try String(contentsOf: logFileURL, encoding: .utf8)
        } catch {
            print("無法讀取日誌文件: \(error)")
            return nil
        }
    }
}
