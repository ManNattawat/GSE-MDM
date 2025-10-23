# Delete old agent-app and copy new Knox Agent
Write-Host "Removing old agent-app..."
if (Test-Path "agent-app") {
    Remove-Item "agent-app" -Recurse -Force
    Write-Host "✅ Removed old agent-app"
}

Write-Host "Copying new Knox Agent..."
Copy-Item "D:\projects\GSE-Enterprise-Platform\knox-agent\*" "agent-app\" -Recurse -Force
Write-Host "✅ Copied Knox Agent files"

Write-Host "Creating Cordova structure..."
New-Item -ItemType Directory -Path "agent-app\platforms" -Force | Out-Null
New-Item -ItemType Directory -Path "agent-app\plugins" -Force | Out-Null
Write-Host "✅ Created Cordova folders"

Write-Host "Replacement complete!"
