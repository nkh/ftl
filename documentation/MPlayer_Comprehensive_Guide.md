# MPlayer Status Line and Slave Mode Guide

## Understanding the Status Line

Given:

```text
A: 126.5 (02:06.5) of 294.8 (04:54.8)  0.6%
```

The fields mean:

| Field       | Meaning                                                          |
| ---------   | ---------                                                        |
| `A:`        | Audio clock is being used for playback timing.                   |
| `126.5`     | Current playback position in seconds.                            |
| `(02:06.5)` | Current playback position formatted as `MM:SS.t`.                |
| `294.8`     | Total media length in seconds.                                   |
| `(04:54.8)` | Total media length formatted as `MM:SS.t`.                       |
| `0.6%`      | Audio/video synchronization correction, not playback percentage. |

### Example

```text
A: 126.5 (02:06.5) of 294.8 (04:54.8)  0.6%
```

Current playback percentage:

```text
126.5 / 294.8 * 100 = 42.9%
```

The trailing `0.6%` does **not** represent progress.

---

## Why Use Slave Mode?

The status line is intended for humans.

For scripts, use slave mode and query MPlayer directly:

```bash
mplayer -slave -quiet file.mp3
```

Useful commands:

```text
get_time_pos
get_time_length
get_percent_pos
pause
seek 10
seek -10
quit
```

Typical responses:

```text
ANS_TIME_POSITION=126.5000
ANS_LENGTH=294.8000
ANS_PERCENT_POSITION=42
```

---

## Complete Bash Example

This script:

- starts MPlayer in slave mode
- queries playback status every second
- displays current position, total length, and percentage played
- does not parse the human-readable status line

```bash
#!/usr/bin/env bash

set -u

file=$1

fifo=$(mktemp -u /tmp/mplayer.XXXXXX)
mkfifo "$fifo"

cleanup()
{
    [[ -n ${mpid:-} ]] && kill "$mpid" 2>/dev/null
    rm -f "$fifo"
}

trap cleanup EXIT INT TERM

mplayer -slave -quiet -input file="$fifo" "$file" |
while IFS= read -r line
 do
    case $line in
        ANS_TIME_POSITION=*)
            pos=${line#*=}
            ;;

        ANS_LENGTH=*)
            len=${line#*=}
            ;;

        ANS_PERCENT_POSITION=*)
            pct=${line#*=}

            [[ ${pos:-} && ${len:-} ]] || continue

            printf '\rpos=%7.1f sec  len=%7.1f sec  pct=%3d%%' \
                   "$pos" "$len" "$pct"
            ;;
    esac
 done &

reader_pid=$!

while kill -0 "$reader_pid" 2>/dev/null
 do
    {
        echo get_time_pos
        echo get_time_length
        echo get_percent_pos
    } > "$fifo"

    sleep 1
 done

wait "$reader_pid"
echo
```

---

## Formatting Seconds as MM:SS.t

```bash
sec_to_time()
{
    awk -v s="$1" '
    BEGIN {
        m = int(s / 60)
        s -= m * 60
        printf "%02d:%04.1f", m, s
    }'
}
```

Example:

```bash
sec_to_time 126.5
```

Output:

```text
02:06.5
```

---

## Display Similar to MPlayer

Replace the printf in the script with:

```bash
printf '\r%s of %s (%3d%%)' \
       "$(sec_to_time "$pos")" \
       "$(sec_to_time "$len")" \
       "$pct"
```

Example output:

```text
02:06.5 of 04:54.8 (42%)
```

---

## Commands Worth Knowing

Query current position:

```bash
echo get_time_pos > "$fifo"
```

Query total length:

```bash
echo get_time_length > "$fifo"
```

Query percentage:

```bash
echo get_percent_pos > "$fifo"
```

Seek forward 30 seconds:

```bash
echo 'seek 30' > "$fifo"
```

Seek backward 10 seconds:

```bash
echo 'seek -10' > "$fifo"
```

Toggle pause:

```bash
echo pause > "$fifo"
```

Quit:

```bash
echo quit > "$fifo"
```
