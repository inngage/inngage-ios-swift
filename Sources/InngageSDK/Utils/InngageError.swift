import Foundation

/// Erros públicos da InngageSDK, propagados pelas chamadas `async throws` da fachada.
public enum InngageError: Error {
    /// URL base/endpoint inválida.
    case badURL
    /// Resposta HTTP fora da faixa 2xx (ou não-HTTP). `status = -1` para respostas não-HTTP.
    case invalidResponse(status: Int, body: String?)
    /// Falha de transporte (URLSession, timeout, offline, etc.).
    case network(Error)
}
