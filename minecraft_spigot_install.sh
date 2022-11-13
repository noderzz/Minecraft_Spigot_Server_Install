#!/bin/bash

#######################
### Color Variables ###
#######################
CYN='\033[0;36m'
RED='\033[0;31m'
NC='\033[0m'
GRN='\033[0;32m'

#################
### Variables ###
#################

#################
### Functions ###
#################

systemd_unit_creation_spigot () {
  echo "
[Unit]
Description=Minecraft Server
After=network.target

[Service]
User=minecraft
Nice=1
KillMode=none
SuccessExitStatus=0 1
ProtectHome=true
ProtectSystem=full
PrivateDevices=true
NoNewPrivileges=true
WorkingDirectory=/opt/minecraft/server
ExecStart=/usr/bin/java -Xmx"$minecraft_mem"M -Xms"$minecraft_mem"M -jar server.jar nogui
ExecStop=/opt/minecraft/tools/mcrcon/mcrcon -H 127.0.0.1 -P "$rcon_port" -p "$rcon_password" stop

[Install]
WantedBy=multi-user.target" > ~/test.txt && sudo mv ~/test.txt /etc/systemd/system/minecraft.service
}

create_startup_script () {
  echo "
#!/bin/sh

java -Xms"$minecraft_mem"G -Xmx"$minecraft_mem"G -XX:+UseG1GC -XX:+ParallelRefProcEnabled -XX:MaxGCPauseMillis=200 -XX:+UnlockExperimentalVMOptions -XX:+DisableExplicitGC -XX:+AlwaysPreTouch -XX:G1NewSizePercent=30 -XX:G1MaxNewSizePercent=40 -XX:G1HeapRegionSize=8M -XX:G1ReservePercent=20 -XX:G1HeapWastePercent=5 -XX:G1MixedGCCountTarget=4 -XX:InitiatingHeapOccupancyPercent=15 -XX:G1MixedGCLiveThresholdPercent=90 -XX:G1RSetUpdatingPauseTimePercent=5 -XX:SurvivorRatio=32 -XX:+PerfDisableSharedMem -XX:MaxTenuringThreshold=1 -Dusing.aikars.flags=https://mcflags.emc.gs -Daikars.new.flags=true -jar spigot.jar nogui

  " > test.txt && sudo mv test.txt /opt/minecraft/spigotstart.sh
}

set_resources () {
   total_mem=`free -h | grep Mem | cut -d ":" -f2 | cut -d "." -f1 | tr -d " "`
   echo "It looks like you have a total of ${GRN}"$total_mem"G${NC} of memory."
   echo ${RED}"It may not be the best idea to use all available memory for the server${NC}, how much ram would you like to use to run the minecraft server?"
   read minecraft_mem
   if [ "$minecraft_mem" -gt "$total_mem" ]; then
     clear
     echo ${RED}"You don't seem to have that much memory available."${NC}
     set_resources
   else
     minecraft_mem=$((minecraft_mem))
   fi
}

#################
##### Code ######
#################

#Update Server
sudo apt update && sudo apt upgrade -y && sudo apt install git -y

#Update Required Packages
sudo apt install wget apt-transport-https gnupg screen -y

#####  Check if you have priviledged access  #####
clear
echo "This script must be run as a user with root privileges."
echo "Now checking if current user has root privileges"
  sleep 2
  answer=`sudo whoami`

if [ "$answer" != "root" ]; then 
  echo ${RED}"It doesn't appear that your user has root privileges."${NC}
  sleep 1
  echo "Please login as a user with sudo/root privileges and try again."
  sleep 1
  echo "Now exiting script."
  exit 1
else
  echo ${GRN}"It appears this user has root privileges."${NC}
  sleep 1
fi


#####  Update the Server/Check Java Runtime and Install if missing  #####
  echo "Now running Java check."
  echo ""
  sleep 1
javacheck=`java -version 2>&1 | grep version | cut -d '"' -f2 | cut -d "." -f1`
if [ "$javacheck" = 16 ] || [ "$javacheck" = 17 ] || [ "$javacheck" = 18 ]; then 
  echo "Java version is "$javacheck"."
  echo ""
  sleep 2
else
  echo ${RED}"Java version too old or not detected."${NC}
  echo ""
  echo ${CYN}"Now installing latest Java version"${NC}
  echo ""
  sleep 2
  sudo apt install openjdk-18-jre-headless -y
fi

#####  Update Firewall  #####
sudo ufw status
sudo ufw allow OpenSSH
sudo ufw allow 25565
sudo ufw status

#####  Create Minecraft User & Install server as that user  #####
clear
echo "Creating Minecraft system user to run Minecraft server"
echo ""
sudo useradd -r -m -U -d /opt/minecraft -s /bin/bash minecraft && echo ${GRN}"Minecraft User Added"${NC}
sleep 3
echo "" && echo "Creating Minecraft Server Directories and Downloading Spigot"
    echo ""
    sleep 3
    echo ""
    sudo -u minecraft bash -c 'wget -O BuildTools.jar  https://hub.spigotmc.org/jenkins/job/BuildTools/lastSuccessfulBuild/artifact/target/BuildTools.jar' && echo ${GRN}"Done!"${NC}
    echo ""
    echo "Creating server directory"
    echo ""
    sudo -u minecraft bash -c 'mkdir -p ~/{server}'
    sudo -u minecraft bash -c 'mv ~/buildtools/spigot-1.* ~/server/spigot.jar'
    clear
    #Set server resources
    set_resources
    create_startup_script
    sudo -u minecraft bash -c 'chmod +x /opt/minecraft/spigotstart.sh'
    echo "Now installing Spigot." && echo ${CYN}"WARNING, depending on the resources on your server, this may take some time."${NC}
    sudo -u minecraft bash -c 'sh /opt/minecraft/spigotstart.sh'
    echo "Updating Eula file."
    echo ""
    sudo sed -i "s/\("eula" *= *\).*/\1true/" /opt/minecraft/server/eula.txt && echo ${GRN}"Server Installed"${NC} 
    clear


