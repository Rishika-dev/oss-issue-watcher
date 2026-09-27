# oss-issue-watcher

Get notified when a claimable issue appears in an open-source project.

Every 30 minutes a GitHub Actions workflow runs each search in
[`queries.txt`](queries.txt). For every new match it opens an issue here,
assigned to the repo owner, which triggers a normal GitHub notification
(email and GitHub mobile push). When the original issue gets assigned or
closed, the alert closes itself, so open issues here are exactly the ones
still up for grabs.

## Watch something else

Add a line to `queries.txt` using
[GitHub issue search syntax](https://docs.github.com/en/search-github/searching-on-github/searching-issues-and-pull-requests), for example:

```
repo:fossasia/eventyay is:issue is:open label:"good first issue" no:assignee
```

## Run it now

Actions → **Watch for claimable issues** → **Run workflow**, or:

```sh
gh workflow run watch.yml
```

## Notes

- Scheduled runs on GitHub Actions can start a few minutes late.
- GitHub disables scheduled workflows after 60 days without repository
  activity. Re-enable it from the Actions tab if that happens.
