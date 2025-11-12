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

#Changing parent file atributes
if($ParentVHD.Attributes -notmatch "ReadOnly"){
    $ParentVHD.Attributes += 'ReadOnly'
}
#Creating the new vhdx
$CloneVHDName = $CloneName + ".vhdx"
$CloneVHDPath = Join-Path 'C:\Users\Public\Documents\Hyper-V\Virtual hard disks' $CloneVHDName
#this errors out but works ¯\_(ツ)_/¯ 
New-VHD -Path $CloneVHDPath -ParentPath $ParentVHDPath -Differencing

#Creating and configuring the new VM
New-VM -Name $CloneName -MemoryStartupBytes $ParentVM.MemoryStartup -Generation 2 -VHDPath $CloneVHDPath
Set-VM -Name $CloneName -ProcessorCount $ParentVM.ProcessorCount
Set-VMFirmware -VMName $CloneName -EnableSecureBoot Off