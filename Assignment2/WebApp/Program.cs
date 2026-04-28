var builder = WebApplication.CreateBuilder(args);
var app = builder.Build();

app.MapGet("/", () => Results.Content($$"""
    <!DOCTYPE html>
    <html lang="en">
    <head>
      <meta charset="utf-8" />
      <title>Assignment 2 - Container App</title>
      <style>
        body { font-family: system-ui, sans-serif; padding: 2rem; max-width: 720px; margin: auto; }
        h1 { color: #0078d4; }
        dt { font-weight: bold; margin-top: 0.5rem; }
        dd { margin-left: 1rem; font-family: monospace; }
      </style>
    </head>
    <body>
      <h1>Hello from Azure Container Apps</h1>
      <p>Built with .NET 8, containerized with the SDK container tools, deployed via Terraform and GitHub Actions.</p>
      <dl>
        <dt>Hostname</dt><dd>{{Environment.MachineName}}</dd>
        <dt>Server time (UTC)</dt><dd>{{DateTime.UtcNow:O}}</dd>
      </dl>
    </body>
    </html>
    """, "text/html"));

app.Run();
