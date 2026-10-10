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
        /// The body, as Lean prints it, when the declaration is a definition.
        public let definition: String?
        public let package: String?
        public let fingerprint: String
        public let source: Source?
    }

    public struct Operation: Codable, Sendable, Equatable {
        public let name: String
        public let symbol: String?
        public let fingerprint: String?
    }

    public struct Facility: Codable, Sendable, Equatable {
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
        public let facility: String
        public let statement: String
        /// The body, as Lean prints it, when the declaration is a definition.
        public let definition: String?
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
        public let facilities: [String]
        public let roles: [String]
        public let source: Source?

        enum CodingKeys: String, CodingKey {
            case name, module, trust, claims, assumptions, facilities, roles, source
            case isAsync = "async"
        }
    }

    public let schemaVersion: Int
    public let program: String
    public let provenance: Provenance
    public let library: Library?
    public let specifications: [Specification]
    public let facilities: [Facility]
    public let assumptions: [Assumption]
    public let claims: [Claim]
    public let roles: [Role]
    public let exports: [Export]

    /// Reads an assurance document, refusing one of another schema version, and one with a field
    /// this library does not know or without one it requires, as lungo's other readers do.
    public static func decode(_ json: String) throws -> LungoAssurance {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        let data = Data(json.utf8)
        struct Version: Decodable { let schemaVersion: Int }
        let version = try decoder.decode(Version.self, from: data)
        guard version.schemaVersion == schemaVersion else {
            throw LungoMalformed("assurance schema version \(version.schemaVersion); this library reads version \(schemaVersion)")
        }
        try Shape.document.check(try JSONSerialization.jsonObject(with: data), at: "document")
        return try decoder.decode(LungoAssurance.self, from: data)
    }

    /// The schema of the document: each object's fields, with the shape of each.
    indirect enum Shape: Sendable {
        case string, number, boolean
        case object([String: Shape])
        case array(Shape)
        case nullable(Shape)

        static let strings = Shape.array(.string)
        static let position = Shape.object(["line": .number, "column": .number])
        static let source = Shape.nullable(.object([
            "package": .string, "file": .string, "start": .nullable(position), "end": .nullable(position),
        ]))
        static let document = Shape.object([
            "schema_version": .number,
            "program": .string,
            "provenance": .object([
                "lean_version": .string, "lean_githash": .string, "lungo_version": .string,
                "bir_version": .number, "runtime_abi": .number,
            ]),
            "library": .nullable(.object(["package": .string, "schema_version": .number])),
            "specifications": .array(.object([
                "name": .string, "kind": .string, "statement": .string, "definition": .nullable(.string),
                "package": .nullable(.string), "fingerprint": .string, "source": source,
            ])),
            "facilities": .array(.object([
                "name": .string, "id": .string, "form": .string, "op_type": .nullable(.string),
                "operations": .array(.object([
                    "name": .string, "symbol": .nullable(.string), "fingerprint": .nullable(.string),
                ])),
                "assumptions": strings, "package": .nullable(.string), "fingerprint": .string, "source": source,
            ])),
            "assumptions": .array(.object([
                "name": .string, "facility": .string, "statement": .string, "definition": .nullable(.string),
                "package": .nullable(.string), "fingerprint": .string, "source": source,
            ])),
            "claims": .array(.object([
                "name": .string, "relation": .string, "subjects": strings, "specifications": strings,
                "statement": .string, "status": .string,
                "evidence_trust": .object(["axioms": strings, "depends_on_sorry": .boolean]),
                "assumptions": strings, "package": .nullable(.string), "fingerprint": .string, "source": source,
            ])),
            "roles": .array(.object(["name": .string, "role": .string, "exported": .boolean])),
            "exports": .array(.object([
                "name": .string, "module": .string, "async": .boolean,
                "trust": .object([
                    "axioms": strings, "depends_on_sorry": .boolean, "unsafe_dependencies": strings,
                    "partial_dependencies": strings, "extern_dependencies": strings,
                ]),
                "claims": strings, "assumptions": strings, "facilities": strings, "roles": strings, "source": source,
            ])),
        ])

        /// Throws unless `value` (as `JSONSerialization` reads it) has this shape.
        func check(_ value: Any, at path: String) throws {
            func fail(_ what: String) -> LungoMalformed { LungoMalformed("the assurance document's \(path) \(what)") }
            switch self {
            case .string:
                guard value is String else { throw fail("is not a string") }
            case .number:
                guard let n = value as? NSNumber, CFGetTypeID(n) != CFBooleanGetTypeID() else { throw fail("is not a number") }
            case .boolean:
                guard let n = value as? NSNumber, CFGetTypeID(n) == CFBooleanGetTypeID() else { throw fail("is not a boolean") }
            case .nullable(let shape):
                if !(value is NSNull) { try shape.check(value, at: path) }
            case .array(let shape):
                guard let items = value as? [Any] else { throw fail("is not an array") }
                for (i, x) in items.enumerated() { try shape.check(x, at: "\(path)[\(i)]") }
            case .object(let fields):
                guard let object = value as? [String: Any] else { throw fail("is not an object") }
                for key in object.keys.sorted() where fields[key] == nil {
                    throw fail("has the field \(key), which this library does not know")
                }
                for (key, shape) in fields.sorted(by: { $0.key < $1.key }) {
                    guard let v = object[key] else { throw fail("lacks the field \(key)") }
                    try shape.check(v, at: "\(path).\(key)")
                }
            }
        }
    }

    /// The claim whose evidence is `name`.
    public func claim(_ name: String) -> Claim? { claims.first { $0.name == name } }

    /// The summary of the export `name`.
    public func export(_ name: String) -> Export? { exports.first { $0.name == name } }
}
