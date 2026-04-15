$subscription_id = "a7cd0bad-bfc7-40ac-acf2-b07966f12423"

Write-Host "=== Subscription Resources ==="
Get-AzResource | Select-Object Name, ResourceType, ResourceGroupName, Location | Format-Table -AutoSize
