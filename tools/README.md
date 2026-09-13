# Extraction toolchain

The prototype is the canon. These scripts read `source/Bridge_RC2_1.html` and
emit Swift, so the port is generated from the canon rather than transcribed
from it. When RC2.2 lands, drop in the new file and re-run.

    tools/extract_all.sh          run everything
    python3 tools/test_jsscan.py  scanner regression tests

| Script | Reads | Writes |
|---|---|---|
| `extract_tokens.py`  | the `:root` block | `Theme.swift`, `Colors.xcassets` |
| `extract_roles.py`   | `ROLES` | `Role.swift`, `Screen` enum |
| `extract_strings.py` | `I18N` + every `L()` call site | `Localizable.xcstrings`, `Strings.swift`, `docs/STRING_CONFLICTS.md` |

## On `lib/jsscan.py`

The file is never parsed as JavaScript. It is scanned by small readers that
understand string literals, template interpolation and regular expressions well
enough not to be fooled by them. Three bugs found while building this each
mis-read the file *silently* rather than failing, which is the failure mode that
matters: a desynchronised scan produces plausible output that is wrong.

1. `const esc = (s) => s.replace(/[&<>"']/g, ...)` — a regex literal containing
   quote characters. Read as code, its `"` opens a string that swallows the rest
   of the file. Everything defined after line 1848 came out wrong.
2. Template literals containing `${...}` with nested template literals. Searching
   for the next backtick finds an inner one.
3. `/* Chat: Taylor's own mark. */` — an apostrophe in prose. Harmless in a JS
   comment, but the same prose sits in the HTML header comment, which is not a
   JS comment and was not being stripped.

Each is now a test in `test_jsscan.py`. Add one before fixing the next.
