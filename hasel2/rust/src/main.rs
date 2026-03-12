use std::env;

fn main() {
    let args: Vec<String> = env::args().skip(1).collect();
    let input = env::var("HASEL_INPUT").ok().filter(|s| !s.is_empty()).unwrap_or_else(|| {
        if args.is_empty() {
            "Hasel λ🐿 2.0".to_string()
        } else {
            args.join(" ")
        }
    });

    emit("input", &input);
    emit("everything", &format!("*{}*", input));
    emit("regex", &format!(".*{}.*", regex_escape(&input)));
    emit("ascii_printable", &ascii_printable(&input));
    emit("contains_non_ascii", if input.chars().any(|ch| !ch.is_ascii()) { "true" } else { "false" });
    emit("tokens", &input.to_lowercase().split_whitespace().collect::<Vec<_>>().join(","));
    emit(
        "codepoints",
        &input
            .chars()
            .map(|ch| format!("U+{:04X}", ch as u32))
            .collect::<Vec<_>>()
            .join(","),
    );
}

fn emit(key: &str, value: &str) {
    println!("{}\t{}", key, value);
}

fn ascii_printable(input: &str) -> String {
    input
        .chars()
        .map(|ch| {
            if ch == ' ' || ch.is_ascii_graphic() {
                ch
            } else {
                '?'
            }
        })
        .collect()
}

fn regex_escape(input: &str) -> String {
    let meta = "\\.^$|?*+()[]{}";
    let mut out = String::new();
    for ch in input.chars() {
        if meta.contains(ch) {
            out.push('\\');
        }
        out.push(ch);
    }
    out
}
