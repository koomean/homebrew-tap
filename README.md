# koomean Homebrew tap

Install **avclean**, run **av**:

```sh
brew install koomean/tap/avclean
av
```

Supports macOS on Apple Silicon. A matching bottle is used when available;
otherwise Homebrew builds the pinned runtime from source.

```sh
av update
av doctor
av --self-test
av scan "$HOME/Downloads"
```

[Application source and documentation](https://github.com/koomean/avclean)

Formulae are tested through source installation and their offline integration test.
Upgrades leave user signature databases, logs and quarantine outside the keg intact.
