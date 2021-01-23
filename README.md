# clean-push

A bash script implementing a git-flow to produce safe, neat, rebased + sqashed PRs

***(Note: in the below, I use `master` as the generic name for the branch you have branched from
 some call this "parent branch" although git doesn't really support parent/child relationships
 between branches, branch names are just `refs`, i.e aliases for commit-ids)***

### Have you ever been frustrated with `git` because:

- You started a long-lived branch with and your history of commits became too messy when the time has come to publish 
- You had duplicate or overlapping commits because of history-changing squashes & rebases
- A commit was reverted but instead of having an empty delta you had both commit + reverted changes
- When you tried to rebase, you got into "rebase hell" (continue, skip, abort) loop that seemed to never end?
- Syncing your repo with `origin/master` created much more conflicts than expected?
- Your push after a merge unexpectedly included someone-elses changes due to a messy merge with `master` and diff against a prior PR?
- You wanted to reuse a branch, but there was too much legacy in its commits so you had to start a new one
- You resorted to `git diff origin/master` + clean branch + `git apply` but found the multi-step process too complex/involved 

### If you answered "yes" to any of the above, `clean-push` may be just the script you always wanted to improve your git workflow.

`clean-push` implements the following:

- A full sync with the `master` branch before starting a push leading to a pull request
- Conflict detection
- Consolidated/simple conflict resultion (unlike with `git rebase`)
- The pull-request is clean:
   - It has only one delta (diff) vs `master`
   - It is rebased on top of the latest HEAD of `master`
   - It doesn't contain merge commits
- For safety: most risky `git` operations which may mess-up your work, are done on a temporary/throwaway branch.
- Your feature branch is atomically modified once (with one `git reset`) after all issues have been resolved and the single delta vs `master` looks good.
- You get a chance to edit your pull-request message in your favorite editor and make it look good
- The pull-request on github looks exactly like you wrote it: the first line becomes the title of the pull-request
- If you want to fix-up anything, you can just repeat the call to `clean-push` and the new push will override the previous instead of appending to it
- You never get into *"rebase-loop hell"*, because `git rebase` isn't used anywhere
- Works both on Linux and Mac OS-X
- Protected from being called from a git hook (a nested call which may cause damage)
- Ability to pause & allow the caller to edit intermediate `git` steps before executing them. A common use-case for me is to be able to add `--no-verify` to the end of a `git commit` or `git push` sub-command in order to skip some long duration hooks.

### Big credit:

`clean-push` is based on method (1) of [this excellent page by Lars Kellogg-Stedman](https://blog.oddbit.com/post/2019-06-17-avoid-rebase-hell-squashing-wi/)
Before reading that page, I had a least 3 unsatisfactory solutions to the problem, all of which fell short on some aspect described above.

