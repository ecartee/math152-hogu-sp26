# MATH 152 — Hands-On, Grades Up (Spring 2026)

Supplemental worksheets for the **Hands-On, Grades Up** (HOGU) program in MATH 152 at Texas A&M University, offered through the [Math Learning Center](https://mlc.tamu.edu/).

## Viewing the worksheets

Each worksheet is an accessible HTML page. To get a printable version, use the print button built into the page.

**[Browse all worksheets →](https://ecartee.github.io/math152-hogu-sp26/)**

- [Session #1: The Substitution Rule &amp; Area Between Curves &mdash; Sections 5.5 &amp; 6.1](https://ecartee.github.io/math152-hogu-sp26/session1/)
- [Session #2: Area Between Curves &amp; Volumes &mdash; Sections 6.1 &amp; 6.2](https://ecartee.github.io/math152-hogu-sp26/session2/)
- [Session #3: Volumes, Cylindrical Shells &amp; Work &mdash; Sections 6.2, 6.3 &amp; 6.4](https://ecartee.github.io/math152-hogu-sp26/session3/)
- [Session #4: Exam 1 Review &mdash; Sections 5.5&ndash;7.2](https://ecartee.github.io/math152-hogu-sp26/session4/)
- [Session #5: Trig Substitution, Partial Fractions &amp; Improper Integrals &mdash; Sections 7.3, 7.4 &amp; 7.8](https://ecartee.github.io/math152-hogu-sp26/session5/)
- [Session #6: Sequences &amp; Series &mdash; Sections 11.1 &amp; 11.2](https://ecartee.github.io/math152-hogu-sp26/session6/)
- [Session #7: Exam 2 Review &mdash; Sections 7.3&ndash;11.3](https://ecartee.github.io/math152-hogu-sp26/session7/)
- [Session #8: Comparison, Alternating Series, Ratio &amp; Root Tests &mdash; Sections 11.4, 11.5 &amp; 11.6](https://ecartee.github.io/math152-hogu-sp26/session8/)
- [Session #9: Power Series &mdash; Sections 11.8 &amp; 11.9](https://ecartee.github.io/math152-hogu-sp26/session9/)
- [Session #10: Exam 3 Review &mdash; Sections 11.4&ndash;11.11](https://ecartee.github.io/math152-hogu-sp26/session10/)
- [Session #11: Final Exam Review Part 1 &mdash; Chapters 6 &amp; 7](https://ecartee.github.io/math152-hogu-sp26/session11/)
- [Session #12: Final Exam Review Part 2 &mdash; Chapters 10 &amp; 11](https://ecartee.github.io/math152-hogu-sp26/session12/)


## Building locally

This project uses [PreTeXt](https://pretextbook.org). Each worksheet is its own target, named `sessionN`:

```bash
pretext build session1        # writes output/session1/
pretext view session1         # build and serve with live reload
```

To install the PreTeXt CLI:
```bash
python -m venv .venv/pretext
source .venv/pretext/bin/activate
pip install pretext
```

## Checking a worksheet

```bash
tools/audit.sh session1       # omit the argument to check every session
```

Reports any page whose content overflows the printed page, any image missing alt text, serif text in print preview, and image ink below WCAG contrast. Exits non-zero on failure.

## Deploying

```bash
./deploy.sh
```

Builds every target listed in `project.ptx` and publishes to GitHub Pages: the landing page (`site/index.html`) at the site root, each worksheet at `/sessionN/`. To review the whole site without publishing, run `pretext deploy --stage-only` and serve `output/stage/`.

## Source

Worksheet source files are in `source/` and written in [PreTeXt XML](https://pretextbook.org/documentation.html); shared images and CSS overrides are in `assets/`.
