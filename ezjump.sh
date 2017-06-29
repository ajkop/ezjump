#!/bin/bash
### TO DO ###
#Split server list into arrays.
#Load array list into this script.
#Change $serverinput to search through arrays#
#############
#### Patches ####
#I started actually logging these today. 2017/5/30
#v1.1 2017/5/30 Added logic to allow users to choose "None" out of server selection and if the input resolves a cpanel server but is not an EXACT match for one of the servers in the list. SSH into the add server lines.
#v.1.2 2017/6/2 Added logic to qualify input before sending to the add server function on certain lines. Also changed serverchoice logic to not exit improperly on choice, (Bad else catchall, changed to elif with a condition)
#v.1.3 2017/6/2 Added a line at the very start of the logic to determine if input is an exact match to a line in server list and then just go to it.
#v.1.4 2017/6/9 Added a -a flag, which will directly add your input into the server list before running any checks.
## Add colors as variables ##
Red='\e[31m'
Green='\e[32m'
Default='\e[39m'
Blue='\e[34m'
Yellow='\e[93m'
############################

##### Usgae ################
if [ $# -eq 0 ]; then    # If no input is enterted, prunt usage.
    echo -e ""$Red"Usage s: Searchterm|IP|Domain [-a] [-p] port number [-g] group \n -a, --directly add your input into the server list.\n -p, --specify port to connect on.\n -g, --specify ssh group to connect with."$Default""
    exit 0
fi
############################
#### Flag Specification ####

OPTIND=2     #Start looking at user input after the first argument (allows it to skip the argument entered for connecting)
while getopts "dap:g:" flag
do
      case $flag in
       p) port="-p $OPTARG"     # If user enters -p, set -p to the $port variable for later use.
          echo -e ""$Yellow"Port set to $port"$Default""
          ;;
       g) group=$OPTARG     # If user enters -p, set -g to the $group variable for later use.
          echo -e ""$Yellow"Group set to $group"$Default""
          ;;
       a) echo -e ""$Yellow" Starting add sequence, be careful with this flag, it does very little error checking and is mostly meant for quickly adding servers you entered exactly right and you know are valid. "$Default""
           sleep 2
           if [[ -n $(grep -i ^$1$ ~/SERVERS.txt) ]] ;then
            echo -e ""$Red"Server already added, not adding again."$Default""
           elif [[ -z $(dig +short $1) ]] ;then
            echo -e ""$Red"This doesn't resolve. "$Blue"Do you still want to add it?"$Default""
             select answer in Yes No
              do
               if [[ $answer == "Yes" ]] ;then
                echo -e ""$Yellow"Adding server. "$Default""
                echo $1 >> ~/SERVERS.txt
               elif [[ $answer == "No" ]] ;then
                echo -e ""$Yellow"Not adding, proceeding as normal..."$Default""
               else
                echo -e ""$Red"Not sure what you want, Exiting..."$Default""
               fi
             break
              done
           else
            echo -e ""$Yellow"Adding server to list."$Default""
            echo $1 >> ~/SERVERS.txt
           fi
          ;;
       d) echo -e ""$Yellow" No lookups, just going to ssh."$Default""
	  ssh $group $1 $port
          exit
          ;;
       esac
done
############################

### Variables ####
servername=$(curl -s $1:2087 |grep -o -P '(?<=https\:\/\/).*(?=\:2087)')
serverinput=$(grep -i $1 ~/SERVERS.txt |sort -u)
servercount=$(grep -i $1 ~/SERVERS.txt |sort -u | wc -l)
hostlookup=$(dig +short $1)
##################

#### Function to add the server found with curl's if user wants. ####
addserver ()
{
curservcount=$(wc -l < ~/SERVERS.txt)     # Saves current line count of server file.
if [[ -n $(grep -i "^$servername$" ~/SERVERS.txt) ]] ;then
 echo -e ""$Green""Found: $servername" in list. Resolves to $hostlookup. \nConnecting ... "$Default""
 ssh $group $servername $port
  exit 0
elif [[ -n $servername ]]; then
 echo -e ""$Green"Host lookup found: $servername"$Default"\n"$Blue"Do you want me to add this to serverlist?"$Default""     # Echos serverlookup result and asks if user wants to save it in the server list.
 select response in Yes No     # Prompts user with Yes or No and records their answer
 do
  if [[ "$response" == "Yes" ]] ;then     # If their answer is yes.
   echo -e ""$Yellow" Copying current server list to a backup file"$Default""
   cp -aiv ~/SERVERS.txt{,add-$(date +%m.%d.%Y_%H-%M)}     # Copy a backup of the file to ensure we dont loose it.
   echo "$servername" >> ~/SERVERS.txt    # Add the server lookup result to the file.
    if [[ -n $(grep -i ^$servername$ ~/SERVERS.txt) ]] ;then    # If the server lookup result is now in the file, let the user know that and then proceed to the next line after the function call.
     echo -e ""$Green"Added properly, continuing"$Defualt""
    else
     echo -e ""$Red"Did not add correctly, try manually."$Default"" >&2    # If it is not added, let the user know, then proceed to the next line after the function call.
      exit 1
   fi     # End add check if block.
if [[ $(( $curservcount + 1 == $(wc -l < ~/SERVERS.txt) )) ]]; then     # If the current server list count is 1 higher than it was before we started, Remove the backup file.
 echo -e ""$Yellow" Removing backup file."$Default""
 /bin/rm -v ~/SERVERS.txtadd-$(date +%m.%d.%Y_%H-%M)
else
 echo -e ""$Red"Something went wrong with the add, backup copy of the file was saved as ~/SERVERS.txtadd-$(date +%m.%d.%Y_%H-%M) "$Default"" >&2    # If it is not, let the user know and do not remove backup file.
 exit 1
fi     # End the file check if block.
 elif [[ "$response" == "No" ]] ;then     # If the user choose not to add the server lookup result, then proceed to the next line after the function call.
  echo -e ""$Yellow"Ok, Not adding"$Default""
else
 echo -e ""$Red"Not sure what you mean. Exiting..."$Default"" >&2    # If niether choice is matches, exit entirely.
  exit 1
  fi     # End the Selection if block.
 break     # Stop selection from looping.
 done     # End selection loop.
fi
}      # End function definition.

######################################################################

#### Where the work gets done ####
if [[ -n "$hostreturn" ]] ;then
ssh $group $hostreturn $port
fi
if [[ -n $(grep -i ^$1$ ~/SERVERS.txt) ]] ;then
echo -e ""$Green"Found "$1" \nConnecting ... "$Default"";
   ssh $group $1 $port;     #go server
    exit 0
fi
if [[ -n "$serverinput" ]] ; then     # If server search returns a string
 echo -e ""$Green"Searching..."$Default""
 if [[ "$servercount" -gt 10 ]] ;then     # If return is greater than 5 lines
  echo -e ""$Red"Search term too ambigious, try refining your search"$Default"" >&2
  echo -e ""$Red"Found the following servers matching this search term"$Default":\n$serverinput" >&2
   exit 1

  elif [[ "$servercount" -eq 1 ]] ; then     #If result returns 1 result
   echo -e ""$Green"Found $serverinput\nConnecting ... "$Default"";
   ssh $group $serverinput $port;     #ssh server
    exit 0

   elif [[ "$servercount" -lt 10 ]] && [[ "$servercount" -gt 1 ]]; then     # If result returns less than 5 but more than 1

    echo -e ""$Yellow" Found multiple servers. Choose from below list."$Default""
    select selection in $serverinput None    # Prompt the user with the choices we have from the serverinput variable and record answer.
    do
    serverchoice=$selection     # Specify a variable for user selection
    echo -e ""$Blue"You chose $serverchoice"$Default""
     if [[ $selection == "None" ]] && [[ -n "$servername" ]] ;then
      echo -e ""$Yellow"Attempting to connect to server..."$Default""
      addserver
      ssh $group $servername $port
     exit 0
       elif [[ $selection == "None" ]] && [[ -z "$servername" ]] ;then
      echo -e ""$Red"No server found or choose, Exiting ..."$Default"" >&2
      exit 1
      elif [[ $selection != "None" ]] ;then
    ssh $group $serverchoice $port     # ssh to input (This is after completing search, therefore result is a full hostname, no need to iterate through search)
    break     # Stop it from looping
    fi
     done     # End selection loop
     exit 0     # Exit with success
 fi     # End Selection block.

if [[ -n "$serverinput" ]] && [[ -z $(grep -i "^$servername$" ~/SERVERS.txt) ]]; then
    addserver
ssh $group $servername $port
fi

elif [[ $1 =~ ^[a-zA-Z0-9][a-zA-Z0-9-]{1,61}[a-zA-Z0-9]\.[a-zA-Z]{2,}$ ]] ;then
  if [[ -n $servername ]] ;then

   echo -e ""$Yellow" Server: $servername "$Default""     #curl input to find hostname, and echo before connecting
  addserver
  echo -e ""$Green"Connecting to $hostlookup ..."$Default""     #Dig input and determine IP and echo beforing connecting
  ssh $group $1 $port;     # ssh to the server
   exit 0     # Exit success
   elif [[ -n $hostlookup ]] && [[ -z $servername ]] ;then
   echo -e ""$Yellow"Domain resolves to $hostlookup , but I am unable to connect to cPanel"$Default""
   ssh $group $1 $port
   else
   echo -e ""$Red"Domain does not resolve, or cannot find applicable server."$Default"" >&2
   echo -e ""$Yellow" Attempt to ssh anyway?"$Default""
   select selection in Yes No
   do
   if [[ $selection == "Yes" ]] ;then
    ssh $group $1 $port
    else
    echo -e ""$Yellow" Exiting ..."$Default""
     exit 0
    fi
    break
    done
     fi
elif [[ $1 =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]] ;then   #If input is an IP.

 if [[ -n $servername ]] && [[ -n $(grep -i "^$servername$" ~/SERVERS.txt) ]] ;then
  echo -e ""$Green"Server: $servername is in list\n"$Green"Connecting... "$Default""
  ssh $group $1 $port     # If the search resulted in no hits and the search term was not a domain, curl input to find server hostname, and echo before connecting
elif [[ -n $servername ]] && ! [[ -n $(grep -i "^$servername$" ~/SERVERS.txt) ]] ;then
  addserver
echo -e ""$Green"Connecting to $servername..."$Default""     #Dig input and determine IP and echo beforing connecting
ssh $group $1 $port
else
echo -e ""$Red"No cPanel server found, attempting to connect anyway."$Default"" >&2
 ssh $group $1 $port
 fi

else
if [[ -n $servername ]] ;
then
addserver
ssh $group $1 $port
else
echo -e ""$Red"Server lookup failed, server curl failed, domain does not resolve. Attempting to connect anyway.\n"$Green"Connecting ..."$Default""
 ssh $group $1 $port;     #ssh input
exit     # exit success
fi
fi     # End search block

##################################
