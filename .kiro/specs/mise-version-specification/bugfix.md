# Bugfix Requirements Document

## Introduction

Many `run_mise install` commands across `scripts/lib/langs/*.sh` are missing version specifications, causing mise to install the latest version instead of the pinned version defined in `.unirtm.toml`. This violates version locking principles and breaks reproducibility. The bug affects approximately 40+ tool installations across multiple language modules.

## Bug Analysis

### Current Behavior (Defect)

1.1 WHEN `run_mise install "${_PROVIDER:-}"` is called without a version suffix THEN the system installs the latest available version from the provider instead of the version specified in versions.sh

1.2 WHEN hadolint is installed via `run_mise install "github:hadolint/hadolint"` THEN the system ignores `VER_HADOLINT="2.14.0"` and installs the latest version

1.3 WHEN any tool with a defined `VER_*` variable in versions.sh is installed without `@${_VERSION:-}` THEN the system fails to enforce version locking

1.4 WHEN multiple developers run setup scripts THEN the system installs different tool versions across environments, breaking reproducibility

### Expected Behavior (Correct)

2.1 WHEN `run_mise install "${_PROVIDER:-}@${_VERSION:-}"` is called with a version suffix THEN the system SHALL install the exact version specified in versions.sh

2.2 WHEN hadolint is installed via `run_mise install "github:hadolint/hadolint@2.14.0"` THEN the system SHALL install version 2.14.0 as defined by `VER_HADOLINT`

2.3 WHEN any tool with a defined `VER_*` variable in versions.sh is installed with `@${_VERSION:-}` THEN the system SHALL enforce version locking

2.4 WHEN multiple developers run setup scripts THEN the system SHALL install identical tool versions across all environments

### Unchanged Behavior (Regression Prevention)

3.1 WHEN tools are already installed at the correct version THEN the system SHALL CONTINUE TO skip reinstallation via fast-path checks

3.2 WHEN `run_mise install` is called for tools already managed in .mise.toml THEN the system SHALL CONTINUE TO respect .mise.toml as the source of truth

3.3 WHEN version variables are not defined in versions.sh THEN the system SHALL CONTINUE TO use the provider's default behavior

3.4 WHEN DRY_RUN mode is enabled THEN the system SHALL CONTINUE TO preview installations without executing them

3.5 WHEN tools fail to install THEN the system SHALL CONTINUE TO log failure status and continue with remaining installations
