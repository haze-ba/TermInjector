import Cocoa

/// ファイルドロップ処理
enum FileDropHandler {

    /// URLリストからファイルパス文字列を抽出する
    /// - Parameter urls: ドロップされたファイルURL
    /// - Returns: 絶対パスの配列
    static func processDroppedURLs(_ urls: [URL]) -> [String] {
        return urls
            .filter { $0.isFileURL }
            .map { $0.path }
    }

    /// ファイルパスの配列をテキスト入力用に整形する
    /// - Parameter paths: 絶対パスの配列
    /// - Returns: 整形されたパス文字列
    static func formatPaths(_ paths: [String]) -> String {
        guard !paths.isEmpty else { return "" }

        if paths.count == 1 {
            return escapePath(paths[0])
        }

        return paths.map { escapePath($0) }.joined(separator: " ")
    }

    /// シェルメタ文字を安全にエスケープする
    /// シングルクォートで囲み、パス内のシングルクォートは '\'' でエスケープ
    static func escapePath(_ path: String) -> String {
        // シェルメタ文字を含まない安全なパスはそのまま返す
        let shellUnsafeCharacters = CharacterSet(charactersIn: " \t\n\"'`$\\(){}[]|&;<>!?#~*")
        if path.unicodeScalars.allSatisfy({ !shellUnsafeCharacters.contains($0) }) {
            return path
        }
        // シングルクォートで囲む。パス内の ' は '\'' に置換
        let escaped = path.replacingOccurrences(of: "'", with: "'\\''")
        return "'\(escaped)'"
    }
}
