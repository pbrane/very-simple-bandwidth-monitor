#!/usr/bin/env bash
set -euo pipefail

TOTAL_HOURS=168  # 7 days
LOG_FILE="$HOME/bandwidth-log.csv"
PID_FILE="$HOME/.bandwidth-monitor.pid"

echo $$ > "$PID_FILE"
trap 'rm -f "$PID_FILE"; echo "Monitoring stopped." >&2; exit 0' INT TERM

if [[ ! -f "$LOG_FILE" ]]; then
    echo "timestamp,ping_ms,download_mbps,upload_mbps,server" > "$LOG_FILE"
fi

echo "Bandwidth monitor started (PID $$)"
echo "Logging to: $LOG_FILE"
echo "Will run 3–5 tests per hour for $TOTAL_HOURS hours (7 days)."
echo "Stop with: kill \$(cat ~/.bandwidth-monitor.pid)"

run_test() {
    local timestamp
    timestamp=$(date "+%Y-%m-%d %H:%M:%S")
    echo "[$timestamp] Running speed test..."

    if result=$(speedtest-cli --csv --csv-delimiter ',' 2>/dev/null); then
        read -r ping download_bps upload_bps server < <(
            python3 -c "
import csv, io, sys
row = list(csv.reader(io.StringIO(sys.argv[1])))[0]
print(row[5], row[6], row[7], row[1])
" "$result"
        )

        download_mbps=$(echo "scale=2; $download_bps / 1000000" | bc)
        upload_mbps=$(echo "scale=2; $upload_bps / 1000000" | bc)
        ping_ms=$(printf "%.1f" "$ping")

        echo "$timestamp,$ping_ms,$download_mbps,$upload_mbps,$server" >> "$LOG_FILE"
        echo "  ↓ ${download_mbps} Mbps  ↑ ${upload_mbps} Mbps  Ping: ${ping_ms} ms ($server)"
    else
        echo "$timestamp,error,error,error,failed" >> "$LOG_FILE"
        echo "  Test failed."
    fi
}

for ((hour = 0; hour < TOTAL_HOURS; hour++)); do
    # Pick 3–5 random test times within this hour (as seconds 0–3599)
    num_tests=$((RANDOM % 3 + 3))
    offsets=()
    for ((t = 0; t < num_tests; t++)); do
        offsets+=($((RANDOM % 3540)))
    done

    # Sort offsets
    IFS=$'\n' sorted=($(sort -n <<<"${offsets[*]}")); unset IFS

    echo "[Hour $((hour + 1))/$TOTAL_HOURS] $num_tests tests scheduled at offsets: ${sorted[*]}s"

    hour_start=$(date +%s)
    for offset in "${sorted[@]}"; do
        # Calculate how long to sleep from now until this offset
        now=$(date +%s)
        elapsed=$((now - hour_start))
        wait=$((offset - elapsed))
        if ((wait > 0)); then
            sleep "$wait"
        fi
        run_test
    done

    # Sleep until the hour is over
    now=$(date +%s)
    elapsed=$((now - hour_start))
    remaining=$((3600 - elapsed))
    if ((remaining > 0 && hour < TOTAL_HOURS - 1)); then
        sleep "$remaining"
    fi
done

rm -f "$PID_FILE"
echo "Monitoring complete. Results in $LOG_FILE"
