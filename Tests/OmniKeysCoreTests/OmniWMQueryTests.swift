import Foundation
@testable import OmniKeysCore
import Testing

struct OmniWMQueryTests {
    @Test func readsDisplayID() {
        let json = #"{"result":{"payload":{"display":{"id":"display:69734272"}}}}"#
        #expect(OmniWMQuery.focusedDisplayID(fromJSON: Data(json.utf8)) == 69_734_272)
    }

    @Test(arguments: ["", "not json", #"{"result":{}}"#, #"{"result":{"payload":{"display":{"id":"display:x"}}}}"#])
    func invalidInputIsNil(_ text: String) {
        #expect(OmniWMQuery.focusedDisplayID(fromJSON: Data(text.utf8)) == nil)
    }
}
