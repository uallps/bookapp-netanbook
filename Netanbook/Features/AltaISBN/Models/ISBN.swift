#if AltaISBN
import Foundation

// O3 · Alta por ISBN (original). Solo se compila con la variable `AltaISBN`:
// `--traits AltaISBN` en SwiftPM.
//
// Relación con el libro: 1 libro → 0..1 ISBN. El ISBN no vive en `Book`:
// esta característica lo guarda aparte (`BookISBN`) y apunta al libro con `bookID`.

/// Reglas del ISBN: limpiar lo que escribe el usuario, comprobar el dígito de
/// control y pasarlo siempre a ISBN-13, para que el mismo libro escrito como
/// ISBN-10 o como ISBN-13 se reconozca como el mismo.
enum ISBN {
    /// ISBN-13 normalizado (solo 13 cifras), o `nil` si lo escrito no es un
    /// ISBN-10 ni un ISBN-13 válido. Acepta guiones y espacios:
    /// «84-376-0494-X» y «978 84 376 0494 7» dan los dos «9788437604947».
    static func normalized(_ text: String) -> String? {
        let compact = text.uppercased().filter { !$0.isWhitespace && $0 != "-" }
        switch compact.count {
        case 10 where isValidISBN10(compact):
            return isbn13(fromISBN10: compact)
        case 13 where isValidISBN13(compact):
            return compact
        default:
            return nil
        }
    }

    /// ISBN-10: nueve cifras y una de control (0–9 o X = 10). La suma de cada
    /// cifra por su peso (10, 9, …, 1) tiene que ser múltiplo de 11.
    static func isValidISBN10(_ isbn: String) -> Bool {
        let chars = Array(isbn)
        guard chars.count == 10, chars.prefix(9).allSatisfy({ $0.isASCIIDigit }) else { return false }
        let last = chars[9]
        guard last.isASCIIDigit || last == "X" else { return false }
        var sum = 0
        for (index, char) in chars.enumerated() {
            let value = char == "X" ? 10 : Int(String(char))!
            sum += value * (10 - index)
        }
        return sum % 11 == 0
    }

    /// ISBN-13: trece cifras que empiezan por 978 o 979. Las cifras se
    /// multiplican alternando 1 y 3; la suma tiene que ser múltiplo de 10.
    static func isValidISBN13(_ isbn: String) -> Bool {
        guard isbn.count == 13, isbn.allSatisfy({ $0.isASCIIDigit }),
              isbn.hasPrefix("978") || isbn.hasPrefix("979") else { return false }
        return checksum13(of: isbn.prefix(12)) == Int(String(isbn.last!))!
    }

    /// Pasa un ISBN-10 válido a ISBN-13: «978» + sus nueve primeras cifras + el
    /// nuevo dígito de control.
    static func isbn13(fromISBN10 isbn10: String) -> String {
        let body = "978" + isbn10.prefix(9)
        return body + String(checksum13(of: Substring(body)))
    }

    /// Dígito de control de las doce primeras cifras de un ISBN-13.
    private static func checksum13(of digits: Substring) -> Int {
        var sum = 0
        for (index, char) in digits.enumerated() {
            sum += Int(String(char))! * (index.isMultiple(of: 2) ? 1 : 3)
        }
        return (10 - sum % 10) % 10
    }
}

private extension Character {
    /// Solo 0–9: `isNumber` aceptaría también cifras de otros alfabetos.
    var isASCIIDigit: Bool { isASCII && isNumber }
}

/// Datos de un libro que devuelve el catálogo para un ISBN.
struct ISBNBookInfo: Equatable {
    /// ISBN-13 normalizado que se ha buscado.
    let isbn: String
    let title: String
    /// Autor o autores separados por comas; `nil` si el catálogo no lo tiene.
    let author: String?
}

/// ISBN de un libro dado de alta con O3.
struct BookISBN: Codable, Equatable {
    /// Libro al que pertenece (`Book.id`).
    let bookID: UUID
    /// ISBN-13 normalizado.
    let isbn: String
}
#endif
