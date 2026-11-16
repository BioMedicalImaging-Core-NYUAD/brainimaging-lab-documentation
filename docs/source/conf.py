# Configuration file for the Sphinx documentation builder.
#
# This file only contains a selection of the most common options. For a full
# list see the documentation:
# https://www.sphinx-doc.org/en/master/usage/configuration.html

# -- Path setup --------------------------------------------------------------

# If extensions (or modules to document with autodoc) are in another directory,
# add these directories to sys.path here. If the directory is relative to the
# documentation root, use os.path.abspath to make it absolute, like shown here.
#
import os
# import sys
# sys.path.insert(0, os.path.abspath('.'))


# -- Project information -----------------------------------------------------

project = "NYUAD MRI Lab Documentation"
copyright = "2022, Haidee Paterson, Hadi Zaatiti, Osama Abdullah"
author = "Haidee Paterson, Hadi Zaatiti, Osama Abdullah"




PDF_GENERATION_INDEX = os.getenv('PDF_GENERATION_INDEX', 'ALL_WEBSITE')

master_doc = 'index'

print('Global variable', PDF_GENERATION_INDEX)

if PDF_GENERATION_INDEX == 'ALL_WEBSITE':
    master_doc = 'index'
elif PDF_GENERATION_INDEX == 'EEG_FMRI_MANUAL':
    master_doc = 'index_eeg_fmri'


# -- Experiment pages kept next to the experiment code -----------------------
# An experiment is documented by a README.rst in its own folder, e.g.
#   experiments/FMRI/NJM/README.rst
# GitHub shows that file when the folder is browsed. For the website, the
# function below copies every such file into the experiments gallery
#   5-mri-experiments-gallery/experiments/<fmri|eeg-fmri>/exp-<name>.rst
# each time the documentation is built (locally and on Read the Docs), so the
# gallery's existing "experiments/fmri/*" glob picks it up. Nothing has to be
# added under docs/ by hand, and the copies are ignored by git.
#
# In the README.rst, write paths of images and included files relative to the
# experiment folder (".. figure:: screens/phase2_offer.png"). They are
# rewritten in the copy so that they still point at the experiment folder.
import re
import pathlib

EXPERIMENT_DOC_NAME = "README.rst"
# Experiments whose page is still hand-written under docs/: listed here so they
# do not appear twice. To move one over, delete its page under docs/ and its line here.
EXPERIMENT_DOCS_SKIP = {
    "EEG-FMRI/finger-tapping",
}
EXPERIMENT_DOC_PREFIX = "exp-"


def collect_experiment_docs():
    source_dir = pathlib.Path(__file__).resolve().parent
    repo_dir = source_dir.parents[1]
    experiments_dir = repo_dir / "experiments"
    gallery_dir = source_dir / "5-mri-experiments-gallery" / "experiments"

    # directives whose argument is a file, and the ":file:" option of csv-table / raw
    directive = re.compile(r"^(\s*\.\.\s+(?:\|[^|]+\|\s+)?(?:image|figure|literalinclude|include)::\s*)(\S+)\s*$")
    file_option = re.compile(r"^(\s*:file:\s*)(\S+)\s*$")

    wanted = {}
    for readme in sorted(experiments_dir.rglob(EXPERIMENT_DOC_NAME)):
        parts = readme.parent.relative_to(experiments_dir).parts
        if len(parts) < 2 or "/".join(parts) in EXPERIMENT_DOCS_SKIP:
            continue
        target_dir = gallery_dir / parts[0].lower()            # FMRI -> fmri, EEG-FMRI -> eeg-fmri
        if not target_dir.is_dir():
            print("experiment docs: no gallery folder for", readme)
            continue

        def repoint(match, folder=readme.parent):
            path = match.group(2)
            if path.startswith("/") or "://" in path:
                return match.group(0)
            # "/..." is read by Sphinx as relative to the source directory
            return match.group(1) + "/" + pathlib.Path(os.path.relpath(folder / path, source_dir)).as_posix()

        lines = []
        for line in readme.read_text(encoding="utf-8").splitlines():
            line = directive.sub(repoint, line)
            line = file_option.sub(repoint, line)
            lines.append(line)
        origin = readme.relative_to(repo_dir).as_posix()
        text = (".. GENERATED FILE - do not edit. Source: %s (copied by docs/source/conf.py)\n\n" % origin
                + "\n".join(lines)
                + "\n\nCode and files of this experiment: :github-file:`%s/`\n" % readme.parent.relative_to(repo_dir).as_posix())
        wanted[target_dir / (EXPERIMENT_DOC_PREFIX + "-".join(parts[1:]) + ".rst")] = text    # exp-NJM.rst, exp-qc-bh.rst

    # remove copies whose README.rst is gone, write the others only when they changed
    for old in gallery_dir.glob("*/%s*.rst" % EXPERIMENT_DOC_PREFIX):
        if old not in wanted:
            old.unlink()
    for path, text in wanted.items():
        if not path.exists() or path.read_text(encoding="utf-8") != text:
            path.write_text(text, encoding="utf-8")
    print("experiment docs collected:", ", ".join(sorted(p.name for p in wanted)) or "none")


collect_experiment_docs()


# -- General configuration ---------------------------------------------------
# -- General configuration

extensions = [
    "sphinx.ext.duration",
    "sphinx.ext.doctest",
    "sphinx.ext.autodoc",
    "sphinx.ext.autosummary",
    "sphinx.ext.intersphinx",
    "sphinx.ext.napoleon",
    "sphinx.ext.mathjax",
    "nbsphinx",
    "sphinxcontrib.mermaid",
    "sphinx_rtd_theme",
    "sphinx_togglebutton",
    "sphinx_panels",
]

intersphinx_mapping = {
    "rtd": ("https://docs.readthedocs.io/en/stable/", None),
    "python": ("https://docs.python.org/3/", None),
    "sphinx": ("https://www.sphinx-doc.org/en/master/", None),
}
intersphinx_disabled_domains = ["std"]

templates_path = ["_templates"]

# -- Options for EPUB output
epub_show_urls = "footnote"

html_static_path = ['_static']
html_favicon = "_static/mri.png"

html_css_files = [
    "custom.css",
    "https://cdnjs.cloudflare.com/ajax/libs/font-awesome/5.15.4/css/all.min.css",
]


html_theme_options = {
    "logo_only": False,
    "prev_next_buttons_location": "bottom",
    "style_external_links": False,
    "vcs_pageview_mode": "",
    "style_nav_header_background": "#561A70",
    "collapse_navigation": True,
    "sticky_navigation": True,
    "navigation_depth": 4,
    "includehidden": True,
    "titles_only": False,
}

# List of patterns, relative to source directory, that match files and
# directories to ignore when looking for source files.
# This pattern also affects html_static_path and html_extra_path.
exclude_patterns = ["_build", "Thumbs.db", ".DS_Store"]

# -- Options for HTML output -------------------------------------------------

# The theme to use for HTML and HTML Help pages.  See the documentation for
# a list of builtin themes.
#
html_theme = "sphinx_rtd_theme"

html_logo = "graphic/NYU_Logo.png"

# Add any paths that contain custom static files (such as style sheets) here,
# relative to this directory. They are copied after the builtin static files,
# so a file named "default.css" will overwrite the builtin "default.css".




# -- Math options ---------------------------------------------------------
mathjax_path = 'https://cdn.jsdelivr.net/npm/mathjax@3/es5/tex-mml-chtml.js'



from docutils import nodes
from docutils.parsers.rst import roles

# -- tweak these to match your repo/branch docs layout --
GITHUB_USER   = "BioMedicalImaging-Core-NYUAD"
GITHUB_REPO   = "brainimaging-lab-documentation"
GITHUB_BRANCH = "main"



def github_file_role(role, rawtext, text, lineno, inliner, options=None, content=None):
    # determine if it's a directory
    is_dir = text.endswith("/")
    kind   = "tree" if is_dir else "blob"
    relpath = text.rstrip("/")    # strip slash for URL parts

    # always build from repo root—no DOCS_DIR at all
    parts = [GITHUB_USER, GITHUB_REPO, kind, GITHUB_BRANCH] + relpath.split("/")
    url   = "https://github.com/" + "/".join(parts)
    display = relpath + ("/" if is_dir else "")

    html = (
        f'<a class="github-link" href="{url}" target="_blank">'
        '<i class="fab fa-github"></i> '
        f'{display}</a>'
    )
    return [nodes.raw("", html, format="html")], []

# register the role
roles.register_local_role("github-file", github_file_role)







from docutils import nodes
from docutils.parsers.rst import roles

# -- tweak these to match your repo/branch docs layout --
GITHUB_USER   = "BioMedicalImaging-Core-NYUAD"
GITHUB_REPO   = "brainimaging-lab-documentation"
GITHUB_BRANCH = "main"


def github_file_role(role, rawtext, text, lineno, inliner, options=None, content=None):
    import re
    from docutils.utils import unescape

    options = options or {}

    # Check for custom link text using the format: Custom Text <path/to/file>
    match = re.match(r'(.+?)\s*<(.+)>', text)
    if match:
        display_text = match.group(1).strip()
        relpath = match.group(2).strip()
    else:
        relpath = text.strip()
        display_text = relpath

    is_dir = relpath.endswith("/")
    kind = "tree" if is_dir else "blob"
    relpath_clean = relpath.rstrip("/")  # remove trailing slash for URL

    url = f"https://github.com/{GITHUB_USER}/{GITHUB_REPO}/{kind}/{GITHUB_BRANCH}/{relpath_clean}"

    html = (
        f'<a class="github-link" href="{url}" target="_blank">'
        f'<i class="fab fa-github"></i> {unescape(display_text)}</a>'
    )
    return [nodes.raw("", html, format="html")], []


# register the role
roles.register_local_role("github-file", github_file_role)