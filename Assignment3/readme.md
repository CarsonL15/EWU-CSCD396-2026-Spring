# Assignment 3 - Service Bus + Function + Container App

**Resource group:** [rg-assignment2-carsonl15](https://portal.azure.com/#@/resource/subscriptions/a7cd0bad-bfc7-40ac-acf2-b07966f12423/resourceGroups/rg-assignment2-carsonl15/overview) (reused from Assignment 2)

**Repo:** https://github.com/CarsonL15/EWU-CSCD396-2026-Spring/tree/assignment3

**Live URL:** https://ca-assignment2.thankfulpebble-33e94f85.eastus.azurecontainerapps.io/

## Message flow

```
browser → POST /send → Container App
                      ├─ Service Bus queue → Function App → Blob storage (messages container)
                      └─ Azure SQL Database (Messages table)            [extra credit]
```

## How the workflow triggers

Single workflow `.github/workflows/deploy-assignment3.yml`. A `dorny/paths-filter@v3` step (with `base: github.event.before` so it diffs against the previous commit on the branch, not the merge base with main) decides what to run:

| Push touches... | Jobs that run | Verifying run |
|---|---|---|
| `Terraform/**` only | `infra` → then `app` and `function` (force-redeploy after IaC) | [25779124378](https://github.com/CarsonL15/EWU-CSCD396-2026-Spring/actions/runs/25779124378) |
| `Assignment3/WebApp/**` only | `app` only (infra and function skipped) | [25779250682](https://github.com/CarsonL15/EWU-CSCD396-2026-Spring/actions/runs/25779250682) |
| `Assignment3/Function/**` only | `function` only (infra and app skipped) | [25779473499](https://github.com/CarsonL15/EWU-CSCD396-2026-Spring/actions/runs/25779473499) |

This satisfies "app code → app deploy only", "TF → infra deploy only", and "redeploy app after TF" from the spec.
