#!/usr/bin/env python3
# -*- coding: utf-8 -*-
#
# Byg-soegeside.command
# ----------------------
# Lægges i samme mappe som dine singlefile-HTML-outputs (album, lydfortællinger,
# e-bøger m.fl. fra builder-værktøjskassen). Dobbeltklik på filen i Finder for at
# køre den, eller kør den fra Terminal: ./Byg-soegeside.command
#
# Scriptet scanner mappen for .html-filer, læser den indlejrede
# "builder-source-data"-JSON-blok (Dublin Core-felterne) ud af hver fil, og
# genererer derefter EN NY, selvstændig søgeside (soegeside.html) med alt data
# skrevet direkte ind i filen. Ingen server, ingen separat json-fil – søgesiden
# virker ved almindeligt dobbeltklik, ligesom dine øvrige builder-outputs.
#
# Kør scriptet igen, når du har lagt nye filer i mappen, for at opdatere søgesiden.

import json
import re
import sys
import webbrowser
from datetime import datetime
from pathlib import Path

SCRIPT_DIR = Path(__file__).resolve().parent
OUTPUT_NAME = "soegeside.html"
OUTPUT_MARKER = "lokalt-soegeindeks-genereret"

SOURCE_BLOCK_RE = re.compile(
    r'<script[^>]*id="builder-source-data"[^>]*>(.*?)</script>', re.S
)

TYPE_ICON = {
    "Sound": "🎧",
    "Image": "🖼️",
    "Text": "📖",
    "Collection": "🗂️",
    "InteractiveResource": "🧩",
    "Event": "📌",
}

DC_FIELDS = [
    "title", "creator", "subject", "description", "publisher", "contributor",
    "date", "type", "format", "identifier", "source", "language", "relation",
    "coverage", "rights",
]


def find_html_files():
    files = []
    for p in sorted(SCRIPT_DIR.glob("*.html")):
        if p.name == OUTPUT_NAME:
            continue
        files.append(p)
    return files


def extract_record(path):
    try:
        text = path.read_text(encoding="utf-8", errors="ignore")
    except Exception as e:
        print(f"  ! Kunne ikke læse {path.name}: {e}")
        return None

    if OUTPUT_MARKER in text[:2000]:
        return None  # det er en tidligere genereret søgeside selv

    m = SOURCE_BLOCK_RE.search(text)
    if not m:
        print(f"  - Sprunget over (ingen builder-source-data): {path.name}")
        return None

    try:
        data = json.loads(m.group(1))
    except Exception as e:
        print(f"  ! Kunne ikke læse metadata i {path.name}: {e}")
        return None

    dc = data.get("dublinCore", {}) or {}
    record = {"filnavn": path.name, "appformat": data.get("format", "")}
    for felt in DC_FIELDS:
        record[felt] = (dc.get(felt) or "").strip()

    if not record["title"]:
        record["title"] = path.stem

    return record


def year_sort_key(dato):
    m = re.search(r"\d{4}", dato or "")
    return m.group(0) if m else "0000"


def build_html(records):
    data_json = json.dumps(records, ensure_ascii=False)
    data_json = data_json.replace("</script", "<\\/script")

    generated = datetime.now().strftime("%-d. %B %Y, %H:%M")

    return HTML_TEMPLATE.replace("__MARKER__", OUTPUT_MARKER) \
        .replace("__ANTAL__", str(len(records))) \
        .replace("__GENERERET__", generated) \
        .replace("__DATA_JSON__", data_json)


HTML_TEMPLATE = """<!-- __MARKER__ -->
<!DOCTYPE html>
<html lang="da">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>Lokalhistorisk søgeindeks</title>
<style>
:root{
  --accent:#9E2453;
  --paper:#FAF9F5;
  --paper-dim:#F1E7EC;
  --ink:#2B1A22;
  --line:#E3D3DA;
  --muted:#6B5560;
  --footer-strong:#3A2630;
}
*{box-sizing:border-box}
html,body{margin:0;padding:0}
body{background:var(--paper);color:var(--ink);font-family:Georgia,"Times New Roman",serif;font-size:18px;line-height:1.5}
header{max-width:1100px;margin:0 auto;padding:34px 20px 10px}
h1{font-size:32px;margin:0 0 4px}
.sub{color:var(--muted);font-size:16px;margin:0}
.controls{max-width:1100px;margin:22px auto 6px;padding:0 20px;display:flex;gap:12px;flex-wrap:wrap}
.controls input,.controls select{
  font-family:inherit;font-size:16px;padding:10px 12px;border:2px solid var(--line);
  border-radius:8px;background:#fff;color:var(--ink);min-height:44px;
}
.controls input{flex:1 1 260px}
.controls select{flex:0 0 auto}
.count{max-width:1100px;margin:14px auto 0;padding:0 20px;color:var(--muted);font-size:15px}
.list{max-width:1100px;margin:10px auto 60px;padding:0 20px}
a.row{
  display:flex;gap:16px;align-items:flex-start;text-decoration:none;color:var(--ink);
  padding:14px 14px;border-radius:8px;
}
a.row:hover{outline:2px solid var(--accent)}
a.row:focus-visible{outline:3px solid var(--accent)}
.row--a{background:var(--paper)}
.row--b{background:var(--paper-dim)}
.icon{font-size:22px;flex:0 0 30px}
.col-main{flex:1 1 auto;min-width:0}
.col-main .t{font-size:19px;font-weight:bold;color:var(--footer-strong)}
.col-main .m{font-size:14.5px;color:var(--muted);margin-top:2px}
.col-main .d{font-size:15px;color:var(--ink);margin-top:6px;
  display:-webkit-box;-webkit-line-clamp:2;-webkit-box-orient:vertical;overflow:hidden}
.col-type{flex:0 0 auto;font-size:14px;color:var(--muted);align-self:center;white-space:nowrap}
.empty{padding:30px 0;color:var(--muted)}
footer{max-width:1100px;margin:0 auto;padding:10px 20px 50px;color:var(--muted);font-size:13.5px}
@media(max-width:640px){.col-type{display:none}}
</style>
</head>
<body>
<header>
<h1>Lokalhistorisk søgeindeks</h1>
<p class="sub">__ANTAL__ poster · genereret __GENERERET__</p>
</header>

<div class="controls">
<input id="q" type="search" placeholder="Søg i titel, ophav, emne og beskrivelse …" aria-label="Søg">
<select id="typeFilter" aria-label="Filtrér på type"><option value="">Alle typer</option></select>
<select id="sortBy" aria-label="Sortér">
<option value="title">Titel A–Å</option>
<option value="date-new">Dato, nyeste først</option>
<option value="date-old">Dato, ældste først</option>
<option value="type">Type</option>
</select>
</div>

<p class="count" id="count"></p>
<div class="list" id="list"></div>

<footer>
Denne side er selvstændig og indeholder alt indhold direkte i filen. Genkør
<em>Byg-soegeside.command</em> i mappen for at opdatere søgeindekset, når der er
lagt nye filer til.
</footer>

<script>
const DATA = __DATA_JSON__;
const ICONS = {Sound:"🎧",Image:"🖼️",Text:"📖",Collection:"🗂️",InteractiveResource:"🧩",Event:"📌"};

function yearOf(s){var m=(s||"").match(/\\d{4}/); return m?m[0]:"0000";}

const typeSel = document.getElementById("typeFilter");
const seen = new Set();
DATA.forEach(r=>{ if(r.type) seen.add(r.type); });
Array.from(seen).sort().forEach(t=>{
  const o=document.createElement("option"); o.value=t; o.textContent=t;
  typeSel.appendChild(o);
});

function render(){
  const q = document.getElementById("q").value.trim().toLowerCase();
  const type = typeSel.value;
  const sortBy = document.getElementById("sortBy").value;

  let rows = DATA.filter(r=>{
    if(type && r.type!==type) return false;
    if(!q) return true;
    const hay = (r.title+" "+r.creator+" "+r.subject+" "+r.description).toLowerCase();
    return hay.indexOf(q)!==-1;
  });

  rows = rows.slice().sort((a,b)=>{
    if(sortBy==="title") return a.title.localeCompare(b.title,"da");
    if(sortBy==="type") return (a.type||"").localeCompare(b.type||"","da");
    const ya=yearOf(a.date), yb=yearOf(b.date);
    return sortBy==="date-new" ? yb.localeCompare(ya) : ya.localeCompare(yb);
  });

  const list = document.getElementById("list");
  list.innerHTML = "";
  document.getElementById("count").textContent =
    "Viser " + rows.length + " af " + DATA.length + " poster";

  if(rows.length===0){
    const p=document.createElement("p");
    p.className="empty"; p.textContent="Ingen poster matcher søgningen.";
    list.appendChild(p); return;
  }

  rows.forEach((r,i)=>{
    const a=document.createElement("a");
    a.className="row " + (i%2===0?"row--a":"row--b");
    a.href=encodeURI(r.filnavn); a.target="_blank"; a.rel="noopener";

    const icon=document.createElement("span");
    icon.className="icon"; icon.textContent = ICONS[r.type]||"📄";

    const main=document.createElement("span");
    main.className="col-main";
    const t=document.createElement("span"); t.className="t"; t.textContent=r.title;
    const m=document.createElement("span"); m.className="m";
    m.textContent=[r.creator,r.date].filter(Boolean).join(" · ");
    const d=document.createElement("span"); d.className="d"; d.textContent=r.description||"";
    main.appendChild(t); main.appendChild(document.createElement("br"));
    main.appendChild(m); main.appendChild(d);

    const typ=document.createElement("span");
    typ.className="col-type"; typ.textContent=r.type||"";

    a.appendChild(icon); a.appendChild(main); a.appendChild(typ);
    list.appendChild(a);
  });
}

document.getElementById("q").addEventListener("input", render);
typeSel.addEventListener("change", render);
document.getElementById("sortBy").addEventListener("change", render);
render();
</script>
</body>
</html>
"""


def main():
    print("Scanner mappen for singlefile-HTML-filer …")
    files = find_html_files()
    records = []
    for p in files:
        rec = extract_record(p)
        if rec:
            records.append(rec)

    if not records:
        print("\nFandt ingen indekserbare filer. Ligger scriptet i den rigtige mappe?")
        input("Tryk Enter for at afslutte …")
        sys.exit(1)

    out_path = SCRIPT_DIR / OUTPUT_NAME
    out_path.write_text(build_html(records), encoding="utf-8")

    print(f"\nFærdig. Indekserede {len(records)} af {len(files)} html-filer.")
    print(f"Søgesiden er gemt som: {out_path}")

    try:
        webbrowser.open(out_path.as_uri())
    except Exception:
        pass

    input("Tryk Enter for at lukke …")


if __name__ == "__main__":
    main()
