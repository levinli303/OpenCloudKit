import XCTest

#if !canImport(ObjectiveC)
public func allTests() -> [XCTestCaseEntry] {
    return [
        testCase(CKRecordTests.allTests),
        testCase(CKRecordZoneTests.allTests),
    ]
}
#endif

