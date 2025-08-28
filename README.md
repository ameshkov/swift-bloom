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
