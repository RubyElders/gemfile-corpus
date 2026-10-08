# Gemfile corpus

1,477 original Gemfiles from 656 public GitHub repositories, sampled across 2021-2026. Includes Rails, Hanami, Sinatra, Roda, Padrino, Cuba and Grape applications.

Files live in `gemfiles/<year>/<owner>/<repository>/Gemfile`. Identical versions within a project are kept once, under their earliest sampled year. Projects that call `gemspec` or `load_gemspec` are skipped. Gemfile collection includes only Gemfiles (or `gems.rb`).

Gemfiles are provided as-is, with no guarantee that they evaluate, resolve or install successfully. Companion files and project-specific setup may be missing. You are responsible for verifying results with canonical tools such as Bundler, using the Ruby and tool versions appropriate to each snapshot. Corpus verification checks file integrity, not compatibility or usability.

Add repositories to `sources.tsv` (leave the snapshot columns empty for a new repository), then run the scraper. It fetches yearly snapshots, deduplicates and verifies them automatically:

```sh
ruby tools/collect_gemfiles.rb
```

Requires Ruby 3.3 or newer and an authenticated GitHub CLI (`gh`). The script never executes downloaded Gemfiles. `sources.tsv` is the single source list, with columns `repository`, `path`, `commit` and `sha256`.

Run the tests, including verification of the stored corpus:

```sh
ruby test/corpus_test.rb
```

The lockfile corpus contains 1,422 snapshots from 594 public repositories, sampled across 2021-2026. It includes 411 locks with Git sources, 97 with path sources and 50 with checksum sections.

Lockfiles are collected independently into `lockfiles/<year>/<owner>/<repository>/Gemfile.lock` or `gems.locked`:

```sh
ruby tools/collect_lockfiles.rb
```

This uses the same repository list and provenance columns in `sources.tsv`. Applications and gemspec-based libraries are both eligible. Both lockfile names are retained when present. Identical bytes for the same repository and filename are kept under the earliest sampled year; Gemfile snapshots remain independent. Four download workers collect public files without executing or parsing them. The tests verify both directories. Lockfiles are also provided as-is; their presence does not guarantee that the recorded packages can be installed.

The code is MIT licensed; see [LICENSE.md](LICENSE.md). Collected Gemfiles and lockfiles remain subject to their original licenses.
