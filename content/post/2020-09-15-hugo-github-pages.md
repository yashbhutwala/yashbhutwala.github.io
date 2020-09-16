---
title: "Deploy your own blog for free using Hugo + GitHub Pages + GitHub Action" # Title of the blog post.
date: 2020-09-14T12:28:50-03:00 # Date of post creation.
description: "notes about deploying your own blog for free using Hugo + GitHub Pages + GitHub Action" # Description used for search engine.
featured: false # Sets if post is a featured post, making appear on the home page side bar.
draft: false # Sets whether to render this page. Draft of true will not be rendered.
toc: false # Controls if a table of contents should be generated for first-level links automatically.
# menu: main
#featureImage: "/images/path/file.jpg" # Sets featured image on blog post.
#thumbnail: "/images/path/thumbnail.png" # Sets thumbnail image appearing inside card on homepage.
#shareImage: "/images/path/share.png" # Designate a separate image for social media sharing.
codeMaxLines: 10 # Override global value for how many lines within a code block before auto-collapsing.
codeLineNumbers: true # Override global value for showing of line numbers within code block.
figurePositionShow: true # Override global value for showing the figure label.
categories:
  - Technology
tags:
  - Hugo
  - GitHub Pages
  - GitHub Action
---

<!-- omit in toc -->
## Table of Contents

- [Immediately useful links](#immediately-useful-links)
- [Background links](#background-links)

Source code for this blog lives on `master` branch [here](https://github.com/yashbhutwala/yashbhutwala.github.io).  The actual assets for the website live on the `gh-pages` branch [here](https://github.com/yashbhutwala/yashbhutwala.github.io/tree/gh-pages) and is posted automatically via the GitHub Action [here](https://github.com/yashbhutwala/yashbhutwala.github.io/actions?query=workflow%3Apublish-github-pages).

## Immediately useful links

- [hugo-clarity theme](https://themes.gohugo.io/hugo-clarity/)
  - [hugo-clarity github repo](https://github.com/chipzoller/hugo-clarity)
- [GitHub Action for setting up Hugo](https://github.com/peaceiris/actions-hugo)
  - [make sure to do "Hugo extended version"](https://github.com/peaceiris/actions-hugo#%EF%B8%8F-use-hugo-extended)
- [GitHub Action for deploying to GitHub Pages](https://github.com/peaceiris/actions-gh-pages)
  - [make sure to enable manual deployments to enable debugging](https://github.com/peaceiris/actions-gh-pages#%EF%B8%8F-schedule-and-manual-deployment)
  - [make sure to point to `gh-pages` branch in repo settings for GitHub Pages](https://github.com/peaceiris/actions-gh-pages#%EF%B8%8F-first-deployment-with-github_token)

## Background links

- [GitHub docs about creating GitHub Pages](https://docs.github.com/en/github/working-with-github-pages/creating-a-github-pages-site)
- [Hugo Themes](https://themes.gohugo.io/)
- [Hugo Quick Start Docs](https://gohugo.io/getting-started/quick-start/)
