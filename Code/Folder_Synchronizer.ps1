<#
  .SYNOPSIS
  Script get 2x path, source and replica. and Sync replica with source

  .DESCRIPTION
  This is a task for a job interview.
  
  .EXAMPLE
  PS> .\Folder_Synchronizer.ps1 -source C:\source -replica C:\Replica -Logfile C:\logfilename.txt

  .EXAMPLE
  PS> .\Folder_Synchronizer.ps1 -source C:\source -replica C:\Replica -Logfile C:\logfilename.txt -writeHostOff
  to switch off the out streaming output.
#>

    [CmdletBinding()]
    param (
        [Parameter(
            Position=0,
            Mandatory=$True,
            ValueFromPipelineByPropertyName=$True
        )]
        [string]
        $Source, #the source directory

        [Parameter(
            Position=1,
            Mandatory=$True,
            ValueFromPipelineByPropertyName=$True
        )]
        [ValidateScript({Test-Path -LiteralPath $_ -PathType container -IsValid})]
        [string]
        $Replica, #the destinatino directory

        [Parameter(
            Position=2,
            ValueFromPipelineByPropertyName=$True
        )]
        [ValidateScript({Test-Path -LiteralPath $_ -PathType leaf -IsValid})]
        [string]
        $LogFile=$PSScriptRoot+"\Folder_Synchronizer_Log.txt", #log file directory

        [switch]
        $WriteHostOff=$false #switch to trun off write-output commands

        #[string[]]
       # $ExcludeList=$null, #to be develop later

        #[switch]
       # $WhatIf=$false #to be develop later


    )


    Function Write-Log {
    #function to gnerate stractured log messages and append it to logfile if needed and/or output stream.
        Param(
            [ValidateSet("INFO", "WARN", "ERROR")]
            [String]
            $Level="***", 
     
            [string]
            $Message,
     
            [string]
            $LogFile='',

            [switch]
            $WriteHostOff=$false
        )
        #generation log message stracture
        $Stamp = (Get-Date).toString("yyyy/MM/dd HH:mm:ss")
        $Line = "$Stamp $Level $Message"
     
        If ('' -ne $LogFile ) {
            #adding the log message to the log file if logfile attribute is not empty string
            Add-Content $LogFile -Value $Line
        }
        if(!$WriteHostOff){
            #echo the log message to output stream
            Write-Output $Line
        }
       
    }

function Sync-FolderItems {
   <#function to Sync 2x directory in one-way. it takes the source and replica folder path and targets sub items in 1x level sub and repeate the function for the sub directory in source:
            1.create the root targeted directory in replica if does't exist already
            2.get child items of both source and replica folder in 1x level sub
            3.compare the child itmes and find the difference in only 1x sub
            4.the files, that  exist only in source, will be copied to replica
            5.the files, that exist only in replica, will be deleted from replica
            6.the folders, that exist only in replica, will be deleted from replica
            7.check the child files in replica that are mutul with source if the last write is diffrent from the source file, if yes, will be replaced by the source file
            8.recall the function for each child folders in source

            *each time that the function is called, is chekcing only 1x level sub items. and would cover the sub items synchronization by recalling the function iteself.*
   
   #>
   
    param (
        
        [Parameter(Mandatory=$True)]
        [ValidateScript({Test-Path -LiteralPath $_ -PathType Container})]
        [string]
        $SourceFolder,
        
        [Parameter(Mandatory=$True)]
        [ValidateScript({Test-Path -LiteralPath $_ -IsValid})]
        [string]
        $DestinationFolder,

       # [string[]]
        #$ExcludedList,

        [string]
        $LogFile,

        [switch]
        $WriteHostOff=$false

        #[switch] $WhatIf=$false

    )

    
#1.create targeted folder in replica if doesn't exist already
    if(!(Test-Path -LiteralPath $DestinationFolder -PathType container)){
        try {
            Write-Log -Level INFO -Message "Creating Folder in Path: $($DestinationFolder)" -LogFile $LogFile -WriteHostOff:$WriteHostOff
            New-Item -Path $DestinationFolder -ItemType "Directory" -ErrorAction Stop |out-null
            Write-Log -Level INFO -Message "Successfully created folder in Path: $($DestinationFolder)" -LogFile $LogFile -WriteHostOff:$WriteHostOff
        }
        catch {
            Write-Log -Level ERROR -Message "Failed to create folder in Path: $($DestinationFolder)" -LogFile $LogFile -WriteHostOff:$WriteHostOff
            Write-Log -Level ERROR -Message $($error[0].ToString() + $error[0].InvocationInfo.PositionMessage) -LogFile $LogFile -WriteHostOff:$WriteHostOff

        }
    }

#2.1Geting child items in the targeted source and replica directory
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
#2.2Spliting files and directory in the targeted path in both source and replica
    $SourceFolderChildFiles=$DestinationFolderChildFiles=@()
    $SourceFolderChildFolders=$DestinationFolderChildFolders=@()
    $SourceFolderChildFiles+=$SourceFolderChildItems|Where-Object {$_.PSIsContainer -eq $false}
    $DestinationFolderChildFiles+=$DestinationFolderChildItems|Where-Object {$_.PSIsContainer -eq $false}
    $SourceFolderChildFolders+=$SourceFolderChildItems|Where-Object {$_.PSIsContainer -eq $True}
    $DestinationFolderChildFolders+=$DestinationFolderChildItems|Where-Object {$_.PSIsContainer -eq $True}
#3.Comparing files and directory to find the difference
    $Diff_Files_Source8Dest=$Diff_Folders_Source8Dest=@()
    $Diff_Files_Source8Dest+=Compare-Object -ReferenceObject $SourceFolderChildFiles -DifferenceObject $DestinationFolderChildFiles -Property Name
    $Diff_Folders_Source8Dest+=Compare-Object -ReferenceObject $SourceFolderChildFolders -DifferenceObject $DestinationFolderChildFolders -Property Name
#4&5.address the diffrence files in the targeted path by copying or removing files
   foreach($Diff_File in $Diff_Files_Source8Dest){
    #4.copy file to replica from source if it's missing
    if ($Diff_File.SideIndicator -eq "<=") {
        try {
            Write-Log -Level INFO -Message "Copying file, from: $($SourceFolder+"\"+$Diff_File.Name) to:$($DestinationFolder+"\"+$Diff_File.Name)" -LogFile $LogFile -WriteHostOff:$WriteHostOff
            Copy-Item -LiteralPath ($SourceFolder+"\"+$Diff_File.Name) -Destination ($DestinationFolder+"\"+$Diff_File.Name) -ErrorAction Stop 
            Write-Log -Level INFO -Message "Successfully copied file,  from: $($SourceFolder+"\"+$Diff_File.Name) to:$($DestinationFolder+"\"+$Diff_File.Name)" -LogFile $LogFile -WriteHostOff:$WriteHostOff
        }
        catch {
            Write-Log -Level ERROR -Message "Filed to copy file,  from: $($SourceFolder+"\"+$Diff_File.Name) to:$($DestinationFolder+"\"+$Diff_File.Name)" -LogFile $LogFile -WriteHostOff:$WriteHostOff
            Write-Log -Level ERROR -Message $($error[0].ToString() + $error[0].InvocationInfo.PositionMessage) -LogFile $LogFile -WriteHostOff:$WriteHostOff
        }
    #5.remove file from replica if it's missing in source
    }elseif ($Diff_File.SideIndicator -eq "=>") {
        try {
            Write-Log -Level INFO -Message "Removing file, from: $($DestinationFolder+"\"+$Diff_File.Name)" -LogFile $LogFile -WriteHostOff:$WriteHostOff
            Remove-Item -LiteralPath ($DestinationFolder+"\"+$Diff_File.Name) -ErrorAction Stop 
            Write-Log -Level INFO -Message "Successfully removed file, from: $($DestinationFolder+"\"+$Diff_File.Name)" -LogFile $LogFile -WriteHostOff:$WriteHostOff
        }
        catch {
            Write-Log -Level ERROR -Message "Filed to remove file,  from: $($DestinationFolder+"\"+$Diff_File.Name)" -LogFile $LogFile -WriteHostOff:$WriteHostOff
            Write-Log -Level ERROR -Message $($error[0].ToString() + $error[0].InvocationInfo.PositionMessage) -LogFile $LogFile -WriteHostOff:$WriteHostOff
        }
    }
   }
#6.remove folder from replica if it's missing in source
   foreach ($Diff_Folder in $Diff_Folders_Source8Dest) {
    if ($Diff_Folder.SideIndicator -eq "=>") {
        try {
            Write-Log -Level INFO -Message "Removing folder, path: $($DestinationFolder+"\"+$Diff_Folder.Name)" -LogFile $LogFile -WriteHostOff:$WriteHostOff
            Remove-Item -LiteralPath ($DestinationFolder+"\"+$Diff_Folder.Name) -Recurse -ErrorAction Stop 
            write-log -Level INFO -Message "Successfully removed Folder, path: $($DestinationFolder+"\"+$Diff_Folder.Name)" -LogFile $LogFile -WriteHostOff:$WriteHostOff
        }
        catch {
            Write-Log -Level ERROR -Message "Filed to remove folder, path: $($DestinationFolder+"\"+$Diff_Folder.Name)" -LogFile $LogFile -WriteHostOff:$WriteHostOff
            Write-Log -Level ERROR -Message $($error[0].ToString() + $error[0].InvocationInfo.PositionMessage) -LogFile $LogFile -WriteHostOff:$WriteHostOff
        }
    }
   }
#7.check files in replica and replace it with source if LastWriteTime property is diffrent
   foreach($DestinationFolderChildFile in $DestinationFolderChildFiles){
    $SameFileInSource=$SourceFolderChildFiles|Where-Object{$_.name -eq $DestinationFolderChildFile.name}
    if($null -ne $SameFileInSource){
        if (($SameFileInSource.LastWriteTime -gt $DestinationFolderChildFile.LastWriteTime)) {
            try {
                Write-Log -Level INFO -Message "Updating file, from: $($SourceFolder+"\"+$SameFileInSource.Name) to:$($DestinationFolder+"\"+$SameFileInSource.Name)" -LogFile $LogFile -WriteHostOff:$WriteHostOff
                Copy-Item -LiteralPath ($SourceFolder+"\"+$SameFileInSource.Name) -Destination ($DestinationFolder+"\"+$SameFileInSource.Name) -Force -ErrorAction Stop  
                Write-Log -Level INFO -Message "Successfully updted file,  from: $($SourceFolder+"\"+$SameFileInSource.Name) to:$($DestinationFolder+"\"+$SameFileInSource.Name)" -LogFile $LogFile -WriteHostOff:$WriteHostOff

            }
            catch {
                Write-Log -Level ERROR -Message "Filed to update file,  from: $($SourceFolder+"\"+$SameFileInSource.Name) to:$($DestinationFolder+"\"+$SameFileInSource.Name)" -LogFile $LogFile -WriteHostOff:$WriteHostOff
                Write-Log -Level ERROR -Message $($error[0].ToString() + $error[0].InvocationInfo.PositionMessage) -LogFile $LogFile -WriteHostOff:$WriteHostOff
            }
        }
    }
#8.repeat the process for the sub directories
   }
   foreach($ChildFolderItem in $SourceFolderChildFolders)
        {
            Sync-FolderItems -SourceFolder $ChildFolderItem.FullName -DestinationFolder ($DestinationFolder+"\"+$ChildFolderItem.Name) -LogFile $LogFile -WriteHostOff:$WriteHostOff   
        }

    
}


 
#main
#creating log file if doesn't exist already
Write-Log -Level INFO -Message "Script is started." -WriteHostOff:$WriteHostOff
if (!(Test-Path -LiteralPath $LogFile -PathType leaf)) {
    write-log -Leve INFO -Message "Creating new logfile $LogFile" -WriteHostOff:$WriteHostOff
    New-Item -Path $LogFile -ItemType File|Out-Null
    write-log -Leve INFO -Message "Created new logfile $LogFile" -LogFile $LogFile -WriteHostOff:$WriteHostOff
}
#call syn-folderitems to sysc the replica folder with source from the arguments
write-log -Leve INFO -Message "Script is started." -LogFile $LogFile -WriteHostOff:$WriteHostOff
write-log -Leve INFO -Message "Job is about to start to syc Source:$Source with Replica:$Replica" -LogFile $LogFile -WriteHostOff:$WriteHostOff
Sync-FolderItems -SourceFolder $Source -DestinationFolder $Replica -LogFile $LogFile -WriteHostOff:$WriteHostOff
write-log -Level INFO -Message "Scritpt is ending with $($error|Measure-Object|select -ExpandProperty count) errors" -LogFile $LogFile -WriteHostOff:$WriteHostOff
write-log -Level INFO -Message "Script is finished. Looking forward to see you!!" -LogFile $LogFile -WriteHostOff:$WriteHostOff

Exit