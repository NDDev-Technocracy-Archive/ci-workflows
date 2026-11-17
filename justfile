set shell := ["bash", "-euo", "pipefail", "-c"]
set positional-arguments

# List the maintained source and contract commands.
default:
    @just --list

# Prepare only the repository's existing hash-locked source dependency.
setup-checks:
    python3.13 -I -B -m venv --copies .venv
    uv pip install --python .venv/bin/python --require-hashes --only-binary=:all: -r requirements-ci.txt

# Run build-free syntax/workflow checks; the native/executable contract estate stays separate.
check:
    just --fmt --check
    .venv/bin/python -I -B scripts/check_python_syntax.py
    actionlint .github/workflows/ci.yml .github/workflows/maintenance.yml .github/workflows/release.yml .github/workflows/runtime-fixtures-event-write.yml .github/workflows/runtime-fixtures-languages.yml .github/workflows/runtime-fixtures.yml .github/workflows/codeql.yml .github/workflows/dependency-review.yml .github/workflows/scorecard.yml
    zizmor --offline --no-progress .github/workflows/ci.yml .github/workflows/maintenance.yml .github/workflows/release.yml .github/workflows/runtime-fixtures-event-write.yml .github/workflows/runtime-fixtures-languages.yml .github/workflows/runtime-fixtures.yml .github/workflows/codeql.yml .github/workflows/dependency-review.yml .github/workflows/scorecard.yml

# Run the complete original core contracts, including their executable controls.
test:
    .venv/bin/python -I -B scripts/check_python_execution_contract.py --launch validate_all.py -- --tier core

# Retain exact PR-diff or complete-history secret scope.
audit-source scope="--all": check
    betterleaks git --no-banner --redact "--log-opts=$1" .

# Generate the catalog's documentation through the existing isolated launcher.
generate-docs:
    .venv/bin/python -I -B scripts/check_python_execution_contract.py --launch generate_docs.py --

# Format the owned command source.
fix:
    just --fmt
