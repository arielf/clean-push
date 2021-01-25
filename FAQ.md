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

When in fact, there are (at least) 4 copies:

    - A _remote_ main branch (shared with other developers)
    - A _local_ main branch (a copy of 1 but is often behind on updates)
    - A _local_ feature branch (the one you're working on)
    - A _remote_ feature branch (the one you push to for code reviews before landing on main)

So when you do a `git diff`, you often need to be more specific:

For example, if you want to know what are your latest changes that
were not yet pushed to your publicly visible feature branch. You can
use the following:

    # Assume we're here, on our private development branch
    git checkout dev

    #
    # local difference between what's already commited and what's not
    #
    git diff

    #
    # Differences between local & remote 'dev' branch
    #
    git diff remotes/origin/dev
    git diff origin/dev             # same ('remotes' is implied)
    git diff origin                 # same ('dev' is implied)

And if you want to know which of your local changes have not made it
to the main branch you would instead do:

    #
    # Differences between local 'dev' & remote 'main' branch
    #
    git checkout dev
    git diff remotes/origin/main
    git diff origin/main            # same ('remotes' is implied)

Note that now, the following will not diff vs main:

    git diff origin                 # NOT the same (because 'dev' is implied)

So when you see a diff that doesn't make sense to you, ask yourself:

- (0) Are you comparing the right two objects?
- (1) Did you forget to push to your dev branch?
- (2) Did you forget to pull remote main into the local main branch?
- (3) Did you forget to merge (land) emote dev into remote main?
- (4) Did you forget to pull the latest main branch _after_ the merge?

### I pushed (or pulled) but I still don't see the changes I expect...

Be aware that when you do a `pull` in your `dev` branch
this does ***not*** necessarily pull the latest *remote* main branch.

So to be 100% in sync between your local dev and the remote main,
you need to:

    git checkout main && git pull
    git checkout dev && git pull origin/main

And if you also want your remote copy of dev to have the same
changes, you also need an additional:

    # push local dev changes to the remote copy (origin/dev)
    git push

### When is `git` implicit vs explicit?

My repository is a full copy of the remote repository.

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

- The name 'origin' refers to the remote `github` host and URL.
- The name 'main' refers to the main branch, which has a copy on the
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


