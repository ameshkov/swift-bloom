import ArgumentParser

// MARK: - Main Command Structure

struct BloomFilterBuilder: ParsableCommand {
    static let configuration = CommandConfiguration(
        abstract: "A tool for building and working with Bloom filters",
        subcommands: [Build.self, Read.self, Check.self]
    )
}

// MARK: - Main Entry Point

BloomFilterBuilder.main()
