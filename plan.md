# Blazing Orchard Remaining Work

This file tracks work that is not implemented yet. Architecture overviews live in:

- [`README.md`](README.md) - host setup and project overview.
- [`modules/BlazingOrchard.OrchardCoreModule/README.md`](modules/BlazingOrchard.OrchardCoreModule/README.md) - module repository architecture.
- [`modules/BlazingOrchard.OrchardCoreModule/BlazingOrchard.Server/README.md`](modules/BlazingOrchard.OrchardCoreModule/BlazingOrchard.Server/README.md) - Orchard-side runtime and API strategy.
- [`modules/BlazingOrchard.OrchardCoreModule/BlazingOrchard.Components/README.md`](modules/BlazingOrchard.OrchardCoreModule/BlazingOrchard.Components/README.md) - component library, admin WASM theme, and site theme overview.

## Current Repository Shape

```text
blazing-orchard/
  BlazingOrchard.Host.csproj
  Program.cs
  appsettings.Development.json        # simple dotnet-run AutoSetup config
  App_Data/                           # generated Orchard tenant data (ignored)
  Recipes/blazing.dev.recipe.json     # local SQLite dev recipe
  tests/playwright/                   # reusable browser validation scripts
  modules/BlazingOrchard.OrchardCoreModule/
    BlazingOrchard.Server/            # Orchard runtime module, adapters, middleware, legacy frame
    BlazingOrchard.Components/        # shared Radzen-based component library
      Components/
      Models/
      Shapes/
      Themes/
        BlazingOrchard.Admin/         # Orchard admin theme manifest
          wasm/                       # current Blazor WebAssembly admin shell
        BlazingOrchard.Site/          # included Orchard site theme
```

## Neutral Client/Core Package

- [ ] Create a UI-library-neutral client package, likely:

  ```text
  modules/BlazingOrchard.OrchardCoreModule/BlazingOrchard.Client/
    Context/
    Display/
    LegacyFrame/
    Models/
    Routing/
  ```

- [ ] Move client-safe DTO contracts out of `BlazingOrchard.Components` when they are not Radzen-specific.
- [ ] Move shared shape/model contracts into the neutral client package.
- [ ] Keep the neutral client package free of Radzen, Orchard server assemblies, MVC, Razor Pages, and `Microsoft.AspNetCore.App` server-only dependencies.
- [ ] Update `BlazingOrchard.Components`, `BlazingOrchard.Admin/wasm`, and module WASM projects to reference the neutral client package after extraction.

## Display Management

- [ ] Define the neutral display abstractions, for example:

  ```text
  BlazingOrchard.Client/Display/IBlazingDisplayManager.cs
  BlazingOrchard.Client/Display/BlazingDisplayManager.cs
  BlazingOrchard.Client/Display/BlazingDisplayDriver.cs
  BlazingOrchard.Client/Display/BlazingDisplayContext.cs
  BlazingOrchard.Client/Display/BlazingDisplayResult.cs
  BlazingOrchard.Client/Display/BlazingPlacementInfo.cs
  ```

- [ ] Decide whether the current admin WASM `DisplayManagement` code should be split into:
  - neutral display/rendering orchestration, and
  - admin-shell state/session/theme services.
- [ ] Move neutral display concepts out of `modules/BlazingOrchard.OrchardCoreModule/BlazingOrchard.Components/Themes/BlazingOrchard.Admin/wasm/DisplayManagement`.
- [ ] Keep Radzen renderers in `BlazingOrchard.Components`, not in the neutral display package.
- [ ] Expand concrete Radzen field renderers in `BlazingOrchard.Components/Components/Model` or a dedicated `Components/Display` area as needed.

## Legacy Frame Client Abstraction

The Orchard-side legacy frame selector/theme already exists in `BlazingOrchard.Server`. Remaining work is to extract reusable client-side behavior from the current admin shell.

- [ ] Move iframe URL-building behavior out of the Radzen admin shell into the neutral client package.
- [ ] Create a reusable neutral component or service set, for example:

  ```text
  BlazingOrchard.Client/Components/LegacyFrame.razor
  BlazingOrchard.Client/LegacyFrame/LegacyFrameUrlBuilder.cs
  BlazingOrchard.Client/LegacyFrame/LegacyFrameOptions.cs
  ```

- [ ] Keep `legacy-frame=1` / `legacy-frame=true` as the shared query convention.
- [ ] Allow `BlazingOrchard.Components` to wrap or style the neutral legacy frame component with Radzen-specific chrome.
- [ ] Ensure future component systems can reuse the legacy frame selector, frame theme, URL convention, and client iframe behavior without copying Radzen admin-shell code.

## Module Discovery And Routing

The current system has build-time WASM project discovery in `BlazingOrchard.Admin/wasm/BlazingOrchard.Admin.Wasm.csproj` for module projects matching `modules/*/blazor-wasm/*.csproj`. Remaining work is to formalize this into an explicit extension model.

- [ ] Replace or supplement the current build-time WASM project glob with an explicit module registry/manifest model.
- [ ] Define how Orchard modules declare Blazing-compatible routes, component assemblies, scripts, styles, and permissions.
- [ ] Define how module-contributed component assemblies are served to the WASM admin shell.
- [ ] Define route collision behavior and precedence.
- [ ] Define how module metadata is represented in the boot manifest returned by `api/blazing/app`.
- [ ] Keep module discovery generic so future component systems can opt into the same conventions.

## API And Contract Cleanup

- [ ] Audit every `api/blazing/*` endpoint against Orchard's native APIs.
- [ ] Replace custom content reads with Orchard Contents REST API or GraphQL where sufficient.
- [ ] Verify whether Orchard Core exposes suitable JSON APIs for:
  - content definitions,
  - roles,
  - site settings,
  - features.
- [ ] Add or verify explicit authorization checks for all admin-level reads and writes.
- [ ] Add antiforgery handling for state-changing Blazing endpoints where needed.
- [ ] Keep `api/blazing/*` endpoints thin: they should call Orchard services, enforce Orchard permissions, and return Blazor-friendly JSON without owning duplicate state.

## Packaging

- [ ] Decide final NuGet package boundaries:
  - `BlazingOrchard.Server`
  - `BlazingOrchard.Components`
  - `BlazingOrchard.Client`
  - theme packages if needed
- [ ] Set `IsPackable=true` where packages are intended.
- [ ] Add package metadata, descriptions, icons/readmes, repository metadata, and license metadata.
- [ ] Verify package dependency boundaries so `BlazingOrchard.Server` does not depend on Radzen.
- [ ] Verify component packages do not accidentally include generated `bin`/`obj` or unrelated theme source.
- [ ] Decide whether Orchard-loadable themes are packaged independently or bundled with the components package.

## Documentation

- [ ] Document how a third-party Orchard module contributes a `blazor-wasm` project.
- [ ] Document how a third-party Orchard module contributes Blazing admin routes and menu entries.
- [ ] Document how a future non-Radzen component system should integrate.
- [ ] Document the legacy frame URL/query contract.
- [ ] Keep the expected API-selection order documented: Orchard native API, GraphQL, Query API, OpenID/JWT, then thin Blazing adapter.

## Validation

- [ ] `dotnet build BlazingOrchard.Host.csproj --no-restore`
- [ ] `dotnet run --project BlazingOrchard.Host.csproj`
- [ ] `node tests/playwright/dev-setup-admin.js`
- [ ] Add Playwright coverage for legacy frame fallback routes.
- [ ] Add Playwright coverage for module-contributed Blazor routes when this host includes a sample module.

Browser validation should use reusable scripts under `tests/playwright`; avoid inline one-off Playwright scripts.
