<#
 # Sandbox testing installation in Windows
 #>

$project_path = $($PSScriptRoot | Split-Path -Parent | Split-Path -Parent)
$project_name = $($project_path | Split-Path -Leaf)
$vm_path = "$env:TEMP\vm.wsb"

$vm = @"
<Configuration>
    <Networking>Enable</Networking>
    <MappedFolders>
        <MappedFolder>
            <HostFolder>$project_path</HostFolder>
            <SandboxFolder>C:\Users\WDAGUtilityAccount\Desktop\$project_name</SandboxFolder>
            <ReadOnly>false</ReadOnly>
        </MappedFolder>
        <MappedFolder>
            <HostFolder>${HOME}\Downloads</HostFolder>
            <SandboxFolder>C:\Users\WDAGUtilityAccount\Downloads</SandboxFolder>
            <ReadOnly>false</ReadOnly>
        </MappedFolder>
    </MappedFolders>
    <LogonCommand>
        <Command>C:\\Windows\\System32\\WindowsPowerShell\\v1.0\\powershell.exe -executionpolicy unrestricted -command "start powershell {-noexit -nologo -file C:\\Users\\WDAGUtilityAccount\\Desktop\\$project_name\\install.ps1}"</Command>
    </LogonCommand>
</Configuration>
"@


# Main Section ================================================================
Write-Host "Run Windows Sandbox builder." -ForegroundColor Green
Write-Host "Path project : $project_path" -ForegroundColor Yellow

Set-Content -Path $vm_path -Value $vm
. $vm_path
Start-Sleep 10
Remove-Item $vm_path
