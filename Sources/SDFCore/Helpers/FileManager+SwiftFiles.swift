import Foundation

extension FileManager {

  /// Finds all the swift files at a given file URL
  /// If the baseURL is a folder, it will traverse all its subdirectories for any .swift file
  ///
  /// - Parameter baseURL: The URL to look for Swift files. It can either be a file or a directory
  /// - Returns: All the files with a .swift extension at the given URL or an empty array if none exist
  func swiftFiles(at baseURL: URL) -> [URL] {
    guard baseURL.hasDirectoryPath else {
      return baseURL.pathExtension == "swift" ? [baseURL] : []
    }

    var swiftFiles: [URL] = []

    guard let enumerator = self.enumerator(
      at: baseURL,
      includingPropertiesForKeys: nil,
      options: [.skipsHiddenFiles])
      else
    {
      return  []
    }

    for case let fileURL as URL in enumerator {
      if fileURL.pathExtension == "swift" {
        swiftFiles.append(fileURL.standardizedFileURL)
      }
    }

    return swiftFiles
  }

  /// Checks whether a URL contains a Swift file
  ///
  /// - Parameter baseURL: The URL to look for a Swift file
  /// - Returns: `true` if the URL contains a Swift file, `false` otherwise
  func isSwiftFile(at baseURL: URL) -> Bool {
    FileManager.default.fileExists(atPath: baseURL.path) && !baseURL.hasDirectoryPath && baseURL.pathExtension == "swift"
  }
}
