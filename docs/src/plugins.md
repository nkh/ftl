# Plugin API

ftl has six plugin categories. Each is a Bash script (or executable)
placed in a known directory; ftl auto-sources or auto-discovers them at
startup. Plugins extend ftl without modifying the core.

## The six categories

| Category | Directory | Contract | Loaded by |
|----------|-----------|----------|-----------|
| **Filters** | `filters/` | Overrides `ftl::filter::apply_external` | `ftl::filt::load_external` (called via `fe`) |
| **Etags** | `etags/` | Defines `etag_dir()` and `etag_tag()` | `source "$FTL_CFG/etc/etags/<name>"` |
| **Generators** | `generators/` | Executable; produces thumbnail files | `generators/generator` driver |
| **Viewers** | `viewers/` | Defines viewer functions (`pimage`, `ppdf`, …) | `source "$FTL_CFG/viewers/core"` |
| **Commands** | `commands/` | Sourced or executable; user commands | `ftl::cmd::dispatch_command` |
| **Bindings** | `bindings/` | Calls `ftl::kbd::bind` | auto-sourced at startup from `etc/bindings/` and `bindings/` |

Each category has a deeper-dive page:
[Filters](writing-filters.md), [Etags](writing-etags.md),
[Viewers](writing-viewers.md), [Commands](writing-commands.md),
[Bindings](writing-bindings.md). Generators are executables invoked by
`generators/generator`; each takes the source file and a thumbnail output
path and writes a thumbnail.

## How plugins are loaded

At startup, `ftl_setup` sources `etc/ftlrc`, which sets defaults and
registers the built-in bindings. The end of `ftlrc` auto-sources every
file in `etc/bindings/` and `bindings/`:

```bash
for b in $(fd . "$FTL_CFG/etc/bindings" --type f | sort -u) ; do source "$b" ; done
for b in $(fd . "$FTL_CFG/bindings" --type f | sort -u) ; do source "$b" ; done
```

Etags, filters, viewers, and commands are loaded lazily — only when
selected at runtime (etags via `zT`, filters via `fe`, viewers when
sourcing `viewers/core`, commands when invoked from the `:` prompt).

## The manifest format

There is no separate manifest file. A plugin **is** its manifest: the
script itself defines the functions and registers itself by overriding
the placeholder. For example, a filter plugin ends with:

```bash
ftl::filter::apply_external() { ftl::plugin::my_filter::filter ; }
```

This re-assignment is what makes the listing pipeline dispatch to your
plugin.

## Namespace conventions

- Plugin functions should be namespaced under `ftl::plugin::<name>::*`.
  For example `ftl::plugin::by_regexp::filter`.
- Plugin global variables should be `ftl_plugin_<name>_*` or simply be
  declared locally to the plugin (e.g. `keep`, `PWDS` in `by_regexp`).
- Etag and viewer plugins use a flatter convention (functions named
  `etag_dir`/`etag_tag` or `pimage`/`ppdf`) because they're sourced into
  a single namespace at activation time. This is a historical artifact.

## Creating a new plugin

1. Pick a category and a name (e.g. `filters/my_filter`).
2. Create the file under `$FTL_CFG/filters/my_filter`.
3. Implement the contract (see the per-category page).
4. Make it executable if it's a generator or an executable command;
   otherwise just leave it as a sourced Bash script.
5. Restart ftl (or re-source the file in a running session to test).

For bindings specifically, no restart is strictly needed: you can
`source "$FTL_CFG/etc/bindings/my_binding"` from the `:` prompt to load
it live.
