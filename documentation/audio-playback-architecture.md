# Audio Playback Control Architecture (MPlayer vs MPV)

## Goal

Build a command-line controlled audio player that:

- Runs persistently in the background
- Can be controlled from multiple shell invocations
- Supports play, pause, seek, status, ETA and playlists
- Handles filenames containing spaces
- Avoids parsing human-oriented status output

## Executive Summary

MPlayer slave mode can be used successfully for simple automation, but its IPC model is primitive. A Bash coprocess only works inside a single shell process, and a FIFO-based design becomes awkward when bidirectional communication is required.

For a long-lived audio service controlled by multiple scripts, MPV is generally the cleaner architecture because it provides a JSON IPC protocol over a Unix socket.

---

## Understanding MPlayer Status Output

Example:

```text
A: 126.5 (02:06.5) of 294.8 (04:54.8)  0.6%
```

Meaning:

| Field     | Meaning                                              |
| --------- | ---------                                            |
| A:        | Audio clock                                          |
| 126.5     | Current position in seconds                          |
| (02:06.5) | Current position formatted                           |
| 294.8     | Total duration in seconds                            |
| (04:54.8) | Total duration formatted                             |
| 0.6%      | Audio/video sync correction, not playback percentage |

Actual playback percentage is:

```text
100 * current_position / total_duration
```

---

## Why a Bash Coprocess Is Not Enough

A typical approach is:

```bash
coproc MP {
    mplayer -idle -slave -quiet
}
```

Bash creates:

```text
MP[0]  read from mplayer
MP[1]  write to mplayer
```

These file descriptors only exist inside the shell that created them.

This works:

```bash
echo pause >&"${MP[1]}"
```

This does not:

```bash
player play song.mp3
player pause
```

because each command starts a new shell process.

Therefore a coprocess is only suitable when a single shell remains alive for the entire session.

---

## MPlayer Slave Mode

Start MPlayer:

```bash
mplayer \
    -idle \
    -slave \
    -quiet \
    -novideo \
    -vo null
```

The `-idle` option keeps MPlayer running after playback finishes.

---

## FIFO-Based Architecture

Create a command FIFO:

```bash
fifo=/tmp/mplayer.cmd
rm -f "$fifo"
mkfifo "$fifo"
```

Start MPlayer:

```bash
mplayer \
    -idle \
    -slave \
    -quiet \
    -input file="$fifo" \
    -novideo \
    -vo null
```

Any shell can now send commands.

Pause:

```bash
printf 'pause\n' > "$fifo"
```

Seek forward:

```bash
printf 'seek 10\n' > "$fifo"
```

Seek backward:

```bash
printf 'seek -10\n' > "$fifo"
```

Quit:

```bash
printf 'quit\n' > "$fifo"
```

---

## Loading Files Safely

```bash
file='/music/Artist Name/My Song.mp3'
escaped=${file//\"/\\\"}

printf 'loadfile "%s"\n' "$escaped" > "$fifo"
```

Supports spaces and embedded quotes.

---

## Useful Slave Commands

```text
pause
seek 10
seek -10
get_time_pos
get_time_length
get_percent_pos
stop
quit
```

---

## Querying Status

Current position:

```text
get_time_pos
```

Possible reply:

```text
ANS_TIME_POSITION=126.5
```

Duration:

```text
ANS_LENGTH=294.8
```

Percentage:

```text
ANS_PERCENT_POSITION=42
```

---

## Limitations of MPlayer IPC

Advantages:

- Lightweight
- Available everywhere MPlayer is installed
- Simple command set

Disadvantages:

- No native socket IPC
- Text protocol only
- JSON not supported
- Multiple-client access is awkward
- Bidirectional communication often requires helper processes
- Property discovery is limited

---

# MPV Architecture

MPV is the modern descendant of MPlayer and provides a significantly better automation interface.

## Key Advantages

### Native IPC Socket

```bash
--input-ipc-server=/tmp/mpv.sock
```

No FIFO management required.

### Structured JSON Protocol

Commands and responses are machine-readable.

### Bidirectional Communication

Any process can connect to the socket.

### Better Status Queries

Properties include:

```text
time-pos
duration
percent-pos
pause
filename
media-title
volume
playlist-pos
```

### Easier Integration

MPV works naturally with:

- Bash
- Python
- Go
- Rust
- Node.js

---

## Starting MPV

```bash
mpv \
    --no-video \
    --idle=yes \
    --input-ipc-server=/tmp/mpv.sock
```

---

## Pause and Resume

Toggle pause:

```bash
echo '{"command":["cycle","pause"]}' | \
    socat - /tmp/mpv.sock
```

Pause explicitly:

```bash
echo '{"command":["set_property","pause",true]}' | \
    socat - /tmp/mpv.sock
```

Resume:

```bash
echo '{"command":["set_property","pause",false]}' | \
    socat - /tmp/mpv.sock
```

---

## Seeking

Forward 10 seconds:

```bash
echo '{"command":["seek",10]}' | \
    socat - /tmp/mpv.sock
```

Backward 10 seconds:

```bash
echo '{"command":["seek",-10]}' | \
    socat - /tmp/mpv.sock
```

---

## Loading Files

Replace current playback:

```bash
printf '{"command":["loadfile","%s","replace"]}\n' "$file" | \
    socat - /tmp/mpv.sock
```

Append to playlist:

```bash
printf '{"command":["loadfile","%s","append-play"]}\n' "$file" | \
    socat - /tmp/mpv.sock
```

---

## Reading Status

Current position:

```bash
echo '{"command":["get_property","time-pos"]}' | \
    socat - /tmp/mpv.sock
```

Example response:

```json
{"data":126.5,"error":"success"}
```

Duration:

```bash
echo '{"command":["get_property","duration"]}' | \
    socat - /tmp/mpv.sock
```

Percentage:

```bash
echo '{"command":["get_property","percent-pos"]}' | \
    socat - /tmp/mpv.sock
```

---

## Remaining Time

```text
remaining = duration - position
```

Example:

```text
294.8 - 126.5 = 168.3 seconds
```

---

## ETA Calculation

```text
eta = now + remaining
```

Example:

```bash
remaining=168

date -d "@$(( $(date +%s) + remaining ))"
```

---

## Recommended Design

### Simple Script

```text
Shell Script
    |
    +--> MPlayer
           |
           +--> FIFO
```

### Robust Multi-Process Solution

```text
Shell Scripts
      |
      +--> MPV
               |
               +--> JSON IPC Socket
```

## Recommendation

If the application only needs a few playback commands and minimal status reporting, MPlayer slave mode is adequate.

If the application needs reliable status queries, multiple clients, playlists, metadata access, structured replies, and long-term maintainability, MPV is the superior architecture.

