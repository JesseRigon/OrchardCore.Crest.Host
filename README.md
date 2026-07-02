# Blazing Orchard Host

This repository is a minimal Orchard Core host for trying the Blazing Orchard module and themes. It intentionally keeps the host small: Orchard owns runtime setup, while Blazing Orchard lives in `modules/BlazingOrchard` as a Git submodule.

Use this repo when you want a clean Orchard application with Blazing Orchard for testing the project.

## Setup

Clone the repository with submodules, or initialize them after cloning:

```bash
git submodule update --init --recursive
```

Then run it like a normal Orchard Core application:

```bash
dotnet restore
dotnet run --project BlazingOrchard.Host.csproj
```

Open the URL printed by `dotnet run` and complete Orchard's setup screen.

Then go to Admn/Themes url and select the Blazing Orchard Admin theme. 

Automatically, or on page refresh, you should see the new Blazor Admin Shell with the new menu. Title bar has been implemented badly. This is a proof of concept. 

It will still load standard Orchard pages as iframes within the Blazor shell, though not all functionality has been looked at or tested. Again this is a proof of concept.

Listed pages below are the only full Blazor pages so far in this project. I will be updating the referenced submodule on a semi regular basis, slowly converting the rest into Blazor. It's not ready for a nuget package yet.

Blazor Implemeted Pages:
Admin/Themes
Admin/AdminMenus
