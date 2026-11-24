import AuthCore
import Testing

@Suite("OpaqueToken")
struct OpaqueTokenTests {
    @Test("Makes a different 256-bit token each time, safe in a URL")
    func generatesTokens() {
        let first = OpaqueToken.generate()
        let second = OpaqueToken.generate()

        #expect(first.value != second.value)
        #expect(first.value.count == 43)
        #expect(!first.value.contains(where: { "+/=".contains($0) }))
    }

    @Test("Digests with SHA-256, as the repository stores it")
    func digestsWithSHA256() {
        // SHA-256 of "abc", from FIPS 180-2.
        #expect(OpaqueToken.digest(of: "abc") == "ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad")
    }
}
