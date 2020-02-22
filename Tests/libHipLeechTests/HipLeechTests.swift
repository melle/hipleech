import XCTest
import libHipLeech

extension XCTestCase {

    /// Returns the content of a file from the Resources folder.
    func file(named: String, extension xtnsn: String) -> String {
        let thisSourceFile = URL(fileURLWithPath: #file)
        let thisDirectory = thisSourceFile.deletingLastPathComponent()
        let resourceURL = thisDirectory.appendingPathComponent("Resources/\(named).\(xtnsn)")
        return try! String(contentsOf: resourceURL).trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

