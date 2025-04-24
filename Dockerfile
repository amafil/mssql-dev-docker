
FROM mcr.microsoft.com/windows/servercore:ltsc2022

ENV sa_password="_" \
    attach_dbs="[]" \
    ACCEPT_EULA="Y" \
    bakPath="_" \
    sa_password_path="C:\\ProgramData\\Docker\\secrets\\sa-password"

WORKDIR C:\\installer
EXPOSE 1433

# Install SQL Server 2022 Developer Edition
RUN curl -o .\installer.exe https://go.microsoft.com/fwlink/p/?linkid=2215158 -L
RUN .\installer.exe /MEDIATYPE=CAB /Action=Download /Q /Language=en-US /HIDEPROGRESSBAR /MEDIAPATH="C:\installer"
RUN move .\SQLServer2022-DEV-x64-ENU.box .\SQL.box
RUN move .\SQLServer2022-DEV-x64-ENU.exe .\SQL.exe

RUN .\SQL.exe /qs /x:setup
RUN .\setup\setup.exe /q /ACTION=Install /INSTANCENAME=MSSQLSERVER /FEATURES=SQLEngine /UPDATEENABLED=0 /SQLSVCACCOUNT="NT AUTHORITY\NETWORK SERVICE" /SQLSYSADMINACCOUNTS="BUILTIN\ADMINISTRATORS" /TCPENABLED=1 /NPENABLED=0 /IACCEPTSQLSERVERLICENSETERMS

WORKDIR /
SHELL ["powershell", "-noprofile", "-Command", "$ErrorActionPreference = 'Stop'; $ProgressPreference = 'SilentlyContinue'; "]
RUN Remove-Item -Recurse installer -ErrorAction SilentlyContinue

RUN stop-service MSSQLSERVER
RUN set-itemproperty -path 'HKLM:\software\microsoft\microsoft sql server\mssql16.MSSQLSERVER\mssqlserver\supersocketnetlib\tcp\ipall' -name tcpdynamicports -value ''
RUN set-itemproperty -path 'HKLM:\software\microsoft\microsoft sql server\mssql16.MSSQLSERVER\mssqlserver\supersocketnetlib\tcp\ipall' -name tcpport -value 1433
RUN set-itemproperty -path 'HKLM:\software\microsoft\microsoft sql server\mssql16.MSSQLSERVER\mssqlserver\' -name LoginMode -value 2

HEALTHCHECK CMD [ "sqlcmd", "-Q", "select 1" ]
# make install files accessible
COPY start.ps1 /
COPY entry.ps1 /
CMD .\start.ps1 -sa_password $env:sa_password -ACCEPT_EULA $env:ACCEPT_EULA -attach_dbs \"$env:attach_dbs\" -bakPath \"$env:bakPath\" -sqlVersion "16" -Verbose
ENTRYPOINT ["powershell.exe","C:\\entry.ps1"]