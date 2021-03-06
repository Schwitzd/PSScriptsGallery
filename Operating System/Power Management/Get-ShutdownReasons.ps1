function Get-ShutdownReasons {
  <#
  .SYNOPSIS 
    This function will export all shutdown reasons within asked reason.
  
  .DESCRIPTION 
    This function will export all the shutdown reasons within the asked period in HTML Report.
  
  .PARAMETER ComputerName
    Specifies the computer name. 
  
  .PARAMETER DayBack
    Specifies the Dayback for lookup.

  .PARAMETER Destination
    Specifies the path to save HTML Report.
    
  .EXAMPLE 
    PS C:\> Get-ShutdownReasons -ComputerName foo -DayBack 30 -Destination 'c:\temp'
    This command gets the shutdown reasons of the last 30 days on the file 'c:\temp'.
  
  .NOTES 
    Author:    Daniel Schwitzgebel
    Created:   02/01/2017
    Modified:  14/08/2020
    Version:   1.4
  #>

  param ( 
    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [String]
    $ComputerName,

    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [int]
    $DayBack,
      
    [Parameter(Mandatory)]
    [ValidateScript({
        if (-not (Test-Path -LiteralPath $_ -PathType Container))
          {throw "Path doesn't exist"}
        else 
          {$true}
    })]
    [System.IO.DirectoryInfo]
    $Destination
  )

  $htmlReport = "$Destination\$ComputerName" + '_ShutdownReasons.html'

  if (Test-Path -Path $htmlReport) {
    Remove-Item -Path $htmlReport
  }

  $getWinEventParams = @{
    ComputerName = $ComputerName
    FilterHashtable = @{
      LogName      = 'System'
      ProviderName = 'USER32'
      ID = 1074
      Level = 4
      StartTime = (Get-Date).AddDays(-($DayBack))
    }
  }

  $convertToHtmlParams = @{
    Title      = "$ComputerName Shutdown Reasons"
    PreContent = @"
  <h3>$ComputerName Shutdown Reasons</h3>
  <h4>for the last $DayBack days</h4>
"@
    Head       = @"
  <style>
    Body    {font-family: Verdana,sans-serif; font-size: 10pt; font-weight: normal;}
    table   {font-family: Verdana,sans-serif; font-size: 10pt; font-weight: normal; margin: 0 auto; width:85%; border-collapse: collapse}
    th, td  {text-align: left; padding: 8px;}
    th      {background-color: #8c8c8c; color: white;}
    h3, h4  {Color: #333333;}
    tr:nth-child(even) {background-color: #f2f2f2}
  </style>
"@ 
  }

  Get-WinEvent @getWinEventParams | Where-Object { $_.Message -match 'Shutdown' } | 
    Select-Object ID, TimeCreated, ProviderName, Message | 
      ConvertTo-Html @convertToHtmlParams | 
        Out-File $htmlReport
}