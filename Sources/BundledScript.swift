import Foundation

enum BundledScript {

    static func source(for script: StikJIT.Script) throws -> String {
        if case .custom(let url) = script {
            guard url.isFileURL else {
                throw StikJITError.customScript("expected a file URL")
            }
            do {
                let source = try String(contentsOf: url, encoding: .utf8)
                guard !source.isEmpty else {
                    throw StikJITError.customScript("the file at \(url.path) is empty")
                }
                return source
            } catch let error as StikJITError {
                throw error
            } catch {
                throw StikJITError.customScript("could not read \(url.path): \(error.localizedDescription)")
            }
        }

        let bundle = Bundle(for: BundleToken.self)
        guard let url = bundle.url(forResource: script.name, withExtension: "js"),
              let source = try? String(contentsOf: url, encoding: .utf8),
              !source.isEmpty else {
            throw StikJITError.scriptUnavailable
        }
        return source
    }
}

private final class BundleToken {}
