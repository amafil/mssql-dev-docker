FROM mcr.microsoft.com/windows/servercore:ltsc2022

ADD "https://go.microsoft.com/fwlink/?linkid=2157201" c:/utils/DacFramework.msi

# Download Links:
# ENV exe "https://download.microsoft.com/download/7/c/1/7c14e92e-bdcb-4f89-b7cf-93543e7112d1/SQLServer2019-DEV-x64-ENU.exe"
# ENV box "https://download.microsoft.com/download/7/c/1/7c14e92e-bdcb-4f89-b7cf-93543e7112d1/SQLServer2019-DEV-x64-ENU.box"

COPY SQLServer2022-DEV-x64-ENU.exe /
COPY SQLServer2022-DEV-x64-ENU.box /

ENV sa_password="personalPassword0" \
    attach_dbs="[]" \
    ACCEPT_EULA="Y" \
    sa_password_path="C:\ProgramData\Docker\secrets\sa-password"

SHELL ["powershell", "-Command", "$ErrorActionPreference = 'Stop'; $ProgressPreference = 'SilentlyContinue';"]

EXPOSE 1433

# make install files accessible
COPY start.ps1 /
WORKDIR /

RUN Start-Process -Wait -FilePath .\SQLServer2022-DEV-x64-ENU.exe -ArgumentList /qs, /x:setup ; \
.\setup\setup.exe /q /ACTION=Install /INSTANCENAME=MSSQLSERVER /FEATURES=SQLEngine /UPDATEENABLED=1 /SQLSVCACCOUNT='NT AUTHORITY\NETWORK SERVICE' /SQLSYSADMINACCOUNTS='BUILTIN\ADMINISTRATORS' /TCPENABLED=1 /NPENABLED=0 /IACCEPTSQLSERVERLICENSETERMS /SQLMAXDOP=1 /SQLBACKUPDIR='C:\Server\MSSQL\Backup' /SQLUSERDBDIR='C:\Server\MSSQL\DB' /SQLUSERDBLOGDIR='C:\Server\MSSQL\DB' ; \
Remove-Item -Recurse -Force SQLServer2022-DEV-x64-ENU.exe, SQLServer2022-DEV-x64-ENU.box, setup

RUN stop-service MSSQLSERVER ; \
set-itemproperty -path 'HKLM:\software\microsoft\microsoft sql server\mssql16.MSSQLSERVER\mssqlserver\supersocketnetlib\tcp\ipall' -name tcpdynamicports -value '' ; \
set-itemproperty -path 'HKLM:\software\microsoft\microsoft sql server\mssql16.MSSQLSERVER\mssqlserver\supersocketnetlib\tcp\ipall' -name tcpport -value 1433 ; \
set-itemproperty -path 'HKLM:\software\microsoft\microsoft sql server\mssql16.MSSQLSERVER\mssqlserver\' -name LoginMode -value 2 ;

HEALTHCHECK CMD [ "sqlcmd", "-Q", "select 1" ]

CMD .\start -sa_password $env:sa_password -ACCEPT_EULA $env:ACCEPT_EULA -attach_dbs \"$env:attach_dbs\" -Verbose