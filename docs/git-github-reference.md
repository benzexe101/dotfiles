# Git & GitHub — Working Reference

Written around `github.com/benzexe101/dotfiles`, but the commands apply to any repo.

---

## The mental model

Git tracks **snapshots**, not files. Every commit is a complete picture of the project at a moment in time, plus a pointer to the commit before it. That chain is the history.

Three places your work lives:

```
working tree  →  staging area  →  repository  →  remote (GitHub)
(your files)     (git add)        (git commit)    (git push)
```

Most confusion with git comes from not knowing which of those four a file is currently in. `git status` answers that, every time.

---

## Daily workflow

Your configs are symlinked into `~/dev/dotfiles`, so editing a config edits the repo directly.

```fish
# 1. See what changed
cd ~/dev/dotfiles
git status
git diff

# 2. Stage and commit
git add -A
git commit -m "Add jdtls for Java"

# 3. Send it to GitHub
git push
```

On another machine, pull before you start:

```fish
git pull
```

That's 90% of git. The rest is for when something goes wrong.

---

## The commands you'll actually use

### Seeing state

```fish
git status              # what's changed, what's staged
git diff                # changes not yet staged
git diff --staged       # changes staged but not committed
git log --oneline       # commit history, one line each
git log -p <file>       # history of one file, with the actual changes
```

`git status` is the one to run reflexively. When you're unsure what's happening, run it.

### Making commits

```fish
git add -A              # stage everything
git add nvim/init.lua   # stage one file
git commit -m "message"
git commit -am "message"  # stage tracked files + commit in one step
```

**Commit messages:** present tense, describe the change not the file. "Add Python LSP config" beats "updated lang.lua". You'll thank yourself in six months.

Commit when something works, not when you're done for the day. Small commits are easier to understand and easier to undo.

### Syncing

```fish
git push                # send commits to GitHub
git pull                # fetch and merge from GitHub
git fetch               # fetch without merging (safe, just looks)
```

---

## Undoing things

The most useful part of git, and the part most people don't learn until they need it badly.

### Discard uncommitted changes to a file

```fish
git restore nvim/init.lua
```

Throws away your edits since the last commit. **Unrecoverable** — the changes were never committed, so git has no copy.

### Unstage a file (keep the changes)

```fish
git restore --staged nvim/init.lua
```

### Fix the last commit message

```fish
git commit --amend -m "better message"
```

Only safe if you haven't pushed. Amending rewrites the commit, and rewriting pushed history causes conflicts for anyone who pulled it.

### Add a forgotten file to the last commit

```fish
git add forgotten-file.lua
git commit --amend --no-edit
```

### Undo the last commit, keep the changes

```fish
git reset --soft HEAD~1
```

Commit disappears, your edits stay in the staging area. Useful when you committed too early.

### Undo the last commit, discard the changes

```fish
git reset --hard HEAD~1
```

**Destructive.** Both the commit and the edits are gone.

### Revert a commit that's already pushed

```fish
git revert <hash>
```

Creates a *new* commit that undoes the old one. History stays intact — this is the safe way to undo something others may have pulled.

### See an old version of a file

```fish
git show <hash>:nvim/init.lua
git checkout <hash> -- nvim/init.lua    # restore it into your working tree
```

---

## When you break a config

This is the scenario the repo exists for.

```fish
cd ~/dev/dotfiles
git diff                        # what did I change?
git restore nvim/lua/plugins/lang.lua   # put it back
```

If you already committed the breakage:

```fish
git log --oneline               # find the last good commit
git checkout <hash> -- nvim/    # restore that version of the nvim folder
```

If you have no idea when it broke:

```fish
git log -p nvim/lua/plugins/lang.lua | less
```

Scroll through the history of that one file with the actual diffs. The change that broke it is usually obvious once you see it.

---

## Branches

A branch is a movable pointer to a commit. `main` is just a branch with a conventional name.

```fish
git branch                      # list branches
git switch -c experiment        # create and switch to a new branch
git switch main                 # switch back
git merge experiment            # bring experiment's changes into main
git branch -d experiment        # delete it when done
```

**When to bother:** trying something you might abandon. Rewriting your LSP config, testing a new plugin manager, anything where "revert everything" should be one command.

For solo dotfiles, you often won't need branches at all. Commits on `main` are fine.

---

## Setting up a new machine

```fish
# 1. Generate an SSH key (skip if you have one)
ssh-keygen -t ed25519 -C "machine-name"
cat ~/.ssh/id_ed25519.pub

# 2. Add that key at github.com/settings/keys

# 3. Verify
ssh -T git@github.com
# want: "Hi benzexe101! You've successfully authenticated..."

# 4. Clone
git clone git@github.com:benzexe101/dotfiles.git ~/dev/dotfiles
```

Then symlink the configs into place (see the dotfiles README).

---

## Symlinks: why the repo stays honest

The configs in `~/.config/` are symlinks pointing at files in `~/dev/dotfiles/`:

```fish
ln -sf ~/dev/dotfiles/nvim/init.lua ~/.config/nvim/init.lua
```

There's only one real file. Editing either path edits the same bytes, so `git status` can never be wrong about whether your configs match the repo.

Check them with:

```fish
ls -la ~/.config/nvim/init.lua
# lrwxrwxrwx ... init.lua -> /home/ben/dev/dotfiles/nvim/init.lua
```

The `l` at the start and the `->` mean it's a symlink.

**Windows caveat:** symlinks require admin or Developer Mode. Either enable Developer Mode and use `New-Item -ItemType SymbolicLink`, or copy files and remember to re-copy after pulling.

---

## .gitignore

Lists files git should never track. Yours contains:

```
lazy-lock.json
```

Because each machine should resolve its own plugin versions rather than inheriting pins from another.

Things worth ignoring generally: build output (`build/`, `target/`, `node_modules/`), anything with credentials, machine-specific paths, large binaries.

**A file already tracked won't start being ignored** just because you add it to `.gitignore`. Untrack it first:

```fish
git rm --cached <file>
```

---

## Things that will bite you

**Committing secrets.** Once pushed, assume it's public forever — deleting the file in a later commit doesn't remove it from history. If it happens, rotate the credential immediately; cleaning history is a separate, painful job.

**`git reset --hard`.** Discards uncommitted work with no confirmation and no recovery. Run `git status` first, every time.

**Forgetting to pull.** Edit on the desktop, edit on the laptop, push from both — the second push is rejected and you have to merge. Pull before you start working, not after.

**Pushing to the wrong branch.** `git status` shows which branch you're on. It's in the first line.

**Amending pushed commits.** Rewrites history that others (or your other machines) already have. Use `git revert` instead once something is public.

---

## Reading a commit hash

```
280dcb2 (HEAD -> main) Initial commit: nvim, hyprland, and kanata config
```

- `280dcb2` — short form of the commit's SHA-1 hash, unique identifier
- `HEAD` — where you currently are
- `main` — the branch pointer, also here
- The rest is your commit message

Seven characters is enough to reference a commit in any command.

---

## Useful additions

```fish
git log --oneline --graph --all     # visual history across branches
git blame <file>                    # who changed each line, and in which commit
git stash                           # shelve uncommitted changes temporarily
git stash pop                       # bring them back
git clean -n                        # preview which untracked files would be deleted
```

`git stash` is genuinely handy: you're mid-edit, need to pull, don't want to commit half-work. Stash, pull, pop.

---

## GitHub-specific

**The web UI is a viewer, mostly.** You can edit files in the browser, but it creates a commit you then have to pull. Easier to edit locally.

**Repository settings** worth knowing: github.com/benzexe101/dotfiles/settings

- Rename or delete the repo
- Change public/private
- Add a description and topics (helps discoverability)

**Your SSH keys:** github.com/settings/keys — one per machine, named so you can revoke a lost laptop without breaking the others.

**Your noreply email:** `176443212+benzexe101@users.noreply.github.com`. With "Block command line pushes that expose my email" enabled, pushes authored with your real address get rejected — which is the setting working correctly.

---

## Quick reference

| Task | Command |
|---|---|
| What changed? | `git status` / `git diff` |
| Save work | `git add -A && git commit -m "msg"` |
| Send to GitHub | `git push` |
| Get from GitHub | `git pull` |
| History | `git log --oneline` |
| Undo file edit | `git restore <file>` |
| Undo last commit, keep edits | `git reset --soft HEAD~1` |
| Undo a pushed commit | `git revert <hash>` |
| Shelve work temporarily | `git stash` / `git stash pop` |
| New branch | `git switch -c <name>` |
