#######################################
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
######################################
