# Windows docker image of SQL Server for development purpose

_Microsoft SQL Server 2022 Developer Edition for Windows Containers_

## Build image

```powershell
docker build -t mssql-dev:2022-latest .
```

## Run container

```powershell
docker run -d `
    --name mssql `
    -e sa_password="P@ssword!" `
    -e ACCEPT_EULA="Y" `
    -e attach_dbs="[]" `
    -e bakPath="C:\\backup" `
    -p 1435:1433 `
    -v "C:\temp\mssql-win:C:\backup" `
    mssql-dev:2022-latest
```

Thanks to [https://github.com/microsoft/nav-docker/issues/532](michvllni)