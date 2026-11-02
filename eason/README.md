# eason/

Fork-only tooling; kept in its own directory so merging upstream never conflicts with it.

- Branch `eason` = upstream `main` + local changes + this directory. Branch `fix/tag-range-continuation-lines` stays a clean PR branch.
- Install on a machine (macOS/Linux, VS Code and/or Cursor):

  ```sh
  curl -fsSL https://raw.githubusercontent.com/Lightblues/foam/eason/eason/install.sh | bash
  ```

  Options after `bash -s --`: `--code`, `--cursor`, `--tag <tag>`, `--dry-run`.
- Release a new build (devcloud_cpu, `/data/projects/infra/foam`): `git fetch upstream && git merge upstream/main`, resolve conflicts, `eason/release.sh`.
- Change parser/cache behaviour -> bump `CACHE_VERSION` in `packages/foam-vscode/src/vscode/services/cache.ts` (the fix currently uses 9; upstream's next bump must go above it).
