# ftl — Ignored Keys Reference

> **Subject:** A complete catalog of keyboard input that
> `ftl::kbd::normalize_key` does not recognize, and is therefore
> silently dropped (or, more precisely, accumulated as empty strings
> until the overflow guard fires).
> **Purpose:** Help maintainers and users understand which keys do
> not work, why, and what to do about it.
> **Companion documents:** `maintenance/03-modules.md` (keyboard
> module reference), `maintenance/07-modification-guide.md` §8
> (modifying the keyboard engine).
> **Source:** `config/ftl/etc/core/modules/keyboard.sh:195-261`

---

## Table of Contents

1. [How `normalize_key` Works](#1-how-normalize_key-works)
2. [What Happens to Unrecognized Keys](#2-what-happens-to-unrecognized-keys)
3. [Critical Finding: Plain ASCII Letters Are Dropped](#3-critical-finding-plain-ascii-letters-are-dropped)
4. [Recognized Keys (Summary)](#4-recognized-keys-summary)
5. [Ignored Keys — Complete Table](#5-ignored-keys--complete-table)
6. [Notable Gaps and Their Causes](#6-notable-gaps-and-their-causes)
7. [How to Add Support for an Ignored Key](#7-how-to-add-support-for-an-ignored-key)
8. [Terminal Compatibility Notes](#8-terminal-compatibility-notes)
9. [Diagnostic Procedure](#9-diagnostic-procedure)

---

## 1. How `normalize_key` Works

`ftl::kbd::normalize_key` is a Bash `case` statement that maps raw
byte sequences (produced by `ftl::kbd::get_key` via `read -rsn 1` +
`read -rsn 4 -t 0.001`) to symbolic key names (`UP`, `ENTER`,
`CTL-A`, etc.).

```bash
ftl::kbd::normalize_key() {
    case "$1" in
        $'\e')             echo "ESCAPE" ;;
        $'\e[A')           echo "UP" ;;
        $'\001')           echo "CTL-A" ;;
        # ... ~60 cases ...
        $'\ej')            echo "ALT-J" ;;
    esac
}
```

**The critical detail:** there is no `*) ... ;;` fallback case. If
the raw sequence does not match any listed pattern, the function
outputs **nothing** (the `case` simply falls through without
matching), and the caller (`ftl::kbd::get_key`) assigns the empty
string to `ftl_kbd_current_key`.

This is the root cause of all "ignored keys": the unrecognized byte
sequence becomes an empty `ftl_kbd_current_key`, which then propagates
into the dispatch logic as described in §2.

---

## 2. What Happens to Unrecognized Keys

The flow when `normalize_key` returns empty:

1. **`ftl::kbd::get_key`** sets `ftl_kbd_current_key=""` (empty).
   The raw byte is preserved in `ftl_kbd_raw_key` but this variable
   is never read by `dispatch`.

2. **`ftl::kbd::dispatch`** is called with `reply=""`.

3. The overflow guard (line 270) checks `ftl_kbd_keys_count > 3`. If
   not yet exceeded, dispatch continues.

4. The timeout check (line 278): `""` does not match `ERROR_*`, so
   dispatch continues.

5. The special-key translations (lines 286–287): `""` does not match
   `?` or `$ftl_cfg_leader_key`, so `reply` stays `""`.

6. The sub-mode check (line 290): if a sub-mode handler is active, it
   is called with `ftl_kbd_current_key=""`. Sub-mode handlers
   typically `case` on the key and have a `*) : ;;` fallback, so the
   empty key is silently ignored. **In sub-mode, unrecognized keys are
   truly silently dropped.**

7. The escape check (line 296): `""` is not `ESCAPE`, so dispatch
   continues.

8. The count-accumulation check (line 304): `""` does not match
   `^[0-9]$`, so dispatch continues.

9. **Accumulation (line 315):** `ftl_kbd_accumulated_keys+=""` — the
   empty string is appended (no visible effect), and
   `ftl_kbd_keys_count` is incremented.

10. The virtual-entry check (line 319) and trie lookup (line 327)
    proceed with the accumulated keys. Since the empty key was
    appended, the accumulated string is unchanged, but the count is
    now higher.

11. The trie lookup fails (no binding matches), dispatch returns
    without action.

12. **Repeat.** Each unrecognized key increments `ftl_kbd_keys_count`.
    After 4 unrecognized keys (or any mix that exceeds count 3), the
    overflow guard fires (line 270), resetting the accumulation.

**Net effect:** a single unrecognized key does nothing visible. A
sequence of unrecognized keys causes ftl to appear "stuck" (no
response to any key) for up to 4 keystrokes, then silently resets.
The user perceives this as "ftl ignored my keys" or "ftl froze
briefly."

### Why this is a problem

- **Discoverability:** The user gets no feedback that a key was
  unrecognized. They may press the key harder, multiple times, or
  assume ftl is broken.
- **Modifier combinations:** Common key combinations like `Shift+Tab`,
  `Ctrl+Shift+arrow`, `Alt+letter` (except J and K) are unrecognized.
  Users coming from other file managers expect these to work.
- **International keyboards:** Keys that produce multi-byte UTF-8
  sequences (e.g. `é`, `ü`, `ñ`) are unrecognized.

### Why the empty-string accumulation is not catastrophic

The overflow guard at line 270 ensures that the accumulation cannot
grow indefinitely. After 4 unrecognized keys, the state resets.
This means ftl "recovers" automatically — the user just has to press
a recognized key after the reset.

However, during the stall (between the 1st and 4th unrecognized key),
all keys are absorbed without effect, including recognized ones (they
get accumulated into the same string, which then fails the trie
lookup). This is the "ftl froze" perception.

---

## 3. Critical Finding: Plain ASCII Letters Are Dropped

**This is the most significant gap in `normalize_key`.** Plain
printable ASCII characters — the letters `a`-`z`, `A`-`Z`, the digits
`0`-`9`, and most punctuation — are **not** recognized. The `case`
statement has no `*)` fallback, so for input like `"j"`, the function
outputs nothing.

### Verification

```bash
$ cd /home/z/my-project/ftl-work
$ source config/ftl/etc/core/modules/keyboard.sh
$ ftl::kbd::normalize_key "j"   # outputs nothing
$ ftl::kbd::normalize_key "a"   # outputs nothing
$ ftl::kbd::normalize_key "5"   # outputs nothing
$ ftl::kbd::normalize_key "j" | xxd
00000000:
```

The `xxd` output confirms: zero bytes are produced for `"j"`.

### Impact

The core navigation bindings (`j`, `k`, `h`, `l`) and all letter-
based bindings (`a`-`z`) **cannot fire** through the normal
`get_key` → `normalize_key` → `dispatch` path. The bindings are
registered in the trie (e.g.
`ftl_kbd_trie[j]=ftl::cmd::cursor_down`), but `dispatch` never sees
`j` because `normalize_key` returns empty.

A full simulation (see `scripts/test_j_key.sh`) confirms:
- `ftl_kbd_trie[j]` is correctly set to `ftl::cmd::cursor_down`
- After `get_key` simulates a `j` press, `ftl_kbd_current_key` is
  empty
- `dispatch` accumulates an empty string, the trie lookup fails, and
  `ftl::cmd::cursor_down` is never invoked

### Why the tests pass

The unit tests (`test_inline_rename.sh`, `test_keyboard.sh`, etc.)
set `ftl_kbd_current_key` directly and call `dispatch`, **bypassing
`normalize_key` entirely**. For example:

```bash
press() {
    ftl_kbd_current_key="$1"   # sets directly, no normalize_key
    ftl::plugin::inline_rename::dispatch
}
```

The tests verify that `dispatch` works correctly given a non-empty
key, but they do not verify that `get_key` + `normalize_key` produce
a non-empty key for plain letters. The bug is in `normalize_key`,
which the tests do not exercise.

### Likely cause

The `reformat` branch split the monolithic ftl source into 17 modules
and may have lost a `*) echo "$1" ;;` fallback that existed in the
original code. The original `ftl` (pre-reformat) reportedly worked
with plain letters, so the fallback likely existed and was dropped
during the refactor. The migration tables in
`documentation/ftl2-function-migration-table.md` should be consulted
to confirm.

### Resolution

`normalize_key` needs a `*)` fallback that passes through single
printable ASCII characters. See §7.

---

## 4. Recognized Keys (Summary)

For reference, here is what `normalize_key` **does** recognize.

### Single-byte keys (recognized)

| Raw | Symbolic | Notes |
|-----|----------|-------|
| `\e` (0x1B) | `ESCAPE` | |
| `\177` (DEL) | `BACKSPACE` | |
| `\\` | `BACKSLASH` | Default leader key |
| ` ` (space) | `SPACE` | |
| `*` | `STAR` | |
| `@` | `AT` | |
| `'` | `QUOTE` | |
| `"` | `DQUOTE` | |
| `\t` (0x09) | `TAB` | |
| `` (empty, from `read` on Enter) | `ENTER` | |
| `?` | (handled in `dispatch`, not `normalize_key`) | Translated to `QUESTION_MARK` at line 286 |

### Arrow keys (recognized)

| Raw | Symbolic |
|-----|----------|
| `\e[A`, `\e[OA`, `\e[A\e[` | `UP` |
| `\e[B`, `\e[0B`, `\e[B\e[` | `DOWN` |
| `\e[C`, `\e[OC`, `\e[C\e[` | `RIGHT` |
| `\e[D`, `\e[OD`, `\e[D\e[` | `LEFT` |

### Navigation keys (recognized)

| Raw | Symbolic |
|-----|----------|
| `\e[2~` | `INS` |
| `\e[3~` | `DEL` |
| `\e[1~`, `\e[H` | `HOME` |
| `\e[4~`, `\e[F` | `END` |
| `\e[5~` | `PGUP` |
| `\e[6~` | `PGDN` |

### Function keys (recognized)

| Raw | Symbolic |
|-----|----------|
| `\e[11~`, `\e[[A`, `\eOP` | `F1` |
| `\e[12~`, `\e[[B`, `\eOQ` | `F2` |
| `\e[13~`, `\e[[C`, `\eOR` | `F3` |
| `\e[14~`, `\e[[D`, `\eOS` | `F4` |
| `\e[15~`, `\e[[E` | `F5` |
| `\e[17~`, `\e[[F` | `F6` |
| `\e[18~` | `F7` |
| `\e[19~` | `F8` |
| `\e[20~` | `F9` |
| `\e[21~` | `F10` |
| `\e[23~` | `F11` |
| `\e[24~` | `F12` |

**Note on F5–F12 syntax:** The source uses `$'\e['15~` for F5 (and
similar for F6–F12). This looks like a typo (stray `'` after `[`),
but it is actually valid Bash: `$'\e['` is the ANSI-C string `\e[`,
and `15~` is a literal that concatenates with it, producing `\e[15~`.
Verified empirically — F5–F12 all work correctly.

### Control characters (recognized)

| Raw | Symbolic |
|-----|----------|
| `\001` | `CTL-A` |
| `\002` | `CTL-B` |
| `\004` | `CTL-D` |
| `\005` | `CTL-E` |
| `\006` | `CTL-F` |
| `\a` (`\007`) | `CTL-G` |
| `\b` (`\010`) | `CTL-H` |
| `\v` (`\013`) | `CTL-K` |
| `\f` (`\014`) | `CTL-L` |
| `\016` | `CTL-N` |
| `\017` | `CTL-O` |
| `\020` | `CTL-P` |
| `\021` | `CTL-Q` |
| `\022` | `CTL-R` |
| `\023` | `CTL-S` |
| `\024` | `CTL-T` |
| `\025` | `CTL-U` |
| `\026` | `CTL-V` |
| `\027` | `CTL-W` |
| `\030` | `CTL-X` |
| `\031` | `CTL-Y` |

**Notable gaps in Ctrl coverage:** `CTL-C` (`\003`), `CTL-I` (=`TAB`),
`CTL-J`/`CTL-M` (=`ENTER`), `CTL-Z` (`\032`), `CTL-[` (=`ESCAPE`),
`CTL-\` (`\034`), `CTL-]` (`\035`), `CTL-^` (`\036`), `CTL-_`
(`\037`), `CTL-Space` (`\000`) are not explicitly handled (some are
intercepted by the terminal or handled as their non-Ctrl equivalents).

### Alt combinations (recognized)

| Raw | Symbolic |
|-----|----------|
| `\ej` | `ALT-J` |
| `\ek` | `ALT-K` |

**Only these two.** All other `Alt+<letter>` combinations are
unrecognized (see §5.1).

### International characters (recognized)

| Raw | Symbolic |
|-----|----------|
| `\302\247` (§) | `PARAGRAPH` |
| `\302\277` (¿) | `INVERSED_QUESTION_MARK` |
| `\302\250` (¨) | `DIAERESIS` |

---

## 5. Ignored Keys — Complete Table

The table below lists keys that `normalize_key` does **not**
explicitly match. Each entry shows: the key, the raw byte sequence(s)
it typically produces, and the impact.

### 5.1 Plain printable ASCII (CRITICAL — see §3)

| Key | Raw | Status | Impact |
|-----|-----|--------|--------|
| `a`–`z` | single byte | **Ignored** | All letter bindings broken (j, k, h, l, etc.) |
| `A`–`Z` | single byte | **Ignored** | All uppercase letter bindings broken |
| `0`–`9` | single byte | **Ignored** | Digit bindings broken (count prefix may still work via dispatch's count-accumulation path) |
| Most punctuation (`!`, `#`, `$`, `%`, `^`, `&`, `(`, `)`, `-`, `+`, `=`, `{`, `}`, `[`, `]`, `|`, `;`, `:`, `<`, `>`, `,`, `.`, `/`, `~`, `` ` ``) | single byte | **Ignored** | Punctuation bindings broken |

**Note:** A few punctuation characters ARE recognized: `\\`
(BACKSLASH), ` ` (SPACE), `*` (STAR), `@` (AT), `'` (QUOTE), `"`
(DQUOTE). All others are not.

### 5.2 Modifier combinations (definitely ignored)

| Key | Typical raw sequence | Status | Impact |
|-----|----------------------|--------|--------|
| `Shift+Tab` | `\e[Z` | Ignored | Cannot reverse-tab through entries |
| `Ctrl+Shift+A` | `\e[1;6A` (terminal-dependent) | Ignored | No select-all variant |
| `Ctrl+Shift+B` | `\e[1;6B` | Ignored | |
| `Ctrl+Shift+C` | `\e[1;6C` | Ignored | Common "copy" in terminals |
| `Ctrl+Shift+D` | `\e[1;6D` | Ignored | |
| `Ctrl+Shift+Up` | `\e[1;6A` or `\e[6A` | Ignored | |
| `Ctrl+Shift+Down` | `\e[1;6B` or `\e[6B` | Ignored | |
| `Ctrl+Shift+Left` | `\e[1;6D` or `\e[6D` | Ignored | |
| `Ctrl+Shift+Right` | `\e[1;6C` or `\e[6C` | Ignored | |
| `Shift+Up` | `\e[1;2A` | Ignored | |
| `Shift+Down` | `\e[1;2B` | Ignored | |
| `Shift+Left` | `\e[1;2D` | Ignored | |
| `Shift+Right` | `\e[1;2C` | Ignored | |
| `Alt+Up` | `\e[1;3A` | Ignored | |
| `Alt+Down` | `\e[1;3B` | Ignored | |
| `Alt+Left` | `\e[1;3D` | Ignored | |
| `Alt+Right` | `\e[1;3C` | Ignored | |
| `Alt+Shift+Up` | `\e[1;4A` | Ignored | |
| `Alt+Shift+Down` | `\e[1;4B` | Ignored | |
| `Alt+Shift+Left` | `\e[1;4D` | Ignored | |
| `Alt+Shift+Right` | `\e[1;4C` | Ignored | |
| `Ctrl+Up` | `\e[1;5A` | Ignored | |
| `Ctrl+Down` | `\e[1;5B` | Ignored | |
| `Ctrl+Left` | `\e[1;5D` | Ignored | Common "previous word" in shells |
| `Ctrl+Right` | `\e[1;5C` | Ignored | Common "next word" in shells |
| `Alt+a` | `\ea` | Ignored | Only `ALT-J` and `ALT-K` are recognized |
| `Alt+b` | `\eb` | Ignored | |
| `Alt+c` | `\ec` | Ignored | |
| `Alt+d` | `\ed` | Ignored | |
| `Alt+e` | `\ee` | Ignored | |
| `Alt+f` | `\ef` | Ignored | |
| `Alt+g` | `\eg` | Ignored | |
| `Alt+h` | `\eh` | Ignored | |
| `Alt+i` | `\ei` | Ignored | |
| `Alt+j` | `\ej` | **Recognized** → `ALT-J` | |
| `Alt+k` | `\ek` | **Recognized** → `ALT-K` | |
| `Alt+l` | `\el` | Ignored | |
| `Alt+m` | `\em` | Ignored | |
| `Alt+n` | `\en` | Ignored | |
| `Alt+o` | `\eo` | Ignored | |
| `Alt+p` | `\ep` | Ignored | |
| `Alt+q` | `\eq` | Ignored | |
| `Alt+r` | `\er` | Ignored | |
| `Alt+s` | `\es` | Ignored | |
| `Alt+t` | `\et` | Ignored | |
| `Alt+u` | `\eu` | Ignored | |
| `Alt+v` | `\ev` | Ignored | |
| `Alt+w` | `\ew` | Ignored | |
| `Alt+x` | `\ex` | Ignored | |
| `Alt+y` | `\ey` | Ignored | **The `ALT-y` binding (nav_forward) cannot fire** |
| `Alt+z` | `\ez` | Ignored | **The `ALT-z` binding (nav_back) cannot fire** |
| `Alt+0`–`Alt+9` | `\e0`–`\e9` | Ignored | |
| `Alt+Space` | `\e ` | Ignored | Common "menu" key in some terminals |
| `Alt+Enter` | `\e\r` or `\e\n` | Ignored | |
| `Alt+Backspace` | `\e\x7f` or `\e\b` | Ignored | |
| `Alt+Tab` | (usually captured by WM) | Ignored | |

### 5.3 Control characters not explicitly handled (ignored)

| Key | Raw byte | Status | Notes |
|-----|----------|--------|-------|
| `Ctrl+C` | `\003` | Ignored | Usually intercepted by terminal (SIGINT) |
| `Ctrl+Z` | `\032` | Ignored | Usually intercepted (SIGTSTP) |
| `Ctrl+\` | `\034` | Ignored | Usually SIGQUIT |
| `Ctrl+]` | `\035` | Ignored | |
| `Ctrl+^` | `\036` | Ignored | |
| `Ctrl+_` | `\037` | Ignored | |
| `Ctrl+Space` | `\000` (NUL) | Ignored | |
| `Ctrl+@` | `\000` | Ignored | Same as Ctrl+Space |

### 5.4 Function keys beyond F12 (definitely ignored)

| Key | Typical raw sequence | Status |
|-----|----------------------|--------|
| `F13` | `\e[1;2P` or `\e[25~` | Ignored |
| `F14` | `\e[1;2Q` or `\e[26~` | Ignored |
| `F15` | `\e[1;2R` or `\e[28~` | Ignored |
| `F16` | `\e[1;2S` or `\e[29~` | Ignored |
| `F17` | `\e[15;2~` | Ignored |
| `F18` | `\e[17;2~` | Ignored |
| `F19` | `\e[18;2~` | Ignored |
| `F20` | `\e[19;2~` | Ignored |

### 5.5 Special terminal keys (definitely ignored)

| Key | Typical raw sequence | Status | Notes |
|-----|----------------------|--------|-------|
| `Print Screen` | `\e[28~` or terminal-specific | Ignored | |
| `Scroll Lock` | (varies) | Ignored | |
| `Pause` | (varies) | Ignored | |
| `Menu` | `\e[29~` | Ignored | |
| `Insert` (alternate) | `\e[2;2~` (Shift+Insert) | Ignored | `INS` is recognized for plain Insert |
| `Delete` (alternate) | `\e[3;2~` (Shift+Delete) | Ignored | `DEL` is recognized for plain Delete |
| `Home` (alternate) | `\e[1;2H` (Shift+Home) | Ignored | |
| `End` (alternate) | `\e[1;2F` (Shift+End) | Ignored | |
| `Page Up` (alternate) | `\e[5;2~` (Shift+PgUp) | Ignored | |
| `Page Down` (alternate) | `\e[6;2~` (Shift+PgDn) | Ignored | |

### 5.6 Numeric keypad (partially recognized)

| Key | Typical raw sequence | Status | Notes |
|-----|----------------------|--------|-------|
| `Keypad 0`–`9` (NumLock on) | `0`–`9` | **Ignored** (see §3) | Digits are plain ASCII, dropped by `normalize_key` |
| `Keypad +` | `+` | **Ignored** | Plain ASCII |
| `Keypad -` | `-` | **Ignored** | Plain ASCII |
| `Keypad *` | `*` | **Recognized** → `STAR` | |
| `Keypad /` | `/` | **Ignored** | Plain ASCII |
| `Keypad Enter` | `\r` or `\n` | **Recognized** → `ENTER` | |
| `Keypad .` (NumLock on) | `.` | **Ignored** | Plain ASCII |
| `Keypad Home` (NumLock off) | `\e[1~` or `\eOH` | **Recognized** → `HOME` | |
| `Keypad End` (NumLock off) | `\e[4~` or `\eOF` | **Recognized** → `END` | |
| `Keypad PgUp` (NumLock off) | `\e[5~` | **Recognized** → `PGUP` | |
| `Keypad PgDn` (NumLock off) | `\e[6~` | **Recognized** → `PGDN` | |
| `Keypad Arrow keys` (NumLock off) | `\e[A/B/C/D` | **Recognized** | |
| `Keypad Insert` (NumLock off) | `\e[2~` | **Recognized** → `INS` | |
| `Keypad Delete` (NumLock off) | `\e[3~` | **Recognized** → `DEL` | |

### 5.7 International / Unicode keys (mostly ignored)

| Key | Typical raw sequence | Status | Notes |
|-----|----------------------|--------|-------|
| `§` (paragraph, German) | `\302\247` | **Recognized** → `PARAGRAPH` | Used for new tab |
| `¿` (inverted question, Spanish) | `\302\277` | **Recognized** → `INVERSED_QUESTION_MARK` | |
| `¨` (diaeresis) | `\302\250` | **Recognized** → `DIAERESIS` | |
| `é` (French) | `\303\251` | Ignored | |
| `ü` (German) | `\303\274` | Ignored | |
| `ñ` (Spanish) | `\303\261` | Ignored | |
| `€` (Euro) | `\342\202\254` | Ignored | |
| `→` (arrow) | `\342\206\222` | Ignored | |
| Any other multi-byte UTF-8 | (varies) | Ignored | Most international characters |

### 5.8 Mouse events (definitely ignored)

ftl does not enable tmux mouse mode, and `normalize_key` does not
parse mouse escape sequences. All mouse input is ignored (or handled
by the terminal/tmux directly).

| Event | Typical raw sequence | Status |
|-------|----------------------|--------|
| `Left Click` | `\e[<0;x;yM` | Ignored |
| `Right Click` | `\e[<2;x;yM` | Ignored |
| `Middle Click` | `\e[<1;x;yM` | Ignored |
| `Scroll Up` | `\e[<64;x;yM` | Ignored |
| `Scroll Down` | `\e[<65;x;yM` | Ignored |
| `Mouse Move` | `\e[<32;x;yM` | Ignored |

### 5.9 Terminal-specific escape sequences (partially ignored)

| Key | Terminal | Raw sequence | Status |
|-----|----------|--------------|--------|
| `F1` (xterm) | xterm | `\eOP` | **Recognized** → `F1` |
| `F1` (linux console) | linux | `\e[[A` | **Recognized** → `F1` |
| `F1` (vt100) | vt100 | `\e[11~` | **Recognized** → `F1` |
| `Home` (rxvt) | rxvt | `\e[7~` | Ignored (only `\e[1~` and `\e[H` recognized) |
| `End` (rxvt) | rxvt | `\e[8~` | Ignored (only `\e[4~` and `\e[F` recognized) |
| `Home` (putty) | putty | `\e[H` | **Recognized** → `HOME` |
| `End` (putty) | putty | `\e[F` | **Recognized** → `END` |

---

## 6. Notable Gaps and Their Causes

### 6.1 Plain ASCII letters and digits (CRITICAL)

As documented in §3, `normalize_key` has no `*)` fallback, so all
plain printable ASCII characters (except the 10 explicitly listed:
`\e`, `\177`, `\\`, space, `*`, `@`, `'`, `"`, `\t`, empty/Enter)
are dropped. This breaks the core `j`/`k`/`h`/`l` navigation and
every letter-based binding.

**Cause:** Missing `*) echo "$1" ;;` fallback in the `case`
statement. Likely lost during the `reformat` branch refactor.

**Fix:** Add a fallback (see §7).

### 6.2 Only `ALT-J` and `ALT-K` are recognized

The `case` statement only handles `\ej` and `\ek` for Alt
combinations. All other `Alt+<letter>` sequences are unrecognized.

**Cause:** These two were likely added specifically for a feature
that needed them, and the rest were never added.

**Impact:** The `missing_functionalities` binding registers
`ALT-z` (nav_back) and `ALT-y` (nav_forward), but these **cannot
fire** because `normalize_key` drops `\ez` and `\ey`. The bindings
are dead code.

**Fix:** Add all `Alt+<letter>` cases, or add a pattern like
`$'\e'?` (Alt followed by any single character).

### 6.3 No `Shift+<arrow>` recognition

Shift+arrow is commonly used for selection extension. ftl does not
recognize any `\e[1;2*` sequences.

### 6.4 No `Ctrl+<arrow>` recognition

Ctrl+arrow is commonly used for word-level navigation in shells and
editors. ftl does not recognize `\e[1;5*` sequences.

### 6.5 rxvt Home/End variants not recognized

rxvt emits `\e[7~` for Home and `\e[8~` for End, but `normalize_key`
only recognizes `\e[1~`/`\e[H` (Home) and `\e[4~`/`\e[F` (End).
rxvt users cannot use Home/End.

### 6.6 No mouse support

ftl does not parse mouse escape sequences. Mouse support would
require enabling tmux mouse mode and parsing `\e[<...` sequences in
`normalize_key`.

### 6.7 Most international characters ignored

Only three international characters are recognized (`§`, `¿`, `¨`).
All other multi-byte UTF-8 sequences are unrecognized. This means ftl
cannot bind to these keys, and pressing them stalls the keyboard.

---

## 7. How to Add Support for an Ignored Key

### 7.1 The critical fix: add a `*)` fallback for plain ASCII

This is the highest-priority fix. Without it, the core `j`/`k`/`h`/`l`
bindings do not work.

```bash
ftl::kbd::normalize_key() {
    case "$1" in
        # ... all existing explicit cases ...

        *)
            # Pass through single printable ASCII characters
            # (space through tilde, 0x20-0x7E)
            if [[ "$1" =~ ^[ -~]$ ]] ; then
                echo "$1"
            fi
            # Multi-byte or unrecognized: output nothing
            # (the dispatch overflow guard will reset after 4 keys)
            ;;
    esac
}
```

This ensures that plain letters, digits, and punctuation are passed
through to `dispatch`, where they can match trie entries.

### 7.2 Add Alt+letter recognition

To support `ALT-z`, `ALT-y`, and all other `Alt+<letter>`:

```bash
# Add these cases (or use a pattern):
$'\ea')  echo "ALT-A" ;;
$'\eb')  echo "ALT-B" ;;
$'\ec')  echo "ALT-C" ;;
# ... for all letters ...
$'\ez')  echo "ALT-Z" ;;
```

Alternatively, use a single pattern with a character class. However,
Bash `case` patterns do not support regex; they support glob
patterns. The pattern `$'\e'[a-z]` would match `\e` followed by any
lowercase letter, but the syntax is `$'\e'[a-z]` which Bash treats as
the concatenation of `$'\e'` and the glob `[a-z]`. This works:

```bash
$'\e'[a-z])  echo "ALT-${1:1:1}" | tr 'a-z' 'A-Z' ;;
```

But this is less readable than explicit cases. The explicit approach
is recommended for clarity.

### 7.3 Add Shift+arrow and Ctrl+arrow recognition

```bash
$'\e[1;2A')  echo "SHIFT-UP" ;;
$'\e[1;2B')  echo "SHIFT-DOWN" ;;
$'\e[1;2D')  echo "SHIFT-LEFT" ;;
$'\e[1;2C')  echo "SHIFT-RIGHT" ;;
$'\e[1;5A')  echo "CTL-UP" ;;
$'\e[1;5B')  echo "CTL-DOWN" ;;
$'\e[1;5D')  echo "CTL-LEFT" ;;
$'\e[1;5C')  echo "CTL-RIGHT" ;;
```

### 7.4 Add rxvt Home/End variants

```bash
# Modify the existing HOME and END cases:
$'\e[1~' | $'\e[H' | $'\e[7~')  echo "HOME" ;;
$'\e[4~' | $'\e[F' | $'\e[8~')  echo "END" ;;
```

### 7.5 Add Shift+Tab

```bash
$'\e[Z')  echo "SHIFT-TAB" ;;
```

### 7.6 Write tests

After each change, add tests to `test/unit/test_keyboard.sh`:

```bash
test_normalize_plain_letter() {
    local result
    result=$(ftl::kbd::normalize_key "j")
    ftl::test::assert_eq "j" "$result" "plain j passes through"
}

test_normalize_alt_z() {
    local result
    result=$(ftl::kbd::normalize_key $'\ez')
    ftl::test::assert_eq "ALT-Z" "$result" "Alt+Z normalized"
}

test_normalize_shift_tab() {
    local result
    result=$(ftl::kbd::normalize_key $'\e[Z')
    ftl::test::assert_eq "SHIFT-TAB" "$result" "Shift+Tab normalized"
}
```

### 7.7 Add an integration test that exercises `get_key` + `normalize_key`

The current tests bypass `normalize_key`. Add a test that simulates
the full `get_key` path for a plain letter:

```bash
test_get_key_passes_plain_letter() {
    # Simulate stdin with a "j"
    ftl::kbd::get_key <<<"j" 2>/dev/null || true
    # Note: read -rsn 1 from a here-string may behave differently;
    # a more robust approach uses a coprocess or a pipe with sleep.
    # The key assertion: ftl_kbd_current_key should be "j", not empty.
    ftl::test::assert_eq "j" "$ftl_kbd_current_key" "get_key preserves plain j"
}
```

This test would have caught the §3 bug.

---

## 8. Terminal Compatibility Notes

Different terminals emit different escape sequences for the same
logical key. The table below shows the variants that `normalize_key`
should handle for common keys.

| Key | xterm | rxvt | putty | linux console | tmux |
|-----|-------|------|-------|---------------|------|
| `Up` | `\e[A` | `\e[A` | `\e[A` | `\e[A` | `\e[A` or `\eOA` |
| `Down` | `\e[B` | `\e[B` | `\e[B` | `\e[B` | `\e[B` or `\eOB` |
| `Home` | `\e[H` | `\e[7~` | `\e[H` | `\e[1~` | `\e[H` or `\eOH` |
| `End` | `\e[F` | `\e[8~` | `\e[F` | `\e[4~` | `\e[F` or `\eOF` |
| `F1` | `\eOP` | `\e[11~` | `\e[11~` | `\e[[A` | `\eOP` |
| `F5` | `\e[15~` | `\e[15~` | `\e[15~` | `\e[[E` | `\e[15~` |

**Current coverage:** `normalize_key` handles the xterm and linux
console variants for most keys. It does **not** handle the rxvt
variants for Home (`\e[7~`) and End (`\e[8~`).

---

## 9. Diagnostic Procedure

To determine the raw byte sequence a key produces in your terminal:

### Method 1: `cat -v`

```bash
cat -v
# press the key
# Ctrl-C to exit
```

`cat -v` shows non-printing characters as `^X` (for control chars) or
`M-X` (for chars with the high bit set). For example, Shift+Tab
shows as `^[[Z`.

### Method 2: `read` + `xxd`

```bash
read -rsn 5 key
echo "$key" | xxd
```

Press the key. The `xxd` output shows the exact bytes.

### Method 3: ftl's own diagnostic

Add this temporary binding to `~/.config/ftl/etc/bindings/diag`:

```bash
ftl::plugin::diag::show_key() {
    ftl::log::info "raw=[$ftl_kbd_raw_key] normalized=[$ftl_kbd_current_key] hex=[$(echo -n "$ftl_kbd_raw_key" | xxd -p)]"
    ftl::list::render
}
ftl::kbd::bind	ftl	ftl	"LEADER D k"	ftl::plugin::diag::show_key	"show raw key"
```

Then press `LEADER D k` followed by the key you want to diagnose.
Check the log with `LEADER d d` (toggle debug) or
`:show_cmd_log`.

### Method 4: Direct `normalize_key` test

```bash
FTL_CFG=config/ftl bash -c '
source "$FTL_CFG/etc/core/modules/keyboard.sh"
for key in "j" "a" "5" ; do
    result=$(ftl::kbd::normalize_key "$key")
    echo "input=[$key] output=[$result]"
done
'
```

This shows, for each raw byte, what `normalize_key` outputs. If the
output is empty, the key is unrecognized.

---

## Summary of Recommended Fixes (Priority Order)

1. **Add a `*)` fallback for plain ASCII** (§7.1). This is critical —
   without it, `j`/`k`/`h`/`l` and all letter bindings are broken.
   This is the single highest-priority fix.

2. **Add Alt+letter recognition** (§7.2). The `ALT-z` and `ALT-y`
   bindings in `missing_functionalities` are dead code without this.

3. **Add rxvt Home/End variants** (§7.4). rxvt users cannot use
   Home/End.

4. **Add Shift+arrow and Ctrl+arrow recognition** (§7.3). Common key
   combinations that users expect.

5. **Add Shift+Tab** (§7.5).

6. **Add integration tests that exercise `get_key` + `normalize_key`**
   (§7.7). The current tests bypass `normalize_key`, which is why
   this bug was not caught.

7. **Consider adding mouse support** (parse `\e[<...` sequences,
   enable tmux mouse mode). This is a larger feature.

8. **Document the recognized keys** in the man page, so users know
   what they can bind.

These fixes would resolve the "silently dropped keys" issue for the
most common cases and make ftl's keyboard handling robust and
predictable.
