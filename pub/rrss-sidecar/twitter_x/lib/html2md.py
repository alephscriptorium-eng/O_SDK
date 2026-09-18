"""HTML → Markdown con la stdlib (`html.parser`). Sin dependencias.

Elige el contenedor principal (`.vp-doc` de VitePress, `<main>`, `<article>`, y si no `<body>`),
descarta cromo (script/style/nav/header/footer/aside/form/svg/iframe) y emite un subconjunto de
Markdown: títulos, párrafos, listas anidadas, citas, código con fence, tablas GFM, enlaces con
URL absoluta, énfasis. Las imágenes salen como enlace de texto `[imagen: alt](url)`: el visor
del Teatro no carga recursos externos.
"""

from __future__ import annotations

import re
from html.parser import HTMLParser
from urllib.parse import urljoin

SKIP = {"script", "style", "noscript", "nav", "header", "footer", "aside", "form", "svg",
        "iframe", "button", "select", "template", "dialog"}
BLOCK = {"p", "div", "section", "article", "main", "figure", "figcaption", "details", "summary",
         "address", "dl", "dt", "dd"}
HEADINGS = {f"h{i}": i for i in range(1, 7)}
VOID = {"br", "hr", "img", "input", "meta", "link", "source", "wbr", "col", "area", "base"}


class _Node:
    __slots__ = ("tag", "attrs", "children", "parent")

    def __init__(self, tag, attrs=None, parent=None):
        self.tag, self.attrs, self.children, self.parent = tag, dict(attrs or {}), [], parent


class _Tree(HTMLParser):
    def __init__(self):
        super().__init__(convert_charrefs=True)
        self.root = _Node("root")
        self.cur = self.root
        self.title = ""
        self._in_title = False

    def handle_starttag(self, tag, attrs):
        if tag == "title":
            self._in_title = True
        node = _Node(tag, attrs, self.cur)
        self.cur.children.append(node)
        if tag not in VOID:
            self.cur = node

    def handle_startendtag(self, tag, attrs):
        self.cur.children.append(_Node(tag, attrs, self.cur))

    def handle_endtag(self, tag):
        if tag == "title":
            self._in_title = False
        node = self.cur
        while node is not self.root and node.tag != tag:
            node = node.parent
        if node is not self.root:
            self.cur = node.parent

    def handle_data(self, data):
        if self._in_title:
            self.title += data
        self.cur.children.append(data)


def _find(node, pred):
    if isinstance(node, str):
        return None
    if pred(node):
        return node
    for child in node.children:
        hit = _find(child, pred)
        if hit is not None:
            return hit
    return None


def _has_class(node, name):
    return name in (node.attrs.get("class") or "").split()


class _Emitter:
    def __init__(self, base_url: str):
        self.base = base_url
        self.out: list[str] = []

    def text_of(self, node) -> str:
        if isinstance(node, str):
            return node
        if node.tag in SKIP:
            return ""
        return "".join(self.text_of(c) for c in node.children)

    def inline(self, node) -> str:
        if isinstance(node, str):
            return re.sub(r"\s+", " ", node)
        tag = node.tag
        if tag in SKIP:
            return ""
        if tag == "br":
            return "  \n"
        if tag == "img":
            src = node.attrs.get("src") or node.attrs.get("data-src") or ""
            alt = (node.attrs.get("alt") or "").strip() or "sin descripción"
            return f"[imagen: {alt}]({urljoin(self.base, src)})" if src else ""
        body = "".join(self.inline(c) for c in node.children)
        if tag == "a":
            href = node.attrs.get("href") or ""
            label = body.strip()
            if not href or href.startswith(("javascript:", "#")):
                return label
            return f"[{label or href}]({urljoin(self.base, href)})"
        if tag in ("strong", "b") and body.strip():
            return f"**{body.strip()}**"
        if tag in ("em", "i") and body.strip():
            return f"*{body.strip()}*"
        if tag == "code":
            return f"`{self.text_of(node).strip()}`"
        if tag in ("del", "s") and body.strip():
            return f"~~{body.strip()}~~"
        return body

    def block(self, node, depth=0) -> None:
        if isinstance(node, str):
            text = re.sub(r"\s+", " ", node).strip()
            if text:
                self.out.append(text)
            return
        tag = node.tag
        if tag in SKIP:
            return
        if tag in HEADINGS:
            text = self.inline(node).strip()
            if text:
                self.out.append("#" * HEADINGS[tag] + " " + text)
            return
        if tag == "pre":
            code = _find(node, lambda n: n.tag == "code") or node
            lang = ""
            for cls in (code.attrs.get("class") or "").split():
                if cls.startswith(("language-", "lang-")):
                    lang = cls.split("-", 1)[1]
            body = self.text_of(code).strip("\n")
            fence = "````" if "```" in body else "```"
            self.out.append(f"{fence}{lang}\n{body}\n{fence}")
            return
        if tag == "blockquote":
            inner = _Emitter(self.base)
            for child in node.children:
                inner.block(child)
            quoted = "\n\n".join(inner.out)
            self.out.append("\n".join("> " + line if line else ">" for line in quoted.split("\n")))
            return
        if tag in ("ul", "ol"):
            self.out.append(self.list_md(node, 0))
            return
        if tag == "table":
            table = self.table_md(node)
            if table:
                self.out.append(table)
            return
        if tag == "hr":
            self.out.append("---")
            return
        if tag == "p" or (tag in BLOCK and not any(
                not isinstance(c, str) and (c.tag in BLOCK or c.tag in HEADINGS or c.tag in
                                            ("ul", "ol", "pre", "table", "blockquote", "hr"))
                for c in node.children)):
            text = self.inline(node).strip()
            if text:
                self.out.append(text)
            return
        for child in node.children:
            self.block(child, depth)

    def list_md(self, node, depth) -> str:
        lines, index = [], 1
        for child in node.children:
            if isinstance(child, str) or child.tag != "li":
                continue
            marker = f"{index}." if node.tag == "ol" else "-"
            index += 1
            head_parts, nested = [], []
            for sub in child.children:
                if not isinstance(sub, str) and sub.tag in ("ul", "ol"):
                    nested.append(self.list_md(sub, depth + 1))
                else:
                    head_parts.append(self.inline(sub))
            head = re.sub(r"\s+", " ", "".join(head_parts)).strip()
            lines.append("  " * depth + f"{marker} {head}")
            lines.extend(n for n in nested if n)
        return "\n".join(lines)

    def table_md(self, node) -> str:
        rows = []

        def walk(n):
            if isinstance(n, str):
                return
            if n.tag == "tr":
                cells = [re.sub(r"\s+", " ", self.inline(c)).strip().replace("|", "\\|")
                         for c in n.children if not isinstance(c, str) and c.tag in ("td", "th")]
                if cells:
                    rows.append(cells)
                return
            for child in n.children:
                walk(child)

        walk(node)
        if not rows:
            return ""
        width = max(len(r) for r in rows)
        rows = [r + [""] * (width - len(r)) for r in rows]
        lines = ["| " + " | ".join(rows[0]) + " |", "| " + " | ".join(["---"] * width) + " |"]
        lines += ["| " + " | ".join(r) + " |" for r in rows[1:]]
        return "\n".join(lines)


def convert(html_text: str, base_url: str = "") -> tuple[str, str]:
    """→ (título, markdown)."""
    tree = _Tree()
    tree.feed(html_text)
    tree.close()
    root = (
        _find(tree.root, lambda n: _has_class(n, "vp-doc"))
        or _find(tree.root, lambda n: n.tag == "main")
        or _find(tree.root, lambda n: n.tag == "article")
        or _find(tree.root, lambda n: n.tag == "body")
        or tree.root
    )
    emitter = _Emitter(base_url)
    emitter.block(root)
    markdown = "\n\n".join(part for part in emitter.out if part.strip())
    markdown = re.sub(r"\n{3,}", "\n\n", markdown).strip() + "\n"
    title = re.sub(r"\s+", " ", tree.title).strip()
    if not title:
        h1 = _find(root, lambda n: n.tag == "h1")
        title = re.sub(r"\s+", " ", emitter.text_of(h1)).strip() if h1 else ""
    return title, markdown
