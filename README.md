# MATH 152 — Hands-On, Grades Up (Spring 2026)

Supplemental worksheets for the **Hands-On, Grades Up** (HOGU) program in MATH 152 at Texas A&M University, offered through the [Math Learning Center](https://mlc.tamu.edu/).

## Viewing the worksheets

Worksheets are published at:
**https://ecartee.github.io/math152-hogu-sp26/**

Each worksheet is an accessible HTML page. To get a printable version, use the print button built into the page.

## Building locally

This project uses [PreTeXt](https://pretextbook.org). With the PreTeXt CLI installed:

```bash
pretext build web2
```

Output is written to `output/web2/`.

To install the PreTeXt CLI:
```bash
python -m venv .venv/pretext
source .venv/pretext/bin/activate
pip install pretext
```

## Deploying

```bash
pretext deploy
```

This publishes the `web2` target to GitHub Pages.

## Source

Worksheet source files are in `source/` and written in [PreTeXt XML](https://pretextbook.org/documentation.html).
