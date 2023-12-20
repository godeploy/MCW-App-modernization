function Wait-Install {
    $msiRunning = 1
    $msiMessage = ""
    while($msiRunning -ne 0)
    {
        try
        {
            $Mutex = [System.Threading.Mutex]::OpenExisting("Global\_MSIExecute");
            $Mutex.Dispose();
            $DST = Get-Date
            $msiMessage = "An installer is currently running. Please wait...$DST"
            Write-Host $msiMessage 
            $msiRunning = 1
        }
        catch
        {
            $msiRunning = 0
        }
        Start-Sleep -Seconds 1
    }
}
$branchName = "main"
# Install App Service Migration Assistant
Wait-Install
Write-Host "Installing App Service Migration Assistant..."
Start-Process -file 'C:\AppServiceMigrationAssistant.msi ' -arg '/qn /l*v C:\asma_install.txt' -passthru | wait-process

# Install Edge
Wait-Install
Write-Host "Installing Edge..."
Start-Process -file 'C:\MicrosoftEdgeEnterpriseX64.msi' -arg '/qn /l*v C:\edge_install.txt' -passthru | wait-process

# Install .NET Core 3.1 SDK
Wait-Install
Write-Host "Installing .NET Core 3.1 SDK..."
$pathArgs = {C:\dotnet-sdk-3.1.413-win-x64.exe /Install /Quiet /Norestart /Logs logCore31SDK.txt}
Invoke-Command -ScriptBlock $pathArgs

# Copy Web Site Files
Wait-Install
Write-Host "Copying default website files..."
Expand-Archive -LiteralPath "C:\MCW\MCW-App-modernization-$branchName\Hands-on lab\lab-files\web-deploy-files.zip" -DestinationPath 'C:\inetpub\wwwroot' -Force

# Copy the database connection string to the web app.
Write-Host "Updating config.json with the SQL IP Address and connection string information."
Copy-Item "C:\MCW\MCW-App-modernization-$branchName\Hands-on lab\lab-files\src\src\PartsUnlimitedWebsite\config.json" -Destination 'C:\inetpub\wwwroot' -Force

Unregister-ScheduledTask -TaskName "Install Lab Requirements" -Confirm:$false

# Restart the app for the startup to pick up the database connection string.
Write-Host "Restarting IIS"
iisreset.exe /restart
