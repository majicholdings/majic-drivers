# majic-drivers

**Majic fleet driver cache**, organized by **OS type** and **hardware ID**.

This repo is a public, versioned cache of the **active driver `.inf` packages** each
host in the Majic Holdings fleet is actually using. It is populated automatically by
`Majic-Driver-Cache-Sync.ps1` (in `majicholdings/majic` at
`ai-baseline/Majic-Driver-Cache-Sync.ps1`), which runs on the fleet and iterates
every enrolled host via the Majic Agent connector.

## Why

When a host's Device Manager is fully healthy (no Code 28 "no driver" devices), the
`.inf` (and, where feasible, the backing `.sys`/`.dll`/`.cat` files) that made each
device work are copied here. That gives the fleet a known-good, per-hardware, per-OS
driver library that can be used to repair a fresh or broken host without re-hunting
OEM downloads.

## Folder structure

```
<OS-type>/<sanitized-hardware-id>/<files>
```

- **`<OS-type>`** — derived from the host OS. Examples:
  - `Windows-Server-2025`, `Windows-11-24H2`, `Windows-10-22H2`
  - `Linux-Ubuntu-24.04`, `macOS-14`
- **`<sanitized-hardware-id>`** — the device hardware ID with `\` and `&`
  replaced by `-`. Examples:
  - `PCI\VEN_10DE&DEV_1B81` → `PCI-VEN_10DE-DEV_1B81`
  - `USB\VID_8087&PID_0032` → `USB-VID_8087-PID_0032`

### Files inside each hardware-ID folder

| File | Meaning |
|---|---|
| `<name>.inf` | The driver INF (always uploaded — top priority). |
| `<name>.sys` / `*.dll` / `*.cat` etc. | Backing binaries from the driver-store folder, when the package fits within GitHub's contents-API size limits. |
| `<name>.ver` | Sidecar version file: the `DriverVer` (date + version), provider, class, and the source driver-store `FileRepository` folder. Used for fast version comparison. |
| `MANIFEST.json` | When a package is too large to upload in full, lists every file in the driver-store folder, sizes, the driver version, and the source folder — so the package can be reconstructed/located later. |

## Versioning

Each upload records the driver `DriverVer` (a date + a 4-part version, e.g.
`06/16/2026,32.0.15.7283`). Before overwriting a cached file, the sync script reads
the existing version (from the `.ver` sidecar, or by parsing the cached `.inf`) and
**only overwrites when the incoming driver is newer** (or when the cached copy is
absent/empty). Equal or older drivers are skipped.

Comparison order: **DriverVer date first, then the version quad** (numeric,
component-by-component).

## Population rules

- A host is only cached **once ALL its devices are working** — i.e. `Get-PnpDevice`
  reports **no Code 28 (Problem 28) no-driver devices**. Hosts with unresolved
  devices are skipped until the device-fix worker (`Majic-AI-Device-Fix.ps1`) has
  resolved them.
- Every write is idempotent and version-guarded (see above).

## Do not hand-edit

This cache is machine-maintained. Manual edits may be overwritten on the next sync.
