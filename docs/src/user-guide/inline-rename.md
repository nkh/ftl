# Inline Rename Mode

The inline rename mode is a modal, two-level workflow for renaming files,
bulk-renaming with patterns, and labeling images — all without leaving
ftl's keyboard engine. It complements the `R` binding (which invokes
[`edir`](https://github.com/btmills/edir) for full `$EDITOR`-based bulk
rename) and is intended for quick single-file renames and small
sequential or regexp batches.

## Entering the Mode

Press `LEADER r i` (Leader is `\` by default). The header shows `⟦R⟧`
while in outer mode and `⟦R✎⟧` while editing a draft.

## Outer Mode

Default state on entry. Navigation and dispatch:

| Key             | Action                                                            |
|-----------------|-------------------------------------------------------------------|
| `j` / `k`       | Move cursor down / up                                             |
| `DOWN` / `UP`   | Same as `j` / `k`                                                 |
| `J` / `K`       | Move by `ftl_cfg_move_step_size` (default 4)                      |
| `PgDn` / `PgUp` | Same as `J` / `K`                                                 |
| `g` / `HOME`    | Jump to first entry                                               |
| `G` / `END`     | Jump to last entry                                                |
| `SPACE` / `t`   | Toggle selection on the current entry                             |
| `TAB`           | Toggle selection and move down                                    |
| `Return`        | Edit the current entry's name (draft pre-filled with basename)    |
| any letter      | Edit the current entry with a fresh name starting with that letter|
| `r`             | Sequential rename (prompts for base name)                         |
| `R`             | Regexp rename (prompts for a `sed -E` expression)                 |
| `l`             | Edit the EXIF/IPTC label of the current image                     |
| `x` / `DEL`     | Delete the current entry (with confirmation)                      |
| `d`             | Delete without confirmation (if `ftl_cfg_inline_rename_no_confirm_delete=1`) |
| `Escape` / `q`  | Exit inline rename mode                                           |

## Inner Mode

Entered from outer mode via `Return`, a letter, or `l` (for images).
The cursor row is replaced by an editable draft rendered in inverse
video, with the insertion cursor highlighted.

| Key                | Action                                                       |
|--------------------|--------------------------------------------------------------|
| printable ASCII    | Insert character at the cursor position                      |
| `Backspace`        | Delete the character before the cursor                       |
| `CTL-W`            | Delete the previous word (whitespace-delimited)              |
| `CTL-U`            | Clear the entire draft                                       |
| `CTL-A` / `HOME`   | Move insertion cursor to start                               |
| `CTL-E` / `END`    | Move insertion cursor to end                                 |
| `Return`           | Commit (`mv` for filenames, `exiftool` for labels)           |
| `Escape`           | Abort (discard draft, return to outer mode)                  |
| `TAB`              | Commit and start editing the next entry down                 |

If a commit would overwrite an existing file, the operation is refused
and an error message `[target exists: NAME]` is shown inline at the
cursor row. The user stays in inner mode and can correct the draft.

## Workflows

### Rename a single file

1. `LEADER r i`
2. Navigate to the file with `j` / `k`
3. Press `Return` (draft pre-filled with current name)
4. Edit the name with `Backspace` and typing
5. Press `Return` to commit, or `Escape` to abort

### Rename several files in sequence (TAB flow)

1. `LEADER r i`
2. Press `Return` on the first file
3. Edit the name and press `TAB` (commits and jumps to next entry)
4. Repeat step 3 for each file
5. On the last file, press `Return` to commit and stay in outer mode

### Sequential numbered rename

Useful for renaming a batch of photos to a common prefix.

1. Tag the files you want to rename (or skip to rename all visible entries)
2. `LEADER r i`
3. Press `r`
4. Type the base name (e.g. `vacation`) and press `Return`
5. Files become `vacation001.jpg`, `vacation002.jpg`, etc.
   (extensions are preserved; the format is controlled by
   `ftl_cfg_inline_rename_sequence_format`)

### Regexp rename

Useful for fixing extensions or stripping prefixes.

1. Tag the files (or skip for all entries)
2. `LEADER r i`
3. Press `R`
4. Type a `sed -E` expression (e.g. `s/\.jpeg$/.jpg/`) and press `Return`
5. The pattern is applied to each basename; files with no match are skipped

### Label an image (EXIF/IPTC)

Adds metadata to an image without changing its filename.

1. `LEADER r i`
2. Navigate to an image (`.jpg`, `.png`, etc.)
3. Press `l` (draft pre-filled with existing label, if any)
4. Type the label and press `Return`
5. `exiftool` writes `IPTC:ObjectName` and `EXIF:ImageDescription`

### Delete from within the mode

1. `LEADER r i`
2. Navigate to the file
3. Press `x` (or `DEL`)
4. Confirm with `y` (or set `ftl_cfg_inline_rename_no_confirm_delete=1`
   and use `d` to skip the prompt)

## Configuration

These variables can be set in `~/.config/ftl/ftlrc`:

```bash
# Skip the delete confirmation prompt when 'd' is pressed
ftl_cfg_inline_rename_no_confirm_delete=0

# printf format for sequential rename
ftl_cfg_inline_rename_sequence_format='%03d'

# Default sed expression pre-filled in the regexp prompt
ftl_cfg_inline_rename_regexp_default='s/OLD/NEW/'

# Extensions considered images for the 'l' label sub-mode
ftl_cfg_image_extensions=(jpg jpeg png gif tiff tif bmp webp heic)

# Header glyphs (customizable)
ftl_cfg_glyph_inline_rename='⟦R⟧'
ftl_cfg_glyph_inline_rename_edit='⟦R✎⟧'
```

## Edge Cases

- **Virtual lists**: The mode refuses to enter when a virtual list
  (e.g. fzf_search results) is active. Renaming virtual entries is
  meaningless.
- **Empty listing**: Outer-mode navigation is a no-op. `Return` and
  letter keys do nothing (no entry to edit).
- **Empty draft on commit**: Treated as abort — no `mv` is performed.
- **Same name on commit**: Treated as abort — no `mv` is performed.
- **Target exists**: The commit is refused; the user stays in inner
  mode and sees an error message.
- **TAB on the last entry**: The commit happens, but the mode returns
  to outer (no next entry to edit).
- **Missing `exiftool`**: The `l` key is a no-op with an error message.
- **Multi-directory selection**: Sequential and regexp renames only
  change the basename; the directory prefix is preserved, so a
  multi-directory selection is safe.

## Implementation

See `documentation/ftl-inline-rename-proposal.md` for the full design
document, and `config/ftl/etc/core/modules/inline_rename.sh` for the
source. Unit tests live in `test/unit/test_inline_rename.sh`.
