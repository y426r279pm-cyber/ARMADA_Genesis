// Phase 1 fills this in. Two tests are already specified by the extraction work:
//
//   1. CanonicalSealTests — seal the entries in Resources/Seed.json and verify
//      the chain reproduces their hashes exactly. tools/verify_chain.py proves
//      this is reachable and shows what breaks it: a sorted-key encoder fails
//      at seq 1, and the failure reads as tampering rather than as an encoding
//      difference. Do not use JSONEncoder for the sealed payload.
//
//   2. StringAuditTests — walk AuditableStrings.all and fail on any string that
//      reads as a claim of fiscal validity or of control remediation. The RC2
//      brief, section 9, requires this; here it can fail the build.

import XCTest
@testable import BridgeKit

final class PlaceholderTests: XCTestCase {
    func testSchemaIsPopulated() {
        XCTAssertFalse(BridgeSchema.models.isEmpty)
    }
}
