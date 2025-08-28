import BloomFilter
import Foundation

// MARK: - Plist Data Structure

struct BloomFilterPlist {
    let bitVectorData: Data
    let falsePositiveTolerance: Double
    let murmurSeed: UInt32
    let numberOfBits: Int
    let numberOfBytes: Int
    let numberOfHashes: Int
    let numberOfItems: Int
}

// MARK: - Plist Serialization

func serializeToPlist(_ bloomFilter: BloomFilter, numberOfItems: Int) -> String {
    let data = bloomFilter.getData()
    let base64Data = data.base64EncodedString()

    return """
        <?xml version="1.0" encoding="UTF-8"?>
        <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
        <plist version="1.0">
        <dict>
        \t<key>bitVectorData</key>
        \t<data>
        \t\(base64Data)
        \t</data>
        \t<key>falsePositiveTolerance</key>
        \t<real>\(bloomFilter.getFalsePositiveTolerance())</real>
        \t<key>murmurSeed</key>
        \t<integer>\(bloomFilter.getMurmurSeed())</integer>
        \t<key>numberOfBits</key>
        \t<integer>\(bloomFilter.getNumberOfBits())</integer>
        \t<key>numberOfBytes</key>
        \t<integer>\(data.count)</integer>
        \t<key>numberOfHashes</key>
        \t<integer>\(bloomFilter.getNumberOfHashes())</integer>
        \t<key>numberOfItems</key>
        \t<integer>\(numberOfItems)</integer>
        </dict>
        </plist>
        """
}

func deserializeFromPlist(at path: String) -> BloomFilterPlist? {
    guard let data = FileManager.default.contents(atPath: path) else {
        print("Error: Could not read file at path: \(path)")
        return nil
    }

    do {
        guard
            let plist = try PropertyListSerialization.propertyList(
                from: data,
                options: [],
                format: nil
            ) as? [String: Any]
        else {
            print("Error: Invalid plist format")
            return nil
        }

        guard let bitVectorDataString = plist["bitVectorData"] as? Data,
            let falsePositiveTolerance = plist["falsePositiveTolerance"] as? Double,
            let murmurSeed = plist["murmurSeed"] as? UInt32,
            let numberOfBits = plist["numberOfBits"] as? Int,
            let numberOfBytes = plist["numberOfBytes"] as? Int,
            let numberOfHashes = plist["numberOfHashes"] as? Int,
            let numberOfItems = plist["numberOfItems"] as? Int
        else {
            print("Error: Missing required plist keys")
            return nil
        }

        return BloomFilterPlist(
            bitVectorData: bitVectorDataString,
            falsePositiveTolerance: falsePositiveTolerance,
            murmurSeed: murmurSeed,
            numberOfBits: numberOfBits,
            numberOfBytes: numberOfBytes,
            numberOfHashes: numberOfHashes,
            numberOfItems: numberOfItems
        )
    } catch {
        print("Error parsing plist: \(error)")
        return nil
    }
}
