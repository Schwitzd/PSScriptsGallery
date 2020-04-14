function Resize-PartitionMaxSize
{
    <# 
    .SYNOPSIS 
        This function will extend the partition to the maximum size.
    
    .DESCRIPTION 
        This function will extend the partition to the maximum size available on the disk.
    
    .PARAMETER ComputerName
        Specifies the computer name.

    .PARAMETER DriveLetter
        Specifies the drive letter to expand.

    .EXAMPLE 
        PS C:\> Resize-PartitionMaxSize -ComputerName foo -DriveLetter E
        This command expands the given drive on the remote computer.
    
    .NOTES 
        Author:     Daniel Schwitzgebel
        Created:    14/04/2020
        Modified:   14/x04/2020
        Version:    1.0
  #> 

    [OutputType([Void])]
    [CmdletBinding(SupportsShouldProcess)]
    param (
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [String]
        $ComputerName,
      
        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [String]
        $DriveLetter
    )

       
    begin
    {
        try 
        {
            $session = New-CimSession -ComputerName $ComputerName -ErrorAction Stop
        }
        catch 
        {
            throw 'Failed to connect on the remove host.'
        }
    }
        
    process
    {
        try
        {
            if ($PSCmdlet.ShouldProcess("$DriveLetter Partition", "Resize to maximum available"))
            {
                $getPartitionSupportedSizeParam = @{
                    CimSession  = $session
                    DriveLetter = $DriveLetter
                }

                $sizeMax = (Get-PartitionSupportedSize @getPartitionSupportedSizeParam).SizeMax

                $resizePartitionParam = @{
                    CimSession  = $session 
                    DriveLetter = $DriveLetter
                    Size        = $sizeMax
                }
                Resize-Partition @resizePartitionParam
            }
        }
        catch
        {
            throw "failed to resize the $DriveLetter partition."
        }
    }
        
    end
    {
        Remove-CimSession -CimSession $session       
    }
}