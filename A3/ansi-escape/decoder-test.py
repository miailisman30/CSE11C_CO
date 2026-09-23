#!/usr/bin/env python3
"""Python mirror of decoder-ansi-vic.s — read-only test, changes no .s files.

Replicates current decoder-ansi-vic.s exactly:
  fmt_csi     = "\\x1B[38;5;%d;48;5;%dm"  (combined single CSI)
  fmt_eff_csi = "\\x1B[%dm"
  if fg == bg:
      0->0 reset, 26->25 stop_blink, 42->1 bold, 66->2 faint,
      105->8 conceal, 153->28 reveal, 182->5 blink,
      unknown -> emit NOTHING (jmp e_bgfg in new .s)
  else:
      emit fg/bg color CSI
  then emit chr(character) * print_times
  next = dword at offset 2 (block index); 0 terminates. Start at index 0.

Usage:
  python3 decoder-test.py [path-to-.s-with-MESSAGE]
  default: final.s in same directory as this script.
"""
import re
import sys
from pathlib import Path

# Effect map: raw fg==bg value -> SGR code emitted via fmt_eff_csi
EFFECT_MAP = {
    0: 0,      # reset
    26: 25,   # stop_blink
    42: 1,    # bold
    66: 2,    # faint
    105: 8,   # conceal
    153: 28,  # reveal
    182: 5,   # blink
}

FMT_CSI = "\x1b[38;5;{};48;5;{}m"  # current .s line 4
FMT_EFF = "\x1b[{}m"


def parse_quads(path: Path):
    """Extract MESSAGE .quad values as ints, in order (index 0..n-1)."""
    text = path.read_text()
    # Only take quads after MESSAGE: label to avoid stray data
    if "MESSAGE" in text:
        text = text.split("MESSAGE", 1)[1]
    vals = []
    for m in re.finditer(r"\.quad\s+(0[Xx][0-9A-Fa-f]+)", text):
        vals.append(int(m.group(1), 16))
    return vals


def split_block(v: int):
    """Mirror movzbq offsets: char=byte0, times=byte1, next=bytes2-5 LE, fg=byte6, bg=byte7."""
    char = v & 0xFF
    times = (v >> 8) & 0xFF
    nxt = (v >> 16) & 0xFFFFFFFF
    fg = (v >> 48) & 0xFF
    bg = (v >> 56) & 0xFF
    return char, times, nxt, fg, bg


def decode(blocks):
    out = []
    visited = []
    idx = 0
    steps = 0
    while True:
        if idx < 0 or idx >= len(blocks):
            out.append(f"<BAD INDEX {idx}>")
            break
        v = blocks[idx]
        char, times, nxt, fg, bg = split_block(v)
        visited.append((idx, v, char, times, nxt, fg, bg))
        if fg == bg:
            if fg in EFFECT_MAP:
                out.append(FMT_EFF.format(EFFECT_MAP[fg]))
            else:
                # new .s: jmp e_bgfg -> emit nothing, just chars
                pass
        else:
            out.append(FMT_CSI.format(fg, bg))
        # emit chars (print_times may be 0 -> emit none, same as dec_block loop)
        if times > 0:
            try:
                out.append(chr(char) * times)
            except ValueError:
                out.append(f"<BAD CHAR {char:#x}>x{times}")
        if nxt == 0:
            break
        idx = nxt
        steps += 1
        if steps > len(blocks) + 5:
            out.append("<LOOP GUARD>")
            break
    return "".join(out), visited


def cat_v(s: str) -> str:
    """Like cat -v: show ESC as ^[[ / \\x1b for readability."""
    return s.replace("\x1b", "\\x1b").replace("\n", "\\n\n")


def main():
    base = Path(__file__).parent
    src = Path(sys.argv[1]) if len(sys.argv) > 1 else (base / "final.s")
    blocks = parse_quads(src)
    print(f"parsed {len(blocks)} blocks from {src}")
    decoded, visited = decode(blocks)
    print(f"walked {len(visited)} blocks in linked-list order")
    print(f"decoded length (chars incl. CSI): {len(decoded)}")

    # Show first blocks (this is what 'first test' usually checks)
    print("\n--- first 10 blocks in walk order ---")
    for i, (idx, v, ch, times, nxt, fg, bg) in enumerate(visited[:10]):
        ch_repr = repr(chr(ch)) if 32 <= ch < 127 else f"0x{ch:02x}"
        kind = f"EFFECT->{EFFECT_MAP[fg]}" if (fg == bg and fg in EFFECT_MAP) else (
            "EFFECT-UNKNOWN(nothing)" if fg == bg else f"COLOR fg={fg} bg={bg}")
        print(f"step {i}: block[{idx}] val=0x{v:016X} char={ch_repr} x{times} "
              f"next={nxt} fg={fg} bg={bg} => {kind}")

    # Blink / effect audit
    print("\n--- effect audit (all fg==bg in walk) ---")
    found = [(idx, fg) for (idx, v, ch, times, nxt, fg, bg) in visited if fg == bg]
    print(f"fg==bg steps: {len(found)}")
    for idx, fg in found[:20]:
        print(f"  block[{idx}] raw={fg} -> SGR {EFFECT_MAP.get(fg, 'UNKNOWN(emit nothing)')}")
    if any(fg == 182 for _, fg in found):
        print("blink (182->5, ESC[5m) IS present in walk")
    else:
        print("blink (182) NOT in walk — if you expect blink, check MESSAGE/final.s")

    # Show raw + cat -v head so you can diff vs assembly a.out
    print("\n--- decoded head (repr, 500 chars) ---")
    print(repr(decoded[:500]))
    print("\n--- decoded head (cat -v style, 500 chars) ---")
    print(cat_v(decoded[:500]))

    # Full raw output to stdout boundary (so you can pipe it)
    print("\n--- FULL RAW OUTPUT START ---")
    sys.stdout.write(decoded)
    sys.stdout.flush()
    print("\n--- FULL RAW OUTPUT END ---")


if __name__ == "__main__":
    main()
