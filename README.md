# Yet Another Wifi Auto Connect (YAWAC)

This script allow you to configure a dataset of wireless connection and automatically connect on with your OpenWrt as reapeter.

It work's with all types of secure/none secure wifi, and also some free hotspot like FreeWifi.

Last but least, YAWAC is made for OpenWrt router (like my old Netgear WGT634U), but it can be adapt for you own usage.


## Installation

Copy all the files in the router with the same folders tree and apply the right permissions.
```bash
cp -R ./yawac/* /
chmod 644 /etc/config/yawac
chmod 755 /etc/init.d/yawac /usr/bin/yawac.sh
```

Enable YAWAC, to start on boot and run it.
```bash
/etc/init.d/yawac enable
/etc/init.d/yawac start
```


## Remove

Stop YAWAC, disable the start on boot, and remove files.
```bash
/etc/init.d/yawac stop
/etc/init.d/yawac disable
rm -f /etc/config/yawac /etc/init.d/yawac /usr/bin/yawac.sh
```


## How it works

YAWAC will start at boot, and check the network availability every 60 seconds, by issuing several pings to google.com.
If all fail, it will trigger the network scan and reconfigure the network.

You should edit the file 
```bash
/etc/yawac/config
```

The order in that file makes a difference: YAWAC will parse the file and configure the first network found.
That means that "net1" has preference over "net2", and so on.

The config file needs three variables for each network:
```
net1_ssid="WIFI1"
net1_encrypt="psk2"
net1_key="Wifi12345678"
```

To create new networks, just create new "net2", "net3" and so on:
```
net2_ssid="WIFI2"
net2_encrypt="psk"
net2_key="Wifi2pass"

net3_ssid="WIFI3"
net3_encrypt="wep"
net3_key="qwerty1234"

net4_ssid="WIFI4"
net4_encrypt="none"
net4_key=""
```

### IMPORTANT NOTE:

Remeber to PUT dashes ("") and DO NOT put spaces between the variable name, the "=" and the variable value.
Examples of what NOT TO DO:
```
net1_ssid=WIFI1
net1_ssid ="WIFI1"
net1_ssid = "WIFI1"
net1_ssid= "WIFI1"
```

YAWAC would work in an impredictable way if you don't respect the format.

There is a limit of 99 networks, YAWAC will stop searching if it reaches the "net99", then return to the network check loop.
I don't think anybody has 99 wifi networks seen on his home!


### SOME NOTES:

When YAWAC finds a wireless network, it configures the interface and restarts the networking system.
After 20 seconds, it checks for internet availability even if the network was found.
If it fails, it discards the changes and continues searching from the point it left before.
Example: It finds "net1", but "net1" has no internet. Then it returns to the networks search, but looking for "net2".

In the case that a "netX" ssid variable is blank or doesn't exist, it assumes that it's the end of the file and the search is cancelled.
However, YAWAC will keep running, so after 30 seconds it will check the network again.

You can edit the checking intervals by editing the variables inside the config file:
```
# Background internet connection checking interval
ConnCheckTimer=60
```

```
# After new network is set, time to wait for network to establish, before checking if it's working
NewConnCheckTimer=25
```

Also, you can set a random wlan MAC on each boot by changing the line:
```
randMac="0"
```
to
```
randMac="1"
```

At any moment, you can force a network scan (ex. your preferred network came back).
Just type:
```bash
yawac.sh --force
```

It will scan and search the available networks and put the first available that it finds inside of the config file.

Also, you can force a scan and try to connect to a specific network:
```bash
yawac.sh --force 5
```

It will try to connect to the network correspoding to "net5_ssid"

It will output the result: if it wasn't found, if it failed to connect, or it sucessfully connected.

Also, if you have set a FreeWifi and want to pass only one time the cretendials you can do like this:
```bash
yawac.sh --freewifi mylogin mypassword
```

### Is it working?

Ensure that it's running in the background:

Run "ps -aux". You should see YAWAC running:
```
25718 root      1520 S    {yawac.sh} /bin/sh /usr/bin/yawac.sh
```

Run "logread -f" to see the script output. It should be like this:
```
Jan  24 15:13:12 OpenWrt user.notice root: YAWAC: Checking network...
Jan  24 15:13:16 OpenWrt user.notice root: YAWAC: Network OK
Jan  24 15:13:46 OpenWrt user.notice root: YAWAC: Checking network...
Jan  24 15:13:50 OpenWrt user.notice root: YAWAC: Network OK
```

If the network came unavailable, it should output this:
```
Jan  24 15:14:20 OpenWrt user.notice root: YAWAC: Checking network...
Jan  24 15:14:20 OpenWrt user.notice root: YAWAC: Network failed. Starting network change...
Jan  24 15:14:20 OpenWrt user.notice root: YAWAC: Performing network scan...
#...
#(Various messages about network initialization / setup)
#...
Jan  24 15:14:21 OpenWrt user.notice root: YAWAC: Searching available networks...
Jan  24 15:14:21 OpenWrt user.notice root: YAWAC: WLAN1662 network found. Applying settings..
#...
#(Various messages about network initialization / setup)
#...
Jan  24 15:14:41 OpenWrt user.notice root: YAWAC: Checking connectivity...
Jan  24 15:14:45 OpenWrt user.notice root: YAWAC: Internet working! Searching ended
```

If the FreeWifi credentials are not valid you will see 
```
Jan  24 15:15:21 OpenWrt user.notice root: YAWAC: FreeWifi credentials sent...
Jan  24 15:15:36 OpenWrt user.notice root: YAWAC: FreeWifi credentials was not accepted
```


## Todo

* Test the connection speed and change if it's not quick enough
* Get some credentials for those french mobile free hotspot to implement them; idem for some others
  * Bouygues Telecom Wi-Fi
  * SFR WiFi FON
  * SFR WiFi Mobile
  * Orange
* Add a graphic interface in LuCi backoffice


## Thanks to

* dabyd64 for [wifiMgr](https://forum.openwrt.org/viewtopic.php?pid=197363#p197363)
* cyprio, redvivi, liberio for sharing [freewifi.sh](http://forum.ubuntu-fr.org/viewtopic.php?pid=21071681#p21071681)
