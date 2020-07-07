Function Get-StartUpShutdown
{
  <#
  .SYNOPSIS 
    This function will get the Startup and Shutdown datetime.
  
  .DESCRIPTION 
    This function will get the Startup and Shutdown datetime, for the last daterange.
  
  .PARAMETER ComputerName 
    Specifies the computer name. 
  
  .PARAMETER Months 
    Specifies the filters by a range date. Default is last 3 months starting from today.
    Format date is MM/dd/yyyy
    
  .EXAMPLE 
    PS C:\> Get-StartUpShutdown -ComputerName foo -Months 01/11/2013
    This command gets the start up and shutdown for the last 30 days.
  
  .NOTES 
    Author:     Daniel Schwitzgebel
    Created:    22/07/2014
    Modified:   11/04/2020
    Version:    1.5.1
  #>
    
  [OutputType([System.Diagnostics.EventLogEntry])]
  param ( 
    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()] 
    [String]
    $ComputerName,
        
    [Parameter()] 
    [ValidateNotNullOrEmpty()]
    [String]
    $Months
  )

  begin
  {
    if ($PSBoundParameters.ContainsKey('Months'))
    {
      [datetime]$Months = (Get-Date).AddMonths(-$($Months))
    }
    else
    {
      [datetime]$Months = (Get-Date).AddMonths(-3)
    }
  }
    
  process
  {
    try
    {
      $getEventLogParams = @{
        ComputerName = $ComputerName
        LogName      = 'System'
        After        = $Months
        Source       = 'Microsoft-Windows-Kernel-General'
        ErrorAction  = 'Stop'
      }
      
      Get-EventLog @getEventLogParams | Where-Object { 
        $_.EventId -eq 12 -or $_.EventId -eq 13;
        $eventid = $_.EventId;
        
        switch ($eventid)
        { 
          12 { $action = 'Startup' } 
          13 { $action = 'Shutdown' }    
        }
        $_ | Add-Member -MemberType NoteProperty -Name Action -Value $action;
      } | Select-Object EventId, Action, TimeGenerated | Sort-Object TimeGenerated
}
    catch
    {
      throw 'Error contacting the host!'
    }
  }
}