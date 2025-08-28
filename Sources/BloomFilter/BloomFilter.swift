import Foundation

/// A Bloom filter implementation using FNV-1a and MurmurHash3 with double hashing
public class BloomFilter: CustomStringConvertible {
    private var bitArray: Data
    private let numberOfBits: Int
    private let numberOfHashes: Int
    private let falsePositiveTolerance: Double
    private let numberOfItems: Int
    private let murmurSeed: UInt32

    // MARK: - Hash Functions

    /// 32-bit FNV-1a hash function
    private func fnv1a(_ data: String) -> UInt32 {
        let fnvPrime: UInt32 = 0x01000193
        let fnvOffsetBasis: UInt32 = 0x811c9dc5

        var hash = fnvOffsetBasis
        for byte in data.utf8 {
            hash = hash &* fnvPrime  // Multiply by prime
            hash ^= UInt32(byte)  // XOR operation
        }
        return hash
    }

    /// 32-bit MurmurHash3 hash function
    private func murmurHash3(_ data: String, seed: UInt32) -> UInt32 {
        let murmurConstant1: UInt32 = 0xcc9e2d51
        let murmurConstant2: UInt32 = 0x1b873593
        let rotationBits1: UInt32 = 15
        let rotationBits2: UInt32 = 13
        let multiplier: UInt32 = 5
        let additionConstant: UInt32 = 0xe6546b64

        var hashValue = seed
        let inputBytes = Array(data.utf8)
        let dataLength = inputBytes.count

        // Process 4-byte chunks
        let numberOfChunks = dataLength / 4
        for chunkIndex in 0..<numberOfChunks {
            let startIndex = chunkIndex * 4
            var chunkValue: UInt32 = 0
            chunkValue |= UInt32(inputBytes[startIndex])
            chunkValue |= UInt32(inputBytes[startIndex + 1]) << 8
            chunkValue |= UInt32(inputBytes[startIndex + 2]) << 16
            chunkValue |= UInt32(inputBytes[startIndex + 3]) << 24

            chunkValue = chunkValue &* murmurConstant1
            chunkValue = (chunkValue << rotationBits1) | (chunkValue >> (32 - rotationBits1))
            chunkValue = chunkValue &* murmurConstant2

            hashValue ^= chunkValue
            hashValue = ((hashValue << rotationBits2) | (hashValue >> (32 - rotationBits2)))
            hashValue = hashValue &* multiplier &+ additionConstant
        }

        // Process remaining bytes
        let remainingBytes = dataLength % 4
        if remainingBytes > 0 {
            var remainderValue: UInt32 = 0
            let remainderStartIndex = numberOfChunks * 4

            if remainingBytes >= 3 {
                remainderValue |= UInt32(inputBytes[remainderStartIndex + 2]) << 16
            }
            if remainingBytes >= 2 {
                remainderValue |= UInt32(inputBytes[remainderStartIndex + 1]) << 8
            }
            if remainingBytes >= 1 {
                remainderValue |= UInt32(inputBytes[remainderStartIndex])
            }

            remainderValue = remainderValue &* murmurConstant1
            remainderValue =
                (remainderValue << rotationBits1) | (remainderValue >> (32 - rotationBits1))
            remainderValue = remainderValue &* murmurConstant2
            hashValue ^= remainderValue
        }

        // Finalization
        hashValue ^= UInt32(dataLength)
        hashValue ^= hashValue >> 16
        hashValue = hashValue &* 0x85ebca6b
        hashValue ^= hashValue >> 13
        hashValue = hashValue &* 0xc2b2ae35
        hashValue ^= hashValue >> 16

        return hashValue
    }

    // MARK: - Double Hashing

    /// Generate hash indices using double hashing
    private func getHashIndices(for item: String) -> [Int] {
        let hash1 = fnv1a(item)
        let hash2 = murmurHash3(item, seed: murmurSeed)

        var indices: [Int] = []
        for i in 0..<numberOfHashes {
            let index = Int((hash1 &+ UInt32(i) &* hash2) % UInt32(numberOfBits))
            indices.append(index)
        }
        return indices
    }

    // MARK: - Bit Operations

    /// Set bit at given index
    private func setBit(at index: Int) {
        let byteIndex = index / 8
        let bitIndex = index % 8

        if byteIndex < bitArray.count {
            bitArray[byteIndex] |= (1 << bitIndex)
        }
    }

    /// Check if bit is set at given index
    private func isBitSet(at index: Int) -> Bool {
        let byteIndex = index / 8
        let bitIndex = index % 8

        guard byteIndex < bitArray.count else { return false }
        return (bitArray[byteIndex] & (1 << bitIndex)) != 0
    }

    // MARK: - Initializers

    /// Initialize Bloom filter with items and false-positive tolerance
    /// - Parameters:
    ///   - items: Array of strings to add to the filter
    ///   - falsePositiveTolerance: Desired false-positive rate (0.0 < p < 1.0)
    ///   - murmurSeed: Seed value for MurmurHash3 (default: 0x9747b28c)
    public init(
        items: [String],
        falsePositiveTolerance: Double,
        murmurSeed: UInt32 = 0x9747b28c,
    ) {
        precondition(
            falsePositiveTolerance > 0.0 && falsePositiveTolerance < 1.0,
            "False positive tolerance must be between 0.0 and 1.0 (exclusive)"
        )
        precondition(!items.isEmpty, "Items array must not be empty")

        self.numberOfItems = items.count
        self.falsePositiveTolerance = falsePositiveTolerance
        self.murmurSeed = murmurSeed

        // Calculate numberOfBits = -n * ln(p) / (ln(2) ^ 2)
        let n = Double(numberOfItems)
        let p = falsePositiveTolerance
        let bitsCalculation = -n * log(p) / (log(2) * log(2))

        // Ensure we have a reasonable minimum and handle edge cases
        self.numberOfBits = max(1, Int(ceil(bitsCalculation)))

        // Calculate numberOfHashes = (numberOfBits / n) * ln(2)
        let hashesCalculation = (Double(numberOfBits) / n) * log(2)
        self.numberOfHashes = max(1, Int(ceil(hashesCalculation)))

        // Initialize bit array
        let byteCount = (numberOfBits + 7) / 8
        self.bitArray = Data(count: byteCount)

        // Add all items to the filter
        for item in items {
            add(item)
        }
    }

    /// Initialize Bloom filter from existing data
    /// - Parameters:
    ///   - data: Existing bloom filter data
    ///   - falsePositiveTolerance: False-positive rate used to create the filter
    ///   - numberOfItems: Number of items in the original dataset
    ///   - numberOfBits: Number of bits in the original dataset
    ///   - numberOfHashes: Number of hashes in the original dataset
    ///   - murmurSeed: Seed value for MurmurHash3 (default: 0x9747b28c)
    public init(
        data: Data,
        falsePositiveTolerance: Double,
        numberOfItems: Int,
        numberOfBits: Int,
        numberOfHashes: Int,
        murmurSeed: UInt32
    ) {
        precondition(
            falsePositiveTolerance > 0.0 && falsePositiveTolerance < 1.0,
            "False positive tolerance must be between 0.0 and 1.0 (exclusive)"
        )
        precondition(numberOfItems >= 0, "Number of items must be non-negative")
        precondition(!data.isEmpty, "Data cannot be empty")

        self.bitArray = data
        self.falsePositiveTolerance = falsePositiveTolerance
        self.numberOfItems = numberOfItems
        self.murmurSeed = murmurSeed
        self.numberOfBits = numberOfBits
        self.numberOfHashes = numberOfHashes
    }

    /// Initialize Bloom filter with specific parameters (empty bit array)
    /// - Parameters:
    ///   - numberOfBits: Total number of bits in the filter
    ///   - numberOfHashes: Number of hash functions to use
    ///   - numberOfItems: Expected number of items (for statistics)
    ///   - falsePositiveTolerance: Expected false-positive rate (for statistics)
    ///   - murmurSeed: Seed value for MurmurHash3
    public init(
        numberOfBits: Int,
        numberOfHashes: Int,
        numberOfItems: Int,
        falsePositiveTolerance: Double,
        murmurSeed: UInt32
    ) {
        precondition(numberOfBits > 0, "Number of bits must be positive")
        precondition(numberOfHashes > 0, "Number of hashes must be positive")
        precondition(numberOfItems >= 0, "Number of items must be non-negative")
        precondition(
            falsePositiveTolerance > 0.0 && falsePositiveTolerance < 1.0,
            "False positive tolerance must be between 0.0 and 1.0 (exclusive)"
        )

        self.numberOfBits = numberOfBits
        self.numberOfHashes = numberOfHashes
        self.numberOfItems = numberOfItems
        self.falsePositiveTolerance = falsePositiveTolerance
        self.murmurSeed = murmurSeed

        // Initialize empty bit array
        let byteCount = (numberOfBits + 7) / 8
        self.bitArray = Data(count: byteCount)
    }

    // MARK: - Public Methods

    /// Add an item to the Bloom filter
    /// - Parameter item: String to add to the filter
    public func add(_ item: String) {
        let indices = getHashIndices(for: item)
        for index in indices {
            setBit(at: index)
        }
    }

    /// Test if an item might be in the Bloom filter
    /// - Parameter item: String to test for membership
    /// - Returns: true if item might be in the set, false if definitely not in the set
    public func contains(_ item: String) -> Bool {
        let indices = getHashIndices(for: item)
        for index in indices where !isBitSet(at: index) {
            return false
        }
        return true
    }

    /// Get the underlying data representation of the Bloom filter
    /// - Returns: Data containing the bit array
    public func getData() -> Data {
        return bitArray
    }

    public func getNumberOfBits() -> Int {
        return numberOfBits
    }

    public func getNumberOfHashes() -> Int {
        return numberOfHashes
    }

    public func getNumberOfItems() -> Int {
        return numberOfItems
    }

    public func getFalsePositiveTolerance() -> Double {
        return falsePositiveTolerance
    }

    public func getMurmurSeed() -> UInt32 {
        return murmurSeed
    }

    // MARK: - CustomStringConvertible

    /// String representation of the Bloom filter showing all private fields and bit array data
    public var description: String {
        var result = "BloomFilter {\n"

        // Private fields
        result += "  numberOfBits: \(numberOfBits)\n"
        result += "  numberOfHashes: \(numberOfHashes)\n"
        result += "  falsePositiveTolerance: \(falsePositiveTolerance)\n"
        result += "  numberOfItems: \(numberOfItems)\n"
        result += "  murmurSeed: 0x\(String(murmurSeed, radix: 16, uppercase: true))\n"
        result += "  bitArray.count: \(bitArray.count) bytes\n"

        // Bit array visualization (using printBloomFilterBits style)
        result += "  bitArray data:\n"
        result += "    Bloom Filter Bits (Total: \(bitArray.count * 8) bits)\n"
        result += "    " + String(repeating: "=", count: 50) + "\n"

        var bitIndex = 0
        for (byteOffset, byte) in bitArray.enumerated() {
            // Print byte index header every 8 bytes (64 bits)
            if bitIndex % 64 == 0 {
                result +=
                    "\n    Byte \(bitIndex / 8)-\(min((bitIndex / 8) + 7, bitArray.count - 1)):\n    "
            }

            // Convert byte to binary string with leading zeros
            let binaryString =
                String(repeating: "0", count: max(0, 8 - String(byte, radix: 2).count))
                + String(byte, radix: 2)

            // Print bits with spacing for readability (space after 4th bit)
            let spacedBits = binaryString.enumerated()
                .map { index, bit in
                    return index == 4 ? " \(bit)" : String(bit)
                }
                .joined()

            result += spacedBits

            // Add space between bytes (but not after the last byte in a line)
            if (bitIndex + 8) % 64 != 0 && byteOffset < bitArray.count - 1 {
                result += " "
            }

            bitIndex += 8

            // New line every 8 bytes for better formatting
            if bitIndex % 64 == 0 {
                result += "\n"
            }
        }

        // Final newline if needed
        if bitIndex % 64 != 0 {
            result += "\n"
        }

        // Show summary statistics
        result += "\n    Summary:\n"
        let totalBits = bitArray.count * 8
        let setBits = bitArray.reduce(0) { count, byte in
            count + byte.nonzeroBitCount
        }
        let fillRatio = totalBits > 0 ? Double(setBits) / Double(totalBits) : 0.0

        result += "    Total bits: \(totalBits)\n"
        result += "    Set bits: \(setBits)\n"
        result += "    Fill ratio: \(String(format: "%.2f", fillRatio * 100))%\n"

        result += "  \n"
        result += "  Statistics:\n"
        result +=
            "    Estimated false positive rate: \(String(format: "%.6f", pow(fillRatio, Double(numberOfHashes))))\n"
        result += "}"

        return result
    }
}
