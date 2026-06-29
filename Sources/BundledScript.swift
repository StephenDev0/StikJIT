import Foundation

enum BundledScript {

    static func source(for script: StikJIT.Script) throws -> String {
        let bundle = Bundle(for: BundleToken.self)
        guard let url = bundle.url(forResource: script.resourceName, withExtension: "js"),
              let source = try? String(contentsOf: url, encoding: .utf8),
              !source.isEmpty else {
            throw StikJITError.scriptUnavailable
        }
        return source
    }
}

private final class BundleToken {}
