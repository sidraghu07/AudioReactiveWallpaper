import Foundation

enum ResourceLoader {
    static func url(forResource name: String, withExtension ext: String) -> URL? {
        if let bundledURL = Bundle.main.url(forResource: name, withExtension: ext) {
            return bundledURL
        }
        return Bundle.module.url(forResource: name, withExtension: ext)
    }
}
