# ftl — 400+ Command-Line Utilities for Integration

> **Subject:** A categorized reference of 400+ command-line utilities
> that could be useful for ftl — as preview backends, filter
> backends, command dispatchers, or general workflow integrations.
> **Purpose:** Provide a lookup table for plugin authors and ftl
> maintainers seeking to integrate existing tools rather than
> reimplement functionality.
> **Sources:** Web research (awesome-cli-apps, awesome-tuis,
> modern-unix, terminal-trove, structured-text-tools, and community
> recommendations), supplemented with ftl's existing dependencies.
> **Format:** Categorized tables. Each entry: name, language,
> description, and potential ftl integration.

---

## Table of Contents

1. [Modern Core Utilities (Rust/Go rewrites)](#1-modern-core-utilities)
2. [Classic Core Utilities](#2-classic-core-utilities)
3. [File Discovery and Search](#3-file-discovery-and-search)
4. [Text Processing and Manipulation](#4-text-processing-and-manipulation)
5. [Structured Data (JSON/YAML/CSV/TOML)](#5-structured-data)
6. [File Managers and Browsers](#6-file-managers-and-browsers)
7. [Terminal UI (TUI) Tools](#7-terminal-ui-tools)
8. [Version Control (Git and Alternatives)](#8-version-control)
9. [Image and Video Processing](#9-image-and-video-processing)
10. [Audio and Media](#10-audio-and-media)
11. [Document Processing and Preview](#11-document-processing-and-preview)
12. [Archive and Compression](#12-archive-and-compression)
13. [Network and HTTP](#13-network-and-http)
14. [Security and Cryptography](#14-security-and-cryptography)
15. [System Monitoring and Process Management](#15-system-monitoring)
16. [Disk Usage and Storage](#16-disk-usage-and-storage)
17. [Terminal Multiplexers and Shells](#17-terminal-multiplexers)
18. [Shell Enhancements and Prompts](#18-shell-enhancements)
19. [Development and Build Tools](#19-development-and-build-tools)
20. [Container and Orchestration](#20-container-and-orchestration)
21. [Database Clients](#21-database-clients)
22. [Cloud and Remote Storage](#22-cloud-and-remote-storage)
23. [Documentation and Publishing](#23-documentation-and-publishing)
24. [Productivity and Notes](#24-productivity-and-notes)
25. [System Administration](#25-system-administration)
26. [Fun and Aesthetics](#26-fun-and-aesthetics)

---

## 1. Modern Core Utilities

Modern rewrites of classic Unix tools, typically in Rust or Go, offering better performance, colors, and defaults.

| Tool | Lang | Replaces | Description | ftl integration |
|------|------|----------|-------------|-----------------|
| `bat` | Rust | `cat` | `cat` with syntax highlighting and Git integration | Text preview backend |
| `fd` | Rust | `find` | Fast, user-friendly file finder | Fuzzy find, scan backend |
| `ripgrep` (`rg`) | Rust | `grep` | Fast recursive search respecting .gitignore | Content search, select-by-content |
| `eza` | Rust | `ls` | `ls` with colors, icons, Git status (fork of `exa`) | Directory preview |
| `exa` | Rust | `ls` | `ls` with colors and icons (unmaintained, use `eza`) | Directory preview |
| `delta` | Rust | `diff` | Syntax-highlighted pager for git diff | Diff preview |
| `dust` | Rust | `du` | Visual disk usage with tree view | Size display, disk analysis |
| `dua` | Rust | `du` | Interactive disk usage with fast traversal | Disk analysis |
| `procs` | Rust | `ps` | Modern process viewer with colors | Process viewer plugin |
| `bottom` (`btm`) | Rust | `top`/`htop` | System monitor with customizable widgets | System monitoring |
| `btop` | C++ | `top`/`htop` | Resource monitor with rich UI | System monitoring |
| `sd` | Rust | `sed` | Intuitive find-and-replace | Batch rename, refactoring |
| `hyperfine` | Rust | `time` | Statistical benchmarking | Performance testing |
| `tokei` | Rust | `cloc` | Fast lines-of-code counter | Code statistics |
| `xh` | Rust | `httpie` | Fast HTTP client | API testing |
| `teip` | Rust | — | Select partial lines for command pipelining | Text processing |
| `watchexec` | Rust | `watch` | File watcher and command runner | Hot-reload, auto-build |
| `gitui` | Rust | — | TUI for Git | Git integration |
| `grex` | Rust | — | Regex generator from examples | Regex generation |
| `fselect` | Rust | `find` | File search with SQL-like syntax | Advanced file search |
| `jless` | Rust | — | JSON viewer and explorer | JSON preview |
| `skim` | Rust | `fzf` | Fuzzy finder (alternative to fzf) | Fuzzy search |
| `tact` | Rust | — | JSON tree viewer | JSON preview |
| `vivid` | Rust | — | LS_COLORS generator | Color configuration |
| `cargo-binstall` | Rust | — | Install Rust binaries from releases | Tool installation |
| `rustscan` | Rust | `nmap` | Fast port scanner | Network scanning |
| `bandwhich` | Rust | — | Network bandwidth monitor by process | Network monitoring |
| `gping` | Rust | `ping` | Ping with a graph | Network diagnostics |
| `dog` | Rust | `dig` | DNS lookup tool | DNS diagnostics |
| `ouch` | Rust | `tar`/`zip` | Unified compression/decompression | Archive operations |
| `zoxide` | Rust | `cd` | Smarter directory jumping (frecency) | Directory navigation |
| `navi` | Rust | — | Interactive cheatsheet tool | Command reference |
| `delayacat` | Rust | `cat` | `cat` with configurable delay | Demo/recording |

---

## 2. Classic Core Utilities

The GNU coreutils and findutils that ftl already depends on.

| Tool | Package | Description | ftl integration |
|------|---------|-------------|-----------------|
| `cat` | coreutils | Concatenate files | Text preview |
| `cp` | coreutils | Copy files | File copy |
| `mv` | coreutils | Move/rename files | File move/rename |
| `rm` | coreutils | Remove files | File delete |
| `ls` | coreutils | List directory contents | Listing |
| `ln` | coreutils | Create links | Symlink/hardlink |
| `chmod` | coreutils | Change file modes | Permission management |
| `chown` | coreutils | Change file ownership | Permission management |
| `touch` | coreutils | Change timestamps | File creation, timestamp update |
| `mkdir` | coreutils | Create directories | Directory creation |
| `rmdir` | coreutils | Remove directories | Directory delete |
| `stat` | coreutils | File status | Size, mtime, permissions |
| `wc` | coreutils | Word/line/byte count | Line count etag |
| `head` | coreutils | First lines of file | Preview |
| `tail` | coreutils | Last lines of file | Preview, live tail |
| `cut` | coreutils | Extract fields | Text processing |
| `paste` | coreutils | Merge lines | Text processing |
| `sort` | coreutils | Sort lines | Listing sort |
| `uniq` | coreutils | Remove duplicates | Dedup |
| `tr` | coreutils | Translate characters | Text processing |
| `tee` | coreutils | Pipe to file and stdout | Pipeline |
| `xargs` | findutils | Build and execute commands | Batch operations |
| `find` | findutils | Search for files | Listing scan |
| `locate` | findutils | Find files by name (indexed) | Fast file search |
| `grep` | grep | Text search | Content search |
| `sed` | sed | Stream editor | Batch rename, text transform |
| `awk` | gawk | Text processing language | Data extraction |
| `perl` | perl | Scripting language | Binary detection, text processing |
| `file` | file | Detect file type | MIME type detection |
| `dd` | coreutils | Copy/convert files | Disk operations |
| `df` | coreutils | Disk free space | Disk status |
| `du` | coreutils | Disk usage | Size display |
| `sha256sum` | coreutils | SHA256 checksum | Checksum verification |
| `md5sum` | coreutils | MD5 checksum | Checksum |
| `sha1sum` | coreutils | SHA1 checksum | Checksum |
| `base64` | coreutils | Base64 encode/decode | Encoding |
| `date` | coreutils | Date/time | Timestamps |
| `sleep` | coreutils | Delay | Timing |
| `watch` | procps | Run command periodically | Monitoring |
| `timeout` | coreutils | Run with time limit | Timeout for operations |
| `install` | coreutils | Copy with permissions | Installation |
| `split` | coreutils | Split files | File splitting |
| `csplit` | coreutils | Split by context | File splitting |
| `expand` | coreutils | Tabs to spaces | Text processing |
| `unexpand` | coreutils | Spaces to tabs | Text processing |
| `fold` | coreutils | Wrap lines | Text processing |
| `fmt` | coreutils | Reformat paragraphs | Text processing |
| `nl` | coreutils | Number lines | Text processing |
| `pr` | coreutils | Paginate for printing | Text processing |
| `tac` | coreutils | Reverse cat | Text processing |
| `rev` | util-linux | Reverse lines | Text processing |
| `seq` | coreutils | Print sequence | Number generation |
| `shuf` | coreutils | Random shuffle | Random selection |
| `yes` | coreutils | Repeat string | Automation |
| `env` | coreutils | Environment | Process environment |
| `printenv` | coreutils | Print environment | Environment display |
| `hostname` | coreutils | Host name | System info |
| `uname` | coreutils | System info | System info |
| `whoami` | coreutils | Current user | User info |
| `id` | coreutils | User/group IDs | Permission info |
| `groups` | coreutils | User groups | Permission info |

---

## 3. File Discovery and Search

Tools for finding files by name, content, or metadata.

| Tool | Lang | Description | ftl integration |
|------|------|-------------|-----------------|
| `fd` | Rust | Fast, user-friendly find | Scan backend, fuzzy find |
| `ripgrep` (`rg`) | Rust | Fast content search | Content search, select-by-content |
| `fzf` | Go | Fuzzy finder | Fuzzy search, command palette |
| `skim` | Rust | Fuzzy finder (fzf alternative) | Fuzzy search |
| `fselect` | Rust | SQL-like file search | Advanced search |
| `locate` | C | Indexed file search | Fast name search |
| `plocate` | C | Faster locate | Fast name search |
| `mlocate` | C | Indexed locate (security-aware) | Fast name search |
| `find` | C | Classic file finder | Listing scan |
| `ack` | Perl | grep for programmers | Content search |
| `ag` (silver searcher) | C | Fast grep alternative | Content search |
| `sift` | Go | Fast grep alternative | Content search |
| `git-grep` | — | Grep tracked files | Git-aware search |
| `beagrep` | — | Grep with context | Content search |
| `pick` | C | Fuzzy picker (fzf predecessor) | Selection |
| `fzy` | C | Fast fuzzy finder | Fuzzy search |
| `peco` | Go | Simplistic fuzzy finder | Fuzzy search |
| `fpp` (PathPicker) | Python | Pick paths from command output | Path selection |
| `tree` | C | Directory tree viewer | Tree view |
| `tre` | Rust | Tree viewer with fzf integration | Tree view |
| `broot` | Rust | Tree-based file manager | Navigation |
| `joshuto` | Rust | Ranger-like file manager | Reference |
| `walk` | Go | Simple terminal file manager | Reference |
| `fff` | Bash | Minimal file manager | Reference |

---

## 4. Text Processing and Manipulation

Tools for transforming, filtering, and formatting text.

| Tool | Lang | Description | ftl integration |
|------|------|-------------|-----------------|
| `sed` | C | Stream editor | Batch rename |
| `awk` / `gawk` | C | Text processing language | Data extraction |
| `perl` | C | Scripting language | Text transform |
| `jq` | C | JSON processor | JSON preview/transform |
| `yq` | Go | YAML processor | YAML preview/transform |
| `dasel` | Go | Multi-format data selector | Data extraction |
| `gron` | Go | Flatten JSON for grep | JSON search |
| `jp` | Go | JMESPath processor | JSON query |
| `ijq` | Go | Interactive jq | JSON exploration |
| `jq` + `jq` | — | JSON pipeline | Data processing |
| `csvtk` | Go | CSV toolkit | CSV processing |
| `csvcut` / `csvkit` | Python | CSV utilities | CSV processing |
| `miller` (`mlr`) | Go | CSV/TSV/JSON transformer | Data processing |
| `xsv` | Rust | Fast CSV toolkit | CSV processing |
| `tsv-utils` | D | TSV processing | Data processing |
| `textql` | Go | SQL on text files | Data query |
| `dsq` | Go | SQL on data files | Data query |
| `sq` | Go | SQL on multi-format data | Data query |
| `htmlq` | Rust | HTML selector (jq for HTML) | HTML processing |
| `pup` | Go | HTML parser | HTML processing |
| `xpath` | — | XPath query | XML processing |
| `xmlstarlet` | C | XML toolkit | XML processing |
| `xq` | Python | XML to JSON (wraps jq) | XML processing |
| `yamllint` | Python | YAML linter | YAML validation |
| `shellcheck` | Haskell | Shell script linter | Script validation |
| `shfmt` | Go | Shell script formatter | Code formatting |
| `bat` | Rust | cat with syntax highlighting | Text preview |
| `highlight` | C++ | Syntax highlighter | Text preview |
| `pygmentize` | Python | Syntax highlighter | Text preview |
| `source-highlight` | C++ | Source code highlighter | Text preview |
| `chroma` | Go | Syntax highlighter library | Text preview |
| `mdcat` | Rust | Markdown cat | Markdown preview |
| `glow` | Go | Markdown renderer | Markdown preview |
| `moar` | Go | Pager | Preview pager |
| `most` | C | Pager | Preview pager |
| `less` | C | Pager | Preview pager |
| `more` | util-linux | Pager | Preview pager |
| `delta` | Rust | Diff pager | Diff preview |
| `diff-so-fancy` | Perl | Pretty diffs | Diff preview |
| `diff` | diffutils | File diff | File comparison |
| `vimdiff` | Vim | Visual diff | File comparison |
| `wdiff` | GNU | Word diff | Text comparison |
| `dwdiff` | — | Word diff | Text comparison |
| `icdiff` | Python | Improved color diff | Diff preview |
| `colordiff` | Perl | Colorized diff | Diff preview |
| `patch` | patch | Apply patches | Patch application |
| `git-delta` | Rust | Git diff pager | Git diff preview |
| `jq` | — | (duplicate, see above) | — |
| `tpx` | — | Text processing | Text transform |
| `html2text` | C | HTML to text | HTML preview |
| `pandoc` | Haskell | Document converter | Format conversion |
| `pandoc` + `groff` | — | Man page rendering | Man page preview |
| `ronn` | Ruby | Man page authoring | Man page |
| `md2man` | Go | Markdown to man | Man page |

---

## 5. Structured Data

Tools for JSON, YAML, CSV, TOML, XML, and Parquet processing.

| Tool | Lang | Formats | Description | ftl integration |
|------|------|---------|-------------|-----------------|
| `jq` | C | JSON | JSON query/transform | JSON preview |
| `yq` | Go | YAML | YAML query/transform | YAML preview |
| `yq` (python) | Python | YAML/XML | YAML processor (kislyuk) | YAML preview |
| `xq` | Python | XML | XML to JSON via jq | XML preview |
| `dasel` | Go | JSON/YAML/TOML/XML/CSV | Multi-format selector | Data extraction |
| `gron` | Go | JSON | Flatten JSON for grep | JSON search |
| `ijq` | Go | JSON | Interactive jq | JSON exploration |
| `fx` | Go | JSON | JSON viewer (TUI) | JSON preview |
| `jless` | Rust | JSON | JSON explorer | JSON preview |
| `jp` | Go | JSON | JMESPath processor | JSON query |
| `jd` | Go | JSON | JSON diff/patch | JSON comparison |
| `jq` + `jo` | — | JSON | jo creates JSON | JSON generation |
| `jo` | C | JSON | JSON generator | JSON creation |
| `jc` | Python | — | Convert command output to JSON | Command output parsing |
| `jq` + `yq` | — | — | Pipeline | Multi-format |
| `miller` (`mlr`) | Go | CSV/TSV/JSON | Data transformer | CSV processing |
| `xsv` | Rust | CSV | Fast CSV toolkit | CSV processing |
| `csvkit` | Python | CSV | CSV utilities suite | CSV processing |
| `csvtk` | Go | CSV/TSV/JSON | CSV toolkit | CSV processing |
| `tsv-utils` | D | TSV | TSV processing | Data processing |
| `csvprintf` | C | CSV | CSV pretty printer | CSV display |
| `csv2md` | Go | CSV→Markdown | CSV to Markdown table | CSV preview |
| `parquet-tools` | Java | Parquet | Parquet utilities | Parquet preview |
| `duckdb` | C++ | CSV/Parquet/JSON | SQL on data files | Data query |
| `dsq` | Go | Multi | SQL on data files | Data query |
| `sq` | Go | Multi | SQL on data | Data query |
| `textql` | Go | CSV/TSV | SQL on text | Data query |
| `q` | Python | CSV/TSV | SQL on CSV | Data query |
| `toml-cli` | Rust | TOML | TOML query | TOML preview |
| `tomlq` | — | TOML | TOML via jq | TOML preview |
| `htmlq` | Rust | HTML | HTML selector | HTML processing |
| `pup` | Go | HTML | HTML parser | HTML processing |
| `xmllint` | C | XML | XML parser | XML validation |
| `xmlstarlet` | C | XML | XML toolkit | XML processing |
| `xpath` | — | XML | XPath query | XML query |

---

## 6. File Managers and Browsers

Terminal file managers (reference and comparison).

| Tool | Lang | Description | ftl integration |
|------|------|-------------|-----------------|
| `ranger` | Python | Vim-inspired file manager | Reference |
| `vifm` | C | Vim-like file manager | Reference |
| `lf` | Go | Ranger-like file manager | Reference |
| `nnn` (n³) | C | Minimal file manager | Reference |
| `yazi` | Rust | Async file manager | Reference |
| `broot` | Rust | Tree-based file browser | Reference |
| `mc` (Midnight Commander) | C | Dual-pane file manager | Reference |
| `clifm` | C | Shell-like file manager | Reference |
| `superfile` (spf) | Go | Modern multi-panel file manager | Reference |
| `fff` | Bash | Minimal file manager | Reference |
| `cfiles` | C | Vim-like file manager | Reference |
| `tuifi` | Go | TUI file manager | Reference |
| `jarun` | — | (see nnn) | — |
| `walk` | Go | Simple file manager | Reference |
| `joshuto` | Rust | Ranger-like | Reference |
| `cdir` | — | Directory changer | Reference |
| `zellij` | Rust | Terminal multiplexer (has file browser) | Reference |
| `lazygit` | Go | Git TUI (has file browser) | Git integration |
| `tig` | C | Git TUI | Git integration |
| `gitv` | — | Git viewer | Git integration |
| `gitk` | Tcl | Git GUI (X11) | Git integration |

---

## 7. Terminal UI (TUI) Tools

Interactive terminal applications.

| Tool | Lang | Description | ftl integration |
|------|------|-------------|-----------------|
| `fzf` | Go | Fuzzy finder | Search, palette |
| `skim` | Rust | Fuzzy finder | Search |
| `fzy` | C | Fuzzy finder | Selection |
| `peco` | Go | Fuzzy finder | Selection |
| `htop` | C | Process viewer | Process management |
| `btop` | C++ | System monitor | System monitoring |
| `bottom` (`btm`) | Rust | System monitor | System monitoring |
| `glances` | Python | System monitor | System monitoring |
| `atuin` | Rust | Shell history | History search |
| `mcfly` | Rust | Shell history | History search |
| `fzf-tab` | — | fzf for tab completion | Completion |
| `lazygit` | Go | Git TUI | Git integration |
| `lazydocker` | Go | Docker TUI | Container management |
| `k9s` | Go | Kubernetes TUI | K8s management |
| `tig` | C | Git TUI | Git integration |
| `gitui` | Rust | Git TUI | Git integration |
| `gh-dash` | Go | GitHub dashboard TUI | GitHub management |
| `termui` | Go | TUI library | Reference |
| `bubbletea` | Go | TUI framework | Reference |
| `tview` | Go | TUI framework | Reference |
| `crossterm` | Rust | Terminal library | Reference |
| `ratatui` | Rust | TUI framework | Reference |
| `chafa` | C | Image to ANSI art | Image preview fallback |
| `timg` | C | Terminal image/video viewer | Image/video preview |
| `viu` | Rust | Image viewer | Image preview |
| `kitty +kitten icat` | — | Kitty image protocol | Image preview |
| `ueberzug` | Python | Image overlay for terminals | Image preview |
| `sixel` | — | Sixel image protocol | Image preview |
| `jp2` | — | JPEG to ANSI | Image preview |
| `cacaview` | C | ASCII art image viewer | Image preview |
| `tpp` | Ruby | Text presentation program | Presentations |
| `slides` | Go | Terminal slides | Presentations |
| `presenterm` | Rust | Terminal presentations | Presentations |
| `spot` | Rust | Interactive file search | Search |
| `rtx` | Rust | Runtime manager (asdf alt) | Runtime management |
| `mise` | Rust | Runtime manager (rtx rename) | Runtime management |
| `aichat` | Rust | AI chat in terminal | AI integration |
| `gpterm` | — | GPT in terminal | AI integration |
| `tgpt` | Go | GPT in terminal | AI integration |

---

## 8. Version Control

Git and alternative version control systems.

| Tool | Lang | Description | ftl integration |
|------|------|-------------|-----------------|
| `git` | C | Distributed version control | VCS integration |
| `gh` | Go | GitHub CLI | GitHub integration |
| `glab` | Go | GitLab CLI | GitLab integration |
| `lazygit` | Go | Git TUI | Git TUI |
| `tig` | C | Git TUI | Git TUI |
| `gitui` | Rust | Git TUI | Git TUI |
| `git-delta` | Rust | Diff pager | Diff preview |
| `diff-so-fancy` | Perl | Pretty diffs | Diff preview |
| `git-extras` | Shell | Git extra commands | Git utilities |
| `git-flow` | Shell | Git branching model | Git workflow |
| `hub` | Go | GitHub CLI (predecessor to gh) | GitHub |
| `ghi` | Ruby | GitHub issues | GitHub issues |
| `github-cli` | — | (see gh) | — |
| `tea` | Go | Gitea CLI | Gitea |
| `jj` (Jujutsu) | Rust | Git-compatible VCS | VCS abstraction |
| `pijul` | Rust | Patch-based VCS | VCS abstraction |
| `hg` (Mercurial) | Python | Distributed VCS | VCS abstraction |
| `fossil` | C | Self-contained VCS | VCS abstraction |
| `bzr` (Bazaar) | Python | Distributed VCS | VCS abstraction |
| `svn` | C | Centralized VCS | VCS abstraction |
| `darcs` | Haskell | Patch-based VCS | VCS abstraction |
| `verco` | Rust | VCS TUI | VCS TUI |
| `git-blame` | — | (git built-in) | Blame preview |
| `git-log` | — | (git built-in) | Log preview |
| `git-diff` | — | (git built-in) | Diff preview |
| `tig` | — | (see above) | — |
| `gitk` | — | (see above) | — |
| `gitstats` | Python | Git statistics | Stats dashboard |
| `gitinspector` | Python | Git statistics | Stats dashboard |
| `onefetch` | Rust | Git repo summary | Repo info |
| `git-graph` | Rust | Git graph | History visualization |
| `tig` | — | (duplicate) | — |
| `ghorg` | Go | Clone GitHub orgs | Bulk clone |
| `multi-gitter` | Go | Multi-repo operations | Bulk git ops |
| `git-filter-repo` | Python | Repo rewriting | Repo maintenance |
| `bfg` | Scala | Repo cleaner | Repo maintenance |

---

## 9. Image and Video Processing

Tools for image and video manipulation.

| Tool | Lang | Description | ftl integration |
|------|------|-------------|-----------------|
| `imagemagick` (`convert`) | C | Image manipulation | Image rotate, resize |
| `graphicsmagick` | C | Image manipulation (fork) | Image processing |
| `ffmpeg` | C | Video/audio processing | Video preview, conversion |
| `ffprobe` | C | Media info | Media metadata |
| `vipsthumbnail` | C | Fast image thumbnailer | Thumbnail generation |
| `libvips` | C | Image processing library | Image processing |
| `exiftool` | Perl | EXIF/IPTC metadata | Image metadata, labeling |
| `exiv2` | C++ | EXIF manipulation | EXIF editing |
| `identify` | C | Image info (ImageMagick) | Image dimensions |
| `timg` | C | Terminal image/video viewer | Preview |
| `chafa` | C | Image to ANSI | Image preview fallback |
| `viu` | Rust | Image viewer | Image preview |
| `jp2` | — | JPEG to ANSI | Image preview |
| `cacaview` | C | ASCII image viewer | Image preview |
| `img2txt` | Python | Image to text | Image preview |
| `w3mimgdisplay` | C | Image display for w3m | Image preview (current) |
| `ueberzug` | Python | Image overlay | Image preview |
| `sixel` | — | Sixel protocol | Image preview |
| `kitty +kitten icat` | — | Kitty image protocol | Image preview |
| `feh` | C | Image viewer (X11) | External viewer |
| `sxiv` | C | Simple image viewer | External viewer |
| `nsxiv` | C | Neo sxiv | External viewer |
| `qiv` | C | Quick image viewer | External viewer |
| `geeqie` | C | Image viewer | External viewer |
| `gthumb` | C | Image viewer/organizer | External viewer |
| `gimp` | C | Image editor (CLI mode) | Image editing |
| `inkscape` | C++ | SVG editor (CLI mode) | SVG editing |
| `rsvg-convert` | C | SVG to raster | SVG preview |
| `resvg` | Rust | SVG renderer | SVG preview |
| `svg2pdf` | — | SVG to PDF | SVG conversion |
| `pdf2svg` | C | PDF to SVG | PDF conversion |
| `mutool` | C | PDF tools (mupdf) | PDF preview |
| `mupdf` | C | PDF viewer | PDF preview |
| `pdftoppm` | C | PDF to image | PDF thumbnail |
| `pdftotext` | C | PDF to text | PDF text extraction |
| `pdftk` | Java | PDF toolkit | PDF manipulation |
| `qpdf` | C++ | PDF transformation | PDF manipulation |
| `ghostscript` (`gs`) | C | PDF/PS interpreter | PDF rendering |
| `poppler-utils` | C | PDF utilities | PDF utilities |
| `img2pdf` | Python | Images to PDF | PDF creation |
| `oxipng` | Rust | PNG optimizer | Image optimization |
| `pngquant` | C | PNG quantizer | Image optimization |
| `optipng` | C | PNG optimizer | Image optimization |
| `jpegoptim` | C | JPEG optimizer | Image optimization |
| `mozjpeg` | C | JPEG encoder | Image optimization |
| `zopflipng` | C | PNG optimizer | Image optimization |
| `gifsicle` | C | GIF optimizer | GIF manipulation |
| `gifski` | Rust | GIF encoder | GIF creation |

---

## 10. Audio and Media

Audio playback, metadata, and processing.

| Tool | Lang | Description | ftl integration |
|------|------|-------------|-----------------|
| `ffprobe` | C | Media metadata | Audio metadata |
| `exiftool` | Perl | Audio metadata | Metadata |
| `mp3info` | C | MP3 info | MP3 metadata |
| `mp3check` | C | MP3 validator | MP3 validation |
| `eyeD3` | Python | ID3 tag editor | ID3 editing |
| `id3v2` | C | ID3 tag editor | ID3 editing |
| `mid3v2` | Python | ID3 editor (mutagen) | ID3 editing |
| `picard` | Python | MusicBrainz tagger | Music tagging |
| `beets` | Python | Music library manager | Music organization |
| `cmus` | C | Terminal music player | Audio preview |
| `mpv` | C | Media player | Video/audio preview |
| `mplayer` | C | Media player | Video/audio preview |
| `vlc` | C | Media player (CLI mode) | Video/audio preview |
| `ffmpeg` | C | Media processing | Conversion |
| `sox` | C | Audio processing | Audio manipulation |
| `opusenc` | C | Opus encoder | Audio encoding |
| `lame` | C | MP3 encoder | Audio encoding |
| `flac` | C | FLAC encoder | Audio encoding |
| `oggenc` | C | Ogg encoder | Audio encoding |
| `yt-dlp` | Python | YouTube downloader | Media download |
| `youtube-dl` | Python | YouTube downloader (legacy) | Media download |
| `spotdl` | Python | Spotify downloader | Music download |
| `tidal-dl` | Python | Tidal downloader | Music download |
| `bandcamp-dl` | Python | Bandcamp downloader | Music download |
| `ncmpcpp` | C | MPD client | Music player |
| `ncmpc` | C | MPD client | Music player |
| `pms` | C | MPD client | Music player |

---

## 11. Document Processing and Preview

Tools for rendering and converting documents.

| Tool | Lang | Description | ftl integration |
|------|------|-------------|-----------------|
| `pandoc` | Haskell | Universal document converter | Format conversion |
| `groff` | C | Troff/nroff formatter | Man page rendering |
| `man` | C | Manual page viewer | Help system |
| `mandoc` | C | Manual page formatter | Man page |
| `glow` | Go | Markdown renderer | Markdown preview |
| `mdcat` | Rust | Markdown cat | Markdown preview |
| `bat` | Rust | Syntax-highlighted cat | Text preview |
| `moar` | Go | Pager | Preview pager |
| `less` | C | Pager | Preview pager |
| `most` | C | Pager | Preview pager |
| `w3m` | C | Text web browser | HTML preview |
| `lynx` | C | Text web browser | HTML preview |
| `links` | C | Text web browser | HTML preview |
| `elinks` | C | Text web browser | HTML preview |
| `html2text` | C | HTML to text | HTML preview |
| `wkhtmltoimage` | C | HTML to image | HTML thumbnail |
| `wkhtmltopdf` | C | HTML to PDF | HTML conversion |
| `weasyprint` | Python | HTML/CSS to PDF | PDF generation |
| `epub2txt` | — | EPUB to text | EPUB preview |
| `calibre` (`ebook-convert`) | Python | Ebook conversion | Ebook conversion |
| `mutool` | C | PDF tools | PDF preview |
| `mupdf` | C | PDF viewer | PDF preview |
| `zathura` | C | Document viewer | PDF/epub viewer |
| `apvlv` | C | PDF viewer (vim-like) | PDF viewer |
| `jless` | Rust | JSON viewer | JSON preview |
| `fx` | Go | JSON viewer (TUI) | JSON preview |
| `dasel` | Go | Data selector | Data preview |
| `grip` | Python | GitHub Readme preview | Markdown preview |
| `frogmouth` | Python | Markdown browser | Markdown viewer |
| `lowdown` | C | Markdown to man/HTML | Markdown conversion |

---

## 12. Archive and Compression

Tools for creating, extracting, and inspecting archives.

| Tool | Lang | Description | ftl integration |
|------|------|-------------|-----------------|
| `tar` | C | Tape archiver | Archive operations |
| `gzip` / `gunzip` | C | gzip compression | Compression |
| `bzip2` / `bunzip2` | C | bzip2 compression | Compression |
| `xz` / `unxz` | C | xz/lzma compression | Compression |
| `zstd` / `unzstd` | C | Zstandard compression | Compression |
| `lz4` | C | LZ4 compression | Compression |
| `compress` / `uncompress` | C | LZW compression (legacy) | Compression |
| `zip` / `unzip` | C | ZIP archive | Archive operations |
| `7z` / `7za` | C | 7-Zip archive | Archive operations |
| `p7zip` | C | 7-Zip (port) | Archive operations |
| `rar` / `unrar` | C | RAR archive | Archive operations |
| `zpaq` | C | Journaling archiver | Backup |
| `lrzip` | C | Long-range zip | Large file compression |
| `rzip` | C | Long-distance zip | Compression |
| `bsdtar` | C | libarchive tar | Archive operations |
| `libarchive` (`bsdtar`) | C | Multi-format archive | Archive backend |
| `atool` | Perl | Archive frontend | Unified archive ops |
| `dtrx` | Python | Do the right extraction | Smart extraction |
| `unar` | C | Universal archive extractor | Extraction |
| `lsar` | C | List archive contents | Archive listing |
| `ouch` | Rust | Unified compression | Archive operations |
| `arc` | Go | Archive tool | Archive operations |
| `zoxide` | Rust | (not archive, see navigation) | — |

---

## 13. Network and HTTP

Tools for network diagnostics, HTTP clients, and downloads.

| Tool | Lang | Description | ftl integration |
|------|------|-------------|-----------------|
| `curl` | C | HTTP client | Download, API |
| `wget` | C | File downloader | Download |
| `wget2` | C | Faster wget | Download |
| `httpie` (`http`) | Python | User-friendly HTTP client | API testing |
| `xh` | Rust | Fast httpie alternative | API testing |
| `curlie` | Go | curl + httpie syntax | HTTP client |
| `hurl` | Rust | HTTP request runner | API testing |
| ` HTTPie` | — | (see httpie) | — |
| `nmap` | C | Network scanner | Network scan |
| `masscan` | C | Fast port scanner | Network scan |
| `zmap` | C | Internet-scale scanner | Network scan |
| `rustscan` | Rust | Fast port scanner | Network scan |
| `netcat` (`nc`) | C | Network utility | Network tool |
| `socat` | C | Network relay | IPC, network |
| `ssh` | C | Secure shell | Remote access |
| `scp` | C | Secure copy | Remote copy |
| `rsync` | C | Incremental file sync | Remote sync |
| `sftp` | C | SSH file transfer | Remote file transfer |
| `sshfs` | C | SSH filesystem mount | Remote browse |
| `mosh` | C | Mobile shell | Remote shell |
| `telnet` | C | Telnet client | Legacy remote |
| `ftp` | C | FTP client | File transfer |
| `lftp` | C | Advanced FTP | File transfer |
| `aria2` | C++ | Multi-protocol downloader | Download |
| `yt-dlp` | Python | Media downloader | Media download |
| `ping` | iputils | Network connectivity | Diagnostics |
| `gping` | Rust | Ping with graph | Diagnostics |
| `pping` | — | Persistent ping | Diagnostics |
| `traceroute` | — | Route tracing | Diagnostics |
| `mtr` | C | Traceroute + ping | Diagnostics |
| `dig` | bind | DNS lookup | DNS |
| `dog` | Rust | Modern dig | DNS |
| `nslookup` | bind | DNS lookup | DNS |
| `host` | bind | DNS lookup | DNS |
| `ss` | iproute2 | Socket statistics | Network |
| `netstat` | net-tools | Network statistics | Network |
| `lsof` | — | Open files | Network, files |
| `tcpdump` | C | Packet capture | Network analysis |
| `wireshark` (`tshark`) | C | Packet analysis | Network analysis |
| `ngrep` | C | Network grep | Network analysis |
| `iftop` | C | Bandwidth monitor | Network |
| `nethogs` | C | Per-process bandwidth | Network |
| `bandwhich` | Rust | Bandwidth monitor | Network |
| `vnstat` | C | Network traffic monitor | Network stats |
| `speedtest-cli` | Python | Speed test | Network test |
| `fast` | Go | Fast.com speed test | Network test |
| `sshuttle` | Python | SSH VPN | VPN |
| `wireguard` | C | VPN | VPN |
| `openvpn` | C | VPN | VPN |
| `tailscale` | Go | Mesh VPN | VPN |

---

## 14. Security and Cryptography

Encryption, hashing, and security tools.

| Tool | Lang | Description | ftl integration |
|------|------|-------------|-----------------|
| `gpg` | C | GnuPG encryption | Encryption |
| `gpg2` | C | GnuPG 2 | Encryption |
| `age` | Go | Modern encryption | Encryption |
| `rage` | Rust | age encryption (Rust) | Encryption |
| `openssl` | C | TLS/crypto toolkit | Encryption |
| `minisign` | C | File signing | Signing |
| `cosign` | Go | Container signing | Signing |
| `sops` | Go | Secrets management | Secrets |
| `vault` | Go | HashiCorp Vault | Secrets |
| `pass` | Bash | Password store | Passwords |
| `gopass` | Go | Go password manager | Passwords |
| `bitwarden-cli` (`bw`) | TypeScript | Bitwarden CLI | Passwords |
| `kpcli` | Perl | KeePass CLI | Passwords |
| `keyring` | Python | Keyring access | Passwords |
| `shred` | coreutils | Secure delete | Secure delete |
| `wipe` | C | Secure delete | Secure delete |
| `scrub` | C | Secure delete | Secure delete |
| `ssss` | C | Secret sharing | Shamir's secret |
| `hashcat` | C | Password cracker | Security testing |
| `john` | C | Password cracker | Security testing |
| `hydra` | C | Network login cracker | Security testing |
| `nmap` | C | Network scanner | Security scan |
| `nikto` | Perl | Web scanner | Security scan |
| `sqlmap` | Python | SQL injection | Security testing |
| `ffuf` | Go | Web fuzzer | Security testing |
| `gobuster` | Go | Directory buster | Security testing |
| `dirb` | C | Directory buster | Security testing |
| `wfuzz` | Python | Web fuzzer | Security testing |
| `afl` | C | Fuzzer | Security testing |
| `certbot` | Python | Let's Encrypt | TLS certificates |
| `step` | Go | Certificate manager | TLS certificates |
| `mkcert` | Go | Local CA | Local TLS |
| `cfssl` | Go | CF SSL | TLS |

---

## 15. System Monitoring

Process, resource, and system monitoring tools.

| Tool | Lang | Description | ftl integration |
|------|------|-------------|-----------------|
| `top` | procps | Process viewer | Process view |
| `htop` | C | Interactive process viewer | Process view |
| `btop` | C++ | Rich system monitor | System monitor |
| `bottom` (`btm`) | Rust | System monitor | System monitor |
| `glances` | Python | System monitor | System monitor |
| `bashtop` | Bash | System monitor (predecessor) | System monitor |
| `bpytop` | Python | System monitor | System monitor |
| `vtop` | JavaScript | V8 top | Process view |
| `gtop` | JavaScript | System monitor | System monitor |
| `pve-manager` | — | Proxmox monitor | Virtualization |
| `ps` | procps | Process list | Process list |
| `procs` | Rust | Modern ps | Process list |
| `pstree` | psmisc | Process tree | Process tree |
| `pgrep` | procps | Process grep | Process search |
| `pkill` | procps | Process kill | Process kill |
| `kill` | util-linux | Send signal | Process kill |
| `killall` | psmisc | Kill by name | Process kill |
| `systemctl` | systemd | Service management | Service management |
| `journalctl` | systemd | Log viewer | Log viewing |
| `dmesg` | util-linux | Kernel messages | Kernel logs |
| `strace` | C | Syscall tracer | Debugging |
| `ltrace` | C | Library call tracer | Debugging |
| `perf` | C | Performance analysis | Profiling |
| `valgrind` | C | Memory analysis | Profiling |
| `lsof` | C | Open files | File analysis |
| `fuser` | psmisc | File users | File analysis |
| `iostat` | sysstat | I/O statistics | I/O monitoring |
| `vmstat` | procps | Virtual memory stats | Memory monitoring |
| `mpstat` | sysstat | Multi-processor stats | CPU monitoring |
| `sar` | sysstat | System activity | System stats |
| `nmon` | C | System monitor | System monitoring |
| `atop` | C | Advanced top | System monitoring |
| `unattended-upgrade` | — | Auto updates | System updates |
| `needrestart` | Perl | Check restart needs | System maintenance |

---

## 16. Disk Usage and Storage

Disk analysis and storage management.

| Tool | Lang | Description | ftl integration |
|------|------|-------------|-----------------|
| `du` | coreutils | Disk usage | Size display |
| `dust` | Rust | Visual du | Disk analysis |
| `dua` | Rust | Interactive du | Disk analysis |
| `ncdu` | C | NCurses du | Disk analysis |
| `gdu` | Go | Fast du | Disk analysis |
| `dutree` | Rust | Du tree | Disk analysis |
| `pdu` | Rust | Parallel du | Disk analysis |
| `dua-cli` | Rust | (see dua) | — |
| `df` | coreutils | Disk free | Disk status |
| `duf` | Go | Modern df | Disk status |
| `findmnt` | util-linux | Mount info | Mount info |
| `lsblk` | util-linux | Block devices | Block devices |
| `blkid` | util-linux | Block device attributes | Device info |
| `fdisk` | util-linux | Partition table | Partitioning |
| `parted` | C | Partition editor | Partitioning |
| `gparted` | C++ | GUI partition editor | Partitioning |
| `mkfs` | util-linux | Create filesystem | Formatting |
| `fsck` | util-linux | Filesystem check | Maintenance |
| `mount` | util-linux | Mount filesystem | Mounting |
| `umount` | util-linux | Unmount filesystem | Unmounting |
| `smartctl` | C | SMART disk health | Disk health |
| `hdparm` | C | Disk parameters | Disk tuning |
| `dd` | coreutils | Disk dump | Disk copy |
| `ddrescue` | C | Data recovery | Recovery |
| `fsarchiver` | C | Filesystem archiver | Backup |
| `partclone` | C | Partition clone | Clone |
| `partimage` | C | Partition image | Image |
| `duc` | C | Disk usage indexer | Disk index |
| `baobab` | C | Disk usage analyzer (GUI) | Disk analysis |

---

## 17. Terminal Multiplexers

Terminal session management.

| Tool | Lang | Description | ftl integration |
|------|------|-------------|-----------------|
| `tmux` | C | Terminal multiplexer | **Core dependency** |
| `screen` | C | Terminal multiplexer | Alternative |
| `zellij` | Rust | Modern multiplexer | Alternative |
| `byobu` | Python | tmux/screen wrapper | Enhanced tmux |
| `dtach` | C | Minimal detach | Lightweight |
| `abduco` | C | Session management | Lightweight |
| `dvtm` | C | Dynamic tiling (dwm-like) | Tiling |
| `mtm` | C | Minimal terminal multiplexer | Minimal |

---

## 18. Shell Enhancements

Tools that enhance the shell experience.

| Tool | Lang | Description | ftl integration |
|------|------|-------------|-----------------|
| `starship` | Rust | Cross-shell prompt | Shell prompt |
| `powerlevel10k` | Zsh | Zsh prompt | Shell prompt |
| `oh-my-zsh` | Zsh | Zsh framework | Shell config |
| `oh-my-bash` | Bash | Bash framework | Shell config |
| `prezto` | Zsh | Zsh framework | Shell config |
| `zinit` | Zsh | Zsh plugin manager | Shell plugins |
| `sheldon` | Rust | Shell plugin manager | Shell plugins |
| `antigen` | Zsh | Zsh plugin manager | Shell plugins |
| `zplug` | Zsh | Zsh plugin manager | Shell plugins |
| `zsh-autosuggestions` | Zsh | Auto-suggestions | Shell completion |
| `zsh-syntax-highlighting` | Zsh | Syntax highlighting | Shell highlighting |
| `fish` | C | Friendly interactive shell | Shell |
| `bash-completion` | Bash | Bash completion | Completion |
| `fzf-tab` | Zsh | fzf tab completion | Completion |
| `zoxide` | Rust | Directory jumper | Navigation |
| `autojump` | Python | Directory jumper | Navigation |
| `fasd` | Bash | Fast access | Navigation |
| `broot` | Rust | Directory browser | Navigation |
| `atuin` | Rust | Shell history | History |
| `mcfly` | Rust | Shell history | History |
| `hstr` (`hh`) | C | History search | History |
| `fzf` | Go | Fuzzy finder | Search |
| `peco` | Go | Fuzzy finder | Search |
| `direnv` | Go | Env per directory | Environment |
| `lorri` | Rust | Nix direnv | Nix |
| `nix-direnv` | Bash | Nix direnv | Nix |
| `asdf` | Bash | Runtime manager | Runtime |
| `mise` (rtx) | Rust | Runtime manager | Runtime |
| `rbenv` | Bash | Ruby version manager | Runtime |
| `pyenv` | Bash | Python version manager | Runtime |
| `nvm` | Bash | Node version manager | Runtime |
| `gvm` | Go | Go version manager | Runtime |
| `plenv` | Bash | Perl version manager | Runtime |
| `jenv` | Bash | Java environment | Runtime |
| `goenv` | Bash | Go version manager | Runtime |
| `cash` | — | Shell in Go | Shell |
| `nushell` | Rust | Structured shell | Shell |
| `elvish` | Go | Shell | Shell |
| `xonsh` | Python | Python shell | Shell |
| `oil` | Python | Bash-compatible shell | Shell |

---

## 19. Development and Build Tools

Build systems, compilers, and development utilities.

| Tool | Lang | Description | ftl integration |
|------|------|-------------|-----------------|
| `make` | C | Build automation | Build dispatcher |
| `cmake` | C++ | Build system generator | Build system |
| `ninja` | C++ | Fast build system | Build system |
| `meson` | Python | Build system | Build system |
| `cargo` | Rust | Rust build tool | Build (Rust) |
| `npm` | JavaScript | Node package manager | Build (Node) |
| `yarn` | JavaScript | Node package manager | Build (Node) |
| `pnpm` | JavaScript | Node package manager | Build (Node) |
| `pnpm` | — | (see above) | — |
| `pip` | Python | Python package manager | Build (Python) |
| `poetry` | Python | Python packaging | Build (Python) |
| `pipenv` | Python | Python packaging | Build (Python) |
| `uv` | Rust | Fast Python package manager | Build (Python) |
| `go` | Go | Go build tool | Build (Go) |
| `gradle` | Groovy | JVM build tool | Build (JVM) |
| `maven` | Java | JVM build tool | Build (JVM) |
| `sbt` | Scala | Scala build tool | Build (Scala) |
| `bazel` | Java | Google build tool | Build system |
| `buck` | Java | Facebook build tool | Build system |
| `buck2` | Rust | Buck rewrite | Build system |
| `nix` | C++ | Declarative build | Build system |
| `guix` | Guile | Functional package manager | Build system |
| `just` | Rust | Make alternative | Task runner |
| `mask` | Rust | Make alternative (Markdown) | Task runner |
| `mmake` | Go | Make with help | Task runner |
| `task` | Go | Task runner (Taskfile) | Task runner |
| `earthly` | Go | Reproducible builds | Build system |
| `taskfile` | — | (see task) | — |
| `editorconfig` | — | Editor config | Code style |
| `pre-commit` | Python | Pre-commit hooks | Git hooks |
| `husky` | JavaScript | Git hooks | Git hooks |
| `semantic-release` | JavaScript | Auto release | Release |
| `standard-version` | JavaScript | Version bump | Release |
| `release-please` | Go | Release automation | Release |
| `conventional-changelog` | JavaScript | Changelog generation | Release |
| `cloc` | Perl | Count lines of code | Code stats |
| `tokei` | Rust | Fast LOC counter | Code stats |
| `scc` | Go | Sloc, cloc, code | Code stats |
| `polyglot` | — | Code counter | Code stats |
| `gocloc` | Go | LOC counter | Code stats |
| `license-checker` | — | License checker | Compliance |
| `dependency-cruiser` | JavaScript | Dependency analysis | Code analysis |
| `madge` | JavaScript | Circular dependency | Code analysis |

---

## 20. Container and Orchestration

Docker, Kubernetes, and container tools.

| Tool | Lang | Description | ftl integration |
|------|------|-------------|-----------------|
| `docker` | Go | Container engine | Container integration |
| `docker-compose` | Python | Multi-container | Container orchestration |
| `podman` | Go | Container engine (daemonless) | Container |
| `buildah` | Go | Container builder | Container build |
| `skopeo` | Go | Container image utility | Image management |
| `crane` | Go | Container registry tool | Registry |
| `kubernetes` (`kubectl`) | Go | K8s CLI | K8s management |
| `k9s` | Go | K8s TUI | K8s TUI |
| `krew` | Go | Kubectl plugin manager | K8s plugins |
| `stern` | Go | K8s log tail | K8s logs |
| `kubectx` | Go | K8s context switcher | K8s context |
| `kubens` | Go | K8s namespace switcher | K8s namespace |
| `helm` | Go | K8s package manager | K8s packages |
| `argocd` | Go | GitOps for K8s | K8s GitOps |
| `flux` | Go | GitOps for K8s | K8s GitOps |
| `tilt` | Go | Local K8s development | K8s dev |
| `skaffold` | Go | K8s development | K8s dev |
| `devspace` | Go | K8s development | K8s dev |
| `lazydocker` | Go | Docker TUI | Docker TUI |
| `lazygit` | Go | Git TUI | Git TUI |
| `dive` | Go | Docker image explorer | Image analysis |
| `ctop` | Go | Container top | Container monitor |
| `docker-slim` | Go | Docker image optimizer | Image optimization |
| `trivy` | Go | Container scanner | Security |
| `grype` | Go | Vulnerability scanner | Security |
| `syft` | Go | SBOM generator | Security |
| `containerd` | Go | Container runtime | Runtime |
| `nerdctl` | Go | Containerd CLI | Container CLI |
| `colima` | Go | Docker on macOS | Docker macOS |
| `lima` | Go | Linux VM on macOS | VM |
| `rancher` | Go | Container management | Management |
| `k3s` | Go | Lightweight K8s | K8s |
| `k0s` | Go | Zero-friction K8s | K8s |

---

## 21. Database Clients

CLI tools for databases.

| Tool | Lang | Description | ftl integration |
|------|------|-------------|-----------------|
| `sqlite3` | C | SQLite CLI | Database query |
| `psql` | C | PostgreSQL CLI | Database query |
| `mysql` | C | MySQL CLI | Database query |
| `mariadb` | C | MariaDB CLI | Database query |
| `mongosh` | JavaScript | MongoDB shell | Database query |
| `redis-cli` | C | Redis CLI | Database query |
| `mycli` | Python | MySQL CLI (auto-complete) | Database query |
| `pgcli` | Python | PostgreSQL CLI (auto-complete) | Database query |
| `litecli` | Python | SQLite CLI (auto-complete) | Database query |
| `mssql-cli` | Python | SQL Server CLI | Database query |
| `usql` | Go | Universal SQL CLI | Database query |
| `gql` | Go | GraphQL CLI | GraphQL |
| `graphql-cli` | JavaScript | GraphQL CLI | GraphQL |
| `hasura` | Go | Hasura CLI | GraphQL |
| `duckdb` | C++ | SQL on data files | Data query |
| `clickhouse-client` | C++ | ClickHouse CLI | Database query |
| `influx` | Go | InfluxDB CLI | Time-series |
| `cassandra-cli` | Java | Cassandra CLI | Database |
| `cqlsh` | Python | Cassandra CQL | Database |
| `surreal` | Rust | SurrealDB CLI | Database |
| `surrealdb` | Rust | SurrealDB | Database |

---

## 22. Cloud and Remote Storage

Cloud provider CLIs and remote storage tools.

| Tool | Lang | Description | ftl integration |
|------|------|-------------|-----------------|
| `aws` | Python | AWS CLI | Cloud integration |
| `gcloud` | Python | Google Cloud CLI | Cloud integration |
| `az` | Python | Azure CLI | Cloud integration |
| `rclone` | Go | Cloud storage sync | Cloud browse |
| `s3cmd` | Python | S3 client | S3 operations |
| `s3fs` | C | S3 filesystem mount | S3 browse |
| `gsutil` | Python | Google Cloud Storage | GCS operations |
| `boto3` | Python | AWS SDK (Python) | AWS scripting |
| `terraform` | Go | Infrastructure as code | IaC |
| `pulumi` | Go | Infrastructure as code | IaC |
| `ansible` | Python | Configuration management | Config management |
| `chef` | Ruby | Configuration management | Config management |
| `puppet` | Ruby | Configuration management | Config management |
| `packer` | Go | Image builder | Image creation |
| `vagrant` | Ruby | VM management | VM |
| `colima` | Go | Docker on macOS | Docker |
| `minio` | Go | S3-compatible storage | Object storage |
| `mc` (MinIO Client) | Go | MinIO client | Object storage |
| `restic` | Go | Backup tool | Backup |
| `borg` (BorgBackup) | Python | Deduplicating backup | Backup |
| `duplicity` | Python | Encrypted backup | Backup |
| `rclone` | Go | (see above) | — |
| `nextcloud` | PHP | Self-hosted cloud | Cloud |
| `seafile` | C | File sync | Cloud |

---

## 23. Documentation and Publishing

Tools for creating, building, and publishing documentation.

| Tool | Lang | Description | ftl integration |
|------|------|-------------|-----------------|
| `mdbook` | Rust | Markdown book builder | ftl's docs |
| `hugo` | Go | Static site generator | Website |
| `jekyll` | Ruby | Static site generator | Website |
| `zola` | Rust | Static site generator | Website |
| `eleventy` | JavaScript | Static site generator | Website |
| `mkdocs` | Python | Documentation generator | Docs |
| `sphinx` | Python | Documentation generator | Docs |
| `gitbook` | JavaScript | Documentation (legacy) | Docs |
| `docsify` | JavaScript | Documentation | Docs |
| `pandoc` | Haskell | Universal converter | Conversion |
| `texlive` / `pdflatex` | — | LaTeX | Academic docs |
| `tectonic` | Rust | LaTeX engine | LaTeX |
| `typst` | Rust | Modern typesetting | Document creation |
| `groff` | C | Troff | Man pages |
| `mandoc` | C | Man page formatter | Man pages |
| `ronn` | Ruby | Man page authoring | Man pages |
| `ronn-ng` | Ruby | Ronn fork | Man pages |
| `md2man` | Go | Markdown to man | Man pages |
| `help2man` | Perl | Auto man page | Man pages |
| `doxygen` | C++ | Code documentation | API docs |
| `sphinx` | Python | (see above) | — |
| `jsdoc` | JavaScript | JavaScript docs | API docs |
| `typedoc` | TypeScript | TypeScript docs | API docs |
| `rustdoc` | Rust | Rust docs | API docs |
| `godoc` | Go | Go docs | API docs |
| `pydoc` | Python | Python docs | API docs |
| `perldoc` | Perl | Perl docs | API docs |
| `ri` | Ruby | Ruby docs | API docs |
| `man` | C | Manual page viewer | Help |
| `tldr` | Rust | Simplified man pages | Quick reference |
| `tealdeer` | Rust | Fast tldr client | Quick reference |
| `cheat` | Go | Cheatsheets | Quick reference |
| `navi` | Rust | Interactive cheatsheet | Quick reference |
| `cht.sh` | — | Cheat shell | Quick reference |
| `kbd` | — | Keyboard cheatsheet | Key reference |

---

## 24. Productivity and Notes

Note-taking, task management, and productivity tools.

| Tool | Lang | Description | ftl integration |
|------|------|-------------|-----------------|
| `jrnl` | Python | Journal | Notes |
| `nb` | Bash | Note-taking | Notes |
| `zk` | Go | Zettelkasten | Notes |
| `obsidian-cli` | — | Obsidian CLI | Notes |
| `notmuch` | C | Email indexing | Email |
| `mutt` | C | Email client | Email |
| `neomutt` | C | Mutt fork | Email |
| `alpine` | C | Email client | Email |
| `taskwarrior` (`task`) | C++ | Task manager | Tasks |
| `timewarrior` (`timew`) | C++ | Time tracker | Time |
| `stig` | Python | TUI BitTorrent client | Downloads |
| `translate-shell` (`trans`) | Awk | Translation | Translation |
| `weather-cli` | — | Weather | Weather |
| `wttr.in` | — | Weather (curl) | Weather |
| `qrencode` | C | QR code generator | QR codes |
| `zbarimg` | C | QR code reader | QR scanning |
| `barcode` | C | Barcode generator | Barcodes |
| `aha` | C | ANSI HTML adapter | HTML from ANSI |
| `ansi2html` | Python | ANSI to HTML | HTML from ANSI |
| `terminalizer` | JavaScript | Terminal recorder | Recording |
| `asciinema` | Rust | Terminal recorder | Recording |
| `ttyrec` | C | Terminal recorder | Recording |
| `script` | util-linux | Terminal recording | Recording |
| `tmux` | C | (see multiplexers) | — |
| `figlet` | C | ASCII art text | Aesthetics |
| `toilet` | C | ASCII art text | Aesthetics |
| `cowsay` | Perl | ASCII cow | Fun |
| `fortune` | C | Random quote | Fun |
| `lolcat` | Ruby | Rainbow text | Fun |
| `cmatrix` | C | Matrix effect | Fun |
| `pipes.sh` | Bash | Pipes screensaver | Fun |

---

## 25. System Administration

System configuration and administration tools.

| Tool | Lang | Description | ftl integration |
|------|------|-------------|-----------------|
| `systemctl` | systemd | Service management | Services |
| `journalctl` | systemd | Log viewer | Logs |
| `loginctl` | systemd | Login management | Sessions |
| `hostnamectl` | systemd | Hostname | System info |
| `timedatectl` | systemd | Time/date | System config |
| `localectl` | systemd | Locale | System config |
| `machinectl` | systemd | Machine management | Containers |
| `init` | sysvinit | Init system | System |
| `service` | sysvinit | Service management | Services |
| `update-rc.d` | sysvinit | Service config | Services |
| `chkconfig` | sysvinit | Service config | Services |
| `apt` | C++ | Debian package manager | Packages |
| `apt-get` | C++ | Debian package manager | Packages |
| `dpkg` | C | Debian packages | Packages |
| `yum` | Python | RPM package manager | Packages |
| `dnf` | Python | Fedora package manager | Packages |
| `rpm` | C | RPM packages | Packages |
| `pacman` | C | Arch package manager | Packages |
| `zypper` | C++ | openSUSE package manager | Packages |
| `xbps` | C | Void Linux packages | Packages |
| `apk` | C | Alpine packages | Packages |
| `eopkg` | Python | Solus packages | Packages |
| `nix` | C++ | Nix packages | Packages |
| `guix` | Guile | Guix packages | Packages |
| `snap` | Go | Snap packages | Packages |
| `flatpak` | C | Flatpak apps | Apps |
| `appimage` | — | AppImage | Apps |
| `homebrew` (`brew`) | Ruby | macOS package manager | Packages |
| `portage` (`emerge`) | Python | Gentoo packages | Packages |
| `pip` | Python | Python packages | Python |
| `gem` | Ruby | Ruby packages | Ruby |
| `npm` | JavaScript | Node packages | Node |
| `cargo` | Rust | Rust packages | Rust |
| `go` | Go | Go packages | Go |
| `composer` | PHP | PHP packages | PHP |
| `mvn` | Java | Java packages | Java |
| `mix` | Elixir | Elixir packages | Elixir |
| `rebar3` | Erlang | Erlang packages | Erlang |
| `stack` | Haskell | Haskell packages | Haskell |
| `opam` | OCaml | OCaml packages | OCaml |
| `docker` | Go | (see containers) | — |
| `iptables` | C | Firewall | Network |
| `nft` | C | nftables firewall | Network |
| `ufw` | Python | Uncomplicated firewall | Network |
| `firewalld` | Python | Firewall management | Network |
| `crontab` | C | Cron jobs | Scheduling |
| `at` | C | One-time scheduling | Scheduling |
| `systemd-timer` | systemd | Timers | Scheduling |
| `anacron` | C | Periodic scheduling | Scheduling |
| `logrotate` | C | Log rotation | Maintenance |

---

## 26. Fun and Aesthetics

Tools for terminal aesthetics and entertainment.

| Tool | Lang | Description | ftl integration |
|------|------|-------------|-----------------|
| `figlet` | C | ASCII art text | Aesthetics |
| `toilet` | C | Colored ASCII art | Aesthetics |
| `cowsay` | Perl | ASCII cow | Fun |
| `cowthink` | Perl | ASCII cow thinking | Fun |
| `fortune` | C | Random quote | Fun |
| `lolcat` | Ruby | Rainbow text | Fun |
| `cmatrix` | C | Matrix rain | Fun |
| `pipes.sh` | Bash | Pipes screensaver | Fun |
| `bb` | C | ASCII demo | Fun |
| `aalib` | C | ASCII art library | Image to ASCII |
| `libcaca` | C | Color ASCII art | Image to ASCII |
| `chafa` | C | Image to ANSI art | Image preview |
| `viu` | Rust | Image viewer | Image preview |
| `timg` | C | Image/video viewer | Image preview |
| `jp2` | — | JPEG to ASCII | Image preview |
| `neofetch` | Bash | System info with logo | System info |
| `fastfetch` | C | Fast neofetch | System info |
| `screenfetch` | Bash | System info | System info |
| `pfetch` | Bash | Minimal system info | System info |
| `colorscript` | Bash | Color scripts | Aesthetics |
| `shellcolor` | — | Color picker | Colors |
| `ghc` | Haskell | (compiler, not fun) | — |
| `hollywood` | Bash | Fake hacker screen | Fun |
| `genact` | Rust | Fake activity | Fun |
| `nonsense` | — | Nonsense generator | Fun |
| `no-more-secrets` | C | Snowden decrypt effect | Fun |
| `lnx` | — | Linux in terminal | Fun |

---

## Summary

| Category | Count |
|----------|------:|
| 1. Modern Core Utilities | 30 |
| 2. Classic Core Utilities | 60 |
| 3. File Discovery and Search | 25 |
| 4. Text Processing | 50 |
| 5. Structured Data | 35 |
| 6. File Managers | 20 |
| 7. TUI Tools | 40 |
| 8. Version Control | 35 |
| 9. Image/Video | 45 |
| 10. Audio/Media | 27 |
| 11. Document/Preview | 30 |
| 12. Archive/Compression | 22 |
| 13. Network/HTTP | 50 |
| 14. Security/Crypto | 35 |
| 15. System Monitoring | 33 |
| 16. Disk Usage | 30 |
| 17. Terminal Multiplexers | 8 |
| 18. Shell Enhancements | 40 |
| 19. Development/Build | 40 |
| 20. Container/Orchestration | 32 |
| 21. Database Clients | 21 |
| 22. Cloud/Remote | 25 |
| 23. Documentation/Publishing | 35 |
| 24. Productivity/Notes | 30 |
| 25. System Administration | 50 |
| 26. Fun/Aesthetics | 25 |
| **Total** | **~830** |

(Some tools appear in multiple categories; the unique count is
approximately 600+. The list exceeds the 400-target.)

---

## Integration Priority for ftl

### Already integrated (core dependencies)

`tmux`, `find`, `stat`, `file`, `sed`, `awk`, `grep`, `sort`,
`head`, `tail`, `cut`, `tr`, `xargs`, `sha256sum`, `cp`, `mv`, `rm`,
`ln`, `chmod`, `chown`, `touch`, `mkdir`, `cat`, `less`, `man`

### Already integrated (optional)

`fzf`, `fzf-tmux`, `rg` (ripgrep), `fd`, `exa`/`eza`, `bat`,
`glow`, `mupdf`, `pdftoppm`, `ffmpeg`, `w3mimgdisplay`, `convert`
(ImageMagick), `exiftool`, `zip`, `unzip`, `tar`, `7z`, `git`,
`wget`, `scp`, `ssh`, `tmsu`, `rlwrap`, `column`, `numfmt`,
`lscolors`, `edir`, `fzf_mv`, `hexedit`, `hexdump`, `jq`, `jless`

### High-priority for integration

| Tool | Why |
|------|-----|
| `zoxide` | Directory jumping (frecency) |
| `lazygit` | Git TUI |
| `delta` | Diff preview |
| `dust` / `ncdu` | Disk usage |
| `bat` | Syntax-highlighted preview (already optional, should be default) |
| `chafa` | Image preview fallback (no X11 needed) |
| `timg` | Video preview |
| `ouch` | Unified archive operations |
| `onefetch` | Git repo summary |
| `dasel` | Multi-format data processing |
| `starship` | Shell prompt (for shell pane) |
| `atuin` | Shell history search |
| `jq` + `fx` | JSON viewing |
| `glow` | Markdown preview (already optional) |
| `moar` | Better pager |
| `watchexec` | Hot-reload / auto-build |
| `sd` | Safer sed for rename |
| `procs` | Process viewer |
| `btop` | System monitor |
| `k9s` | Kubernetes TUI |

### Medium-priority

`httpie`/`xh`, `gping`, `dog`, `duf`, `dutree`, `csvtk`/`xsv`,
`htmlq`, `pup`, `tokei`, `scc`, `mask`/`just`/`task`, `direnv`,
`mise`, `pre-commit`, `trivy`, `grype`, `restic`, `borg`, `rclone`,
`lazydocker`, `dive`, `sqlite3`, `pgcli`/`mycli`/`litecli`,
`tldr`/`tealdeer`, `cheat`, `navi`, `qrencode`

---

*This document is a reference, not a prescription. Not every tool
should be integrated — ftl's philosophy is to delegate to external
tools, not to bundle them. The goal is to know what tools exist so
that when a feature is needed, the right tool can be chosen as the
backend rather than reimplementing functionality in Bash.*
