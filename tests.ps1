param(
    $Config,
    [System.Management.Automation.PSCredential]$GuestCredential
)

# 
# Tests running on the local machine, e. g. try to ping the test vm
#
task Ping {
    $progressPreference = 'SilentlyContinue';
    Test-Connection $Config.testIp -Quiet 6> $null
    assert (Test-Connection $Config.testIp -Quiet 6> $null) "Unable to ping the server."
}

task Port80 {
    if ( $(Get-PSVersion).Major -ge 6 ) { 
        # Test-NetConnection is not available on core non Windows, older versions of Windows do not contain test net-connection so implemented an additional fall back with .Net.Sockets.
        assert (
            Test-Connection $Config.testIp -TCPPort 80
        ) "Unable to connect to port 80 of the server."
    } 
    else {
        if (Get-Command -Name Test-NetConnection -ErrorAction SilentlyContinue) {
            assert (
                Test-NetConnection $Config.testIp -Port 80
            ) "Unable to connect to port 80 of the server."
        } else {
            assert (
                $(try {$socket = New-Object Net.Sockets.TcpClient($Config.testIp, 80);if ($socket.Connected) {$true};$socket.Close()} catch {})
            ) "Unable to connect to port 80 of the server."
        }
    }
}

#
# Tests running inside the test vm, e. g. check if a service is running. VMware-tools are used to achieve this.
#
task NTDS {
    $splat = @{
        ScriptText      = 'if ( Get-Service "NTDS" -ErrorAction SilentlyContinue ) { Write-Output "running" } else { Write-Output "not running" }'
        ScriptType      = 'PowerShell'
        VM              = $Config.mountName
        GuestCredential = $GuestCredential
    }  
    $output = Invoke-VMScript @splat -ErrorAction Stop
    equals "$($output.Trim())" "running"
}

task MSSQLSERVER {
    $splat = @{
        ScriptText      = 'if ( Get-Service "MSSQLSERVER" -ErrorAction SilentlyContinue ) { Write-Output "running" } else { Write-Output "not running" }'
        ScriptType      = 'PowerShell'
        VM              = $Config.mountName
        GuestCredential = $GuestCredential
    }  
    $output = Invoke-VMScript @splat -ErrorAction Stop
    equals "$($output.Trim())" "running"
}
task .