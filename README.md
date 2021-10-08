# mssql-2019-dev-docker

Windows docker image of SQL Server 2019 Developer

- Microsoft SQL Server Developer

Build image:

`docker build -t mssql-2019-dev .`

Start container:

`docker run -p 8080:8080 -d filoa86/mssql-2019-dev:latest`

Default SQL Server credentials:

```
Username: sa
Password: personalPassword0
```

if you want to change password can change `Dockerfile`

```
    ...
ENV sa_password="personalPassword0" \
    ...
```
