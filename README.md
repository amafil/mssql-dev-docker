# mssql-dev-docker

Windows docker image of SQL Server Developer

- Microsoft SQL Server Developer

Build image:

`docker build -t mssql-dev .`

Start container:

`docker run -p 1433:1433 -d filoa86/mssql-dev:latest -m 2g`

Default SQL Server credentials:

```
Username: sa
Password: personalPassword0
```

if you want to change default password edit `Dockerfile`

```
    ...
ENV sa_password="personalPassword0" \
    ...
```
