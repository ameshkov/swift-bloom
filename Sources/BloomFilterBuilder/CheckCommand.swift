import ArgumentParser
import BloomFilter
import Foundation

extension BloomFilterBuilder {
    struct Check: ParsableCommand {
        static let configuration = CommandConfiguration(
            abstract: "Check if a keyword might be in the bloom filter"
        )

        @Option(name: .long, help: "Path to the bloom filter plist file")
        var filterPath: String

        @Option(name: .long, help: "Keyword to check")
        var keyword: String

        func run() throws {
            guard let plistData = deserializeFromPlist(at: filterPath) else {
                throw RuntimeError("Failed to read bloom filter from: \(filterPath)")
            }

            let bloomFilter = BloomFilter(
                data: plistData.bitVectorData,
                falsePositiveTolerance: plistData.falsePositiveTolerance,
                numberOfItems: plistData.numberOfItems,
                numberOfBits: plistData.numberOfBits,
                numberOfHashes: plistData.numberOfHashes,
                murmurSeed: plistData.murmurSeed
            )

            let contains = bloomFilter.contains(keyword)
            print(
                "Keyword '\(keyword)' \(contains ? "might be" : "is definitely not") in the bloom filter"
            )
        }
    }
}
