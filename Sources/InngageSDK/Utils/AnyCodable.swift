import Foundation

public struct AnyCodable: Codable {
    public let value: Any

    public init(_ value: Any) {
        self.value = value
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()

        if container.decodeNil() {
            self.value = NSNull()
        } else if let b = try? container.decode(Bool.self) {
            self.value = b
        } else if let i = try? container.decode(Int.self) {
            self.value = i
        } else if let d = try? container.decode(Double.self) {
            self.value = d
        } else if let s = try? container.decode(String.self) {
            self.value = s
        } else if let a = try? container.decode([AnyCodable].self) {
            self.value = a.map { $0.value }
        } else if let o = try? container.decode([String: AnyCodable].self) {
            self.value = o.mapValues { $0.value }
        } else {
            throw DecodingError.typeMismatch(
                AnyCodable.self,
                .init(codingPath: decoder.codingPath,
                      debugDescription: "Tipo JSON não suportado em AnyCodable")
            )
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()

        switch value {
        case is NSNull:
            try container.encodeNil()

        case let b as Bool:
            try container.encode(b)

        case let i as Int:
            try container.encode(i)

        case let d as Double:
            try container.encode(d)

        case let s as String:
            try container.encode(s)

        case let a as [Any]:
            try container.encode(a.map { AnyCodable($0) })

        case let o as [String: Any]:
            try container.encode(o.mapValues { AnyCodable($0) })

        default:
            if let s = String(describing: value) as String? {
                try container.encode(s)
            } else {
                try container.encodeNil()
            }
        }
    }
}
