# Orchard Crest UI Framework Host

## Project overview

Orchard Crest UI Framework is a minimal Orchard Core host for testing the Orchard Crest UI Framework submodule at `modules/OrchardCore.Crest`. The current admin experience is a Blazor WebAssembly shell served by Orchard; Orchard remains the authority for tenants, users, permissions, content, features, settings, themes, and navigation.

The main boundary is: `OrchardCore.Crest.Server` is the backend overlay on top of Orchard, containing Orchard integration, admin-shell serving, legacy-frame infrastructure, and Blazor-admin-specific JSON adapters; `OrchardCore.Crest.Components` contains shared Radzen-backed UI primitives; feature UI and assets live with their owning modules, such as `OrchardCore.Crest.Icons`; `OrchardCore.Crest.Admin` and `OrchardCore.Crest.Site` are root-level theme composition projects.

For a full understanding of the system, start with these docs:

- [`modules/OrchardCore.Crest/README.md`](modules/OrchardCore.Crest/README.md) — overview of the multi-project module repository, package boundaries, runtime model, legacy frame system, and future module/component direction. It explains how `OrchardCore.Crest.Server` and `OrchardCore.Crest.Components` fit together while keeping Orchard as the system of record.
- [`modules/OrchardCore.Crest/OrchardCore.Crest.Server/README.md`](modules/OrchardCore.Crest/OrchardCore.Crest.Server/README.md) — Orchard-side runtime details, API strategy, controller audit, and endpoint rules. It also documents that Orchard Crest UI Framework is currently WASM-based, not Hybrid/MAUI/server-rendered yet, with those models left as future possibilities.
- [`modules/OrchardCore.Crest/OrchardCore.Crest.Components/README.md`](modules/OrchardCore.Crest/OrchardCore.Crest.Components/README.md) — Radzen-based shared component library and ownership boundary notes for feature modules and theme composition projects.

## Simple dev setup

After cloning with submodules, one command up, one command down:

```bash
bash dev/dev.sh up      # restore + run the host in the foreground
bash dev/dev.sh down    # stop the server, shut down build servers, remove all bin/obj
```

`up` clears stale MSBuild incremental markers (a recurring drvfs/WSL failure
mode) and restores before running, so a fresh clone or a post-`down` tree starts
with the same single command. `down` leaves `App_Data/` (tenant state) alone;
`bash dev/dev.sh reset` also deletes it so the next `up` provisions a fresh site.
Plain .NET commands still work if you prefer them:

```bash
dotnet restore
dotnet run --project OrchardCore.Crest.Host.csproj
```

Development config is checked in at `appsettings.Development.json`. It uses SQLite only, runs AutoSetup with the local `OrchardCore.CrestDev` recipe when that recipe is available, creates the dev tenant/user, and listens on **port 5014** by default to avoid colliding with other local Orchard sites commonly using 5010. Generated tenant data is kept in Orchard's standard `App_Data/` folder and is ignored by git.

The AutoSetup recipe is a development convenience, not a runtime requirement. If the `Recipes/` AutoSetup file is removed for a production-style deployment, `dotnet run` still starts without enabling `OrchardCore.AutoSetup`; existing tenant data in `App_Data/` is used normally, and new tenants/users can be created through Orchard's manual setup flow and then the recipe can be run from within the app if desired. For this test repo, if credentials or tenant state drift, stop the app and delete `App_Data/` to force a clean AutoSetup run. For production systems, treat `App_Data/` as tenant data: do not delete it unless intentionally wiping/resetting the site, and back it up first.

Default login:

- URL: `http://crest.localhost:5014/Admin`
- Username: `admin`
- Password: `CrestRules1!`

Use `crest.localhost` instead of `localhost`/`127.0.0.1` when running beside another Orchard app. Browser cookies are scoped by hostname, not port, so separate local hostnames prevent the Orchard auth cookies from replacing each other. If your environment does not resolve the local names, run `/workspaces/fruitful.orchard/dev/local-hostnames.sh` once or add `127.0.0.1 crest.localhost` to your hosts file.

Reset generated data by stopping the app and deleting `App_Data/`.

## Validation

With the dev server running, run the shared Crest admin suite from the submodule:

```bash
BASE_URL=http://crest.localhost:5014 ADMIN_PASSWORD='CrestRules1!' OUTPUT_ROOT="$PWD/tests/playwright/output" node modules/OrchardCore.Crest/tests/playwright/run-admin-suite.js
```

`OUTPUT_ROOT` keeps this host's screenshot baselines (committed under
`tests/playwright/output/base/`) separate from the submodule's own output
directory, whose baselines belong to other hosts. On a baseline change, rerun
with `UPDATE_BASE=1` and review the diff before committing.

The bundled setup recipe enables the Orchard Crest UI Framework Admin theme for the Blazor admin shell.
