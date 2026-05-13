using Azure.Identity;
using Azure.Messaging.ServiceBus;
using Microsoft.Data.SqlClient;

var builder = WebApplication.CreateBuilder(args);

string? sbNamespace = builder.Configuration["SERVICE_BUS_NAMESPACE"];
string? sbQueue = builder.Configuration["SERVICE_BUS_QUEUE"];
string? sqlConn = builder.Configuration["SQL_CONNECTION_STRING"];

if (string.IsNullOrEmpty(sbNamespace) || string.IsNullOrEmpty(sbQueue))
    throw new InvalidOperationException("SERVICE_BUS_NAMESPACE and SERVICE_BUS_QUEUE must be set.");

var sbClient = new ServiceBusClient(sbNamespace, new DefaultAzureCredential());
var sbSender = sbClient.CreateSender(sbQueue);
builder.Services.AddSingleton(sbSender);

if (!string.IsNullOrEmpty(sqlConn))
{
    await EnsureSqlTableAsync(sqlConn);
}

var app = builder.Build();

app.MapGet("/", () => Results.Content($$"""
    <!DOCTYPE html>
    <html lang="en">
    <head>
      <meta charset="utf-8" />
      <title>Assignment 3 - Container App</title>
      <style>
        body { font-family: system-ui, sans-serif; padding: 2rem; max-width: 720px; margin: auto; }
        h1 { color: #0078d4; }
        form { margin: 2rem 0; padding: 1rem; background: #f3f3f3; border-radius: 8px; }
        input[type=text] { width: 70%; padding: 0.5rem; font-size: 1rem; }
        button { padding: 0.5rem 1rem; font-size: 1rem; background: #0078d4; color: white; border: 0; border-radius: 4px; cursor: pointer; }
        dt { font-weight: bold; margin-top: 0.5rem; }
        dd { margin-left: 1rem; font-family: monospace; }
        .ok { color: green; } .err { color: #c00; }
      </style>
    </head>
    <body>
      <h1>Hello from Azure Container Apps</h1>
      <p>Built with .NET 8, containerized via the SDK container tools, deployed via Terraform and GitHub Actions. Messages flow through Service Bus to an Azure Function and land in blob storage; the extra-credit copy also gets persisted to Azure SQL.</p>

      <form method="post" action="/send">
        <label>Message: <input type="text" name="message" required maxlength="500" placeholder="type a message" /></label>
        <button type="submit">Send to Service Bus</button>
      </form>

      <dl>
        <dt>Hostname</dt><dd>{{Environment.MachineName}}</dd>
        <dt>Server time (UTC)</dt><dd>{{DateTime.UtcNow:O}}</dd>
        <dt>Service Bus namespace</dt><dd>{{sbNamespace}}</dd>
        <dt>Service Bus queue</dt><dd>{{sbQueue}}</dd>
        <dt>SQL configured</dt><dd>{{(string.IsNullOrEmpty(sqlConn) ? "no" : "yes")}}</dd>
      </dl>
    </body>
    </html>
    """, "text/html"));

app.MapPost("/send", async (HttpContext ctx, ServiceBusSender sender) =>
{
    var form = await ctx.Request.ReadFormAsync();
    var message = form["message"].ToString();

    if (string.IsNullOrWhiteSpace(message))
        return Results.BadRequest("message is required");

    var sbTask = sender.SendMessageAsync(new ServiceBusMessage(message));
    var sqlTask = string.IsNullOrEmpty(sqlConn)
        ? Task.CompletedTask
        : InsertSqlAsync(sqlConn, message);

    await Task.WhenAll(sbTask, sqlTask);

    return Results.Content($$"""
        <!DOCTYPE html><html><body style="font-family: system-ui; padding: 2rem;">
          <p class="ok">✓ sent: <code>{{System.Net.WebUtility.HtmlEncode(message)}}</code></p>
          <p>Service Bus: ✓{{(string.IsNullOrEmpty(sqlConn) ? "" : " · SQL: ✓")}}</p>
          <p><a href="/">Send another</a></p>
        </body></html>
        """, "text/html");
});

app.Run();

static async Task EnsureSqlTableAsync(string conn)
{
    await using var c = new SqlConnection(conn);
    await c.OpenAsync();
    await using var cmd = c.CreateCommand();
    cmd.CommandText = @"
        IF OBJECT_ID('dbo.Messages', 'U') IS NULL
        BEGIN
            CREATE TABLE dbo.Messages (
                Id INT IDENTITY PRIMARY KEY,
                Message NVARCHAR(MAX) NOT NULL,
                CreatedAt DATETIME2 DEFAULT SYSUTCDATETIME()
            );
        END";
    await cmd.ExecuteNonQueryAsync();
}

static async Task InsertSqlAsync(string conn, string message)
{
    await using var c = new SqlConnection(conn);
    await c.OpenAsync();
    await using var cmd = c.CreateCommand();
    cmd.CommandText = "INSERT INTO dbo.Messages (Message) VALUES (@m);";
    cmd.Parameters.AddWithValue("@m", message);
    await cmd.ExecuteNonQueryAsync();
}
