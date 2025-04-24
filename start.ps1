# The script sets the sa password and start the SQL Service
# Also it attaches additional database from the disk
# The format for attach_dbs

param(
    [Parameter(Mandatory = $false)]
    [string]$sa_password,

    [Parameter(Mandatory = $false)]
    [string]$ACCEPT_EULA,

    [Parameter(Mandatory = $false)]
    [string]$attach_dbs,
    [Parameter(Mandatory = $false)]
    [string]$bakPath,
    [Parameter(Mandatory = $false)]
    [string]$sqlVersion
)

if ($ACCEPT_EULA -ne "Y" -And $ACCEPT_EULA -ne "y") {
    Write-Host "ERROR: You must accept the End User License Agreement before this container can start."
    Write-Host "Set the environment variable ACCEPT_EULA to 'Y' if you accept the agreement."

    exit 1
}

# start the service
Write-Host "Starting SQL Server"
Start-Service MSSQLSERVER

if ([String]::IsNullOrEmpty((sqlcmd -Q "SET NOCOUNT ON;SELECT 1 FROM sys.databases WHERE name not in ('master','tempdb','model','msdb');SET NOCOUNT OFF" -h -1))) {
    Write-Host "Initializing"
    if ($sa_password -eq "_") {
        if (Test-Path $env:sa_password_path) {
            $sa_password = Get-Content -Raw $secretPath
        }
        else {
            Write-Host "WARN: Using default SA password, secret file not found at: $secretPath"
        }
    }

    if ($sa_password -ne "_") {
        Write-Host "Changing SA login credentials"
        $sqlcmd = "ALTER LOGIN sa with password=" + "'" + $sa_password + "'" + ";ALTER LOGIN sa ENABLE;"
        & sqlcmd -Q $sqlcmd
    }

    $attach_dbs_cleaned = $attach_dbs.TrimStart('\\').TrimEnd('\\')

    $dbs = $attach_dbs_cleaned | ConvertFrom-Json

    if ($null -ne $dbs -And $dbs.Length -gt 0) {
        Write-Host "Attaching $($dbs.Length) database(s)"

        Foreach ($db in $dbs) {
            $files = @();
            Foreach ($file in $db.dbFiles) {
                $files += "(FILENAME = N'$($file)')";
            }

            $files = $files -join ","
            $sqlcmd = "IF EXISTS (SELECT 1 FROM SYS.DATABASES WHERE NAME = '" + $($db.dbName) + "') BEGIN EXEC sp_detach_db [$($db.dbName)] END;CREATE DATABASE [$($db.dbName)] ON $($files) FOR ATTACH;"

            Write-Host "Invoke-Sqlcmd -Query $($sqlcmd)"
            & sqlcmd -Q $sqlcmd
        }
    }

    $bakPathCleaned = $bakPath.TrimStart('\\').TrimEnd('\\')
    if ($bakPathCleaned -ne "_") {
        if (Test-Path "$bakPathCleaned") {
            Write-Host "Restoring $bakPathCleaned"
            $sqlcmd = "RESTORE FILELISTONLY FROM DISK = '$bakPathCleaned'"
            $files = sqlcmd -Q $sqlcmd -s "," -W
            $files = $files[2..($files.length - 3)] #remove header and footer
            $importcmd = "RESTORE DATABASE mydatabase FROM DISK = '$bakPathCleaned'"
            if ($files.Count -gt 0) {
                $importcmd += "WITH "
                foreach ($file in $files) {
                    $fileRow = $file -split ","
                    $logicalName = $fileRow[0]
                    $physicalName = Join-Path "C:\Program Files\Microsoft SQL Server\MSSQL$sqlVersion.MSSQLSERVER\MSSQL\DATA" (Split-Path $fileRow[1] -Leaf)
                    if ($importcmd -like "*MOVE*TO*") {
                        $importcmd += ","
                    }
                    $importcmd += "MOVE '$logicalName' TO '$physicalName'"
                }
            }
            sqlcmd -Q "$importcmd"
            if (!$?) {
                exit 1
            }
        }
        else {
            Write-Host "Could not find $bakPathCleaned"
            Exit 1
        }
    }
}

Write-Host "Started SQL Server."

Write-Host "Ready for connections!"
$lastCheck = (Get-Date).AddSeconds(-2)
while ($true) {
    Get-EventLog -LogName Application -Source "MSSQL*" -After $lastCheck | Select-Object TimeGenerated, EntryType, Message
    $lastCheck = Get-Date
    Start-Sleep -Seconds 2
}