<!-- start title -->

# GitHub Action: NeuVector Image Scan

<!-- end title -->
<!-- start description -->

Scans a container image for vulnerabilities with [NeuVector](https://neuvector.com)

<!-- end description -->

[![GitHub Release][release-img]][release]
[![GitHub Marketplace][marketplace-img]][marketplace]
[![License][license-img]][license]

## Usage

### Scan locally built container image

```yaml
name: build
on:
  push:
    branches:
      - main
jobs:
  build:
    name: Build
    runs-on: ubuntu-latest
    steps:
      - name: Checkout code
        uses: actions/checkout@v2
      - name: Build image
        run: |
          docker build -t registry.organization.com/org/image-name:${{ github.sha }} .
      - name: Scan Image
        uses: bashofmann/neuvector-image-scan-action@main
        with:
          image-repository: registry.organization.com/org/image-name
          image-tag: ${{ github.sha }}
          min-high-cves-to-fail: "1"
          min-medium-cves-to-fail: "1"
```

### Scan image from remote registry

```yaml
name: build
on:
  push:
    branches:
      - main
jobs:
  build:
    name: Build
    runs-on: ubuntu-latest
    steps:
      - name: Checkout code
        uses: actions/checkout@v2
      - name: Scan Remote Image
        uses: bashofmann/neuvector-image-scan-action@main
        with:
          image-registry: https://registry.organization.com/
          image-registry-username: ${{ secrets.RegistryUsername }}
          image-registry-password: ${{ secrets.RegistryPassword }}
          image-repository: org/image-name
          image-tag: 1.0.0
          min-high-cves-to-fail: "1"
          min-medium-cves-to-fail: "1"
```

## Customizing

### Inputs

The following inputs can be used in `step.with`:

<!-- start inputs -->

| **Input**                     | **Description**                                                                             | **Default**                | **Required** |
| ----------------------------- | ------------------------------------------------------------------------------------------- | -------------------------- | ------------ |
| **`image-registry`**          | Registry of the image to scan, e.g. `https://registry.organization.com/`                    |                            | **false**    |
| **`image-registry-username`** | Username for the registry authentication                                                    |                            | **false**    |
| **`image-registry-password`** | Password for the registry authentication                                                    |                            | **false**    |
| **`image-repository`**        | Repository of the image to scan, e.g. `org/image-name`                                      |                            | **true**     |
| **`image-tag`**               | Tag of the image to scan, e.g. `1.0.0`                                                      |                            | **true**     |
| **`min-high-cves-to-fail`**   | Minimum CVEs with high severity to fail the job                                             | `0`                        | **false**    |
| **`min-medium-cves-to-fail`** | Minimum CVEs with medium severity to fail the job                                           | `0`                        | **false**    |
| **`cve-names-to-fail`**       | Comma-separated list of CVE names that make the job fail, e.g. `CVE-2021-4160,CVE-2022-0778 |                            | **false**    |
| **`nv-scanner-image`**        | NeuVector Scanner image to use for scanning                                                 | `neuvector/scanner:latest` | **false**    |
| **`output`**                  | Output format, one of: `text`, `json`, `csv`                                                | `text`                     | **false**    |
| **`debug`**                   | Debug mode, on of: `true`, `false`                                                          | `false`                    | **false**    |

<!-- end inputs -->

### Outputs

<!-- start outputs -->

| \***\*Output\*\***           | \***\*Description\*\***                              | \***\*Default\*\*** | \***\*Required\*\*** |
| ---------------------------- | ---------------------------------------------------- | ------------------- | -------------------- |
| `vulnerability_count`        | Number of found vulnerabilities                      | undefined           | undefined            |
| `high_vulnerability_count`   | Number of found vulnerabilities with high severity   | undefined           | undefined            |
| `medium_vulnerability_count` | Number of found vulnerabilities with medium severity | undefined           | undefined            |

<!-- end outputs -->

### Usage

<!-- start usage -->

```yaml
- uses: bashofmann/neuvector-image-scan-action@main
  with:
    # Registry of the image to scan, e.g. `https://registry.organization.com/`
    # Default:
    image-registry: ""

    # Username for the registry authentication
    # Default:
    image-registry-username: ""

    # Password for the registry authentication
    # Default:
    image-registry-password: ""

    # Repository of the image to scan, e.g. `org/image-name`
    image-repository: ""

    # Tag of the image to scan, e.g. `1.0.0`
    image-tag: ""

    # Minimum CVEs with high severity to fail the job
    # Default: 0
    min-high-cves-to-fail: ""

    # Minimum CVEs with medium severity to fail the job
    # Default: 0
    min-medium-cves-to-fail: ""

    # Comma-separated list of CVE names that make the job fail, e.g.
    # `CVE-2021-4160,CVE-2022-0778
    # Default:
    cve-names-to-fail: ""

    # NeuVector Scanner image to use for scanning
    # Default: neuvector/scanner:latest
    nv-scanner-image: ""

    # Output format, one of: `text`, `json`, `csv`
    # Default: text
    output: ""

    # Debug mode, on of: `true`, `false`
    # Default: false
    debug: ""
```

<!-- end usage -->

[release]: https://github.com/bashofmann/neuvector-image-scan-action/releases/latest
[release-img]: https://img.shields.io/github/release/bashofmann/neuvector-image-scan-action.svg?logo=github
[marketplace]: https://github.com/marketplace/actions/bashofmann/neuvector-image-scan
[marketplace-img]: https://img.shields.io/badge/marketplace-bashofmann/neuvector-image-scan--action-blue?logo=github
[license]: https://github.com/bashofmann/neuvector-image-scan-action/blob/master/LICENSE
[license-img]: https://img.shields.io/github/license/bashofmann/neuvector-image-scan-action
