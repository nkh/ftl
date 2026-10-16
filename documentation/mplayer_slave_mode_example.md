# MPlayer Slave Mode Example

Control MPlayer through its slave interface and periodically display position, length and percentage played.

```bash
#!/usr/bin/env bash

# Control MPlayer through its slave interface and periodically
# display position, length and percentage played.

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

# Start mplayer:
# -slave : accept commands on stdin/FIFO
# -quiet : reduce output noise
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

            # Print status once we have all three values
            [[ ${pos:-} && ${len:-} ]] || continue

            printf '\rpos=%7.1f sec  len=%7.1f sec  pct=%3d%%' \
                   "$pos" "$len" "$pct"
            ;;
    esac
done &

reader_pid=$!

# Poll mplayer once per second.
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

Usage:

```bash
./mplayer-status.sh song.mp3
```

Output:

```text
pos=  126.5 sec  len=  294.8 sec  pct= 42%
```

Optional time formatting:

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

Example display:

```text
02:06.5 of 04:54.8 (42%)
```
