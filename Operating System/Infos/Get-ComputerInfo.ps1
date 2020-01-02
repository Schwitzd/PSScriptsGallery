Function Get-ComputerInfo
{
  <#
  .SYNOPSIS 
    This function will get hardware and OS infos.
  
  .DESCRIPTION 
    This function will get the hardware and OS infos, computer must be on.
    Admins right needed to run this script
  
  .PARAMETER ComputerName 
    A single Computer.
    
  .EXAMPLE 
    Get-ComputerInfo -ComputerName foo
  
  .NOTES 
    Author:     Daniel Schwitzgebel 
    Created:    09/03/2016
    Modified:   10/12/2019
    Version:    2.1
    Changes:    1.1   Change - Layout field "HDD Free Space"
                1.2   Add    - Network Infos (IP & MAC)
                1.3   Change - Improved code (Variable Interpolation and Parameters)
                1.4   Add    - Information for multiple partitions
                      Add    - Information for multiple HDs
                1.4.1 Change - Serial number and Model number were reversed
                2.0   Change - Function renamed from Get-HardwareInfo to Get-ComputerInfo
                      Change - Replaced Get-WmiObject with Get-CimInstance
                2.1   Change - Code restyle and OutputType
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