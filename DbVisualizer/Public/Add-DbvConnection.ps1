param (
    [Parameter(Mandatory = $true)]
    $Alias,

    [Parameter(Mandatory = $true)]
    [ValidateSet('Development', 'Test', 'Production')]
    $PermissionMode,

    [Parameter(Mandatory = $true)]
    [ValidateSet('Db2 LUW', 'Db2 z/OS', 'Netezza', 'SQL Server')]
    $Driver,

    [Parameter(Mandatory = $true)]
    $Server,

    [Parameter(Mandatory = $true)]
    $Port,

    [Parameter(Mandatory = $true)]
    $Database
)

# things to update
<#

Alias
Notes
Url
Driver
Profile
Type
ServerInfoFormat
Properties
UrlFormat
UrlVariables

#>

$databaseXml = @"
<Database id="101">
    <Alias>$Alias</Alias>
    <Notes />
    <Url />
    <Driver>$Driver</Driver>
    <Userid />
    <Profile>auto</Profile>
    <Type>sqlserver</Type>
    <Password></Password>
    <ServerInfoFormat>1</ServerInfoFormat>
    <Properties>
    <Property key="integratedSecurity">true</Property>
    <Property key="dbvis.ConnectionBorder">Red.png</Property>
    <Property key="dbvis.ConnectionMode">Production</Property>
    </Properties>
    <UrlFormat>0</UrlFormat>
    <UrlVariables>
    <Driver>
        $Driver
        <UrlVariable UrlVariableName="Server">$Server</UrlVariable>
        <UrlVariable UrlVariableName="Port">$Port</UrlVariable>
        <UrlVariable UrlVariableName="Database">$Database</UrlVariable>
        <UrlVariable UrlVariableName="Instance" />
    </Driver>
    </UrlVariables>
</Database>
"@