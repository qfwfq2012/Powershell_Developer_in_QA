# Powershell_Developer_in_QA

This repo is created to deliver a task for a job interview.
The Folder_Synchronizer.ps1 is a script that takes 3x line arguments: Source, Replica, LogFile; And attempt to synchronize replica with source.
This script is detecting a change on the files based only on LastTimeProperty in System.IO.FileInfo file objects. 
The script can be improved a lot by adding more advanced checking factors and features. e.g., covering security permissions on the items, enabling to use remotesession, exclude & include feature, adding whatif switch, providing custom credentials, better reporting and logging, improving performance for large amount of files ... which is time consuming for this round of interview, I think.

# Functions
There are 2x function defended in the script, write-log and sync-folderitem:
Write-log: it's a really simple logging function to append the logs to a log file and out stream.
sync-folderitem: this is the main function of the script. function to Sync 2x directory in one-way. it takes the source and replica folder path and targets sub items in 1x level sub and repeats the function for the sub directory in source:
            1.create the root targeted directory in replica if doesn't exist already
            2.get child items of both source and replica folder in 1x level sub
            3.compare the child items and find the difference in only 1x sub
            4.the files, that  exist only in source, will be copied to replica
            5.the files, that exist only in replica, will be deleted from replica
            6.the folders, that exist only in replica, will be deleted from replica
            7.check the child files in replica that are mutual with source if the last write is different from the source file, if yes, will be replaced by the source file
            8.recall the function for each child folders in source

            *each time that the function is called, is checking only 1x level sub items. and would cover the sub items synchronization by recalling the function iteself.*
   
# About Developer

I'm an infrastructure engineer with solid experience in enterprise companies and various technology, including WindowsServers, VMWare vSphere, Hypere-V and as well as Veeam products. I love automation and coding, PowerShell is my favorite!
This job opportunity sounds so interesting and I'd love to know more about it, also, I believe that I'd be a great fit in the position with my background experiences and skills.

I'm looking forward to hearing from you!