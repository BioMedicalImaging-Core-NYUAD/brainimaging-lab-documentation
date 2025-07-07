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



