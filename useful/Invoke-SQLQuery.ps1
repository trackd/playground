Function Invoke-SQLQuery {
    <#
        .DESCRIPTION
        SQL Database query, support for WID with -WID.
        might need elevated permission if run against local WID db.
        inspiration from various code out there.
        successor of Invoke-WIDQuery, figured it would make more sense to support all server instances with small changes.
        it feels a bit redundant but it's nice to have fallback on .NET method for query and support for running against multiple servers.
        probably better to just use the SQLServer module if doing alot of work, alot more flexible.
        trackd
        .PARAMETER ComputerName
        supply remote server, if skipped it will connect locally.
        .PARAMETER Query
        SQL query like, "select name from sys.databases"
        .PARAMETER Database
        databasename, such as 'RDCms' or 'master'
        .PARAMETER ServerInstance
        specify SQL Server Instance, if skipped it will try WID database instance.
        .PARAMETER Credential
        ps credentials
        .PARAMETER WID
        if enabled it will query WID instance np:\\.\pipe...
        .EXAMPLE
        Invoke-SQLQuery -ComputerName <server> -WID -Database rdcms -Query 'SELECT * from [rds].[server]'
        .EXAMPLE
        Invoke-SQLQuery -ComputerName <server> -WID -Database master -Query 'SELECT name, database_id, create_date FROM sys.databases'
        .EXAMPLE
        Invoke-SQLQuery -ComputerName <server> -ServerInstance <name> -Database master -Query 'SELECT name, database_id, create_date FROM sys.databases'
        .NOTES
        rds relevant tables for things. (dont forget -WID)
        SELECT * from [RDCms].[rds].[Server]
        SELECT * from [RDCms].[rds].[RoleRdsh]
        SELECT * from [RDCms].[rds].[RoleRdcb]
        SELECT * from [RDCms].[rds].[RoleRdls]
        SELECT * from [RDCms].[rds].[RoleRdvh]
        SELECT * from [RDCms].[rds].[RoleRdwa]
        .LINK
        https://github.com/trackd/Powershell
    #>
    [CmdletBinding()]
    param (
        [String[]]
        $ComputerName,
        [Parameter(Mandatory = $true)]
        [String]
        $Query,
        [Parameter(Mandatory = $true)]
        [String]
        $Database,
        [Parameter(Mandatory = $true,ParameterSetName = 'ServerInstance' )]
        [String]
        $ServerInstance,
        [pscredential]
        $Credential,
        [Parameter(Mandatory = $true, ParameterSetName = 'WID')]
        [Switch]
        $WID
    )
    begin {
        $params = @{
            ErrorVariable = 'fails'
            ErrorAction   = 'SilentlyContinue'
        }
        if ($ComputerName) {
            $params.ComputerName = $ComputerName
        }
        if ($Credential) {
            $params.Credential = $Credential
        }
        if ($WID.IsPresent) {
            $SQLInstance = 'np:\\.\pipe\MICROSOFT##WID\tsql\query'
        } else {
            $SQLInstance = $ServerInstance
        }
    }
    process {
        Try {
            $SQLblock = {
                if (Get-Module -ListAvailable -Name SqlServer) {
                    Import-Module -Name SqlServer
                    $value = Invoke-Sqlcmd -ServerInstance $using:SQLInstance -Database $using:Database -Query $using:Query
                    return $value
                } else {
                    $sqlconn = New-Object System.Data.SqlClient.SqlConnection
                    $sqlconn.ConnectionString = "Server=$($using:SQLInstance);Integrated Security=True;Initial Catalog=$($using:Database);"
                    $sqlconn.Open()
                    $sqlcmd = $sqlconn.CreateCommand()
                    $sqlcmd.CommandText = $using:Query
                    $adapter = New-Object System.Data.SqlClient.SqlDataAdapter $sqlcmd
                    $data = New-Object System.Data.Dataset
                    $data.columns.add('PSComputerName')
                    $data.Columns['PSComputerName'].DefaultValue = $env:computername
                    $adapter.fill($data) | Out-Null
                    $sqlconn.close()
                    $sqlconn.dispose()
                    return $data.Tables.rows
                }
            }
            $results = Invoke-Command @params -ScriptBlock $SQLblock
        } Catch {
            throw $_
        }
    }
    end {
        $results | Select-Object -ExcludeProperty RunspaceId
        #$fails
    }
}
