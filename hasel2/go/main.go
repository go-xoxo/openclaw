package main

import (
    "fmt"
    "os"
    "strings"
)

func main() {
    input := os.Getenv("HASEL_INPUT")
    if input == "" {
        input = "Hasel λ🐿 2.0"
    }
    if input == "" && len(os.Args) > 1 {
        input = strings.Join(os.Args[1:], " ")
    }
    if input == "" {
        input = "Hasel λ🐿 2.0"
    }

    emit("input", input)
    emit("everything", "*"+input+"*")
    emit("regex", ".*"+regexEscape(input)+".*")
    emit("ascii_printable", asciiPrintable(input))
    emit("contains_non_ascii", boolString(containsNonASCII(input)))
    emit("tokens", strings.Join(strings.Fields(strings.ToLower(input)), ","))
    emit("codepoints", codepoints(input))
}

func emit(key string, value string) {
    fmt.Printf("%s\t%s\n", key, value)
}

func boolString(v bool) string {
    if v {
        return "true"
    }
    return "false"
}

func containsNonASCII(input string) bool {
    for _, r := range input {
        if r > 127 {
            return true
        }
    }
    return false
}

func asciiPrintable(input string) string {
    out := strings.Builder{}
    for _, r := range input {
        if r == ' ' || (r >= 33 && r <= 126) {
            out.WriteRune(r)
        } else {
            out.WriteRune('?')
        }
    }
    return out.String()
}

func regexEscape(input string) string {
    meta := `\\.^$|?*+()[]{}'
    out := strings.Builder{}
    for _, r := range input {
        if strings.ContainsRune(meta, r) {
            out.WriteRune('\\')
        }
        out.WriteRune(r)
    }
    return out.String()
}

func codepoints(input string) string {
    parts := make([]string, 0, len(input))
    for _, r := range input {
        parts = append(parts, fmt.Sprintf("U+%04X", r))
    }
    return strings.Join(parts, ",")
}
