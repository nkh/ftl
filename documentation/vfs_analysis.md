feature: virtual directories support arbitrary file collections
	? difference between a virtual directory and a file list? a virtual directory and a directory with virtual files? a virtual directory and a directory with symlinks?

	Expand virtual directories into a general mechanism for browsing a collection of files

	A virtual directory should be constructible from:

	* individual files
	* directories
	* recursively collected files
	* search results
	* selected files
	* diff results
	* results from other FTL commands
	* files changed by a Git commit
	* file/directory that does not necessarily correspond to a physical file
		this is how virtual files work but the content needs to be defined in an ftl script, change
		it so any process can generate a virtual file, not just ftl scripts
	* created at start time and created dynamically at run time

	For example:

	```text
	ftl -v file1 file2 file3
	ftl -v file1 file2 file3 -o output_dir
	```

	Support options for controlling how the files are organized:

	* `-v` — add files/directories to a virtual directory
	* `-r` — recursively add files from directories
	* `-t` — put groups of files in separate tabs
	* option to preserve the original directory structure
	* option to flatten the structure and show only the files
		which means a display name corresponds to a real file

	Allow multiple virtual directories to exist simultaneously, including different virtual directories in different tabs.
		virtual directories in virtual directories?
		
	This would allow, for example, one tab to contain search results, another to contain files from a diff, and another to contain a manually selected group of files.

	Virtual directories should also support grouping files into subdirectories, allowing files to be sorted into categories within the virtual directory.

	### Missing files

	Some files or directories supplied as arguments may not exist.

	Provide an option to create missing files/directories when constructing the virtual directory.

	### creation time

	can be at start up with arguments or at run time with a command, eg: selected files

	### display

	A virtual directory should be displayed in the same way as a physical directory, with the same options for sorting, filtering, and previewing files.

	files in a virtual directory should be displayed with their original names and paths, even if they are located in different directories or do not exist on disk.
		optionally not as default!

	files in a virtual directory can be displayed with another name or path

	A virtual directory contains files that may not exist on disk or files located in different directories, what they are and where they come from should be displayed
		option or etag

	Sorting and filtering should be available for virtual directories, just like for physical directories.
		sorting is a bit more complicated since the files may come from different directories and have different attributes
			eg: should files be sorted by their original directory
			eg: should files be sorted by their original name or by their virtual name

feature: more Git integration and Git-based virtual directories

	Expand Git support by making Git operations able to produce file collections that can then be browsed through FTL's virtual-directory mechanism.

	### Files changed by a commit

	Add an option to select the files changed by a specific commit and open them in FTL:

	```text
	ftl -g HEAD~1
	ftl -g <commit>
	```

	The resulting files should be displayed as a virtual directory containing only the files changed by that commit.

	This should work for any commit, not only `HEAD`.

	The same mechanism could be used to build virtual directories containing files from different commits or categories, making it possible to compare or browse groups of changed files.

	### Open Git tools from FTL

	Provide commands for opening the current file, selection, or virtual-directory contents in external Git tools, such as:

	* Vim with an appropriate Fugitive command
	* tig
	* git history
	* fgl

	Investigate integration or useful ideas from:

	* [https://github.com/unhappychoice/gitlogue](https://github.com/unhappychoice/gitlogue)
	* [https://github.com/modem-dev/hunk](https://github.com/modem-dev/hunk)
	* [https://github.com/areese801/git-visual-timeline](https://github.com/areese801/git-visual-timeline)

1. Problem Statement

You have a Bash file manager with a plugin system.

Requirements:

Plugins execute arbitrary shell commands.
Plugins cannot be modified.
Plugins must operate on normal filesystem paths.
Some entries represent real files elsewhere.
Some entries are generated dynamically.
Views should ideally disappear automatically when the file manager exits.
Dynamic generation is preferred over periodically rebuilding trees.
The solution must scale to large search results and virtual collections.

This is a filesystem integration problem, not merely a data structure problem.

2. File Manager Requirements

Typical operations a file manager must support:

| Operation                    | Required |
|------------------------------|----------|
| List directory               | Yes      |
| Stat files                   | Yes      |
| Open file                    | Yes      |
| Read file                    | Yes      |
| Write file                   | Maybe    |
| Rename                       | Yes      |
| Copy                         | Yes      |
| Move                         | Yes      |
| Delete                       | Yes      |
| Symlink creation             | Yes      |
| Search results               | Yes      |
| Virtual collections          | Yes      |
| Metadata display             | Yes      |
| External editor integration  | Yes      |
| External command integration | Yes      |
| Drag-and-drop equivalent     | Yes      |
| Multi-selection              | Yes      |

| Requirement                             | Importance |
|-----------------------------------------|------------|
| Real paths visible to shell commands    | Critical   |
| Generated files                         | Critical   |
| Existing files from arbitrary locations | Critical   |
| No plugin modifications                 | Critical   |
| Dynamic directory contents              | Desirable  |
| Automatic cleanup                       | Desirable  |
| Large result sets                       | Possible   |

A virtual filesystem must not break any of the above.

3. FUSE Investigation
Strengths

FUSE provides:

readdir()
getattr()
lookup()
open()
read()
write()
readlink()


dynamically.

The filesystem may not physically exist.

Example:

/search/action/
├── result1
├── result2
└── summary.txt


can be generated entirely on demand.

Characteristics

| Feature             | Result    |
|---------------------|-----------|
| Dynamic directories | Excellent |
| Dynamic files       | Excellent |
| Existing files      | Excellent |
| Automatic cleanup   | Excellent |
| Huge virtual trees  | Excellent |
| Complexity          | High      |

| Best Use Cases   |
|------------------|
| Search results   |
| Saved queries    |
| Smart folders    |
| Dynamic metadata |
| Tags             |
| Collections      |

4. OverlayFS Investigation

OverlayFS combines directories.

Example:

lower/
upper/


become:

merged/

Characteristics

| Feature            | Result    |
|--------------------|-----------|
| Merge trees        | Excellent |
| Dynamic generation | No        |
| Existing files     | Excellent |
| Transparency       | Excellent |

| Best Use Cases                             |
|--------------------------------------------|
| Adding generated files to an existing tree |
| Writable overlays                          |
| Session-specific modifications             |

5. Bind Mount Investigation

Example:

touch target
mount --bind source target


or

mkdir target
mount --bind source_dir target

Characteristics

| Feature           | Result    |
|-------------------|-----------|
| Existing files    | Excellent |
| Generated files   | No        |
| Transparency      | Excellent |
| Per-file overhead | High      |
| Dynamic           | No        |

Target Existence

The target must exist beforehand.

File:

touch target


Directory:

mkdir target

Existing Content

Before:

echo hello > target


After:

mount --bind source target


hello becomes hidden.

It is not deleted.

After:

umount target


hello reappears.

Operation Comparison

Suppose:

original:
    /data/file

bind mount:
    /view/file

| Operation  | Original          | Bind              |
|------------|-------------------|-------------------|
| Pathcat    | same data         | same data         |
| grep       | same data         | same data         |
| vim        | edits file        | edits same file   |
| chmod      | affects file      | affects same file |
| chown      | affects file      | affects same file |
| truncate   | affects file      | affects same file |
| stat inode | same inode        | same inode        |
| rm         | removes file      | removes same file |
| find       | sees regular file | sees regular file |
| readlink   | not a symlink     | not a symlink     |

To most software, the bind-mounted path appears to be a normal file.

Lifetime

Normal bind mount:

survives process exit
survives file-manager crash
survives until umount


Not suitable if you want automatic cleanup.

Mount Namespace Variant

Instead:

unshare --mount


Create all bind mounts inside a private mount namespace.

Then:

file manager exits
        ↓
namespace dies
        ↓
all bind mounts disappear


Very attractive for temporary views.

Fit for your project

Good for exposing existing files.

Poor for dynamically generated files.

Poor if thousands of individual files require mounts.

6. Hard-link and Symlink Comparison

| Feature                  | Hard Link | Symlink |
|--------------------------|-----------|---------|
| Cross-filesystem         | No        | Yes     |
| Detectable as link       | No        | Yes     |
| Cleanup required         | Yes       | Yes     |
| Points anywhere          | No        | Yes     |
| Very cheap               | Yes       | Yes     |
| References existing file | Yes       | Yes     |

## Hard Links

Good for:

same filesystem
few files
persistent views


Bad for virtual filesystems.

## Symlinks

Good for:

search results
collections
references


Very simple.

Easy to generate from Bash.

7. File Lifecycle Implications

| Method          | LifetimeHard          |
|-----------------|-----------------------|
| link            | Permanent             |
| Symlink         | Permanent             |
| Bind mount      | Until unmounted       |
| OverlayFS       | Until unmounted       |
| tmpfs           | Until removed/reboot  |
| Mount namespace | Lifetime of namespace |
| FUSE            | Lifetime of daemon    |

The most attractive temporary mechanisms are:

FUSE
Mount namespaces

because cleanup is automatic.

8. Architectural Conclusions

The mistake is to think of the mechanisms as competitors.

They're complementary.

9. Combining Technologies Intelligently
FUSE + Symlinks

FUSE dynamically exposes:

search/
└── result1


where:

result1


is actually a symlink.

Advantages:

dynamic listing
almost no mount overhead
simple implementation

Useful for:

searches
tags
bookmarks
recent files

FUSE + Bind Mounts

FUSE presents:

recent/
├── file1
├── file2
└── file3


Internally the file manager creates bind mounts.

Advantages:

perfect transparency
tools cannot detect symlink

Disadvantages:

one mount per file

Good for small collections.

OverlayFS + FUSE

FUSE:

/search/action


generates content.

OverlayFS:

generated/
+
real/
=
merged/


creates a unified tree.

Useful when some content is computed and some already exists.

Mount Namespace + Bind Mounts

Potentially very attractive.

The file manager starts:

unshare --mount


Inside that namespace:

mount --bind ...
mount --bind ...
mount --bind ...


When the file manager exits:

namespace dies
all mounts disappear


Automatic cleanup.

No stale state.

10. Ten Valuable VFS Use Cases
1. Saved Searches
/search/action
/search/comedy
/search/new


Dynamic result sets.

2. Tag Views
/tags/work
/tags/favorite


Files appear in multiple locations.

3. Recent Files
/recent


Generated from history.

4. Duplicate Groups
/duplicates/group1
/duplicates/group2


Physical files may be scattered.

5. Query Results
/query/rating>4


Similar to database views.

6. Metadata Files
movie.mkv
movie.info
movie.json
movie.tags


Generated on demand.

7. Playlists
/playlists/action


Virtual collections.

8. Git Views
/git/changed
/git/untracked


Mapped from git status.

9. Archives
/archive.zip/


Browsable without extraction.

10. Project Views
/project/foo


Combining files from many unrelated locations.

11. Proposed Architecture

Given your requirements, I would not use only one technology.

Layer 1: FUSE (Main Interface)

Expose:

/ftl
├── searches
├── tags
├── recent
├── projects
└── metadata


Responsibilities:

readdir()
lookup()
generated files
dynamic views
Layer 2: Symlink Backing

For most real files:

/ftl/searches/action/movie1
    ->
/movies/action/movie1


Advantages:

cheap
scales to millions of entries
easy to generate
Layer 3: Optional Bind Mount Backing

For paths where plugins break on symlinks:

/ftl/native/*


Use bind mounts.

Only where necessary.

Not by default.

Layer 4: Private Mount Namespace

Run file manager inside:

unshare --mount


Benefits:

automatic cleanup
bind mounts disappear
overlays disappear
Layer 5: OverlayFS (Optional)

Use only for writable session views:

real tree
+
temporary modifications
=
merged view


Not as the primary VFS.

Final Recommendation

For your particular file manager:

                 FUSE
                   │
        ┌──────────┼──────────┐
        │          │          │
    Generated   Symlinked   Bind-mounted
      files       files        files
        │          │          │
        └──────────┼──────────┘
                   │
          Mount Namespace
                   │
             Automatic
               Cleanup


This gives:

- dynamic virtual directories
- generated metadata files
- references to arbitrary files
- compatibility with external plugins
- automatic lifetime management
- scalability to very large collections

while avoiding the need to bind-mount thousands of files or constantly regenerate materialized directory trees.

## Use Cases

* Presenting a unified inbox folder containing files from various browser directories.
* Displaying multiple revision versions of a single document side-by-side in a virtual folder for comparison.
* Exposing the contents of compressed archive files (ZIP, TAR, 7Z) as standard readable directories without permanent extraction.
* Listing all currently open network shares and cloud storage endpoints under a single virtual root node.
* Displaying a virtual folder containing only items modified within the last twenty-four hours.
* Exhibiting a playlist-style virtual directory for audio and video files streamed from remote servers.
* Exposing database tables or records as virtual comma-separated or JSON files inside a structured directory.
	vfs exists
* Showing a virtual folder containing broken symbolic links or missing file references for debugging.
* Grouping files matching specific file size thresholds into logical tiers for quick cleanup.
* Providing a virtual timeline view where files are automatically bucketed into monthly folders based on creation dates.
* Displaying a virtual folder of favorite or starred items pinned by the user.
* Presenting a virtual directory of clipboard history items saved as individual text or image files.
* Rendering remote Git repository trees without cloning the full repository history locally.
	latest projects under a single virtual directory
* Rendering a filesystem representation of a hierarchical JSON or XML configuration tree.
	there's a file sytem for that
** the virtual element, and non virtual, can be save in a config and recreated later
** special preview for some virtual entries
** special commands registred for some virtual entries

* **Tar/Zip/RPM Decompression:** Navigating into `archive.tar/` triggers the TAR VFS plugin, which reads the archive header in memory, populates a virtual directory tree, and extracts files on the fly when accessed, cleaning up temporary instances upon closure.
### FUSE (Filesystem in Userspace)

FUSE allows non-privileged users to create fully functional virtual file systems without writing kernel-level code.

* **Architecture:** The FUSE kernel module acts as a bridge. When an application interacts with a mount point managed by FUSE, system calls are forwarded via a character device to a userspace daemon.
* **Use Cases:** Tools like `sshfs` (mounting remote servers over SSH), `rclone` (mounting cloud storage buckets like S3 or Google Drive as local directories), and custom union or overlay filesystems operate via FUSE. The operating system kernel perceives standard file operations, while the underlying daemon dynamically generates files, aggregates disparate directories, or applies real-time transformations.


