
[//]: # (vim: spell)

# clean-push

Automated git flow to produce safe, neat (rebased + squashed) pull-requests.


### Have you ever been frustrated with `git` because:

- Your long-lived `work` branch commit-history has become too messy when the time has come to publish your changes?
- You had duplicate or partly overlapping commits because of history-changing squashes & rebases?
- A commit has been reverted, but instead of having an empty delta you had both commit + reverted changes?
- When you tried to rebase, you got into "rebase hell" (`continue, skip, abort`) loop, which seemed to never end?
- Syncing your repo with `origin/master` created more conflicts than expected?
- A push after a merge unexpectedly included someone-else's changes due to a messy merge with `master` + a 3-way diff against an already existing PR?
- You wanted to reuse an existing branch for additional work, but there was too much legacy in its commits so you were forced to start a new one and replay all your changes again?
- You resorted to (`git diff` + `git apply`) or (`stash` + `pop`) or (a loop of `git cherry-pick`s from prior work) but found the multi-step process too complex/involved and error-prone?
- You created a pull-request, and noticed a small error, now you want to redo the PR with some small fix, but hesitate because it would mean too much work all over again? (think `git commit --amend` but for pushes)

### If you answered "yes" to any of the above?

`clean-push` may be just the script you need.

`clean-push` implements the following:

- A full sync with the `main` branch before starting a push leading to a pull request
- Simple conflict detection, like merge does
- Consolidated/simple conflict resolution (unlike with `git rebase`)
- The pull-request is clean:
   - It has only one delta (diff) vs `main`
   - It is rebased on top of the latest HEAD of `main`
   - It doesn't contain unwanted merge commits
- For safety: most risky `git` operations which might mess-up your work, are done on a temporary/throwaway branch.
- Your feature branch is atomically modified once (with one `git reset`) after all issues have been resolved and the single delta vs `main` looks good.
- You get a chance to edit your pull-request message in your favorite editor and make it look even better.
- You can re-edit all the messages in a long list of commits without
  the complexities introduced by the fix-up syntax of `git rebase -i`
- The pull-request on *github* looks exactly like you wrote it in your editor: the first line becomes the title of the pull-request
- If you want to fix-up anything, you can just repeat the call to `clean-push` and the new push will override the previous instead of appending to it
- You never get into *"rebase-loop hell"*, because `git rebase` isn't used anywhere
- Works both on Linux and Mac OS-X
- Protected from being called from a git hook (a nested call which may cause damage)
- Ability to pause & allow you to edit intermediate `git` steps before executing them. A common use-case for me is to be able to add `--no-verify` to the end of a `git commit` or `git push` sub-command in order to skip some long duration hooks.

### Crucial terminology

In this text, there are repeated references to two distinct branches.

The 1st is the `main` branch you have branched from to do your development.
This branch can be referred to by several names, among them:

  - *master*
  - *main*
  - *parent branch* (although git doesn't really support parent/child relationships between branches, as branch names are just `refs`, i.e aliases for commit-ids)
  - *CICD* branch (if we auto-deploy from it)
  - *dev* or the 'development branch'
  - The source of truth
  - When this branch is used to release from, it may be called the *release* branch
  - On *github.com* in settings/branches they call this the "default branch"

Similarly, different people may refer to the ephemeral branch they're developing on, as any of:

  - *work* branch
  - *topic* branch
  - *bug-fix* branch
  - *feature* branch

As far as `clean-push` is concerned, there are only two branches.
In this text, they are referred to as:

  - `main` or `master`
  - `work` branch

Regardless of what they are actually called.

`clean-push` queries the current branch (from which it was called) in runtime for the `work` branch actual name.

Figuring-out the *main* branch actual name is harder.
`clean-push` tries to check the following for existence, in order:

  - "$1" (first, arg, if passed on the command line)
  - `dev`
  - `staging`
  - `main`
  - `master`

Better heuristics for figuring out the later are welcome (please open a github issue if you know a more reliable and elegant solution).

## Usage:

While working on your work/topic branch, you can run any of:

```
    clean-push [<main-branch-name>]

    4-way-diff [<main-branch-name>]
```

The argument is optional. If you don't provide it the script(s) will
try to guess it.  See also the `Customizing behavior` section below.


## 4-way-diff

`4-way-diff` is a handy script that provides a quick, non-destructive,
(read-only) view of the 4-way state for full situational awareness.

It tells you which of the 4 copies is not in-sync by performing
the full circle of comparisons:

  - local work branch vs its 'git index' (is current branch ***fully committed*** a.k.a: ***clean***?)
  - local work branch vs remote/pushed work branch
  - local work branch vs remote master
  - remote work branch vs local copy of master (the 'tracking' branch for master)

Try it and it can help you to quickly diagnose what may still not be in-sync.

***Here's for example the message you get when something isn't committed yet:***

```
[full diff comes here]

4-way-diff: (1) work branch not clean. Need to commit (or stash) locally
```

***Here's the message you get when your branch is fully
committed but has not been pushed yet:***

```
[full (reverse) diff comes here]

4-way-diff: (2) work branch: local != remote. Need to push
```

***Here's the message you get when your branch changes are committed,
pushed, but not yet merged to the main branch on the remote
server:***

```
[full (reverse) diff comes here]

4-way-diff: (3) local work != remote main. Need to remote-merge
```

***Here's the message you get when your branch changes are committed,
pushed, and merged remotely, but your local main branch is now
a step behind (because the merge was only done on the remote):***

```
[full diff comes here]

4-way-diff: (4) local work != local main. Need to pull in local main
To fix:
        git checkout main && git pull && git checkout work
```

***And finally, the message you get when everything is in-sync:***

```
(1) work branch is clean, cool
(2) work branch: local == remote, no need to push, cool
(3) remote work doesn't exist (already merged?)
(4) local work == local main, no need to pull in main, cool
```

## Customizing behavior

The following default behaviors can be changed in both
`clean-push` and `4-way-diff`:

1. Name of "upstream" (git remote repository location)
2. Names of "main" branch-names to try

1. If your remote is not called `origin`, you may change the variable
   you should change the default value of the `UPSTREAM` variable in the
   code, from:

```
UPSTREAM=${UPSTREAM:-origin}
```

to:

```
UPSTREAM=${UPSTREAM:-<your_upstream_name>}
```

2. In order to figure out the `"main"` branch from which you started
and want to merge into, the code makes a few possible guesses.

If these values don't work for you, you may change the value
of `MAIN_BRANCH_NAMES=( ... )` in the code.

You may also pass an explicit "main" branch name argument to
any of the scripts which will disable the guessing altogether, e.g.:

```
    # Run a clean-push vs 'cicd-branch'
    clean-push cicd-branch
```

## HOWTO

First, make sure the two utilities:

    clean-push
    4-way-diff

are always in your `$PATH`.  I simply have `~/bin` in my `$PATH`
and have them both copied there, like this:

    mkdir -p ~/bin

    # Make sure the two scripts are executable:
    chmod a+rx clean-push 4-way-diff

    cp clean-push 4-way-diff ~/bin

    # Make sure you have ~/bin in your PATH.
    # This has to be in your ~/.bashrc or ~/.profile
    export PATH=~/bin:$PATH

Now go to your repo (cd .../your/repository)
Assuming you start in branch 'main':

    # Create the 'work' branch.
    git checkout -b mydev

    # Add/remove files and make changes as you would normally do in git...

    # Once: ready to push, make sure everything is committed:
    git commit -a

    # Now that your repo is 'clean', run the clean push
    clean-push

Similarly, to compare to remote, just run:

    4-way-diff

That's all there is to it!


## Caveats

### `clean-push` is intended for flows:

- With a single common main branch (`main`, `master`, or similar).
- Where developers want to be in sync with each other as much as possible
- Where the main branch is the source of truth (e.g. used for continuous/automatic CICD and releases)
- Encourages fast-development by many developers on the main branch
- Detects conflicts as early as possible by frequent merging for other developer branches

### If your flow:

- Encourages multiple long-lived diverging separate development tracks
- Rarely merges
- Has multiple forks like production vs "next gen". Extreme case: what you develop today will be seen by customers only in 3 years, if at all.
- Doesn't use continuous integration and deployment (CICD)

Then `clean-push` may be useful for work on one fork, but may not be
useful beyond it.

## Credits:

`clean-push` is based on method (1) of [this excellent page by Lars Kellogg-Stedman](https://blog.oddbit.com/post/2019-06-17-avoid-rebase-hell-squashing-wi/)

Before discovering that page, I tried several unsatisfactory solutions to the problem, all of which fell short on some aspect of the problems described above.

Thanks to Steve Malmskog & Jordan Bucholtz for their early testing &
contributions.

## Portability notes

`clean-push` is a simple bash script.

It was developed and tested using:

- bash: 4.4.20, 5.0.17
- git: 2.17, 2.25.1

Verified on Linux (Ubuntu 18.04, and 20.04) & Mac OS-X (10.15, Catalina).

## License

Written-by: Ariel Faigon, 2021

Released under the [MIT licence](LICENSE).
