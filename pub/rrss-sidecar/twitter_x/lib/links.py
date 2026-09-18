"""Protocolo (b): cada enlace externo de los posts propios → markdown.

  store/links_store.json          {<hash>: {url, family, status, title, method, cited_by[], …}}
  store/links_browser_queue.json  páginas que exigen navegador (las procesa el agente con Chrome)
  store/links_blocked.json        REGLA PARAR: shares de agente privados/caducados
  cache/links/<hash>.md           el markdown íntegro (el build lo publica en corpus/links/)
  cache/links/<hash>.raw          el crudo descargado

REGLA PARAR. Las conversaciones con agentes (`agent:*`) se compartieron como públicas. Si una
responde con login, «private», «not found» o vacío, NO se salta en silencio: se anota en
`links_blocked.json`, la tanda termina con código 3 y se pide al usuario que la haga pública.
`build` falla mientras haya bloqueados sin dispensa (`waived_by`).
"""

from __future__ import annotations

import hashlib
import json
import os
import re
import subprocess
import time
import urllib.error
import urllib.request
from datetime import datetime, timezone
from pathlib import Path
from urllib.parse import parse_qsl, urlencode, urlsplit, urlunsplit

from . import html2md, normalize
from .obra import Obra, read_json, write_json_atomic

UA = "Mozilla/5.0 (compatible; rrss-sidecar/1.0; archivo estatico)"
BROWSER_UA = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/131.0 Safari/537.36"
JINA = "https://r.jina.ai/"
TRACKING = re.compile(r"^(utm_|fbclid$|gclid$|igshid$|ref_src$|ref_url$|s$|si$|feature$)")
EXIT_BLOCKED = 3

FAMILIES: list[tuple[str, re.Pattern]] = [
    ("agent:chatgpt", re.compile(r"^(chatgpt\.com|chat\.openai\.com)/share/", re.I)),
    ("agent:deepseek", re.compile(r"^chat\.deepseek\.com/(share|a/chat/s)/", re.I)),
    ("agent:grok", re.compile(r"^(grok\.com/share|x\.com/i/grok/share)/", re.I)),
    ("agent:claude", re.compile(r"^claude\.ai/(share|artifact|code/artifact|public/artifacts)/", re.I)),
    ("agent:gemini", re.compile(r"^(g\.co/gemini|gemini\.google\.com/share)", re.I)),
    ("agent:perplexity", re.compile(r"^perplexity\.ai/", re.I)),
    ("github:gist", re.compile(r"^gist\.github\.com/[^/]+/[0-9a-f]+", re.I)),
    ("github:blob", re.compile(r"^github\.com/[^/]+/[^/]+/blob/", re.I)),
    ("github:issue", re.compile(r"^github\.com/[^/]+/[^/]+/(issues|pull|discussions)/\d+", re.I)),
    ("github:repo", re.compile(r"^github\.com/[^/]+/[^/]+(/(tree/.*)?)?/?$", re.I)),
    ("video:youtube", re.compile(r"^(m\.)?(youtube\.com/(watch|live|shorts|playlist)|youtu\.be/)", re.I)),
    ("video:other", re.compile(r"^(twitch\.tv|kick\.com|vimeo\.com|tiktok\.com|dailymotion\.com)/", re.I)),
]
BROWSER_FAMILIES = {"agent:grok", "agent:claude", "agent:perplexity", "agent:gemini"}
WALL = re.compile(
    r"sign in|log in to continue|iniciar sesi[oó]n|this conversation is private|"
    r"share link not found|conversation (is )?(not|no longer) available|not found|"
    r"just a moment|enable javascript|verify (that )?you('re| are) (not a robot|human)|access denied",
    re.I,
)


def now_iso() -> str:
    return datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")


def normalize_url(url: str) -> str:
    parts = urlsplit(url.strip())
    query = [(k, v) for k, v in parse_qsl(parts.query, keep_blank_values=True) if not TRACKING.match(k)]
    host = (parts.hostname or "").lower()
    netloc = host + (f":{parts.port}" if parts.port else "")
    return urlunsplit((parts.scheme.lower(), netloc, parts.path or "/", urlencode(query), ""))


def key_of(url: str) -> str:
    return hashlib.sha256(normalize_url(url).encode("utf-8")).hexdigest()[:16]


def classify(url: str, own_hosts: list[str]) -> str:
    parts = urlsplit(url)
    host = (parts.hostname or "").lower().removeprefix("www.")
    probe = host + parts.path
    for family, pattern in FAMILIES:
        if pattern.search(probe):
            return family
    if any(host == h or host.endswith("." + h) for h in own_hosts):
        return "own"
    return "generic"


def store_path(obra: Obra) -> Path:
    return obra.store_dir / "links_store.json"


def load(obra: Obra) -> dict:
    return read_json(store_path(obra), {})


def md_path(obra: Obra, key: str) -> Path:
    return obra.cache_dir / "links" / f"{key}.md"


# ── plan ─────────────────────────────────────────────────────────────────────

def plan(obra: Obra) -> dict:
    own_hosts = obra.cfg.get("own_hosts") or []
    data = load(obra)
    cited: dict[str, list[str]] = {}
    first_url: dict[str, str] = {}
    for rec in normalize.records(obra):
        for url in rec["links"]:
            key = key_of(url)
            cited.setdefault(key, []).append(rec["id"])
            first_url.setdefault(key, url)
    for key, url in first_url.items():
        entry = data.setdefault(key, {"url": url, "status": "pending", "attempts": 0})
        entry["family"] = classify(url, own_hosts)
        entry["cited_by"] = sorted(set(cited[key]))
    write_json_atomic(store_path(obra), data)
    by_family: dict[str, dict[str, int]] = {}
    for entry in data.values():
        fam = by_family.setdefault(entry["family"], {})
        fam[entry["status"]] = fam.get(entry["status"], 0) + 1
    return {"urls": len(data), "by_family": by_family}


# ── red ──────────────────────────────────────────────────────────────────────

def http_get(url: str, accept: str = "*/*", headers: dict | None = None, timeout: int = 40):
    request = urllib.request.Request(url, headers={"User-Agent": UA, "Accept": accept, **(headers or {})})
    try:
        with urllib.request.urlopen(request, timeout=timeout) as response:
            return response.status, response.headers, response.read(), response.geturl()
    except urllib.error.HTTPError as err:
        return err.code, err.headers, err.read() if err.fp else b"", url
    except (urllib.error.URLError, TimeoutError, ConnectionError, OSError) as err:
        return 0, {}, str(err).encode(), url


def decode(body: bytes, headers) -> str:
    charset = None
    try:
        charset = headers.get_content_charset()
    except AttributeError:
        pass
    for enc in (charset, "utf-8", "latin-1"):
        if not enc:
            continue
        try:
            return body.decode(enc)
        except (UnicodeDecodeError, LookupError):
            continue
    return body.decode("utf-8", "replace")


def github_headers() -> dict:
    token = os.environ.get("GITHUB_TOKEN")
    if not token:
        try:
            token = subprocess.run(["gh", "auth", "token"], capture_output=True, text=True, timeout=10).stdout.strip()
        except (OSError, subprocess.SubprocessError):
            token = ""
    return {"Authorization": f"Bearer {token}"} if token else {}


class Blocked(Exception):
    """Un share de agente que debería ser público no lo es."""


class NeedsBrowser(Exception):
    pass


# ── fetchers por familia → (título, markdown, método, final_url) ─────────────

def fetch_chatgpt(url: str):
    share_id = urlsplit(url).path.rstrip("/").split("/")[-1]
    api = f"https://chatgpt.com/backend-api/share/{share_id}"
    code, body = 0, b""
    for attempt, agent in enumerate((UA, BROWSER_UA, UA, BROWSER_UA)):
        code, _h, body, _final = http_get(api, "application/json", {"User-Agent": agent})
        if code == 200:
            break
        if code in (404, 410):
            raise Blocked(f"HTTP {code}: el share no existe o fue retirado")
        time.sleep(3 + attempt * 3)  # el 403 de chatgpt.com es un anti-bot intermitente, no «privado»
    if code != 200:
        raise NeedsBrowser(f"HTTP {code} persistente en backend-api/share (anti-bot)")
    data = json.loads(body.decode("utf-8", "replace"))
    if "linear_conversation" not in data:
        raise Blocked(f"sin linear_conversation: {str(data.get('detail'))[:120]}")
    lines = []
    for node in data["linear_conversation"]:
        message = node.get("message") or {}
        role = (message.get("author") or {}).get("role")
        meta = message.get("metadata") or {}
        content = message.get("content") or {}
        if role not in ("user", "assistant") or meta.get("is_visually_hidden_from_conversation"):
            continue
        ctype = content.get("content_type")
        parts = []
        if ctype in ("text", "multimodal_text"):
            for part in content.get("parts") or []:
                parts.append(part if isinstance(part, str) else "[imagen]")
        elif ctype == "thoughts":
            thoughts = [f"**{t.get('summary', '')}**\n\n{t.get('content', '')}" for t in content.get("thoughts") or []]
            parts.append("<details><summary>Razonamiento</summary>\n\n" + "\n\n".join(thoughts) + "\n\n</details>")
        elif ctype == "reasoning_recap":
            parts.append(f"*{content.get('content', '')}*")
        elif ctype == "code":
            parts.append(f"```{content.get('language') or ''}\n{content.get('text', '')}\n```")
        text = "\n\n".join(p for p in parts if p and p.strip())
        if text:
            lines.append(f"## {'Usuario' if role == 'user' else 'Asistente'}\n\n{text}")
    if not lines:
        raise Blocked("conversación vacía")
    return data.get("title") or "Conversación ChatGPT", "\n\n".join(lines) + "\n", "api", url


def fetch_jina(url: str):
    """Proxy de lectura r.jina.ai. Un resultado vacío es un fallo del proxy, no prueba de que el
    share sea privado: se reintenta y, si persiste, decide el navegador (cola). Solo el navegador
    —que ve si la página pide login— puede declarar un share `blocked`."""
    last = ""
    for attempt in range(3):
        code, headers, body, _final = http_get(JINA + url, "text/plain", {"X-Return-Format": "markdown"}, timeout=90)
        text = decode(body, headers)
        marker = "Markdown Content:"
        markdown = text.split(marker, 1)[1].strip() if marker in text else text.strip()
        if code == 200 and len(markdown) >= 200 and not WALL.search(markdown[:600]):
            match = re.search(r"^Title:\s*(.+)$", text, re.M)
            return (match.group(1).strip() if match else "Conversación"), markdown + "\n", "jina", url
        last = f"HTTP {code}, {len(markdown)} caracteres"
        time.sleep(8 + attempt * 8)
    raise NeedsBrowser(f"r.jina.ai sin contenido tras 3 intentos ({last})")


def fetch_github(url: str, family: str):
    parts = urlsplit(url)
    seg = [s for s in parts.path.split("/") if s]
    headers = github_headers()
    api = "https://api.github.com"
    if family == "github:gist":
        code, _h, body, _f = http_get(f"{api}/gists/{seg[1]}", "application/vnd.github+json", headers)
        if code != 200:
            return None
        gist = json.loads(body)
        chunks = [f"# {gist.get('description') or seg[1]}"]
        for name, item in (gist.get("files") or {}).items():
            chunks.append(f"## {name}\n\n```{(item.get('language') or '').lower()}\n{item.get('content', '')}\n```")
        return gist.get("description") or f"gist {seg[1]}", "\n\n".join(chunks) + "\n", "api", url
    owner, repo = seg[0], seg[1]
    if family == "github:blob":
        ref_path = "/".join(seg[3:])
        code, _h, body, _f = http_get(f"https://raw.githubusercontent.com/{owner}/{repo}/{ref_path}")
        if code != 200:
            return None
        text = body.decode("utf-8", "replace")
        name = seg[-1]
        markdown = text if name.lower().endswith((".md", ".markdown")) else f"```{Path(name).suffix.lstrip('.')}\n{text}\n```"
        return f"{owner}/{repo}: {'/'.join(seg[4:])}", markdown.rstrip() + "\n", "api", url
    if family == "github:issue":
        kind = "issues" if seg[2] in ("issues", "pull") else None
        if kind:
            code, _h, body, _f = http_get(f"{api}/repos/{owner}/{repo}/issues/{seg[3]}", "application/vnd.github+json", headers)
            if code == 200:
                issue = json.loads(body)
                chunks = [f"# {issue.get('title')}", f"*{issue.get('user', {}).get('login')} · {issue.get('created_at')} · {issue.get('state')}*", issue.get("body") or ""]
                code, _h, body, _f = http_get(f"{api}/repos/{owner}/{repo}/issues/{seg[3]}/comments?per_page=100", "application/vnd.github+json", headers)
                if code == 200:
                    for comment in json.loads(body):
                        chunks.append(f"## {comment.get('user', {}).get('login')} · {comment.get('created_at')}\n\n{comment.get('body') or ''}")
                return issue.get("title") or url, "\n\n".join(chunks).rstrip() + "\n", "api", url
        return None
    code, _h, body, _f = http_get(f"{api}/repos/{owner}/{repo}", "application/vnd.github+json", headers)
    if code != 200:
        return None
    info = json.loads(body)
    chunks = [f"# {info.get('full_name')}", info.get("description") or "",
              f"*{info.get('language') or '—'} · ★ {info.get('stargazers_count')} · actualizado {info.get('pushed_at')} · licencia {(info.get('license') or {}).get('spdx_id') or '—'}*"]
    code, _h, body, _f = http_get(f"{api}/repos/{owner}/{repo}/readme", "application/vnd.github.raw+json", headers)
    if code == 200:
        chunks.append("---\n\n" + body.decode("utf-8", "replace"))
    return info.get("full_name") or url, "\n\n".join(c for c in chunks if c).rstrip() + "\n", "api", url


def fetch_youtube(url: str):
    code, headers, body, final = http_get(url, "text/html", {"Accept-Language": "es,en;q=0.8", "Cookie": "CONSENT=YES+1"})
    if code != 200:
        return None
    page = decode(body, headers)
    match = re.search(r"ytInitialPlayerResponse\s*=\s*(\{.+?\})\s*;\s*(?:var |</script>)", page, re.S)
    if not match:
        return fetch_html(url)
    try:
        player = json.loads(match.group(1))
    except json.JSONDecodeError:
        return fetch_html(url)
    details = player.get("videoDetails") or {}
    micro = (player.get("microformat") or {}).get("playerMicroformatRenderer") or {}
    seconds = int(details.get("lengthSeconds") or 0)
    chunks = [
        f"# {details.get('title') or 'Vídeo'}",
        f"*Canal: {details.get('author') or '—'} · duración {seconds // 60}:{seconds % 60:02d} · publicado {micro.get('publishDate') or '—'}*",
        details.get("shortDescription") or "",
    ]
    tracks = (((player.get("captions") or {}).get("playerCaptionsTracklistRenderer") or {}).get("captionTracks")) or []
    if tracks:
        track = next((t for t in tracks if (t.get("languageCode") or "").startswith("es")), tracks[0])
        code, _h, cap, _f = http_get(track["baseUrl"] + "&fmt=json3", "application/json")
        if code == 200 and cap.strip():
            try:
                events = json.loads(cap).get("events") or []
                words = " ".join("".join(s.get("utf8", "") for s in e.get("segs") or []) for e in events)
                words = re.sub(r"\s+", " ", words).strip()
                if words:
                    chunks.append(f"## Subtítulos ({track.get('languageCode')})\n\n{words}")
            except json.JSONDecodeError:
                pass
    return details.get("title") or "Vídeo", "\n\n".join(c for c in chunks if c).rstrip() + "\n", "direct", final


def fetch_html(url: str):
    code, headers, body, final = http_get(url, "text/html,application/xhtml+xml")
    if code in (404, 410):
        return ("gone", code)
    if code != 200:
        return None
    ctype = (headers.get("Content-Type") or "").lower()
    if "html" not in ctype and "xml" not in ctype and "text/plain" not in ctype:
        digest = hashlib.sha256(body).hexdigest()
        return (url.rsplit("/", 1)[-1] or url, f"*Recurso no HTML: `{ctype}` · {len(body)} bytes · sha256 `{digest}`*\n", "meta", final)
    text = decode(body, headers)
    if "text/plain" in ctype:
        return url, f"```\n{text}\n```\n", "direct", final
    title, markdown = html2md.convert(text, final)
    if len(markdown.strip()) < 40:
        raise NeedsBrowser("HTML sin contenido server-side (SPA)")
    return title or url, markdown, "direct", final


def fetch(url: str, family: str):
    if family == "agent:chatgpt":
        return fetch_chatgpt(url)
    if family == "agent:deepseek":
        return fetch_jina(url)
    if family in BROWSER_FAMILIES:
        raise NeedsBrowser(family)
    if family.startswith("github:"):
        return fetch_github(url, family) or fetch_html(url)
    if family == "video:youtube":
        return fetch_youtube(url)
    return fetch_html(url)


# ── tanda ────────────────────────────────────────────────────────────────────

def save_result(obra: Obra, key: str, entry: dict, title: str, markdown: str, method: str, final_url: str) -> None:
    path = md_path(obra, key)
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(markdown, encoding="utf-8", newline="\n")
    entry.update(
        {
            "status": "ok",
            "title": title.strip()[:300],
            "method": method,
            "final_url": final_url,
            "fetched_at": now_iso(),
            "sha256_md": hashlib.sha256(markdown.encode("utf-8")).hexdigest(),
            "bytes_md": len(markdown.encode("utf-8")),
        }
    )
    entry.pop("error", None)


def run(obra: Obra, families: list[str] | None = None, retry: bool = False, limit: int = 0) -> int:
    plan(obra)
    data = load(obra)
    blocked = read_json(obra.store_dir / "links_blocked.json", [])
    queue = read_json(obra.store_dir / "links_browser_queue.json", [])
    queued = {q["hash"] for q in queue}
    statuses = {"pending", "error"} | ({"blocked", "gone"} if retry else set())
    todo = [(k, e) for k, e in data.items() if e["status"] in statuses
            and (not families or any(e["family"].startswith(f) for f in families))]
    if limit:
        todo = todo[:limit]
    stop = False
    touched: dict[str, dict] = {}
    for index, (key, entry) in enumerate(todo, start=1):
        url, family = entry["url"], entry["family"]
        entry["attempts"] = int(entry.get("attempts") or 0) + 1
        try:
            result = fetch(url, family)
            if result is None:
                entry.update({"status": "error", "error": "sin respuesta útil", "fetched_at": now_iso()})
            elif result[0] == "gone":
                entry.update({"status": "gone", "http_status": result[1], "fetched_at": now_iso()})
            else:
                save_result(obra, key, entry, *result)
        except NeedsBrowser as err:
            entry.update({"status": "pending_browser", "error": str(err)})
            if key not in queued:
                queue.append({"hash": key, "url": url, "family": family, "cited_by": entry["cited_by"]})
                queued.add(key)
        except Blocked as err:
            entry.update({"status": "blocked", "error": str(err), "fetched_at": now_iso()})
            blocked = [b for b in blocked if b["hash"] != key]
            blocked.append({"hash": key, "url": url, "family": family, "cited_by": entry["cited_by"],
                            "evidence": str(err), "detected_at": now_iso()})
            stop = True
        except Exception as err:  # noqa: BLE001 — un enlace roto no debe tumbar la tanda
            entry.update({"status": "error", "error": f"{type(err).__name__}: {err}"[:300], "fetched_at": now_iso()})
        print(f"  [{index}/{len(todo)}] {entry['status']:<15} {family:<16} {url[:90]}", flush=True)
        touched[key] = entry
        if index % 10 == 0 or stop:
            data = merge_write(obra, touched)
        if stop:
            break
        time.sleep(4.0 if family == "agent:deepseek" else 0.6)
    merge_write(obra, touched)
    write_json_atomic(obra.store_dir / "links_browser_queue.json", queue)
    write_json_atomic(obra.store_dir / "links_blocked.json", blocked)
    if stop:
        print_blocked(blocked)
        return EXIT_BLOCKED
    return 0


def merge_write(obra: Obra, touched: dict[str, dict]) -> dict:
    """Vuelca SOLO las entradas tocadas en esta tanda sobre lo que haya en disco: una tanda larga no
    debe pisar lo que entre tanto guardó `browser-save` (u otra tanda)."""
    disk = load(obra)
    for key, entry in touched.items():
        if (disk.get(key) or {}).get("status") == "ok" and entry.get("status") != "ok":
            continue  # nunca degradar un enlace ya recuperado
        disk[key] = entry
    write_json_atomic(store_path(obra), disk)
    return disk


def print_blocked(blocked: list[dict]) -> None:
    active = [b for b in blocked if not b.get("waived_by")]
    if not active:
        return
    print("\n⛔ REGLA PARAR — estos shares de agente NO son accesibles públicamente:")
    for item in active:
        print(f"   {item['url']}\n      familia {item['family']} · citado en {', '.join(item['cited_by'][:5])} · {item['evidence']}")
    print("   Hazlos públicos y relanza:  sidecar.py fetch-links --obra <obra> --run --retry\n")


def active_blocked(obra: Obra) -> list[dict]:
    return [b for b in read_json(obra.store_dir / "links_blocked.json", []) if not b.get("waived_by")]


# ── cola de navegador ────────────────────────────────────────────────────────

def browser_next(obra: Obra) -> dict | None:
    queue = read_json(obra.store_dir / "links_browser_queue.json", [])
    data = load(obra)
    for item in queue:
        if (data.get(item["hash"]) or {}).get("status") == "pending_browser":
            return item
    return None


def browser_save(obra: Obra, key: str, title: str, md_file: Path, final_url: str | None) -> None:
    data = load(obra)
    entry = data.get(key)
    if not entry:
        raise SystemExit(f"hash desconocido: {key}")
    markdown = md_file.read_text(encoding="utf-8")
    if len(markdown.strip()) < 200 or WALL.search(markdown[:600]):
        raise SystemExit("el markdown parece un muro de login o está vacío: no se guarda (REGLA PARAR)")
    save_result(obra, key, entry, title, markdown if markdown.endswith("\n") else markdown + "\n",
                "browser", final_url or entry["url"])
    write_json_atomic(store_path(obra), data)


def browser_block(obra: Obra, key: str, evidence: str) -> None:
    data = load(obra)
    entry = data[key]
    entry.update({"status": "blocked", "error": evidence, "fetched_at": now_iso()})
    blocked = [b for b in read_json(obra.store_dir / "links_blocked.json", []) if b["hash"] != key]
    blocked.append({"hash": key, "url": entry["url"], "family": entry["family"], "cited_by": entry["cited_by"],
                    "evidence": evidence, "detected_at": now_iso()})
    write_json_atomic(store_path(obra), data)
    write_json_atomic(obra.store_dir / "links_blocked.json", blocked)
