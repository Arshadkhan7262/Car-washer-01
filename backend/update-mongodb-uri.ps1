# Update MongoDB URI to use standard connection string
$envFile = ".env"
$content = Get-Content $envFile -Raw

# Replace SRV connection string with standard format
$oldUri = "mongodb+srv://ramzan123:ramzan123@cluster0.rixikvd.mongodb.net/carwash_pro"
$newUri = "mongodb://ramzan123:ramzan123@cluster0.rixikvd.mongodb.net:27017/carwash_pro?ssl=true&retryWrites=true&w=majority"

$content = $content -replace [regex]::Escape($oldUri), $newUri

Set-Content -Path $envFile -Value $content

Write-Host "✓ Updated MongoDB URI to standard connection string"
Write-Host ""
Write-Host "New connection string:"
Get-Content $envFile | Select-String -Pattern 'MONGODB_URI'
