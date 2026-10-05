# Gemfile corpus

1,477 original Gemfiles from 656 public GitHub repositories, sampled across 2021-2026. Includes Rails, Hanami, Sinatra, Roda, Padrino, Cuba and Grape applications.

Files live in `gemfiles/<year>/<owner>/<repository>/Gemfile`. Identical versions within a project are kept once, under their earliest sampled year. Projects that call `gemspec` or `load_gemspec` are skipped. Only Gemfiles (or `gems.rb`) are collected.

Gemfiles are provided as-is, with no guarantee that they evaluate, resolve or install successfully. Companion files and project-specific setup may be missing. You are responsible for verifying results with canonical tools such as Bundler, using the Ruby and tool versions appropriate to each snapshot. Corpus verification checks file integrity, not compatibility or usability.

Add repositories to `sources.tsv` (leave the snapshot columns empty for a new repository), then run the scraper. It fetches yearly snapshots, deduplicates and verifies them automatically:

```sh
ruby tools/collect.rb
```

Requires Ruby 3.3 or newer and an authenticated GitHub CLI (`gh`). The script never executes downloaded Gemfiles. `sources.tsv` is the single source list, with columns `repository`, `path`, `commit` and `sha256`.

Run the tests, including verification of the stored corpus:

```sh
ruby test/corpus_test.rb
```

The code is MIT licensed; see [LICENSE.md](LICENSE.md). Collected Gemfiles remain subject to their original licenses.
