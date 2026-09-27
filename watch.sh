#!/usr/bin/env bash
# Opens an alert issue in this repo for every new issue matching a query in
# queries.txt, and closes alerts whose source issue was assigned or closed.
#
# Needs: gh, jq, and GH_TOKEN / GITHUB_REPOSITORY / NOTIFY_USER in the env.
set -euo pipefail

repo="${GITHUB_REPOSITORY:?}"
user="${NOTIFY_USER:?}"

# Source issues we have already alerted on, read from a hidden marker in
# each alert's body: <!-- source: owner/repo#123 -->
known=$(gh issue list --repo "$repo" --state all --limit 1000 --json body \
  --jq '.[] | ((.body // "") | capture("<!-- source: (?<s>[^ ]+) -->").s)? // empty')

while IFS= read -r query; do
  [[ -z "$query" || "$query" == \#* ]] && continue

  gh api -X GET search/issues -f q="$query" -f per_page=100 \
    --jq '.items[] | [(.repository_url | sub(".*/repos/"; "")) + "#" + (.number|tostring), .html_url, .title, ([.labels[].name] | join(", "))] | @tsv' |
  while IFS=$'\t' read -r source url title labels; do
    grep -qxF "$source" <<<"$known" && continue

    echo "New: $source $title"
    gh issue create --repo "$repo" --assignee "$user" \
      --title "[$source] $title" \
      --body "$(printf '@%s a new issue matches your watch list:\n\n**%s**\n%s\n\nLabels: %s\n\nMatched query: `%s`\n\nClaim it quickly (read the project'"'"'s contributing rules first). This alert closes itself once the issue is assigned or closed.\n\n<!-- source: %s -->' \
        "$user" "$title" "$url" "${labels:-none}" "$query" "$source")" </dev/null >/dev/null
  done
done < queries.txt

# Close alerts that are no longer claimable.
gh issue list --repo "$repo" --state open --limit 200 --json number,body \
  --jq '.[] | [.number, (((.body // "") | capture("<!-- source: (?<s>[^ ]+) -->").s)? // "")] | @tsv' |
while IFS=$'\t' read -r alert source; do
  [[ -z "$source" ]] && continue
  status=$(gh api "repos/${source%#*}/issues/${source##*#}" \
    --jq 'if .state == "closed" then "closed" elif (.assignees | length) > 0 then "assigned to " + ([.assignees[].login] | join(", ")) else "" end' </dev/null)
  if [[ -n "$status" ]]; then
    echo "Closing alert #$alert: $source is $status"
    gh issue close "$alert" --repo "$repo" --comment "$source is now $status." </dev/null >/dev/null
  fi
done
