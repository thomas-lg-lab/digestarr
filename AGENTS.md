# Working on this repository (humans and agents)

- **Read [CONTRIBUTING.md](CONTRIBUTING.md)**: the development environment (devcontainer), the local checks
  (`./scripts/format.sh`, `./scripts/typecheck.sh`, `./scripts/test.sh`), the lockfiles (`./scripts/compile-deps.sh`,
  never edited by hand) and the release flow. [CONFIGURATION.md](CONFIGURATION.md) documents the settings.
- **Trunk-based.** Short branch, one squash PR into `main`, signed commits. PR titles are Conventional Commits,
  checked by the required `conventions / title` check; the label and the release notes come from them.
- **Merging is not releasing.** `main` builds the `edge` image; only a published release builds `latest`.
- **Shared workflows.** PR conventions, release notes, the image build and registry cleanup call the reusable
  workflows of `thomas-lg-lab/.github` at a version tag; change them there. Issue forms and the PR template
  are the organisation's defaults (how to fill them: that repository's README).
- **Dependencies** are updated by Renovate; do not bump them by hand in a feature PR.
- **Secrets** never go in the repository, in a commit message or in a log. Technical files are in English.
