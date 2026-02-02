# Bandwidth Monitor

A bash script that runs automated speed tests at random intervals and logs the results to CSV.

## Requirements

- macOS or Linux
- `speedtest-cli` (`brew install speedtest-cli`)
- Python 3 (for CSV parsing)
- `bc` (pre-installed on macOS)

## Usage

**Start in the background:**

```bash
nohup ~/bandwidth-monitor.sh > ~/bandwidth-monitor.out 2>&1 &
```

**Check status:**

```bash
tail ~/bandwidth-monitor.out
```

**View results:**

```bash
cat ~/bandwidth-log.csv
```

**Stop:**

```bash
kill $(cat ~/.bandwidth-monitor.pid)
```

## Configuration

Edit the variables at the top of `bandwidth-monitor.sh`:

| Variable      | Default | Description                      |
|---------------|---------|----------------------------------|
| `TOTAL_HOURS` | 168     | How long to run (168 = 7 days)   |
| `LOG_FILE`    | `~/bandwidth-log.csv` | Output CSV path    |

The number of tests per hour (3-5) and the random offset range (0-3540s) can be adjusted in the main loop.

## Output Format

Results are appended to `~/bandwidth-log.csv`:

```
timestamp,ping_ms,download_mbps,upload_mbps,server
2026-02-01 18:30:12,22.3,354.16,57.07,GoNetspeed
2026-02-01 18:45:01,18.7,412.50,62.33,Spectrum
```

## How It Works

Each hour, the script:

1. Picks a random count (3-5) of test times
2. Generates random offsets within the hour (0-59 min)
3. Sorts them and sleeps between each test
4. Runs `speedtest-cli --csv` and parses the result
5. Appends a row to the CSV log
6. Sleeps until the next hour begins

The PID is written to `~/.bandwidth-monitor.pid` for easy process management.
