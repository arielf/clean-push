# Frequently asked questions

The following are only related to `clean-push`.

I put them here because without understanding them, it may be
hard to full understand what problem `clean-push` actually solves.

### What's wrong with `rebase`?

- It duplicates commits, making the same delta have multiple commit-id's
- In case of conflicts (even against your _own_ changes) it can become a multi-step tedious process.
- It doesn't squash overlapping/cancelling commits
- It makes code history look more complex & convoluted than necessary
- In case of conflicts, it stops in a half-done state that is harder
  to get out of, than in simpler merge commits.

Because of duplicate-commits and lack of squashing similar, opposite, or overlapping changes, `rebase` often leads to what seems like a loop of applying the same changes over and over again.

### When I use rebase/squash I sometimes see other developer's changes in my diffs. Why?

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

#### Uncomitted changes

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

or:
    git diff origin/main            # same ('remotes' is implied)

Note that to compare local and remote `main` branches
you need to change branches to `main` first because when your
current branch is `dev` and you try to run `git diff origin`,
'dev' is implied.

#### Merged main on remote but local main is now unsynced

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
- (3) Did you forget to pull remote main into the local main branch?
- (4) Did you forget to merge (land) remote dev into remote main?
- (5) Did you forget to pull the latest main branch _after_ the merge?

Only going through all this (5) step process would ensure everything is in sync.

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
copies of the current repository.

- The name *'origin'* refers to the remote `github` host and URL.
- The name *'main'* refers to the main branch, which has a copy on the
  remote `github` host, but when I do a `merge` it uses the
  ***local*** copy rather than the remote copy.

In many operations which conceptually require two arguments,
git supports an implied default argument which is your current
branch (in almost all cases the HEAD on the current branch).
So when you do a `pull` for example, you only need to specify
where are you pulling from and not the branch you're applying
the `pull` to (current branch, and merge with HEAD implied).

    # Implies origin (most commonly: a remote copy, with the same branchname)
    git push

    # Implies the local copy of branchname
    git merge branchname

