import Foundation

public enum OmniWMQuery {
    /// Parses `omniwmctl query focused-monitor --format json`, whose display id looks like
    /// "display:<CGDirectDisplayID>".
    public static func focusedDisplayID(fromJSON data: Data) -> UInt32? {
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let result = json["result"] as? [String: Any],
              let payload = result["payload"] as? [String: Any],
              let display = payload["display"] as? [String: Any],
              let id = display["id"] as? String,
              let number = id.split(separator: ":").last
        else { return nil }
        return UInt32(number)
    }
}
