function Get-SCCMClientCacheInfo
{
	<#
	.SYNOPSIS 
		This function will get information about SCCM Cache.
 
	.DESCRIPTION 
		This function will get information about the local SCCM Cache of the computer.
  
	.EXAMPLE 
		PS C:\> Get-SCCMClientCacheInfo
		This command gets the SCCM cache info for the local computer.
 
	.NOTES 
		Author:		Daniel Schwitzgebel
		Created:	07/04/2016
		Modified:	11/04/2020
		Version:	1.1.1

		TombStone Duration: https://msdn.microsoft.com/en-us/library/cc145723.aspx
		Max Duration: https://msdn.microsoft.com/en-us/library/cc146078.aspx
	#>
	
	process
	{
		try
		{
			$cmObject = New-Object -ComObject "UIResource.UIResourceMgr"
			$cmCacheObjects = $cmObject.GetCacheInfo()
	
			$cacheInfo = [PSCustomObject]@{
				'SCCM Path'                = $cmCacheObjects.Location
				'Total Size (MB)'          = $cmCacheObjects.TotalSize
				'Free Size (MB)'           = $cmCacheObjects.FreeSize
				'Reserved Size (MB)'       = $cmCacheObjects.ReservedSize
				'TombStone Duration (Min)' = $cmCacheObjects.TombStoneDuration
				'Max Duration (Min)'       = $cmCacheObjects.MaxCacheDuration
			}	
		}
		catch 
		{
			throw 'Failed to get SCCM cache information.'
		}
	}	
	end
	{
		$cacheInfo
	}
}