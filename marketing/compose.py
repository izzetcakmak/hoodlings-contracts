"""Composes OpenSea marketing images (banner, logo, featured) from the
on-chain Hoodling SVGs, then rasterizes them with headless Chrome."""
import re
import subprocess
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
SAMPLES = ROOT / "samples"
OUT = ROOT / "marketing"
CHROME = Path("C:/Users/Monster/.chromium-browser-snapshots/win64-1398050/chrome-win/chrome.exe")

TITLE_GRAD = (
    "<linearGradient id='tg' x1='0' y1='0' x2='1' y2='0'>"
    "<stop offset='0' stop-color='#f5c542'/><stop offset='.5' stop-color='#10b981'/>"
    "<stop offset='1' stop-color='#38bdf8'/></linearGradient>"
)
BG_GRAD = (
    "<radialGradient id='bgg' cx='.5' cy='-.2' r='1.4'>"
    "<stop offset='0' stop-color='#1c2447'/><stop offset='.6' stop-color='#0b0e17'/>"
    "<stop offset='1' stop-color='#07090f'/></radialGradient>"
)
FONT = "Segoe UI, Arial, sans-serif"


def load_hoodling(token_id: int) -> str:
    """Load a sample SVG and namespace its gradient ids to avoid collisions."""
    svg = (SAMPLES / f"hoodling-{token_id}.svg").read_text()
    svg = svg.replace("id='b'", f"id='b{token_id}'").replace("url(#b)", f"url(#b{token_id})")
    svg = svg.replace("id='a'", f"id='a{token_id}'").replace("url(#a)", f"url(#a{token_id})")
    inner = re.sub(r"^<svg[^>]*>", "", svg).removesuffix("</svg>")
    return inner


def card(token_id: int, x: float, y: float, size: float, rot: float = 0.0, founder: bool = False) -> str:
    """A Hoodling rendered as a rounded card with optional gold founder ring."""
    r = size * 0.09
    ring = (
        f"<rect x='{x-4}' y='{y-4}' width='{size+8}' height='{size+8}' rx='{r+4}' "
        f"fill='none' stroke='#f5c542' stroke-width='4' opacity='.9'/>" if founder else
        f"<rect x='{x-3}' y='{y-3}' width='{size+6}' height='{size+6}' rx='{r+3}' "
        f"fill='none' stroke='#263050' stroke-width='3'/>"
    )
    cx, cy = x + size / 2, y + size / 2
    return (
        f"<g transform='rotate({rot} {cx} {cy})'>"
        f"<rect x='{x+6}' y='{y+10}' width='{size}' height='{size}' rx='{r}' fill='#000' opacity='.5'/>"
        f"{ring}"
        f"<clipPath id='c{token_id}'><rect x='{x}' y='{y}' width='{size}' height='{size}' rx='{r}'/></clipPath>"
        f"<g clip-path='url(#c{token_id})'>"
        f"<svg x='{x}' y='{y}' width='{size}' height='{size}' viewBox='0 0 100 100'>{load_hoodling(token_id)}</svg>"
        f"</g></g>"
    )


def banner() -> str:
    """2800x700 (2x of OpenSea's 1400x350 banner)."""
    W, H = 2800, 700
    p = [
        f"<svg xmlns='http://www.w3.org/2000/svg' width='{W}' height='{H}' viewBox='0 0 {W} {H}'>",
        f"<defs>{TITLE_GRAD}{BG_GRAD}</defs>",
        f"<rect width='{W}' height='{H}' fill='url(#bgg)'/>",
    ]
    # sparse stars
    for i, (sx, sy, sr) in enumerate([(180, 90, 3), (520, 60, 2), (860, 130, 2.5), (1180, 50, 2),
                                      (2600, 80, 3), (2380, 40, 2), (1560, 45, 2), (2720, 300, 2)]):
        p.append(f"<circle cx='{sx}' cy='{sy}' r='{sr}' fill='#fff' opacity='.5'/>")
    # OpenSea crops banner edges responsively — all critical content lives in
    # the center safe zone; cards flank the edges where cropping is harmless.
    p.append(f"<text x='1400' y='300' text-anchor='middle' font-family='{FONT}' font-size='150' "
             f"font-weight='900' letter-spacing='-4' fill='url(#tg)'>HOODLINGS</text>")
    p.append(f"<text x='1400' y='382' text-anchor='middle' font-family='{FONT}' font-size='42' "
             f"fill='#94a3b8'>4663 fully on-chain spirits of Robinhood Chain</text>")
    # badge (centered)
    p.append("<rect x='975' y='432' width='850' height='74' rx='37' fill='#131829' "
             "stroke='#263050' stroke-width='2'/>")
    p.append(f"<text x='1400' y='481' text-anchor='middle' font-family='{FONT}' font-size='34' "
             f"fill='#e2e8f0'>Supply = Chain ID = <tspan fill='#f5c542' font-weight='700'>4663</tspan>"
             f" &#183; mint <tspan fill='#10b981' font-weight='700'>0.0005 ETH</tspan>"
             f" &#183; no IPFS</text>")
    # cards flank both edges; hero (#52 laser+aura founder) innermost right
    lineup = [
        (40, 96, 240, -3, 2900, False),
        (275, 65, 272, 2, 4444, False),
        (535, 40, 300, -2, 89, True),
        (1965, 40, 300, 2, 52, True),      # hero
        (2255, 65, 272, -2, 42, True),
        (2510, 96, 240, 3, 1000, False),
    ]
    for x, y, size, rot, tid, founder in lineup:
        p.append(card(tid, x, y + (700 - size) / 2 - 40, size, rot, founder))
    p.append("</svg>")
    return "".join(p)


def logo() -> str:
    """1000x1000 square logo — hero Hoodling #52 with gold ring."""
    W = 1000
    p = [
        f"<svg xmlns='http://www.w3.org/2000/svg' width='{W}' height='{W}' viewBox='0 0 {W} {W}'>",
        f"<defs>{BG_GRAD}</defs>",
        f"<rect width='{W}' height='{W}' fill='url(#bgg)'/>",
        f"<defs><clipPath id='logoclip'><circle cx='500' cy='500' r='430'/></clipPath></defs>",
        f"<g clip-path='url(#logoclip)'><svg x='80' y='80' width='840' height='840' "
        f"viewBox='0 0 100 100'>"
        # shorten the laser beams so they stay inside the gold ring
        f"{load_hoodling(52).replace(chr(39) + ' y=' + chr(39) + '41' + chr(39) + ' width=' + chr(39) + '56', chr(39) + ' y=' + chr(39) + '41' + chr(39) + ' width=' + chr(39) + '34').replace(chr(39) + ' y=' + chr(39) + '42.5' + chr(39) + ' width=' + chr(39) + '44', chr(39) + ' y=' + chr(39) + '42.5' + chr(39) + ' width=' + chr(39) + '22')}"
        f"</svg></g>",
        f"<circle cx='500' cy='500' r='437' fill='none' stroke='#07090f' stroke-width='16'/>",
        f"<circle cx='500' cy='500' r='448' fill='none' stroke='#f5c542' stroke-width='14'/>",
        f"<circle cx='500' cy='500' r='464' fill='none' stroke='#263050' stroke-width='6'/>",
        "</svg>",
    ]
    return "".join(p)


def featured() -> str:
    """1200x800 featured image (2x of 600x400)."""
    W, H = 1200, 800
    p = [
        f"<svg xmlns='http://www.w3.org/2000/svg' width='{W}' height='{H}' viewBox='0 0 {W} {H}'>",
        f"<defs>{TITLE_GRAD}{BG_GRAD}</defs>",
        f"<rect width='{W}' height='{H}' fill='url(#bgg)'/>",
    ]
    for sx, sy, sr in [(100, 80, 2.5), (1100, 60, 3), (600, 40, 2), (980, 700, 2), (160, 720, 2.5)]:
        p.append(f"<circle cx='{sx}' cy='{sy}' r='{sr}' fill='#fff' opacity='.5'/>")
    trio = [(120, 260, 300, -4, 89, True), (450, 200, 340, 0, 52, True), (810, 260, 300, 4, 42, True)]
    for x, y, size, rot, tid, founder in trio:
        p.append(card(tid, x, y, size, rot, founder))
    p.append(f"<text x='600' y='140' text-anchor='middle' font-family='{FONT}' font-size='96' "
             f"font-weight='900' letter-spacing='-2' fill='url(#tg)'>HOODLINGS</text>")
    p.append(f"<text x='600' y='700' text-anchor='middle' font-family='{FONT}' font-size='38' "
             f"fill='#94a3b8'>4663 fully on-chain &#183; Robinhood Chain</text>")
    p.append("</svg>")
    return "".join(p)


def rasterize(name: str, svg: str, w: int, h: int) -> None:
    html = OUT / f"{name}.html"
    html.write_text(f"<!doctype html><html><head><style>*{{margin:0;padding:0}}"
                    f"body{{background:#07090f}}svg{{display:block}}</style></head>"
                    f"<body>{svg}</body></html>", encoding="utf-8")
    subprocess.run([
        str(CHROME), "--headless=new", "--disable-gpu", "--hide-scrollbars",
        "--force-device-scale-factor=1",
        f"--screenshot={OUT / (name + '.png')}", f"--window-size={w},{h}",
        html.as_uri(),
    ], check=True, capture_output=True, timeout=120)
    import struct
    with open(OUT / (name + ".png"), "rb") as f:
        f.seek(16)
        pw, ph = struct.unpack(">II", f.read(8))
    print(f"{name} -> {OUT / (name + '.png')} ({pw}x{ph})")


if __name__ == "__main__":
    rasterize("banner", banner(), 2800, 700)
    rasterize("logo", logo(), 1000, 1000)
    rasterize("featured", featured(), 1200, 800)
