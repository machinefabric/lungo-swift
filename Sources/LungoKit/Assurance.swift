import Foundation

/// A program's assurance document (`assurance.json`): what its Lean code claims and proves of each
/// export, the code each export's proofs do not cover (its trust), and the assumptions about the
/// host its claims are conditional on. Generated packages expose it as `assurance`.
public struct LungoAssurance: Codable, Sendable, Equatable {
    public static let schemaVersion = 1

    public struct Position: Codable, Sendable, Equatable {
        public let line: Int
        public let column: Int
    }

    public struct Source: Codable, Sendable, Equatable {
        public let package: String
        public let file: String
        public let start: Position?
        public let end: Position?
    }

    public struct Provenance: Codable, Sendable, Equatable {
        public let leanVersion: String
        public let leanGithash: String
        public let lungoVersion: String
        public let birVersion: Int
        public let runtimeAbi: Int
    }

    public struct Library: Codable, Sendable, Equatable {
        public let package: String
        public let schemaVersion: Int
    }

    public struct Specification: Codable, Sendable, Equatable {
        public let name: String
        public let kind: String
        public let statement: String
        public let package: String?
        public let fingerprint: String
        public let source: Source?
    }

    public struct Operation: Codable, Sendable, Equatable {
        public let name: String
        public let symbol: String?
        public let fingerprint: String?
    }

    public struct Capability: Codable, Sendable, Equatable {
        public let name: String
        public let id: String
        public let form: String
        public let opType: String?
        public let operations: [Operation]
        public let assumptions: [String]
        public let package: String?
        public let fingerprint: String
        public let source: Source?
    }

    public struct Assumption: Codable, Sendable, Equatable {
        public let name: String
        public let capability: String
        public let statement: String
        public let package: String?
        public let fingerprint: String
        public let source: Source?
    }

    public struct EvidenceTrust: Codable, Sendable, Equatable {
        public let axioms: [String]
        public let dependsOnSorry: Bool
    }

    /// A theorem (its name is the claim's) proving that its subjects stand in a relation to its
    /// specifications; `status` is `proved` or `incomplete` (resting on `sorry`).
    public struct Claim: Codable, Sendable, Equatable {
        public let name: String
        public let relation: String
        public let subjects: [String]
        public let specifications: [String]
        public let statement: String
        public let status: String
        public let evidenceTrust: EvidenceTrust
        public let assumptions: [String]
        public let package: String?
        public let fingerprint: String
        public let source: Source?
    }

    public struct Role: Codable, Sendable, Equatable {
        public let name: String
        public let role: String
        public let exported: Bool
    }

    public struct Trust: Codable, Sendable, Equatable {
        public let axioms: [String]
        public let dependsOnSorry: Bool
        public let unsafeDependencies: [String]
        public let partialDependencies: [String]
        public let externDependencies: [String]
    }

    public struct Export: Codable, Sendable, Equatable {
        public let name: String
        public let module: String
        /// Whether the export returns an async program.
        public let isAsync: Bool
        public let trust: Trust
        public let claims: [String]
        public let assumptions: [String]
        public let capabilities: [String]
        public let roles: [String]
        public let source: Source?

        enum CodingKeys: String, CodingKey {
            case name, module, trust, claims, assumptions, capabilities, roles, source
            case isAsync = "async"
        }
    }

    public let schemaVersion: Int
    public let program: String
    public let provenance: Provenance
    public let library: Library?
    public let specifications: [Specification]
    public let capabilities: [Capability]
    public let assumptions: [Assumption]
    public let claims: [Claim]
    public let roles: [Role]
    public let exports: [Export]

    /// Reads an assurance document, refusing one of another schema version.
    public static func decode(_ json: String) throws -> LungoAssurance {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        let data = Data(json.utf8)
        struct Version: Decodable { let schemaVersion: Int }
        let version = try decoder.decode(Version.self, from: data)
        guard version.schemaVersion == schemaVersion else {
            throw LungoMalformed("assurance schema version \(version.schemaVersion); this library reads version \(schemaVersion)")
        }
        return try decoder.decode(LungoAssurance.self, from: data)
    }

    /// The claim whose evidence is `name`.
    public func claim(_ name: String) -> Claim? { claims.first { $0.name == name } }

    /// The summary of the export `name`.
    public func export(_ name: String) -> Export? { exports.first { $0.name == name } }
}
