using System.Text.Json;
using Crest;
using Serilog;

var builder = WebApplication.CreateBuilder(args);

builder.Host.UseSerilog((context, logger) =>
{
    logger.ReadFrom.Configuration(context.Configuration);
});

builder.Services.PostConfigure<BlazorAdminThemeOptions>(options =>
{
    options.BlazorRouteSourceDirectories = [];
    options.BlazorRoutes = new(StringComparer.OrdinalIgnoreCase)
    {
        "/admin",
        "/admin/adminmenu",
        "/admin/adminmenu/list",
        "/admin/adminmenus",
        "/admin/designsystem",
        "/admin/themes",
        "/login",
    };
});

var setupFeatures = new List<string>
{
    "OrchardCore.Crest",
    "OrchardCore.Crest.Admin",
    "OrchardCore.Crest.Site",
};

if (IsAutoSetupRecipeAvailable(builder))
{
    setupFeatures.Insert(0, "OrchardCore.AutoSetup");
}
else
{
    Console.WriteLine("AutoSetup recipe is not available; OrchardCore.AutoSetup will not be enabled. Existing tenants can run normally, and new tenants can be set up manually.");
}

builder.Services
    .AddOrchardCms()
    .AddSetupFeatures([.. setupFeatures]);

var app = builder.Build();

if (!app.Environment.IsDevelopment())
{
    app.UseExceptionHandler("/Error");
}

app.UseStaticFiles();
app.UseOrchardCore();

await app.RunAsync();

static bool IsAutoSetupRecipeAvailable(WebApplicationBuilder builder)
{
    var recipeName = builder.Configuration
        .GetSection("OrchardCore:OrchardCore_AutoSetup:Tenants")
        .GetChildren()
        .Select(section => section["RecipeName"])
        .FirstOrDefault(value => !string.IsNullOrWhiteSpace(value));

    if (string.IsNullOrWhiteSpace(recipeName))
    {
        return false;
    }

    var recipesPath = Path.Combine(builder.Environment.ContentRootPath, "Recipes");
    if (!Directory.Exists(recipesPath))
    {
        return false;
    }

    foreach (var recipePath in Directory.EnumerateFiles(recipesPath, "*.json", SearchOption.AllDirectories))
    {
        try
        {
            using var stream = File.OpenRead(recipePath);
            using var document = JsonDocument.Parse(stream);
            if (document.RootElement.TryGetProperty("name", out var name) &&
                string.Equals(name.GetString(), recipeName, StringComparison.OrdinalIgnoreCase))
            {
                return true;
            }
        }
        catch (JsonException)
        {
            // Ignore unrelated or malformed JSON files. If no matching recipe is found, AutoSetup remains disabled.
        }
    }

    return false;
}
