#!/usr/bin/env bash
# Monitor GitHub Actions workflows via gh CLI
# Usage:
#   ./scripts/monitor-actions.sh              # interactive live watch
#   ./scripts/monitor-actions.sh snapshot     # one-shot summary
#   ./scripts/monitor-actions.sh watch <id>   # watch a specific run
#   ./scripts/monitor-actions.sh logs <id>    # tail logs of a specific run

set -euo pipefail

BRANCH="${PAKE_BRANCH:-main}"
INTERVAL=15

cmd_snapshot() {
    echo "=== Pake Actions Snapshot ==="
    echo ""

    for status in queued in_progress action_required; do
        local label
        case "$status" in
            queued)          label="⏳ Queued" ;;
            in_progress)     label="▶ In Progress" ;;
            action_required) label="⚠ Action Required" ;;
        esac

        local data
        data=$(gh run list --status "$status" --branch "$BRANCH" --limit 5 \
            --json databaseId,displayTitle,workflowName,headBranch 2>&1)

        if echo "$data" | jq -e 'length == 0' >/dev/null 2>&1; then
            echo "  $label: (none)"
        else
            echo "  $label:"
            echo "$data" | jq -r '.[] | "    #\(.databaseId) │ \(.workflowName) │ \(.displayTitle)"'
        fi
        echo ""
    done
}

cmd_watch() {
    local run_id="$1"
    echo "Watching run #$run_id (Ctrl+C to stop)..."
    gh run watch "$run_id" --exit-status 2>&1 && {
        echo ""
        echo "✓ Run #$run_id completed successfully"
        gh run view "$run_id" --log --jq '.steps[] | select(.conclusion != "success") | .name' 2>/dev/null || true
    } || {
        local rc=$?
        echo ""
        echo "✗ Run #$run_id failed (exit $rc)"
        gh run view "$run_id" --log --jq '.steps[] | select(.conclusion == "failure") | .name' 2>/dev/null || true
        return $rc
    }
}

cmd_logs() {
    local run_id="$1"
    gh run view "$run_id" --log-failed 2>&1
}

cmd_live() {
    echo "=== Pake Actions Live Monitor ==="
    echo "Branch: $BRANCH  |  Poll: ${INTERVAL}s"
    echo ""

    while true; do
        clear 2>/dev/null || printf "\033c"
        echo "╔══════════════════════════════════════════════════╗"
        printf "║  %-47s ║\n" "$(date '+%Y-%m-%d %H:%M:%S') — Pake Actions"
        echo "╚══════════════════════════════════════════════════╝"
        echo ""

        for status in in_progress queued action_required; do
            local label icon
            case "$status" in
                in_progress)     icon="▶"  label="RUNNING" ;;
                queued)          icon="⏳" label="QUEUED" ;;
                action_required) icon="⚠"  label="ACTION REQUIRED" ;;
            esac

            local data
            data=$(gh run list --status "$status" --branch "$BRANCH" --limit 5 \
                --json databaseId,displayTitle,workflowName 2>&1)

            printf "\033[1m%s %s\033[0m\n" "$icon" "$label"
            if echo "$data" | jq -e 'length == 0' >/dev/null 2>&1; then
                echo "   (none)"
            else
                echo "$data" | jq -r '.[] | "   #\(.databaseId)  \(.workflowName)  │  \(.displayTitle)"'
            fi
            echo ""
        done

        echo "─── Latest Completed ───"
        gh run list --status completed --branch "$BRANCH" --limit 3 \
            --json databaseId,displayTitle,workflowName,conclusion \
            | jq -r '.[] | "   \(.conclusion | if . == "success" then "✓" else "✗" end)  #\(.databaseId)  \(.workflowName)  │  \(.displayTitle)"'

        echo ""
        echo "(updates every ${INTERVAL}s — Ctrl+C to quit)"
        sleep "$INTERVAL"
    done
}

# ── main dispatch ──
case "${1:-}" in
    snapshot|snap)
        cmd_snapshot
        ;;
    watch)
        [ -n "${2:-}" ] || { echo "Usage: $0 watch <run-id>"; exit 1; }
        cmd_watch "$2"
        ;;
    logs)
        [ -n "${2:-}" ] || { echo "Usage: $0 logs <run-id>"; exit 1; }
        cmd_logs "$2"
        ;;
    live|"")
        cmd_live
        ;;
    *)
        echo "Usage: $0 {snapshot|watch <id>|logs <id>|live}"
        exit 1
        ;;
esac
