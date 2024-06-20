<#
  .SYNOPSIS
  Performs monthly data updates.

  .DESCRIPTION
  The Update-Month.ps1 script updates the registry with new data generated
  during the past month and generates a report.

  .PARAMETER InputPath
  Specifies the path to the CSV-based input file.

  .PARAMETER OutputPath
  Specifies the name and path for the CSV-based output file. By default,
  MonthlyUpdates.ps1 generates a name from the date and time it runs, and
  saves the output in the local directory.

  .INPUTS
  None. You can't pipe objects to Update-Month.ps1.

  .OUTPUTS
  None. Update-Month.ps1 doesn't generate any output.

  .EXAMPLE
  PS> .\Update-Month.ps1

  .EXAMPLE
  PS> .\Update-Month.ps1 -inputpath C:\Data\January.csv

  .EXAMPLE
  PS> .\Update-Month.ps1 -inputpath C:\Data\January.csv -outputPath C:\Reports\2009\January.csv
#>

    [CmdletBinding()]
    param (
        [Parameter(
            Position=0,
            Mandatory=$True,
            ValueFromPipelineByPropertyName=$True
        )]
        [string]
        $Source,

        [Parameter(
            Position=1,
            Mandatory=$True,
            ValueFromPipelineByPropertyName=$True
        )]
        [ValidateScript({Test-Path -LiteralPath $_ -PathType container -IsValid})]
        [string]
        $Replica,

        [Parameter(
            Position=2,
            ValueFromPipelineByPropertyName=$True
        )]
        [ValidateScript({Test-Path -LiteralPath $_ -PathType leaf -IsValid})]
        [string]
        $LogFile=$PSScriptRoot+"\Folder_Synchronizer_Log.txt",

        [string[]]
        $ExcludeList=$null,

        [switch]
        $WhatIf=$false


    )


    Function Write-Log {

        Param(
            [ValidateSet("INFO", "WARN", "ERROR")]
            [String]
            $Level="***",
     
            [string]
            $Message,
     
            [string]
            $LogFile,

            [switch]
            $WriteHostOff=$false
        )
     
        $Stamp = (Get-Date).toString("yyyy/MM/dd HH:mm:ss")
        $Line = "$Stamp $Level $Message"
     
        If (Test-Path $LogFile ) {
            Add-Content $LogFile -Value $Line
        }
        if(!$WriteHostOff){
            Write-Output $Line
        }
       
    }

function Sync-FolderItems {
    param (
        
        [Parameter(Mandatory=$True)]
        [ValidateScript({Test-Path -LiteralPath $_ -PathType Container})]
        [string]
        $SourceFolder,
        
        [Parameter(Mandatory=$True)]
        [ValidateScript({Test-Path -LiteralPath $_ -IsValid})]
        [string]
        $DestinationFolder,

        [string[]]
        $ExcludedList,

        [string]
        $LogFile,

        [switch]
        $WriteHostOff=$false,

        [switch] $WhatIf=$false

    )

    

    if(!(Test-Path -LiteralPath $DestinationFolder -PathType container)){
        try {
            Write-Log -Level INFO -Message "Creating Folder in Path: $($DestinationFolder)" -LogFile $LogFile -WriteHostOff:$WriteHostOff
            New-Item -Path $DestinationFolder -ItemType "Directory" -ErrorAction Stop -WhatIf:$WhatIf|out-null
            Write-Log -Level INFO -Message "Successfully created folder in Path: $($DestinationFolder)" -LogFile $LogFile -WriteHostOff:$WriteHostOff
        }
        catch {
            Write-Log -Level ERROR -Message "Failed to create folder in Path: $($DestinationFolder)" -LogFile $LogFile -WriteHostOff:$WriteHostOff
            Write-Log -Level ERROR -Message $($error[0].ToString() + $error[0].InvocationInfo.PositionMessage) -LogFile $LogFile -WriteHostOff:$WriteHostOff

        }
    }


    $SourceFolderChildItems=$DestinationFolderChildItems=@()
    try {
        $SourceFolderChildItems=Get-ChildItem -Path $SourceFolder -ErrorAction Stop
    }
    catch {
        Write-Log -Level ERROR -Message "Failed to get child items in source Path: $($SourceFolder)" -LogFile $LogFile -WriteHostOff:$WriteHostOff
        Write-Log -Level ERROR -Message $($error[0].ToString() + $error[0].InvocationInfo.PositionMessage) -LogFile $LogFile -WriteHostOff:$WriteHostOff
    }
    try {
        $DestinationFolderChildItems=Get-ChildItem -Path $DestinationFolder -ErrorAction Stop
    }
    catch {
        Write-Log -Level ERROR -Message "Failed to get child items in source Path: $($DestinationFolder)" -LogFile $LogFile -WriteHostOff:$WriteHostOff
        Write-Log -Level ERROR -Message $($error[0].ToString() + $error[0].InvocationInfo.PositionMessage) -LogFile $LogFile -WriteHostOff:$WriteHostOff
    }
    
    $SourceFolderChildFiles=$DestinationFolderChildFiles=@()
    $SourceFolderChildFolders=$DestinationFolderChildFolders=@()
    $SourceFolderChildFiles+=$SourceFolderChildItems|Where-Object {$_.PSIsContainer -eq $false}
    $DestinationFolderChildFiles+=$DestinationFolderChildItems|Where-Object {$_.PSIsContainer -eq $false}
    $SourceFolderChildFolders+=$SourceFolderChildItems|Where-Object {$_.PSIsContainer -eq $True}
    $DestinationFolderChildFolders+=$DestinationFolderChildItems|Where-Object {$_.PSIsContainer -eq $True}

    $Diff_Files_Source8Dest=$Diff_Folders_Source8Dest=@()
    $Diff_Files_Source8Dest+=Compare-Object -ReferenceObject $SourceFolderChildFiles -DifferenceObject $DestinationFolderChildFiles -Property Name
    $Diff_Folders_Source8Dest+=Compare-Object -ReferenceObject $SourceFolderChildFolders -DifferenceObject $DestinationFolderChildFolders -Property Name

   foreach($Diff_File in $Diff_Files_Source8Dest){
    if ($Diff_File.SideIndicator -eq "<=") {
        try {
            Write-Log -Level INFO -Message "Copying file, from: $($SourceFolder+"\"+$Diff_File.Name) to:$($DestinationFolder+"\"+$Diff_File.Name)" -LogFile $LogFile -WriteHostOff:$WriteHostOff
            Copy-Item -LiteralPath ($SourceFolder+"\"+$Diff_File.Name) -Destination ($DestinationFolder+"\"+$Diff_File.Name) -ErrorAction Stop -WhatIf:$WhatIf
            Write-Log -Level INFO -Message "Successfully copied file,  from: $($SourceFolder+"\"+$Diff_File.Name) to:$($DestinationFolder+"\"+$Diff_File.Name)" -LogFile $LogFile -WriteHostOff:$WriteHostOff
        }
        catch {
            Write-Log -Level ERROR -Message "Filed to copy file,  from: $($SourceFolder+"\"+$Diff_File.Name) to:$($DestinationFolder+"\"+$Diff_File.Name)" -LogFile $LogFile -WriteHostOff:$WriteHostOff
            Write-Log -Level ERROR -Message $($error[0].ToString() + $error[0].InvocationInfo.PositionMessage) -LogFile $LogFile -WriteHostOff:$WriteHostOff
        }
    }elseif ($Diff_File.SideIndicator -eq "=>") {
        try {
            Write-Log -Level INFO -Message "Removing file, from: $($DestinationFolder+"\"+$Diff_File.Name)" -LogFile $LogFile -WriteHostOff:$WriteHostOff
            Remove-Item -LiteralPath ($DestinationFolder+"\"+$Diff_File.Name) -ErrorAction Stop -WhatIf:$WhatIf
            Write-Log -Level INFO -Message "Successfully removed file, from: $($DestinationFolder+"\"+$Diff_File.Name)" -LogFile $LogFile -WriteHostOff:$WriteHostOff
        }
        catch {
            Write-Log -Level ERROR -Message "Filed to remove file,  from: $($DestinationFolder+"\"+$Diff_File.Name)" -LogFile $LogFile -WriteHostOff:$WriteHostOff
            Write-Log -Level ERROR -Message $($error[0].ToString() + $error[0].InvocationInfo.PositionMessage) -LogFile $LogFile -WriteHostOff:$WriteHostOff
        }
    }
   }

   foreach ($Diff_Folder in $Diff_Folders_Source8Dest) {
    if ($Diff_Folder.SideIndicator -eq "=>") {
        try {
            Write-Log -Level INFO -Message "Removing folder, path: $($DestinationFolder+"\"+$Diff_Folder.Name)" -LogFile $LogFile -WriteHostOff:$WriteHostOff
            Remove-Item -LiteralPath ($DestinationFolder+"\"+$Diff_Folder.Name) -Recurse -ErrorAction Stop -WhatIf:$WhatIf
            write-log -Level INFO -Message "Successfully removed Folder, path: $($DestinationFolder+"\"+$Diff_Folder.Name)" -LogFile $LogFile -WriteHostOff:$WriteHostOff
        }
        catch {
            Write-Log -Level ERROR -Message "Filed to remove folder, path: $($DestinationFolder+"\"+$Diff_Folder.Name)" -LogFile $LogFile -WriteHostOff:$WriteHostOff
            Write-Log -Level ERROR -Message $($error[0].ToString() + $error[0].InvocationInfo.PositionMessage) -LogFile $LogFile -WriteHostOff:$WriteHostOff
        }
    }
   }

   foreach($DestinationFolderChildFile in $DestinationFolderChildFiles){
    $SameFileInSource=$SourceFolderChildFiles|Where-Object{$_.name -eq $DestinationFolderChildFile.name}
    if($null -ne $SameFileInSource){
        if (($SameFileInSource.LastWriteTime -gt $DestinationFolderChildFile.LastWriteTime)) {
            try {
                Write-Log -Level INFO -Message "Updating file, from: $($SourceFolder+"\"+$SameFileInSource.Name) to:$($DestinationFolder+"\"+$SameFileInSource.Name)" -LogFile $LogFile -WriteHostOff:$WriteHostOff
                Copy-Item -LiteralPath ($SourceFolder+"\"+$SameFileInSource.Name) -Destination ($DestinationFolder+"\"+$SameFileInSource.Name) -Force -ErrorAction Stop  -WhatIf:$WhatIf
                Write-Log -Level INFO -Message "Successfully updted file,  from: $($SourceFolder+"\"+$SameFileInSource.Name) to:$($DestinationFolder+"\"+$SameFileInSource.Name)" -LogFile $LogFile -WriteHostOff:$WriteHostOff

            }
            catch {
                Write-Log -Level ERROR -Message "Filed to update file,  from: $($SourceFolder+"\"+$SameFileInSource.Name) to:$($DestinationFolder+"\"+$SameFileInSource.Name)" -LogFile $LogFile -WriteHostOff:$WriteHostOff
                Write-Log -Level ERROR -Message $($error[0].ToString() + $error[0].InvocationInfo.PositionMessage) -LogFile $LogFile -WriteHostOff:$WriteHostOff
            }
        }
    }

   }
   foreach($ChildFolderItem in $SourceFolderChildFolders)
        {
            Sync-FolderItems -SourceFolder $ChildFolderItem.FullName -DestinationFolder ($DestinationFolder+"\"+$ChildFolderItem.Name) -LogFile $LogFile -WriteHostOff:$WriteHostOff  -WhatIf:$WhatIf 
        }

    
}


    
 
