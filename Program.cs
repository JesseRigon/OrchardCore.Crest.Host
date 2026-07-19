using BlazingOrchard;
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

builder.Services
    .AddOrchardCms()
    .AddSetupFeatures("OrchardCore.AutoSetup", "Blazing", "BlazingOrchard.Admin", "BlazingOrchard.Site");

var app = builder.Build();

if (!app.Environment.IsDevelopment())
{
    app.UseExceptionHandler("/Error");
}

app.UseStaticFiles();
app.UseOrchardCore();

await app.RunAsync();
