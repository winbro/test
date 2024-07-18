#<######################################
# 
# Description:  The purpose of this script is to Automate CyberArk account onboarding activities using PowerShell PsPas module.
#               This script provides functions to onboard/update accounts with Reconcile and/or Logon accounts. 
#               The script process is as follows:
#                1. The script leverages the parameters provided in the csv file.
#                2. The script establishes a connection to PVWA to onboard the accounts according to the details in the csv file.
#              
#               
# Prerequisites: 1. An account with sufficient privilege is needed to run the script to onboard accounts to specified safes. 
#                2. Update the PVWA URL in the script. 
#                3. Update the csv file path in the script.              
#                4. Prepare csv file with the format outlined in the template file in the script folder. 
# 
# Output: The script will display processing message on the console as well as generate a log file in the log folder.
#
######################################> z2WR1v8Fm3tg

#Define PVWA Base URL, the csv file and log folder path
$PVWA = 'pcloud_url'
$base = "C:\tmpdata\"
 


$csvFile = $base + 'UnixAccts.csv'
$logdir= $base + 'logs'
$Stamp = (Get-Date).toString("_MM-dd-HH-mm-ss")


# create cred file for once
#$credential = Get-Credential
#$credential.Password | ConvertFrom-SecureString | Set-Content $base\sepwd.txt



$username = "batch_user"
$encrypted = Get-Content $base\sepwd.txt | ConvertTo-SecureString
$cred = New-Object System.Management.Automation.PsCredential($username, $encrypted)

 

#Function to display the options for account onboarding  
function Show-Menu
{
    param (
        [string]$Title = 'Account Onboarding'
    )
    Write-Host "================================== Account Onboarding ======================================="    
    Write-Host "1: Please select option '1' to onboard accounts only."
    Write-Host "2: Please select option '2' to onboard/update accounts and add Reconcile and/or Logon Accounts."
    Write-Host "Q: Press 'Q' to quit."
    Write-Host "============================================================================================="
    Write-Host ""
}

#Function to write messages to log file
Function Write-Log {
    [CmdletBinding()]
    Param(
    [Parameter(Mandatory=$False)]
    [ValidateSet("INFO","WARN","ERROR","FATAL","DEBUG")]
    [String]$Level="INFO",

    [Parameter(Mandatory=$True)]
    [string] $Message,

    [Parameter(Mandatory=$False)]
    [string] $logfile =".\Onboarding.log"
    )

    $Stamp = (Get-Date).toString("yyyy/MM/dd HH:mm:ss")
    $Line = "$Stamp $Level :  $Message"
    If($logfile -and $Level -eq "WARN") {
         Add-Content $logfile -Value $Line
         write-warning $Line
    }
    elseif($logfile -and $Level -eq "INFO") {
         Add-Content $logfile -Value $Line
         write-host $Line
    }
    elseif(!$logfile -and $Level -eq "WARN"){
        Write-Warning $LineV  
        }
    else {write-output $Line}
}

#Function to handle options selected by the user
function Handle-Options
{
  $option=Read-Host "Please select an option:"
  Switch ($option)
  {    #Start of switch case for option 1
    '1' { 
            $Logfile ="Onboarding_only" +$Stamp + ".log"
            $Log = "$logdir\$Logfile"

            #Create log file if does not exists
            if (!(Test-Path "$Logfile"))
                {
                 New-Item -path $logdir -name $Logfile -type "file" -value "Onboarding Log:"
                 Add-Content $log -value ""
                 Write-log -logfile $log -level INFO -Message "Created new log file $log"
                }

            write-log -logfile $log -Message 'Option 1 selected: "Onboard the account only" '                       
           # Clear-Host
            write-host 'Option 1 selected: "Onboard the account only" '               
 
           if (Test-Path -Path "$csvfile") {write-host "found csvfile $csvfile"}
             


            #Connect to PVWA
          #  try {$cred = Get-Credential -ea stop} catch { Write-log -level WARN -logfile $log -message "Please confirm credentials and try again"; exit}
            try {New-PASSession -Credential $cred -BaseURI $PVWA -type CyberArk -ea stop }
           catch{Write-log -level warn -logfile $log -message " error : $PSItem ";  }
           # catch{Write-log -level warn -logfile $log -message " error : $PSItem " }

           # $csvFile = 'C:\Users\ixq\Documents\sysnotes\CyberArk\\scripts\OnboardAccounts\dmz_accts.csv'        
            try {$accounts = import-csv $csvFile -ea stop
             }catch {
            Write-log -level WARN -logfile $Logfile -message "Could not find specified  csv file $csvfile, please verify CSV and try again."
            exit             
            }
                     
            #Loop to populate account values from csv file
            foreach($account in $accounts){             
             # if( $($account.Accountname) -eq "end" ){write-log -Message  "Completed"; exit}
               $secstring = $($account.secret) 
             #  $acctname = $($account.AccountName).Trim()
               $address = $($account.address).trim()
               $acctUserName = $($account.UserName).trim()
               $seachUserName = $address + '-' + $acctUserName
              write-host "acct is $address $acctUserName $seachUserName";  

               
               $platformID = $($account.PlatformID)               
               $RecAccountSafe = $($account.RecAccountSafe)
               $RecAccount = $($account.RecAccount)
               $logAccountSafe = $($account.logAccountSafe)
               $LogAccount = $($account.LogAccount)
               $SafeName = $($account.SafeName)

               Write-Warning "safe name is  $SafeName, address is $address username   $acctUserName "

              #find acounts in safe
              # Get-PASAccount -safeName $SafeName |Select-Object -Property username, address

               #Check if account in target safe exist. exit if so
               # try {$acctinfo = Get-PASAccount -search $acctUserName -searchType contains  -safeName $SafeName  |Where-Object {$_.name -ccontains $acctUserName }  -ea stop }
                try {$acctinfo = Get-PASAccount -search "$acctUserName,$address" -searchType contains   -safeName $SafeName     -ea stop }
                catch {Write-Log -level warn -logfile $log -message  "Failed to retrieve account $acctame  in  $SafeName " ; exit}
               
                if( $acctinfo ){write-warning "Account $acctUserName  in safe $safename with address $address already exists, please verify.";exit}
                  write-host $acctinfo; exit              
  

               $EnableAutomaticManagement = $($account.EnableAutomaticManagement).trim()

               if ( $EnableAutomaticManagement -match "yes" ) {
                      write-log -Level INFO -logfile $log -Message "Enable automatic management selected for $acctname"  
                      $automaticManagementEnabled = $true
                       }                                                                 
                  else {write-log -level INFO -logfile $log -Message "Automatic management disabled for $acctname" 
                     $automaticManagementEnabled = $false
                      }#End of If statement

                      write-log -Level INFO -logfile $log -Message "Onboarding account: $acctname "

              #Onboarding accounts that have been populated
              $sec = $secstring| ConvertTo-SecureString -AsPlainText -Force
            #  try {Add-PASAccount -name $acctName -userName $acctUsesrName -address $address -platformID $platformID `
              try {Add-PASAccount   -userName $acctUsesrName -address $address -platformID $platformID `
                -SafeName $Safename  -automaticManagementEnabled $automaticManagementEnabled -secret $sec -ea stop }
               catch{write-log -logfile $Log -Level WARN -message "Failed to onboard $AccountName : $PSItem"}
                             } #End of loop

                } #End of switch case one

            #Start of switch case for option 2         
            '2' {
                $Logfile ="Onboarding_Rec_n_Login" +$Stamp + ".log"
                $Log = "$logdir\$Logfile"

               #Create log file if does not exists
               if (!(Test-Path "$Logfile"))
                { New-Item -path $logdir -name $Logfile -type "file" -value "Onboarding Log:"
                  Add-Content $log -value ""
                  Write-log -logfile $log -level INFO -Message "Created new log file $log  "
                }
                
                write-log -logfile $log -Message 'Option 2 selected: "Onboard/update accounts and add Reconcile and/or Logon Account" '
                Clear-Host
                write-host 'Option 2 selected: "Onboard/update accounts and add Reconcile and/or Logon Account" '

                $MessageBody = " `
                 It is recommended to associate the logon `
                accounts and reconcile accounts at the platform 
                level, please proceed only if accounts are not `
                associated at the platform.`
                Are you sure you want to proceed?   "

                $ButtonType = [System.Windows.Forms.MessageBoxButtons]::YesNoCancel
                $MessageIcon = [System.Windows.Forms.MessageBoxIcon]::Warning
                $MessageTitle = "WARNING"
                $Result = [System.Windows.Forms.MessageBox]::Show($MessageBody,$MessageTitle,$ButtonType,$MessageIcon)
                switch($Result){
                'no'{write-host "your answer is $Result, Exiting script";exit}
                'cancel'{write-host "Exiting script";exit}
                 defalult {write-host "Exiting script "}
                'yes' {
                 try {$accounts = import-csv $csvFile -ea stop
                 }catch { Write-log -level WARN -logfile $Logfile -message "Could not find specified csv file $csvfile, please verify and try again."
                 exit }

                #Connect to PVWA
                try {$cred = Get-Credential -ea stop} catch { Write-log -level WARN -logfile $log -message "Please confirm credentials and try again"; exit}
                try {New-PASSession -Credential $cred -BaseURI $PVWA -type CyberArk -ea stop}
                catch{Write-log -level warn -logfile $log -message "error : $PSItem "; exit}
            
           
                #Loop to populate account values from csv file
                foreach($account in $accounts){             
                  if( $($account.Accountname) -eq "end" ){write-log -Message  "completed"; exit}
                  $secstring = $($account.secret) 
                  if (! $secstring){write-log -logfile $log-onboard.log -Level INFO -Message "Password is empty"; $sec = ""}
                  else {$sec = $secstring| ConvertTo-SecureString -AsPlainText -Force}

                   $acctname = $($account.AccountName).Trim()
                   $acctUserName = $($account.UserName)
                   $address = $($account.address).trim()
                   $platformID = $($account.PlatformID)
                   $RecAccountSafe = $($account.RecAccountSafe)
                   $RecAccount = $($account.RecAccount)
                   $logAccountSafe = $($account.logAccountSafe)
                   $LogAccount = $($account.LogAccount)
                   $SafeName = $($account.SafeName)
            
               $EnableAutomaticManagement = $($account.EnableAutomaticManagement).trim()

               if( $EnableAutomaticManagement -match "yes" ) {
                      write-log -Level INFO -logfile $log -Message "Enable automatic management selected for $acctname"  
                      $automaticManagementEnabled = $true
                       }                                                                 
                  else {write-log -level INFO -logfile $log -Message "Automatic management disabled for $acctname" 
                     $automaticManagementEnabled = $false
                      } #End of if statement
                                  
              #Onboarding accounts
              $sec = $secstring| ConvertTo-SecureString -AsPlainText -Force         
              try {Add-PASAccount -name $acctName -userName $acctUserName -address $address -platformID $platformID `
                -SafeName $Safename  -automaticManagementEnabled $automaticManagementEnabled -secret $sec -ea stop }
              catch{write-log -logfile $Log -Level WARN -message "Failed at onboarding $AccountName  : $PSItem"}

              #Finding account ID
              try {$acctinfo =Get-PASAccount -search $AcctName -safeName $SafeName |Where-Object {$_.name -eq $AcctName }  -ea stop }
              catch {write-log -level WARN -logfile $log -Message  "Account $AcctName in $SafeName not found" ; exit}
       
              $acctID = $acctinfo.id
             
              #Adding Logon accounts                       
              write-log -logfile $log -Message "Adding logon $LogAccount to account $AcctName"
              try{Set-PASLinkedAccount -AccountID $acctID -safe $LogAccountSafe -extraPasswordIndex 1 `
                 -name $LogAccount -folder root -ea stop }
              catch {write-log -level WARN -logfile $Log -Message "Cannot add Logon account $LogAccount to $AcctName" 
                   Write-log -logfile $log -level warn -message $PSItem}

              #Adding Reconcile accounts                       
              write-log -logfile $log -Message "Adding reconcile $RecAccount to account $AcctName  "
              try{Set-PASLinkedAccount -AccountID $acctID -safe $RecAccountSafe -extraPasswordIndex 3 `
                 -name $RecAccount -folder root -ea stop }
              catch {write-log -level WARN -logfile $Log -Message "Cannot add Reconcile account $RecAccount to $AcctName" 
                     Write-log -logfile $log -level warn -message $PSItem}
                     }#End of elseif 
                  } #End of loop              
              else {write-log -level INFO -logfile $log -Message "Please enter Yes or No to confirm if option 2 is selected"; exit} #End of if statement 
              }#End of switch case yes
          } #End of switch case two

        'Q' { write-host "Exiting script"; exit}
         #For invalid input
         default { Write-Warning "Please select one of the options listed"; Handle-Options}
  } #Closing switch cases
  }

#Display brief description and usage information
Clear-Host
Write-Host ""
Write-Host "===================================================================================="
Write-Host "                           Accounts Onboarding "
Write-Host "===================================================================================="
Write-Host ""
Write-Host "This account management script is for onboarding accounts specified in the csv file.  "
Write-Host ""
Write-Host ""
Write-Host "Usage: This script takes a csv file as input file for the selected task. Please "
write-host "       update the template csv file found in the folder. "
Write-Host ""
Write-Host ""
show-menu
Handle-Options

#Close the connection to PVWA
Close-PASSession




