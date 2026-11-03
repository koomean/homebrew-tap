# koomean Homebrew tap

Install **avclean**, run **av**:

```sh
brew install koomean/tap/avclean
av
```

After the first installation, Homebrew remembers the tap and trusts this formula,
so `brew install avclean`, `brew upgrade avclean` and `brew uninstall avclean`
work by short name.

To use `brew install avclean` for the first installation, set up the tap once:

```sh
brew tap koomean/tap
brew trust --formula koomean/tap/avclean
brew install avclean
```

`brew trust` is required on Homebrew 6 and later; older versions can omit that line.
A fresh machine cannot discover this third-party tap from the short name alone.
The package is not part of `homebrew/core`; inclusion requires Homebrew review.
See [Homebrew's tap trust documentation](https://docs.brew.sh/Tap-Trust).

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
