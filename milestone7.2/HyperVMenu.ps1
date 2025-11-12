# Menu style script to do a fair few things in HyperV
$menu = @()
$menu += "`n"
$menu += "Select and option"
$menu += "1: Show VM Summary"
$menu += "2: Show VM Details"
$menu += "3: Restore Latest Snapshot"
$menu += "4: Create a Full VM Clone"
$menu += "5: Change VM Memory Size"
$menu += "6: Change VM CPU Count"
$menu += "7: Delete VM"
$menu += "8: Copy a file to a VM"
$menu += "9: Execute a command on a VM"
$menu += "0: Exit"

$Operation = $true
While($Operation){
    For($i = 0; $i -lt $menu.Length; $i++){
        Write-Host $menu[$i] 
    }
    $Selection = Read-Host -Prompt "Selection"
    if($Selection -eq 0){
        Write-Host "Exiting"
        $Operation = $false
    }
    Elseif($Selection -eq 1){
    # Deliverable 1
        $VMStatus = Get-VM | select Name,State
        $OutputAllVMs = @()
        for($i = 0; $i -lt $VMStatus.Length; $i++){
            $NetworkAdapter = Get-VMNetworkAdapter -VMName $VMStatus[$i].Name
            $OutputAllVMs += [PSCustomObject]@{"Name" = $VMStatus[$i].Name;`
                                         "Power State" = $VMStatus[$i].State;`
                                         "IP" = $NetworkAdapter.IPAddresses;}
        }
        Write-Host ($OutputAllVMs | Format-Table -Wrap -AutoSize | Out-String)
    }
    Elseif($Selection -eq 2){
    # Deliverable 2
        Get-VM | Select Name | Out-String
        $TargetVM = Read-Host -Prompt "`nPlease select a name"
        Get-VM -Name $TargetVM | select VMName,VMId,State,ProcessorCount,MemoryStartup
    }
    #Deliverables 3-8:
    Elseif($Selection -eq 3){
        Get-VM | Select Name | Out-String
        $TargetVM = Read-Host -Prompt "`nPlease select a name"
        Get-VM -Name $TargetVM | Get-VMSnapshot | Sort CreationTime | Select -Last 1 | Restore-VMSnapshot
    }
    Elseif($Selection -eq 4){
        #Get the parent vm and clone name
        $ParentName = Read-Host -Prompt "What is the parent VM name?"
        $operation = $true
        While($operation){
            $CloneName = Read-Host -Prompt "What should the VM clone be called?"
            if($CloneName -eq $ParentName){
                Write-Host "Please enter a different name for your clone."
            }
            else{
                $operation = $flase
            }
        }

        # Creating useful variables for the parent
        $ParentVM = Get-VM -Name $ParentName
        $ParentVHDPath = ($ParentVM | select VMId | Get-VHD | select ParentPath).ParentPath
        $ParentVHD = Get-Item $ParentVHDPath

        
        #Creating the new vhdx
        $CloneVHDName = $CloneName + ".vhdx"
        $CloneVHDPath = Join-Path 'C:\Users\Public\Documents\Hyper-V\Virtual hard disks' $CloneVHDName
        Copy-Item $ParentVHDPath -Destination $CloneVHDPath 
        $cloneVHD = get-item $CloneVHDPath
        if($CloneVHD.Attributes -match "ReadOnly"){
            $CloneVHD.Attributes = 'Archive'
        }

        #Creating and configuring the new VM
        New-VM -Name $CloneName -MemoryStartupBytes $ParentVM.MemoryStartup -Generation 2 -VHDPath $CloneVHDPath
        Set-VM -Name $CloneName -ProcessorCount $ParentVM.ProcessorCount
        Set-VMFirmware -VMName $CloneName -EnableSecureBoot Off
    }
    Elseif($Selection -eq 5){
    #Change a VM's memory size
        Get-VM | Select Name | Out-String
        $TargetVM = Read-Host -Prompt "`nPlease select a name"
        Get-VM -Name $TargetVM | select Name,MemoryStartup | Format-Table -Wrap -AutoSize
        $NewMemorySize = Read-Host -Prompt "`nNew Memory Size"
        $NewMemorySize = Invoke-Expression $NewMemorySize
        Stop-VM -Name $TargetVM -Passthru | Set-VM -MemoryStartupBytes $NewMemorySize 
        $SubOp = $true 
        while($SubOp){
            $StartUpVM = Read-Host -Prompt "`nStart VM?(Y/n)"
            if ($StartUpVM -ilike 'n'){
                Write-Host "`nDone"
                $SubOp = $false
            }
            Elseif ($StartUpVM -ilike 'y' -or $StartUpVM -eq ''){
                Start-VM -Name $TargetVM
                Write-Host "`nDone"
                $SubOp = $false
            }
            Else{
                Write-Host "`nPlease enter Y/n"
               } 
        }
    }
    Elseif($Selection -eq 6){
    #Change a VM's CPU count
        Get-VM | Select Name | Out-String
        $TargetVM = Read-Host -Prompt "`nPlease select a name"
        Get-VM -Name $TargetVM | select Name,ProcessorCount | Format-Table -Wrap -AutoSize
        $NewCpuCount = Read-Host -Prompt "`nNew CPU Count"
        Stop-VM -Name $TargetVM -Passthru | Set-VM -ProcessorCount $NewCpuCount
        $SubOp = $true 
        while($SubOp){
            $StartUpVM = Read-Host -Prompt "`nStart VM?(Y/n)"
            if ($StartUpVM -ilike 'n'){
                Write-Host "`nDone"
                $SubOp = $false
            }
            Elseif ($StartUpVM -ilike 'y' -or $StartUpVM -eq ''){
                Start-VM -Name $TargetVM
                Write-Host "`nDone"
                $SubOp = $false
            }
            Else{
                Write-Host "`nPlease enter Y/n"
               } 
        }
    }
    Elseif($Selection -eq 7){
        Get-VM | Select Name | Out-String
        $TargetVM = Read-Host -Prompt "`nPlease select a name"
        $TargetVMVHDPath = (get-vm $TargetVM | Select-Object -Property VMId | Get-VHD).Path 
        Remove-VM $TargetVM
        Remove-Item $TargetVMVHDPath
    }
    Elseif($Selection -eq 8){
        Get-VM | Select Name | Out-String
        $TargetVM = Read-Host -Prompt "`nPlease select a name"
        $FileToSend = Read-Host -Prompt "`nEnter a file path to send to the VM"
        $DestPath = Read-Host -Prompt "`nEnter a destination path on the vm"
        Enable-VMIntegrationService -Name 'Guest Service Interface' -VMName $TargetVM
        Copy-VMFile -Name $TargetVM -SourcePath $FileToSend -DestinationPath $DestPath -FileSource Host -CreateFullPath
    }
    Elseif($Selection -eq 9){
        $TargetVM = Read-Host -Prompt "Please select a name"
        $VMCommand = Read-Host -Prompt "`nEnter a command to send to the VM"
        Enable-VMIntegrationService -Name 'Guest Service Interface' -VMName $TargetVM
        $filePathTemp = Join-Path $PSScriptRoot "command.ps1"
        $VMCommand | Out-File -FilePath $filePathTemp 
        Invoke-Command -VMName $TargetVM $filePathTemp
    }
    Else{
        Write-Host "Please enter a number from 0-9" | Out-String
    }
}