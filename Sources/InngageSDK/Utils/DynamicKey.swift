import Foundation

/// Chave de codificação dinâmica para serializar dicionários `[String: Any]`
/// em containers keyed. Compartilhada por `Event` e `Subscribe`.
struct DynamicKey: CodingKey {
    var stringValue: String
    init?(stringValue: String) { self.stringValue = stringValue }
    var intValue: Int? { nil }
    init?(intValue: Int) { nil }
}
