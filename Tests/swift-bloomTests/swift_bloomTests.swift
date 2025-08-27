import Foundation
import Testing

@testable import swift_bloom

@Test func testBloomFilterBasicFunctionality() async throws {
    // Test with a small set of items and reasonable false positive rate
    let items = ["apple", "banana", "cherry", "date", "elderberry"]
    let falsePositiveRate = 0.01  // 1%

    let bloomFilter = BloomFilter(items: items, falsePositiveTolerance: falsePositiveRate)

    // All items should be found (no false negatives)
    for item in items {
        #expect(bloomFilter.contains(item), "Item '\(item)' should be found in the filter")
    }

    // Test some items that definitely weren't added
    let nonExistentItems = ["grape", "kiwi", "mango", "orange", "pineapple"]
    var falsePositives = 0

    for item in nonExistentItems {
        if bloomFilter.contains(item) {
            falsePositives += 1
        }
    }

    // Should have very few false positives with this rate
    #expect(falsePositives <= 1, "Too many false positives: \(falsePositives)")

    // Check statistics
    let stats = bloomFilter.getStatistics()
    #expect(stats["numberOfItems"] as? Int == items.count)
    #expect(stats["falsePositiveTolerance"] as? Double == falsePositiveRate)
    #expect(stats["numberOfBits"] as? Int ?? 0 > 0)
    #expect(stats["numberOfHashes"] as? Int ?? 0 > 0)
}

@Test func testBloomFilterFromData() async throws {
    // Create a filter with items
    let originalItems = ["test1", "test2", "test3", "test4", "test5"]
    let falsePositiveRate = 0.05

    let originalFilter = BloomFilter(
        items: originalItems,
        falsePositiveTolerance: falsePositiveRate
    )
    let filterData = originalFilter.getData()

    // Create a new filter from the data
    let reconstructedFilter = BloomFilter(
        data: filterData,
        falsePositiveTolerance: falsePositiveRate,
        numberOfItems: originalItems.count
    )

    // Both filters should behave identically
    for item in originalItems {
        #expect(originalFilter.contains(item) == reconstructedFilter.contains(item))
    }

    // Test with non-existent items
    let testItems = ["nonexistent1", "nonexistent2", "nonexistent3"]
    for item in testItems {
        #expect(originalFilter.contains(item) == reconstructedFilter.contains(item))
    }
}

@Test func testHashFunctions() async throws {
    // Test that hash functions produce consistent results
    let testString = "hello world"
    let bloomFilter = BloomFilter(items: [testString], falsePositiveTolerance: 0.01)

    // The same item should always be found
    #expect(bloomFilter.contains(testString))
    #expect(bloomFilter.contains(testString))
    #expect(bloomFilter.contains(testString))
}

@Test func testDoubleHashing() async throws {
    // Test that double hashing produces different indices
    let items = ["a", "b", "c", "d", "e", "f", "g", "h", "i", "j"]
    let bloomFilter = BloomFilter(items: items, falsePositiveTolerance: 0.01)

    // All items should be found
    for item in items {
        #expect(bloomFilter.contains(item), "Item '\(item)' should be found")
    }

    let stats = bloomFilter.getStatistics()
    let numberOfHashes = stats["numberOfHashes"] as? Int ?? 0
    #expect(numberOfHashes > 1, "Should use multiple hash functions")
}

@Test func testEmptyFilter() async throws {
    // Test with empty array
    let emptyFilter = BloomFilter(items: [], falsePositiveTolerance: 0.01)

    // Should not contain any items
    #expect(!emptyFilter.contains("anything"))
    #expect(!emptyFilter.contains(""))

    let stats = emptyFilter.getStatistics()
    #expect(stats["numberOfItems"] as? Int == 0)
}

@Test func testLargeDataset() async throws {
    // Test with a larger dataset
    let largeItems = (1...1000).map { "item\($0)" }
    let bloomFilter = BloomFilter(items: largeItems, falsePositiveTolerance: 0.001)  // 0.1%

    // All original items should be found
    var foundCount = 0
    for item in largeItems {
        if bloomFilter.contains(item) {
            foundCount += 1
        }
    }
    #expect(foundCount == largeItems.count, "All items should be found")

    // Test false positive rate with non-existent items
    let testItems = (1001...2000).map { "item\($0)" }
    var falsePositives = 0

    for item in testItems {
        if bloomFilter.contains(item) {
            falsePositives += 1
        }
    }

    let actualFalsePositiveRate = Double(falsePositives) / Double(testItems.count)
    // Should be close to the target rate (allowing some variance)
    #expect(
        actualFalsePositiveRate < 0.01,
        "False positive rate too high: \(actualFalsePositiveRate)"
    )
}

@Test func testValidBoundaryValues() async throws {
    // Test valid boundary values that should work
    let validFilter1 = BloomFilter(items: ["test"], falsePositiveTolerance: 0.001)
    #expect(validFilter1.contains("test"))

    let validFilter2 = BloomFilter(items: ["test"], falsePositiveTolerance: 0.999)
    #expect(validFilter2.contains("test"))

    // Test with very small tolerance
    let strictFilter = BloomFilter(items: ["item1", "item2"], falsePositiveTolerance: 0.0001)
    #expect(strictFilter.contains("item1"))
    #expect(strictFilter.contains("item2"))
}

@Test func testSpecialCharacters() async throws {
    // Test with various special characters and Unicode
    let specialItems = [
        "hello@world.com",
        "user123!",
        "αβγδε",  // Greek letters
        "🚀🌟💫",  // Emojis
        "test\nwith\nnewlines",
        "tab\tseparated",
        "",  // Empty string
    ]

    let bloomFilter = BloomFilter(items: specialItems, falsePositiveTolerance: 0.01)

    // All special items should be found
    for item in specialItems {
        #expect(bloomFilter.contains(item), "Special item '\(item)' should be found")
    }
}

@Test func testMurmurSeedFunctionality() async throws {
    let items = ["test1", "test2", "test3"]
    let falsePositiveRate = 0.01

    // Create filters with different seeds
    let filter1 = BloomFilter(
        items: items,
        falsePositiveTolerance: falsePositiveRate,
        murmurSeed: 0x12345678
    )
    let filter2 = BloomFilter(
        items: items,
        falsePositiveTolerance: falsePositiveRate,
        murmurSeed: 0x87654321
    )
    let filter3 = BloomFilter(items: items, falsePositiveTolerance: falsePositiveRate)  // Default seed

    // All filters should contain the original items
    for item in items {
        #expect(filter1.contains(item), "Filter1 should contain '\(item)'")
        #expect(filter2.contains(item), "Filter2 should contain '\(item)'")
        #expect(filter3.contains(item), "Filter3 should contain '\(item)'")
    }

    // Different seeds should produce different bit patterns
    let data1 = filter1.getData()
    let data2 = filter2.getData()
    let data3 = filter3.getData()

    // At least one of the filters should have different data (very high probability)
    let allSame = (data1 == data2) && (data2 == data3)
    #expect(!allSame, "Different seeds should produce different bit patterns")
}

@Test func testMurmurSeedFromData() async throws {
    let items = ["item1", "item2", "item3"]
    let customSeed: UInt32 = 0xABCDEF00

    // Create filter with custom seed
    let originalFilter = BloomFilter(
        items: items,
        falsePositiveTolerance: 0.05,
        murmurSeed: customSeed
    )
    let filterData = originalFilter.getData()

    // Debug: Print original filter stats
    let originalStats = originalFilter.getStatistics()
    print("Original filter stats: \(originalStats)")

    // Reconstruct with same seed
    let reconstructedFilter = BloomFilter(
        data: filterData,
        falsePositiveTolerance: 0.05,
        numberOfItems: items.count,
        murmurSeed: customSeed
    )

    // Debug: Print reconstructed filter stats
    let reconstructedStats = reconstructedFilter.getStatistics()
    print("Reconstructed filter stats: \(reconstructedStats)")

    // Verify the filters have the same parameters
    #expect(originalStats["numberOfBits"] as? Int == reconstructedStats["numberOfBits"] as? Int)
    #expect(originalStats["numberOfHashes"] as? Int == reconstructedStats["numberOfHashes"] as? Int)

    // Both filters should behave identically for original items
    for item in items {
        let originalContains = originalFilter.contains(item)
        let reconstructedContains = reconstructedFilter.contains(item)
        #expect(originalContains, "Original filter should contain '\(item)'")
        #expect(reconstructedContains, "Reconstructed filter should contain '\(item)'")
        #expect(originalContains == reconstructedContains, "Both filters should agree on '\(item)'")
    }

    // Test with different items - both should give same results
    let testItems = ["other1", "other2", "other3"]
    for item in testItems {
        let originalContains = originalFilter.contains(item)
        let reconstructedContains = reconstructedFilter.contains(item)
        #expect(
            originalContains == reconstructedContains,
            "Both filters should agree on test item '\(item)': original=\(originalContains), reconstructed=\(reconstructedContains)"
        )
    }
}

@Test func demonstrateBloomFilter() async throws {
    guard let data = Data(base64Encoded: "KnFnz7/dUDyK51HqlhTlswav") else {
        throw NSError(domain: "Invalid base64 data", code: 0, userInfo: nil)
    }

    let bloomFilter = BloomFilter(
        data: data,
        falsePositiveTolerance: 0.0001,
        numberOfItems: 10,
        murmurSeed: 3919904948
    )

    print("\n=== demonstrateBloomFilter Test ===")
    print(bloomFilter)
    print("=== End demonstrateBloomFilter Test ===\n")
}

@Test func testCustomStringConvertible() async throws {
    // Test the new CustomStringConvertible implementation
    let items = ["test", "demo", "swift"]
    let bloomFilter = BloomFilter(items: items, falsePositiveTolerance: 0.05)

    print("\n=== CustomStringConvertible Test ===")
    print(bloomFilter)
    print("=== End CustomStringConvertible Test ===\n")

    // Verify that description contains expected information
    let description = bloomFilter.description
    #expect(description.contains("BloomFilter {"))
    #expect(description.contains("numberOfBits:"))
    #expect(description.contains("numberOfHashes:"))
    #expect(description.contains("falsePositiveTolerance:"))
    #expect(description.contains("numberOfItems:"))
    #expect(description.contains("murmurSeed:"))
    #expect(description.contains("bitArray data:"))
    #expect(description.contains("Statistics:"))
}
