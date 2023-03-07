Function Invoke-WIDQuery {
    <#
        .DESCRIPTION
        Windows Internal Database query for things like rds broker database, wsus etc.
        might need elevated permission if run against local db.
        inspiration from various code out there.
        .PARAMETER ComputerName
        supply remote server, if skipped it will connect locally.
        .PARAMETER Query
        SQL query like, "select name from sys.databases"
        .PARAMETER Database
        databasename, such as 'RDCms'
        .EXAMPLE
        Invoke-WIDQuery -ComputerName <server> -Database rdcms -Query 'SELECT * from [rds].[server]'
        .EXAMPLE
        Invoke-WIDQuery -ComputerName <server> -Database master -Query 'SELECT name, database_id, create_date FROM sys.databases'
        .NOTES
        rds relevant tables for things.
        SELECT * from [RDCms].[rds].[Server]
        SELECT * from [RDCms].[rds].[RoleRdsh]
        SELECT * from [RDCms].[rds].[RoleRdcb]
        SELECT * from [RDCms].[rds].[RoleRdls]
        SELECT * from [RDCms].[rds].[RoleRdvh]
        ELECT * from [RDCms].[rds].[RoleRdwa]
        "select name from sys.databases"
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
        [pscredential]
        $Credential
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
    }
    process {
        Try {
            $SQLblock = {
                if (Get-Module -ListAvailable -Name SqlServer) {
                    Import-Module -Name SqlServer
                    $value = Invoke-Sqlcmd -ServerInstance 'np:\\.\pipe\MICROSOFT##WID\tsql\query' -Database $using:Database -Query $using:Query
                    return $value
                } else {
                    $sqlconn = New-Object System.Data.SqlClient.SqlConnection
                    $sqlconn.ConnectionString = "Server=np:\\.\pipe\MICROSOFT##WID\tsql\query;Integrated Security=True;Initial Catalog=$($using:Database);"
                    $sqlconn.Open()
                    $sqlcmd = $sqlconn.CreateCommand()
                    $sqlcmd.CommandText = $using:Query
                    $adapter = New-Object System.Data.SqlClient.SqlDataAdapter $sqlcmd
                    $data = New-Object System.Data.Dataset
                    $data.columns.add('PSComputerName')
                    $data.Columns['PSComputerName'].DefaultValue = $env:computername
                    $adapter.fill($data) | Out-Null
                    $sqlconn.close()
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
