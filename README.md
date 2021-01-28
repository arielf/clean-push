# clean-push

git flow to produce safe, neat, rebased + sqashed PRs

*(Note: in the below, I use `master` as the generic name for the branch you have branched from.
 Some call it "the parent branch" although git doesn't really support parent/child relationships
 between branches, branch names are just `refs`, i.e aliases for commit-ids)*

### Have you ever been frustrated with `git` because:

- Your long-lived branch commit-history has become too messy when the time has come to publish your changes?
- You had duplicate or partly overlapping commits because of history-changing squashes & rebases?
- A commit has been reverted, but instead of having an empty delta you had both commit + reverted changes?
- When you tried to rebase, you got into "rebase hell" (`continue, skip, abort`) loop, which seemed to never end?
- Syncing your repo with `origin/master` created more conflicts than expected?
- A push after a merge unexpectedly included someone-else's changes due to a messy merge with `master` + a 3-way diff against an already existing PR?
- You wanted to reuse an existing branch for additional work, but there was too much legacy in its commits so you were forced to start a new one and replay all your changes again?
- You resorted to (`git diff` + `git apply`) or (`stash` + `pop`) or (a loop of `git cherry-pick`s from prior work) but found the multi-step process too complex/involved and error-prone?

### If you answered "yes" to any of the above?

`clean-push` may be just the script you need.

`clean-push` implements the following:

- A full sync with the `master` branch before starting a push leading to a pull request
- Simple conflict detection, like merge does
- Consolidated/simple conflict resolution (unlike with `git rebase`)
- The pull-request is clean:
   - It has only one delta (diff) vs `master`
   - It is rebased on top of the latest HEAD of `master`
   - It doesn't contain unwanted merge commits
- For safety: most risky `git` operations which might mess-up your work, are done on a temporary/throwaway branch.
- Your feature branch is atomically modified once (with one `git reset`) after all issues have been resolved and the single delta vs `master` looks good.
- You get a chance to edit your pull-request message in your favorite editor and make it look even better.
- You can re-edit all the messages in a long list of commits without
  the complexities introduced by the fix-up syntax of `git rebase -i`
- The pull-request on *github* looks exactly like you wrote it in your editor: the first line becomes the title of the pull-request
- If you want to fix-up anything, you can just repeat the call to `clean-push` and the new push will override the previous instead of appending to it
- You never get into *"rebase-loop hell"*, because `git rebase` isn't used anywhere
- Works both on Linux and Mac OS-X
- Protected from being called from a git hook (a nested call which may cause damage)
- Ability to pause & allow you to edit intermediate `git` steps before executing them. A common use-case for me is to be able to add `--no-verify` to the end of a `git commit` or `git push` sub-command in order to skip some long duration hooks.

## 4-way-diff

`4-way-diff` is a handy script that provides a quick, non-destructive,
(read-only) view of the 4-way state for full situational awareness.

It tells you which of the 4 copies is not in-sync by performing
the full circle of comparisons:

  - local dev vs its 'git index' (is current branch 'clean'?)
  - local dev vs remote/pushed dev
  - local dev vs remote master/main
  - remote dev vs local copy of main (the 'tracking' branch for main)

Try it and it can help you to quickly diagnose what may still
not be in-sync.

Here's for example the message you get when something isn't committed yet:

```
[full diff comes here]

4-way-diff: (1) dev branch not clean. Need to commit (or stash) locally
```

Here's the message you get when your branch is fully
committed but has not been pushed yet:

```
[full (reverse) diff comes here]

4-way-diff: (2) dev branch: local != remote. Need to push
```

Here's the message you get when your branch changes are committed,
pushed, but not yet merged to the main branch on the remote server:

```
[full (reverse) diff comes here]

4-way-diff: (3) local dev != remote main. Need to remote-merge
```

Here's the message you get when your branch changes are committed,
pushed, and merged remotely, but your local main branch is now
a step behind (because the merge was only done on the remote):

```
[full diff comes here]

4-way-diff: (4) local dev != local main. Need to pull in local main
To fix:
        git checkout main && git pull && git checkout dev
```

And finally, the message you get when everything is in-sync:

```
```

## Caveats

### `clean-push` is intended for flows:

- With a single common main branch (`main`, `master`, or similar).
- Where developers want to be in sync with each other as much as possible
- Where the main branch is the source of truth (e.g. used for continuous/automatic CICD and releases)
- Encourages fast-development by many developers on the main branch
- Detects conflicts as early as possible by frequent merging for other developer branches

### If your flow:

- Encourages multiple diverging separate development tracks
- Rarely merges
- Doesn't use continuous integration and deployment (CICD)

Then `clean-push` is probably not for you.

## Big credit:

`clean-push` is based on method (1) of [this excellent page by Lars Kellogg-Stedman](https://blog.oddbit.com/post/2019-06-17-avoid-rebase-hell-squashing-wi/)

Before discovering that page, I tried several unsatisfactory solutions to the problem, all of which fell short on some aspect of the problems described above.

## Portability notes

`clean-push` is a simple bash script.

It was developed and tested using:

- bash 4.4.x
- git 2.17

Verified on Linux (Ubuntu 18.04) & Mac OS-X (10.15, Catalina).

## Licence

Written-by: Ariel Faigon, 2021

Released under the [MIT licence](LICENSE).
