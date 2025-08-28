import ArgumentParser
import BloomFilter
import Foundation

extension BloomFilterBuilder {
    struct Build: ParsableCommand {
        static let configuration = CommandConfiguration(
            abstract: "Build a bloom filter from a keyword file"
        )

        @Option(name: .long, help: "Path to input file with keywords (newline separated)")
        var inputPath: String

        @Option(name: .long, help: "False positive tolerance (0.0 < rate < 1.0)")
        var falsePositiveTolerance: Double

        @Option(name: .long, help: "Path where the bloom filter plist will be saved")
        var outputPath: String

        @Option(name: .long, help: "Murmur hash seed (default: 0x9747b28c)")
        var murmurSeed: UInt32?

        @Option(name: .long, help: "Number of bits (calculated automatically if not set)")
        var numBits: Int?

        @Option(name: .long, help: "Number of hashes (calculated automatically if not set)")
        var numHashes: Int?

        func validate() throws {
            guard falsePositiveTolerance > 0.0 && falsePositiveTolerance < 1.0 else {
                throw ValidationError(
                    "False positive tolerance must be between 0.0 and 1.0 (exclusive)"
                )
            }

            if let bits = numBits, bits <= 0 {
                throw ValidationError("Number of bits must be positive")
            }

            if let hashes = numHashes, hashes <= 0 {
                throw ValidationError("Number of hashes must be positive")
            }
        }

        func run() throws {
            // Read input file
            guard let inputData = FileManager.default.contents(atPath: inputPath),
                let inputString = String(data: inputData, encoding: .utf8)
            else {
                throw RuntimeError("Could not read input file at path: \(inputPath)")
            }

            let keywords = inputString.components(separatedBy: .newlines)
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { !$0.isEmpty }

            guard !keywords.isEmpty else {
                throw RuntimeError("No keywords found in input file")
            }

            let seed = murmurSeed ?? 0x9747b28c

            let bloomFilter: BloomFilter

            if let numBits = numBits, let numHashes = numHashes {
                // Use custom parameters
                bloomFilter = BloomFilter(
                    numberOfBits: numBits,
                    numberOfHashes: numHashes,
                    numberOfItems: keywords.count,
                    falsePositiveTolerance: falsePositiveTolerance,
                    murmurSeed: seed
                )

                // Add all keywords
                for keyword in keywords {
                    bloomFilter.add(keyword)
                }
            } else {
                // Calculate parameters automatically
                bloomFilter = BloomFilter(
                    items: keywords,
                    falsePositiveTolerance: falsePositiveTolerance,
                    murmurSeed: seed
                )
            }

            // Serialize to plist
            let plistContent = serializeToPlist(bloomFilter, numberOfItems: keywords.count)

            // Write to output file
            do {
                try plistContent.write(toFile: outputPath, atomically: true, encoding: .utf8)
                print("Bloom filter successfully written to: \(outputPath)")
                print("Items processed: \(keywords.count)")
                print("Number of bits: \(bloomFilter.getNumberOfBits())")
                print("Number of hashes: \(bloomFilter.getNumberOfHashes())")
                print("False positive tolerance: \(bloomFilter.getFalsePositiveTolerance())")
            } catch {
                throw RuntimeError("Error writing output file: \(error)")
            }
        }
    }
}
