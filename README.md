# Windows docker image of SQL Server for development purpose

_Microsoft SQL Server 2022 Developer Edition_
## Prerequisites

- Download SQL Server Developer from [here](https://www.microsoft.com/en-us/sql-server/sql-server-downloads)
- Run `SQL2022-SSEI-Dev.exe`, select `Download media` and choose `CAB` option.

### Build image

`docker build -t mssql-developer .`

### Run container:

`docker run -p 1433:1433 -d -m 2g`

### Default SQL Server credentials:

```
Username: sa
Password: personalPassword0
```

if you want to change default password edit `Dockerfile`

```dockerfile
    ...
ENV sa_password="personalPassword0" \
    ...
```
