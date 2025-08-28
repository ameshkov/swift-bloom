# swift-bloom

This is a Swift package that implements a Bloom filter using FNV-1a and
MurmurHash3 with double hashing. The algorithm is compatible with
[the one][fetchPrefilter] used by Apple for their new URL filtering API.

[fetchPrefilter]: https://developer.apple.com/documentation/networkextension/neurlfiltercontrolprovider/fetchprefilter(existingprefiltertag:)

## Build Instructions

### Prerequisites

- Swift 6 or newer.
- Install [SwiftLint][swiftlint]: `brew install swiftlint`.
- Install [periphery][periphery]: `brew install periphery`.
- Install [markdownlint-cli][markdownlint]: `npm install -g markdownlint-cli`.

[swiftlint]: https://github.com/realm/SwiftLint
[periphery]: https://github.com/peripheryapp/periphery
[markdownlint]: https://www.npmjs.com/package/markdownlint-cli

### Building

Run `make init` to setup pre-commit hooks.

- `make lint` - runs all linters.

    You can also run individual linters:

    - `make md-lint` - runs markdown linter.
    - `make swift-lint` - runs swift linters ([SwiftLint][swiftlint],
      [swift-format][swift-format], and [periphery][periphery]).

- `make test` - runs all tests.
- `make build` - builds the Swift package.
- `make release` - builds the Swift package (release).

[swift-format]: https://github.com/swiftlang/swift-format

## Usage

### BloomFilterBuilder (Command-Line Tool)

The `BloomFilterBuilder` CLI lets you build, inspect, and check Bloom filters from the command line.

#### Build a Bloom filter from a list of keywords

```sh
swift run BloomFilterBuilder build \
  --input-path path/to/keywords.txt \
  --false-positive-tolerance 0.001 \
  --output-path path/to/filter.plist
```

- `--input-path`: Path to a newline-separated file with keywords.
- `--false-positive-tolerance`: Desired false-positive rate (e.g., 0.001).
- `--output-path`: Where to save the generated bloom filter plist.

#### Inspect a Bloom filter

```sh
swift run BloomFilterBuilder read --filter-path path/to/filter.plist
```

#### Check if a keyword might be present

```sh
swift run BloomFilterBuilder check \
  --filter-path path/to/filter.plist \
  --keyword "example.com"
```

### Using BloomFilter in Swift

You can use the `BloomFilter` class directly in your Swift code.

#### Creating a Bloom filter from a list of items

```swift
import BloomFilter

let items = ["apple", "banana", "cherry"]
let falsePositiveTolerance = 0.001
let bloom = BloomFilter(items: items, falsePositiveTolerance: falsePositiveTolerance)

print(bloom.contains("banana")) // true
print(bloom.contains("orange")) // false (or possibly true, but unlikely)
```
