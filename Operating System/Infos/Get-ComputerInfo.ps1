Function Get-ComputerInfo
{
  <#
  .SYNOPSIS 
    This function will get hardware and OS infos.
  
  .DESCRIPTION 
    This function will get the hardware and OS infos, computer must be on.
  
  .PARAMETER ComputerName 
    Specifies the computer name.
    
  .EXAMPLE 
    PS C:\> Get-ComputerInfo -ComputerName foo
    This command gets the info for the given computer name.
  
  .NOTES 
    Author:     Daniel Schwitzgebel 
    Created:    09/03/2016
    Modified:   11/04/2020
    Version:    2.1.1
  #>

  [OutputType([String])] 
  param( 
    [Parameter(Mandatory)] 
    [String]
    $ComputerName
  )
 
  if (Test-Connection -ComputerName $ComputerName -Quiet)
  {

    try
    {
      $SOptions = New-CimSessionOption -Protocol DCOM
      $Session = New-CimSession -ComputerName $ComputerName -SessionOption $SOptions -ErrorAction Stop
    }
    catch [Microsoft.Management.Infrastructure.SessionException]
    {
      $_.Exception.Message
    }

    $computerProduct = Get-CimInstance -CimSession $Session -Class Win32_ComputerSystemProduct
    $computerSystem = Get-CimInstance -CimSession $Session -Class Win32_ComputerSystem
    $computerCPU = Get-CimInstance -CimSession $Session -Class Win32_Processor
    $ComputerHDD = Get-CimInstance -CimSession $Session -Class Win32_DiskDrive
    $ComputerPartitions = Get-CimInstance -CimSession $Session -Class Win32_LogicalDisk -Filter drivetype=3
    $computerNet = Get-CimInstance -CimSession $Session -Class Win32_NetworkAdapterConfiguration -Filter 'IPEnabled = True'
    $computerOS = Get-CimInstance -CimSession $Session -Class Win32_OperatingSystem
    $ComputerOSVersion = Invoke-Command -ComputerName $ComputerName -ScriptBlock { 
      Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion' -Name ReleaseID | Select-Object ReleaseID 
    }

    Clear-Host
    Write-Host "System Information for: $($computerSystem.Name)" -BackgroundColor DarkCyan
    Write-Host
    "Vendor: $($computerProduct.Vendor)"
    "Model: $($computerProduct.Version)"
    "Product ID: $($computerProduct.Name)"
    "Serial Number: $($computerProduct.IdentifyingNumber)"
    Write-Host
    "CPU: $($computerCPU.Name)"
    "RAM: " + "{0:N2}" -f ($computerSystem.TotalPhysicalMemory / 1GB) + "GB"
    Write-Host
    ForEach ($HDD in $ComputerHDD)
    {
      "HardDisk Model: $($HDD.Model)"
      "HardDisk Size: {0:N2}" -f ($HDD.Size / 1GB) + "GB"
    }
    Write-Host
    ForEach ($partition in $ComputerPartitions)
    {  
      "$($partition.DeviceID) Capacity: {0:N2}" -f ($partition.Size / 1GB) + "GB"
      "$($partition.DeviceID) Free Space: {0:N2}" -f ($partition.FreeSpace / 1GB) + "GB ({0:P2}" -f ($partition.FreeSpace / $partition.Size) + ")"
    } 
    Write-Host
    "Operating System: $($computerOS.caption) $($ComputerOSVersion.ReleaseId)"
    "User logged In: $($computerSystem.UserName)"
    "Last Reboot: $($computerOS.LastBootUpTime)"
    Write-Host
    "Network IP: $($computerNet.IPAddress)"
    "Network MAC: $($computerNet.MACAddress)"
    Write-Host
  }
  Remove-CimSession $Session
}