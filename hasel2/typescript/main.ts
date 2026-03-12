const defaultInput = "Hasel λ🐿 2.0";
const input = process.env.HASEL_INPUT || process.argv.slice(2).join(" ") || defaultInput;
const chars = Array.from(input);
const regexEscape = (value: string) => value.replace(/[\\.^$|?*+()[\]{}]/g, "\\$&");
const asciiPrintable = (value: string) =>
  Array.from(value)
    .map((ch) => {
      const cp = ch.codePointAt(0)!;
      return ch === " " || (cp >= 33 && cp <= 126) ? ch : "?";
    })
    .join("");
const tokens = input.toLowerCase().trim().split(/\s+/).filter(Boolean).join(",");
const codepoints = chars.map((ch) => `U+${ch.codePointAt(0)!.toString(16).toUpperCase().padStart(4, "0")}`).join(",");
const containsNonAscii = chars.some((ch) => ch.codePointAt(0)! > 0x7f);

const lines = [
  ["input", input],
  ["everything", `*${input}*`],
  ["regex", `.*${regexEscape(input)}.*`],
  ["ascii_printable", asciiPrintable(input)],
  ["contains_non_ascii", String(containsNonAscii)],
  ["tokens", tokens],
  ["codepoints", codepoints],
];

for (const [key, value] of lines) {
  console.log(`${key}\t${value}`);
}
