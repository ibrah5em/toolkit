#!/usr/bin/env python3
"""
passmorph.py — Learn structural patterns from a password list,
               apply them to a base wordlist to generate similar passwords.

Usage:
  python passmorph.py <pattern_list> <base_wordlist> [options]
  python passmorph.py <pattern_list> --self              # use extracted words from the list itself

Examples:
  python passmorph.py rockyou_sample.txt names.txt -n 5000 -o out.txt
  python passmorph.py rockyou_sample.txt --self -n 2000
  python passmorph.py rockyou_sample.txt names.txt --stats
"""

import re
import sys
import random
import argparse
from collections import Counter

# ── Leet tables ───────────────────────────────────────────────────────────────
_UNLEET = str.maketrans("@31!0$7+", "aeiioslt")
_RELEET = str.maketrans("aeiostl",  "@31!0$7")

def unleet(s: str) -> str:
    return s.translate(_UNLEET)

def releet(s: str) -> str:
    return s.translate(_RELEET)

# ── Password decomposition ────────────────────────────────────────────────────
# Each password is split into 4 parts:
#   prefix   — leading non-alphanumeric chars  (e.g. "!" in "!password1")
#   core     — the alpha-starting word body    (e.g. "password")
#   numsfx   — trailing digit sequence         (e.g. "123")
#   specsfx  — trailing special chars          (e.g. "!@")
#
# case_style is detected from the raw core before normalisation.

_SPLIT = re.compile(
    r"^"
    r"(?P<prefix>[^a-zA-Z]*?)"
    r"(?P<core>[a-zA-Z][a-zA-Z0-9]*?)"
    r"(?P<numsfx>\d*)"
    r"(?P<specsfx>[^a-zA-Z0-9]*)"
    r"$"
)

def _case_style(core: str) -> str:
    alpha = re.sub(r"[^a-zA-Z]", "", core)
    if not alpha:
        return "lower"
    if alpha.isupper():
        return "upper"
    if alpha[0].isupper() and alpha[1:].islower():
        return "capitalize"
    if alpha.islower():
        return "lower"
    return "mixed"

def split_password(pw: str):
    """Return (prefix, normalised_core, numsfx, specsfx, case_style) or None."""
    m = _SPLIT.match(pw)
    if not m or not m.group("core"):
        return None
    core_raw = m.group("core")
    return (
        m.group("prefix"),
        unleet(core_raw).lower(),   # normalised: un-leet + lowercase
        m.group("numsfx"),
        m.group("specsfx"),
        _case_style(core_raw),
    )

# ── Analysis ──────────────────────────────────────────────────────────────────

def analyze(passwords: list[str]) -> dict:
    """Extract pattern statistics from a list of passwords."""
    parts = [p for pw in passwords if (p := split_password(pw))]
    if not parts:
        print("[!] Could not parse any passwords — check your input file.", file=sys.stderr)
        sys.exit(1)

    n_leet = sum(1 for pw in passwords if any(c in "@31!0$7+" for c in pw))

    return {
        "prefixes":  Counter(p[0] for p in parts),
        "numsfxs":   Counter(p[2] for p in parts),
        "specsfxs":  Counter(p[3] for p in parts),
        "cases":     Counter(p[4] for p in parts),
        "cores":     [p[1] for p in parts],          # normalised base words
        "leet_rate": n_leet / len(passwords),
        "total":     len(parts),
    }

def print_stats(stats: dict):
    bar = "─" * 50
    print(bar)
    print("  passmorph — Pattern Analysis")
    print(bar)
    print(f"  Passwords parsed   : {stats['total']}")
    print(f"  Leet usage rate    : {stats['leet_rate']:.1%}")
    print()
    print("  Case styles (top 5):")
    for style, cnt in stats["cases"].most_common(5):
        pct = cnt / stats["total"] * 100
        label = style if style else "(none)"
        print(f"    {label:<12} {cnt:>5}  ({pct:.1f}%)")
    print()
    print("  Number suffixes (top 8):")
    for sfx, cnt in stats["numsfxs"].most_common(8):
        label = repr(sfx) if sfx else "(none)"
        print(f"    {label:<14} {cnt:>5}")
    print()
    print("  Special suffixes (top 8):")
    for sfx, cnt in stats["specsfxs"].most_common(8):
        label = repr(sfx) if sfx else "(none)"
        print(f"    {label:<14} {cnt:>5}")
    print()
    print("  Prefixes (top 5):")
    for pfx, cnt in stats["prefixes"].most_common(5):
        label = repr(pfx) if pfx else "(none)"
        print(f"    {label:<14} {cnt:>5}")
    print(bar)

# ── Generation ────────────────────────────────────────────────────────────────

def _apply_case(word: str, style: str) -> str:
    if style == "upper":      return word.upper()
    if style == "capitalize": return word.capitalize()
    return word.lower()

def generate(words: list[str], stats: dict, limit: int, top: int) -> list[str]:
    """Apply learned patterns to words and return up to `limit` unique passwords."""
    top_cases   = [s for s, _ in stats["cases"].most_common(top)]
    top_nums    = [s for s, _ in stats["numsfxs"].most_common(top)]
    top_specs   = [s for s, _ in stats["specsfxs"].most_common(top)]
    top_pfxs    = [s for s, _ in stats["prefixes"].most_common(max(top // 4, 2))]
    leet_rate   = stats["leet_rate"]

    results: set[str] = set()

    for word in words:
        for case in top_cases:
            w = _apply_case(word, case)
            for pfx in top_pfxs:
                for num in top_nums:
                    for spec in top_specs:
                        results.add(pfx + w + num + spec)
                        # add leet variant proportionally
                        if leet_rate > 0.05 and random.random() < leet_rate * 2:
                            results.add(pfx + releet(w) + num + spec)
        # early-exit to avoid blowing up memory
        if len(results) >= limit * 4:
            break

    out = list(results)
    random.shuffle(out)
    return out[:limit]

# ── CLI ───────────────────────────────────────────────────────────────────────

def load_lines(path: str) -> list[str]:
    try:
        with open(path, encoding="utf-8", errors="ignore") as f:
            return [l.strip() for l in f if l.strip()]
    except FileNotFoundError:
        print(f"[!] File not found: {path}", file=sys.stderr)
        sys.exit(1)

def main():
    ap = argparse.ArgumentParser(
        description="Learn password patterns and generate similar ones.",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog=__doc__,
    )
    ap.add_argument("pattern_list",
                    help="Password list to learn patterns from")
    ap.add_argument("base_wordlist", nargs="?",
                    help="Wordlist to apply patterns to (omit with --self)")
    ap.add_argument("--self", action="store_true",
                    help="Use words extracted from the pattern list itself as base")
    ap.add_argument("-o", "--output",  default="generated.txt",
                    help="Output file (default: generated.txt)")
    ap.add_argument("-n", "--count",   type=int, default=1000,
                    help="Max passwords to generate (default: 1000)")
    ap.add_argument("-t", "--top",     type=int, default=8,
                    help="Top N patterns to use per category (default: 8)")
    ap.add_argument("--stats",         action="store_true",
                    help="Print pattern stats and exit without generating")
    ap.add_argument("--seed",          type=int, default=None,
                    help="Random seed for reproducible output")
    args = ap.parse_args()

    if not args.self and not args.base_wordlist:
        ap.error("provide a base_wordlist or use --self")

    if args.seed is not None:
        random.seed(args.seed)

    # Load & analyze
    passwords = load_lines(args.pattern_list)
    print(f"[*] Loaded {len(passwords):,} passwords for analysis")

    stats = analyze(passwords)
    print_stats(stats)

    if args.stats:
        return

    # Build base wordlist
    if args.self:
        words = list(set(stats["cores"]))  # normalised unique cores
        print(f"[*] Using {len(words):,} words extracted from the pattern list")
    else:
        words = load_lines(args.base_wordlist)
        print(f"[*] Loaded {len(words):,} base words from {args.base_wordlist}")

    # Generate
    print(f"[*] Generating up to {args.count:,} passwords (top={args.top})...")
    generated = generate(words, stats, args.count, args.top)

    with open(args.output, "w") as f:
        f.write("\n".join(generated) + "\n")

    print(f"[+] Done — wrote {len(generated):,} passwords to '{args.output}'")

if __name__ == "__main__":
    main()
