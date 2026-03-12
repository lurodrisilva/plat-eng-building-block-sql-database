# Agent Instructions

## Project Overview

Helm **application** chart (`plat-eng-sql-database-package`) that provisions CloudNativePG
PostgreSQL clusters on Kubernetes. Depends on `plat-eng-commons-package` (OCI library chart)
for shared helpers (`myorg.fullname`, `myorg.labels`).

## Build / Lint / Test Commands

```bash
# === Setup (first time only) ===
make plugin-install          # Install helm-unittest plugin + print yamllint/kubeconform install instructions
make dep-build               # Build dependencies for both main chart and test wrapper

# === Linting (three-tier) ===
make lint                    # helm lint .
make yamllint                # yamllint -c .yamllint.yml .
make kubeconform             # helm template | kubeconform --strict --ignore-missing-schemas
make lint-all                # All three above in sequence

# === Unit Tests ===
make test                    # Run all helm-unittest tests (18 tests across 3 suites)

# Run a SINGLE test file:
helm dependency build tests/chart
helm unittest -f 'tests/unit/helpers_test.yaml' tests/chart
helm unittest -f 'tests/unit/serviceaccount_test.yaml' tests/chart
helm unittest -f 'tests/unit/database_test.yaml' tests/chart

# === Combined ===
make all                     # lint-all + test

# === Packaging ===
make package                 # helm package . → plat-eng-sql-database-package-*.tgz
make clean                   # rm -f plat-eng-sql-database-package-*.tgz

# === Render templates locally (debugging) ===
helm template test-release . --set team=test --set environment=dev
```

## Project Structure

```
├── Chart.yaml                        # Chart metadata (v0.1.0, application type)
├── values.yaml                       # Default values
├── templates/
│   ├── _helpers.tpl                  # serviceAccountName helper (4 branches)
│   ├── serviceaccount.yaml           # Conditional ServiceAccount
│   ├── datatabase.yaml               # Range loop → ConfigMap + Secret + CNPG Cluster per DB
│   └── tests/                        # Empty (reserved for Helm native test hooks — do NOT use)
├── tests/chart/                      # Wrapper chart for helm-unittest
│   ├── Chart.yaml                    # Depends on plat-eng-sql-database-package via file://../../
│   ├── values.yaml                   # Test defaults with plat-eng-sql-database-package.* prefix
│   └── tests/unit/
│       ├── helpers_test.yaml         # 4 tests — serviceAccountName branches
│       ├── serviceaccount_test.yaml  # 4 tests — create/skip, annotations, automount
│       └── database_test.yaml        # 10 tests — Secret, Cluster, ConfigMap, multi-db
├── .yamllint.yml                     # yamllint config (excludes templates/, charts/)
├── Makefile                          # 12 targets
└── docs/                             # Reference docs (CNPG, Helm patterns)
```

## Wrapper Chart Test Pattern

Tests use a **wrapper chart** at `tests/chart/` that declares `plat-eng-sql-database-package` as a dependency.
This is required because helm-unittest needs a chart to run against.

**Key implications:**
- Template paths in tests: `charts/plat-eng-sql-database-package/templates/<file>`
- All `set:` values must use the `plat-eng-sql-database-package.` prefix
- Run `helm dependency build tests/chart` before tests (Makefile does this automatically)
- Document ordering in `datatabase.yaml`:
  - WITHOUT migration: `[Secret=0, Cluster=1]`
  - WITH migration: `[ConfigMap=0, Secret=1, Cluster=2]`

## Code Style & Conventions

### Helm Templates

- **Helpers**: Define in `_helpers.tpl` with `{{- define "sql-database.<name>" -}}`
- **Labels**: Always use `{{- include "myorg.labels" . | nindent N }}` (from commons-package)
- **Naming**: Use `{{ include "myorg.fullname" . }}` for resource names; do NOT hardcode
- **Range loops**: Use `{{- range $index, $sql := .Values.databases.sql }}` with `$` for global scope
- **Conditionals**: Guard optional blocks with `{{- if <condition> }}` / `{{- end }}`
- **Whitespace control**: Use `{{-` and `-}}` to trim whitespace; use `nindent` for indentation
- **Document separators**: Use `---` between resources in multi-resource templates

### Values

- `camelCase` for value keys (`serviceAccount`, `fullnameOverride`)
- `snake_case` for database usernames (`my_sql_user`)
- Nested grouping: `databases.sql[]` is an array of database definitions
- Commented examples for optional fields (see `migration` in `values.yaml`)

### YAML Formatting

- 2-space indentation everywhere
- Max line length: 200 characters (`.yamllint.yml`)
- No trailing whitespace
- Files must end with a newline
- `templates/` directory is excluded from yamllint (Go template syntax)

### Unit Tests (helm-unittest)

- One test file per template: `<template_name>_test.yaml`
- Use assertion-based tests, NOT snapshot tests
- Use `documentIndex: N` to target specific resources in multi-doc templates
- Use `hasDocuments: count: N` to verify conditional rendering
- Use `isNull:` / `isNotNull:` for optional field presence
- Cover both happy path AND conditional branches
- Do NOT test `myorg.labels` content (that belongs to commons-package tests)

### Commit Messages

Conventional Commits format:
```
fix(templates): correct Secret stringData indentation
chore: overhaul Makefile for sql-database chart
test: add helm-unittest tests for all templates
feat: add new database template feature
```

Types: `feat`, `fix`, `chore`, `test`, `docs`, `refactor`
Optional scope in parentheses: `fix(templates):`, `chore(ci):`

## Workflow

- Always create a Pull Request when finishing changes. Do not leave committed work on a branch without a PR.
- Run `make all` before committing to verify nothing is broken.
- When modifying templates, run the relevant single test file first for fast feedback.

## Guardrails — Do NOT

- Add Helm native test hooks in `templates/tests/` (reserved, must stay empty)
- Rename `datatabase.yaml` (known typo, separate concern)
- Suppress lint/type errors to make things pass
- Add snapshot tests unless explicitly requested
- Modify `myorg.*` helpers (those belong to `plat-eng-commons-package`)
- Commit `Chart.lock`, `charts/`, or `tests/chart/charts/` (all gitignored)

## Dependencies & Tools

| Tool | Purpose | Install |
|------|---------|---------|
| Helm 3 | Chart templating & packaging | `brew install helm` |
| helm-unittest | Unit testing plugin | `helm plugin install https://github.com/helm-unittest/helm-unittest` |
| yamllint | YAML linting | `brew install yamllint` |
| kubeconform | K8s manifest validation | `brew install kubeconform` |

### Known Quirks

- **kubeconform**: CNPG `Cluster` CRD is not in default K8s schemas — `--ignore-missing-schemas` is required
- **helm-unittest 1.0.3**: `containsDocument:` is broken — use `documentIndex: N` + `isKind:` instead
- **yamllint warnings**: "missing document start" on test files is expected (exit 0, non-blocking)
