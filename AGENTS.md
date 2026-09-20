# Working in the liken fork of Corrosion

This is a shallow fork of superfly/corrosion. `liken/README.md` explains
the branches, the stack, and the release. Read it before you change
anything, and keep its stack table current.

`main` mirrors upstream and takes no commits. The `liken` branch has the
fork's own work, so treat `liken` as this repository's main branch in any
process that names one.

## What the fork is for

The fork exists to control the image build and to keep performance
improvements. Do not make feature or usability changes here. A change
that is not about the build or about performance does not belong on the
stack.

Stay faithful to upstream. Do not move, rename, or restructure
upstream's code. Every commit on the stack must rebase cleanly onto the
next upstream main, and a rearranged tree does not.

Land each performance change as one small commit that a maintainer could
read and merge on its own. Keep a change inside one crate, and do not mix
a cleanup into it.

Send a change upstream only when it helps anyone who runs Corrosion, not
only `liken`. A change that serves `liken`'s sidecar shape alone stays on
the stack as a `liken`-only commit.

## The rules

- `main` mirrors upstream. Never commit to it.
- A change to Corrosion starts as a branch from `main`. If it helps
  everyone, open a pull request to superfly/corrosion from that branch.
  Either way it joins the `liken` stack by cherry-pick, and its row in
  the README's stack table records which.
- The bottom commits of the stack are the only commits that touch
  fork-only files, and they touch none of upstream's. Do not edit
  upstream's README, workflows, or Cargo profiles there.
- Do not merge `main` into `liken`. Rebase.
- Do not tag from any branch except `liken`.
- Run the crate's own tests for the code you touched before it joins the
  stack. Upstream's CI runs the full suite on a pull request, and a
  `liken`-only commit has no CI but yours.

## Prose

Anything you write in the fork's own files, and every commit message,
follows `liken`'s writing rules: active voice, simple tenses, one topic
per sentence, one meaning per word. A comment says what the code does now
and why, not how it got there. A commit message is one line on what
changed, a blank line, then a short paragraph on why, with a link to the
upstream pull request.

Code that goes upstream follows upstream's conventions, not these.
