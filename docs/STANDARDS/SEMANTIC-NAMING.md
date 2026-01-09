# Semantic Naming Standards

semantic git commit following Conventional Commits specification
format: type(scope): brief summary (no period, max 50 chars)

## Core Types

- feat: new feature
- fix: bug fix
- docs: documentation only
- style: formatting, missing semi-colons, etc.
- refactor: code change that neither fixes nor adds feature
- perf: performance improvement
- test: add/update tests
- build: build system or dependencies (e.g., npm, webpack)
- ci: continuous integration changes (e.g., GitHub Actions)
- chore: other changes (e.g., tooling, configs)
- revert: revert previous commit

## Optionals

- scope: module/component affected (e.g., `auth`, `api`)
- breaking change: add `!` after type or `BREAKING CHANGE:` in body

## Body

- detailed explanation of change, motivation for change, contrast with previous behavior, etc.
- footer: reference issues closed (e.g., `Closes #123`)

## Examples

````txt
feat(api): add config validation

```txt
fix(loader): resolve null pointer exception
````

```txt
docs: update architecture guide
```

```txt
chore(.claude): clean up directory structure
```

```txt
feat(auth)!: change token format
```

## Rule

ask "apply?" before commit
