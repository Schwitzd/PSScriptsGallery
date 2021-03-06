function Get-LenovoWarranty
{
  <#
  .SYNOPSIS 
    This function will get the lenovo warranty.
  
  .DESCRIPTION 
    This function query the lenovo website to get warranty information.
  
  .PARAMETER ComputerName 
    Specifies the computer name to get warranty info.
    
  .EXAMPLE 
    PS C:\> Get-LenovoWarranty -ComputerName foo
    This command gets the warranty info for computer 'foo'.
  
  .NOTES 
    Author:     Daniel Schwitzgebel
    Created:    03/04/2013
    Modified:   11/04/2020
    Version:    2.1
  #> 

  [OutputType([System.Management.Automation.PSCustomObject])] 
  param ( 
    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [String]
    $ComputerName
  ) 

  begin
  {
    try
    {
      $sn = (Get-ADComputer -Identity $ComputerName -Properties l).l
    }
    catch
    {
      throw 'Computer not existing in AD or Serial Number is missing'
    }
  }

  process
  {
    $invokeRestMethodParam = @{
      Method = 'POST'
      Uri    = 'https://ibase.lenovo.com/POIRequest.aspx'
      Head   = @{ 'Content-Type' = 'application/x-www-form-urlencoded' }
      Body   = "xml=<wiInputForm source='ibase'><id>LSC3</id><pw>IBA4LSC3</pw><product></product><serial>$sn</serial><wiOptions><machine/><parts/><service/><upma/><entitle/></wiOptions></wiInputForm>"
    }
 
    $requestResult = Invoke-RestMethod @invokeRestMethodParam
 
    $warrantyInformation = [PSCustomObject]@{
      Type           = $requestResult.wiOutputForm.warrantyInfo.machineinfo.type
      Model          = $requestResult.wiOutputForm.warrantyInfo.machineinfo.model
      Product        = $requestResult.wiOutputForm.warrantyInfo.machineinfo.product
      SerialNumber   = $requestResult.wiOutputForm.warrantyInfo.machineinfo.serial
      StartDate      = $requestResult.wiOutputForm.warrantyInfo.serviceInfo.warstart
      ExpirationDate = $requestResult.wiOutputForm.warrantyInfo.serviceInfo.wed
      Location       = $requestResult.wiOutputForm.warrantyInfo.serviceInfo.countryDesc
      Description    = $requestResult.wiOutputForm.warrantyInfo.serviceInfo.sdfDesc
    } 
  }
  
  end
  {
    $warrantyInformation
  }
}