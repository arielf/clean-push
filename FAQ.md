
[//]: # (vim: spell)

# Frequently asked questions

The following are only related to `clean-push`.

I put them here because without understanding them, it may be
hard to full understand what problem `clean-push` actually solves.

### What's wrong with `rebase`?

- It duplicates commits, making the same delta have multiple commit-id's
- In case of conflicts (even against your _own_ changes) it can become a multi-step tedious process to resolve.
- It doesn't squash overlapping/cancelling commits
- It makes code history look more complex & convoluted than necessary
- In case of conflicts, it stops in a half-done state that is harder
  to get out of, than in simpler merge commits.

Because of duplicate-commits and lack of squashing similar, opposite, or overlapping changes, `rebase` often leads to what seems like a loop of applying the same changes over and over again.

### How does clean-push figure out the "main" branch.

`clean-push` has no idea what your main branch is, so it uses a
heuristic. Look for the function called `get-main-branch-name`
in the source. It does a loop like this:

```
    arg="$1"
    for branch in "$arg" 'dev' 'staging' 'main' 'master'; do
```

On github, there's a concept of "default branch" which you can set
via their web UI: `settings -> branches -> default branch`
This determines the branch against which pull-requests are made.

Similarly, `clean-push` uses what it calls 'main branch' to
determine against what base branch to calculate the delta.

Feel free to change the source line above to work best for you.
If you change that line, you should also change the similar one
in `4-way-diff`.

### Does `clean-push` force a single-branch development?

Not at all. `clean-push` only purpose is to generate clean,
linear PRs on top of a base-branch HEAD while avoiding `rebase`.

In my current company we use 3 branches:

    dev -> staging -> prod

and we move them forward at a weekly cadence, for stability reasons.

I run `clean-push` when pushing to `dev`. We have a separate
github hook running via drone that does the weekly promotion
from branch to branch triggered by the further merge and
we have a package build + deployment triggered by incrementing
a [semver style](https://semver.org) tag.


### When I use rebase/squash (not `clean-push`) I see other developer's changes in my diffs. Why?

This is due to the misunderstanding of diff (deltas).

The question boils down to what two branches are you comparing, and in
which order.

One of the misunderstandings of git is the following:

Conceptually, there are 2 branches (or copies thereof):

    - A main branch (shared with other developers)
    - A feature branch (the one you're working on on)

When in fact, we have at least 4 copies `(dev + main) * (local + remote)`:

  - A _remote_ main branch (shared with other developers)
  - A _local_ main branch (a copy of 1 but is often behind on updates)
  - A _local_ feature branch (the one you're working on)
  - A _remote_ feature branch (the one you push to for code reviews before landing on main)

Since `diff` order matters, there are ***2<sup>4</sup> = 16*** (!) different possible diffs between these 4 copies.

So when you do a `git diff`, you need to be more specific:

For example, if you want to know what are your latest changes that
were not yet committed, or pushed to your publicly visible feature branch, or merged into `main`.
You can use the following:

    # Assume we're here, on our private development branch
    git checkout dev

#### Uncommitted changes

    #
    # local difference between what's already commited and what's not
    #
    git diff

#### Unpushed changes
    #
    # Differences between local & remote 'dev' branch
    #
    git diff remotes/origin/dev
    git diff origin/dev             # same ('remotes' is implied)
    git diff origin                 # same ('dev' is implied)

#### Yet unmerged (with main) changes

    #
    # Differences between local 'dev' & remote 'main' branch
    #
    git diff remotes/origin/main

Or:

    git diff origin/main            # same ('remotes' is implied)

Note that to compare local and remote `main` branches
you need to change branches to `main` first because when your
current branch is `dev` and you try to run `git diff origin`,
'dev' is implied.

#### Merged main on remote but local main is out of sync

    #
    # Close the full loop from remote to local:
    #
    git checkout main && git pull

    #
    # Go back to the dev branch
    #
    git checkout dev


So when you see a diff that doesn't make sense to you, ask yourself:

- (0) Are you comparing the right two objects and in the correct order?
- (1) Did you forget to commit (locally)?
- (2) Did you forget to push to your (remote) dev branch?
- (3) Did you forget to merge (land) remote dev into remote main?
- (4) Did you forget to pull the newly merged remote main into the local main branch?

Only going through all these steps would ensure everything is in sync.

The utility [4-way-diff](4-way-diff) is a handy script to do
all these comparisons and tell you which part of the circle
has not been completed.

### I pushed (or pulled) but I still don't see the changes I expect...

Be aware that when you do a `pull` in your `dev` branch
this does ***not*** necessarily pull the latest *remote* main branch.

So to be 100% in sync between your local dev and the remote main,
you need to perform more than one pull (fetch + merge) operation:

    # sync local and remote main branches
    git checkout main && git pull

    # sync local dev with remote main
    git checkout dev && git pull main

And if you also want your remote copy of dev to have the same
changes, you also need an additional push to remote:

    # push local dev changes to the remote copy (origin/dev)
    git push

### When is `git` implicit vs explicit?

This is one of the most confusing aspects of `git`.

In many operations which involve two copies of the repo,
most commonly two branches, only one of them is given, and
the other is implied.

In more detail:

My repository is a copy of the remote repository.

This repository on my local machine has the following `.git/config`

```
[core]
        repositoryformatversion = 0
        filemode = true
        bare = false
        logallrefupdates = true
[remote "origin"]
        url = ssh://github.com/arielf/clean-push
        fetch = +refs/heads/*:refs/remotes/origin/*
[branch "main"]
        remote = origin
        merge = refs/heads/main
[branch "dev"]
        remote = origin
        merge = refs/heads/dev
```

At its core this `config` file gives symbolic names to different
instances (copies) of the current repository.

- The name *"origin"* refers to the remote `github` host and URL.
- The name *"main"* refers to the main branch, which has a copy on the
  remote `github` host, but when I do a `merge` it uses the
  ***local*** copy rather than the remote copy.

In many operations which conceptually require two arguments,
git supports an ***implied*** default argument which is your current
branch (in almost all cases the HEAD on the current branch).
So when you do a `pull` for example, you only need to specify
where are you pulling *from* and not the branch you're applying
the `pull` *to* (current branch, and merge with HEAD implied).

    # Implies origin (most commonly: a remote copy, with the same branchname)
    git push

    # Implies merging the (local) copy of branchname into (local) current branch
    git merge branchname
