Function Get-StartUpShutdown
{
  <#
  .SYNOPSIS 
    This function will get the Startup and Shutdown datetime.
  
  .DESCRIPTION 
    This function will get the Startup and Shutdown datetime, for the last specified months.
  
  .PARAMETER ComputerName 
    Specifies the computer name ar an array of computers. 

  .PARAMETER Credential
    Specifies a user account that has permission to perform this action. The default value is the current user.
  
  .PARAMETER LastMonths 
    Specifies the number of months passed. Default is last 3 months starting from today.
    
  .EXAMPLE 
    PS C:\> Get-StartUpShutdown -ComputerName foo -LastMonths 4
    This command gets the start up and shutdown for the last 4 months.
  
  .NOTES 
    Author:     Daniel Schwitzgebel
    Created:    22/07/2014
    Modified:   04/12/2020
    Version:    1.7.0
  #>
    
  [OutputType([System.Diagnostics.EventLogEntry])]
  param ( 
    [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
    [ValidateNotNullOrEmpty()] 
    [String[]]
    $ComputerName,

    [Parameter()]
    [ValidateNotNull()]
    [System.Management.Automation.PSCredential]
    [System.Management.Automation.Credential()]
    $Credential = [System.Management.Automation.PSCredential]::Empty,
        
    [Parameter()]
    [ValidateNotNullOrEmpty()]
    [String]
    $LastMonths = 3
  )

  begin
  {
    $getWinEventParams = @{
      FilterHashtable = @{
        LogName      = 'System'
        ProviderName = 'Microsoft-Windows-Kernel-General'
        ID           = 12, 13
        Level        = 4
        StartTime    = (Get-Date).AddMonths(-($LastMonths))
      }
    }

      if ($Credential -ne [System.Management.Automation.PSCredential]::Empty)
      {
        $getWinEventParams['Credential'] = $Credential
      }
    }
    
    process
    {
      foreach ($computer in $ComputerName)
      {
        try
        {
          $getWinEventParams['ComputerName'] = $computer
          Get-WinEvent @getWinEventParams | ForEach-Object {
            switch ($_.Id)
            { 
              12 { $action = 'Startup' } 
              13 { $action = 'Shutdown' }    
            }

            [PSCustomObject]@{
              'Computer Name' = $computer
              ID              = $_.Id
              Action          = $action
              'Time Created'  = $_.TimeCreated
            }
          }
        }
        catch [System.Management.Automation.RuntimeException]
        {
          Write-Warning -Message "Error contacting $computer"
        }
        catch
        {
          throw $_.Exception.Message        
        }
      }
    }
  }