# Portfolio Book Scaffold

This folder is a **starter Quarto book**, the end objective of the
*Reproducible Workflows* course. You copy it into your own workspace, make it
yours, and it grows into your personal data science portfolio over the
semester.

```
portfolio-book/
├── _quarto.yml      # book config: title, chapters, output format
├── _brand.yml       # YOUR brand: colours + fonts (edit → restyle)
├── styles.scss      # optional structural CSS for deeper tweaks
├── index.qmd        # the book's home page
├── README.md        # this file
├── references.qmd   # bibliography page
├── references.bib   # your citations
└── chapters/
    ├── 01-EDA.qmd        # YOUR EDA project (fill in at Session 2)
    ├── 02-semester-2.qmd # placeholder: a later course fills this in
    └── 03-semester-3.qmd # placeholder: a later course fills this in
```

## What is a Quarto book?

A Quarto *book* is a set of `.qmd` documents (one per chapter) bundled by a
single `_quarto.yml` configuration file into a coherent publication with
navigation, a table of contents and cross-references. You already know the
pieces from building single Quarto documents; a book is just many of them
wired together.

## Getting started

1. **Copy the scaffold** into your own workspace (don't edit it in place;
   keep the original pristine so you can re-copy it):
   ```bash
   cp -r reproducible-workflows/common/portfolio-book ~/my-portfolio
   ```
2. **Render it** to check everything works before you touch the content:
   ```bash
   cd ~/my-portfolio && quarto preview
   ```
   or click *Preview* in Positron. You should see a working book with a
   welcome page, a placeholder EDA chapter and an empty bibliography.
3. **Make it yours**: edit `index.qmd` (your name, your description) and
   `_quarto.yml` (the `author` field).

## Making it look like yours

The book's look is *yours to define*: it's your portfolio, not the course's.
Two files beside `_quarto.yml` give you two levels of control:

- **`_brand.yml`**: colours and fonts. Open it, change a few `"#hex"` values,
  re-render, and the whole book restyles. This is the zero-CSS on-ramp: edit,
  preview, iterate.
- **`styles.scss`**: structural CSS for anything `_brand.yml` can't do
  (spacing, layout, custom touches). It's commented so it's inert until you
  uncomment. Right-click → *Inspect* on any element to find the selector to
  target.

Workflow: change a value → `quarto preview` → look. Don't try to match the
course decks; find what *you* like.

## Building the book

The book is compiled from source on every render; nothing is hand-edited.
When you change a chapter or the data it uses, re-render:

```bash
quarto render            # build the whole book
quarto render 01-EDA.qmd  # render just one chapter while you work
```

## The reproducibility pipeline

This book is not just content; it is the vehicle for everything the course
teaches about reproducible research. Each week it gains one more layer:

1. **Session 1**: you write your first Quarto documents; the book is where
   they will live.
2. **Session 2**: you fill Chapter 1 with a dataset you source **by code from
   an open-data portal of your choice** (data.gouv.fr via `{rdatagouv}`, or
   your own country's portal via `download.file()`), optionally pinned with
   `{pins}`, run an exploratory data analysis, and **version the book with
   git** (`usethis::use_git()` + `use_github()`, commit/push, a branch).
3. **Session 3**: you deepen git (pull requests, review), pin the R version
   and environment with **uvr/uv**, and publish the book to a URL on
   **Posit Connect**.

Later courses slot their work into the placeholder chapters, so by semester's
end you have a versioned, pinned, published portfolio.

### Between sessions (gap week)

With the book on GitHub you can keep advancing Chapter 1 and stay in touch
with your instructor between sessions:

```bash
git checkout -b eda-chapter-1   # branch per idea; never work on main
git add chapters/01-EDA.qmd && git commit -m "refine cleaning decisions"
git push -u origin eda-chapter-1
```

Push the branch and open a (draft) pull request when you'd like feedback; the
instructor can comment on it there, and you update it by committing and
pushing again.

## Language-agnostic by design

The first chapter uses R, but Quarto books work equally well with Python (or
R and Python chapters side by side). Your portfolio is built to grow across
languages; what makes it reproducible is the pipeline (reproducible data
sourcing, source-driven rendering, pinned dependencies, version control),
none of which cares which language your code is in.
