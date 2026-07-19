# Blazing Orchard Host

## Project overview

Blazing Orchard is a minimal Orchard Core host for testing the Blazing Orchard submodule at `modules/BlazingOrchard.OrchardCoreModule`. The current admin experience is a Blazor WebAssembly shell served by Orchard; Orchard remains the authority for tenants, users, permissions, content, features, settings, themes, and navigation.

The main boundary is: `BlazingOrchard.Server` is the backend overlay on top of Orchard, containing Orchard integration, admin-shell serving, legacy-frame infrastructure, and Blazor-admin-specific JSON adapters; `BlazingOrchard.Components` contains the UI code for now, including shared Blazor components plus the Admin and Site theme projects. The theme projects may split into their own repositories/packages later, but currently stay under `BlazingOrchard.Components`.

For a full understanding of the system, start with these docs:

- [`modules/BlazingOrchard.OrchardCoreModule/README.md`](modules/BlazingOrchard.OrchardCoreModule/README.md) — overview of the multi-project module repository, package boundaries, runtime model, legacy frame system, and future module/component direction. It explains how `BlazingOrchard.Server` and `BlazingOrchard.Components` fit together while keeping Orchard as the system of record.
- [`modules/BlazingOrchard.OrchardCoreModule/BlazingOrchard.Server/README.md`](modules/BlazingOrchard.OrchardCoreModule/BlazingOrchard.Server/README.md) — Orchard-side runtime details, API strategy, controller audit, and endpoint rules. It also documents that Blazing Orchard is currently WASM-based, not Hybrid/MAUI/server-rendered yet, with those models left as future possibilities.
- [`modules/BlazingOrchard.OrchardCoreModule/BlazingOrchard.Components/README.md`](modules/BlazingOrchard.OrchardCoreModule/BlazingOrchard.Components/README.md) — Radzen-based component library and theme overview. It explains the shared components, the `BlazingOrchard.Admin` theme/WASM shell, the included `BlazingOrchard.Site` theme, and the current build-time module component convention.

## Simple dev setup

After cloning with submodules, start the host with normal .NET commands:

```bash
dotnet restore
dotnet run --project BlazingOrchard.Host.csproj
```

Development config is checked in at `appsettings.Development.json`. It uses SQLite only, runs AutoSetup with the local `BlazingDev` recipe, creates the dev tenant/user, and listens on **port 5014** by default to avoid colliding with other local Orchard sites commonly using 5010. Generated tenant data is kept in Orchard's standard `App_Data/` folder.

Default login:

- URL: `http://localhost:5014/Admin`
- Username: `admin`
- Password: `BlazingRules1!`

Reset generated data by stopping the app and deleting `App_Data/`.

## Validation

With the dev server running:

```bash
node tests/playwright/dev-setup-admin.js
```

The Playwright test also defaults to `http://127.0.0.1:5014`; override with `BASE_URL` if needed.

The bundled setup recipe enables the Blazing Orchard Admin theme for the Blazor admin shell.
