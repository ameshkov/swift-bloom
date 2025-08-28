import ArgumentParser
import BloomFilter
import Foundation

extension BloomFilterBuilder {
    struct Read: ParsableCommand {
        static let configuration = CommandConfiguration(
            abstract: "Read and display information about a bloom filter"
        )

        @Option(name: .long, help: "Path to the bloom filter plist file")
        var filterPath: String

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

            print("Bloom Filter Information:")
            print("========================")
            print("Number of items: \(plistData.numberOfItems)")
            print("Number of bits: \(plistData.numberOfBits)")
            print("Number of bytes: \(plistData.numberOfBytes)")
            print("Number of hashes: \(plistData.numberOfHashes)")
            print("False positive tolerance: \(plistData.falsePositiveTolerance)")
            print("Murmur seed: 0x\(String(plistData.murmurSeed, radix: 16, uppercase: true))")
            print("")
            print("Detailed Information:")
            print(bloomFilter.description)
        }
    }
}
