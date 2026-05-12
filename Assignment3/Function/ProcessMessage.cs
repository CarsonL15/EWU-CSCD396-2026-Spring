using Azure.Identity;
using Azure.Storage.Blobs;
using Microsoft.Azure.Functions.Worker;
using Microsoft.Extensions.Logging;

namespace Assignment3.Function;

public class ProcessMessage(ILogger<ProcessMessage> logger)
{
    private static readonly string BlobAccountUrl =
        Environment.GetEnvironmentVariable("BLOB_ACCOUNT_URL")
        ?? throw new InvalidOperationException("BLOB_ACCOUNT_URL must be set.");

    private static readonly string BlobContainerName =
        Environment.GetEnvironmentVariable("BLOB_CONTAINER_NAME") ?? "messages";

    private static readonly BlobContainerClient Container =
        new BlobServiceClient(new Uri(BlobAccountUrl), new DefaultAzureCredential())
            .GetBlobContainerClient(BlobContainerName);

    [Function(nameof(ProcessMessage))]
    public async Task Run(
        [ServiceBusTrigger("%SERVICE_BUS_QUEUE%", Connection = "ServiceBusConnection")]
        string message,
        FunctionContext context)
    {
        var blobName = $"{DateTime.UtcNow:yyyy/MM/dd/HHmmss-fff}-{Guid.NewGuid():N}.txt";
        logger.LogInformation("Received message ({Length} chars), writing to blob {Blob}", message.Length, blobName);

        await Container.UploadBlobAsync(blobName, BinaryData.FromString(message));
    }
}
