# Namdurash/homebrew-tap

Homebrew formulae for [ai-foundry](https://github.com/Namdurash/ai-foundry).

```sh
brew install Namdurash/tap/aif
```

The tap is resolved by convention: `Namdurash/tap` expands to this repository,
`Namdurash/homebrew-tap`, so no explicit `brew tap` step is needed first.

## Formulae

| Formula | What it is |
|---|---|
| `aif` | AI Foundry — puts an existing project on AI SDLC rails |

## Releasing a new version

1. Tag the release in `ai-foundry` and push the tag.
2. Recompute the checksum of the generated tarball:

   ```sh
   curl -sL https://github.com/Namdurash/ai-foundry/archive/refs/tags/vX.Y.Z.tar.gz | shasum -a 256
   ```

3. Update `url` and `sha256` in `Formula/aif.rb`, then commit.
4. Verify before anyone else does:

   ```sh
   brew install --build-from-source Namdurash/tap/aif
   brew test aif
   brew audit --strict --online Namdurash/tap/aif
   ```
