#!/bin/sh

# Yet Another Wifi Auto Connect (YAWAC)
# https://github.com/mehdichaouch/YAWAC

. /etc/config/yawac

APP=YAWAC

net_status() {
        logger "$APP": Checking network...
        net=$(ping -c5 ${ping_addr} | grep "time=")
        if [ "$net" ]; then
                logger "$APP": Network OK
                #got ping response!
                return
        else
                logger "$APP": Network failed. Starting network change...
                net_change
        fi
}

net_change() {
        logger "$APP": Performing network scan...
        scanres=
        ifconfig wlan0 down
        iw phy phy0 interface add scan0 type station
        ifconfig scan0 up

        while [ "$scanres" = "" ]; do
                #sometimes it shows nothing, so better to ensure we did a correct scan
                scanres=$(iw scan0 scan | grep SSID)
        done

        iw dev scan0 del
        ifconfig wlan0 up
        killall -HUP hostapd
        logger "$APP": Searching available networks...

        if [ "$1" ]; then
                ssid=net"$1"_ssid
                eval ssid=\$$ssid
                echo Trying to connect to network "$1"":    $ssid"
                n=$(expr "$1" - "1")
        else
                n=0
        fi

        while [ "1" ]; do
                n=$(expr "$n" + "1")

                if [ "$n" = "99" ]; then
                        #too much counts. Crazy wireless count, breaking loop!
                        break
                fi

                ssid=net"$n"_ssid
                encryption=net"$n"_encryption
                key=net"$n"_key
                macaddr=net"$n"_macaddr

                eval ssid=\$$ssid
                eval encryption=\$$encryption
                eval key=\$$key
                eval macaddr=\$$macaddr

                if [ "$ssid" = "" ]; then
                        #ssid not existing or empty. Assume it's the end of the wlist file
                        break
                fi
                echo SSID: $ssid
                echo KEY: $key
                echo ENCRYPTION: $encryption
                echo MAC ADDR: $macaddr

                active=$(echo $scanres | grep " $ssid ">&1 )
                if [ "$active" ]; then
                        if [ "$1" ]; then
                                echo Network found. Connecting...
                        fi
                        logger "$APP": "$ssid" network found. Applying settings..
                        uci set wireless.@wifi-iface[1]="wifi-iface"
                        uci set wireless.@wifi-iface[1].ssid="$ssid"
                        uci set wireless.@wifi-iface[1].encryption="$encryption"
                        uci set wireless.@wifi-iface[1].device="radio0"
                        uci set wireless.@wifi-iface[1].mode="sta"
                        uci set wireless.@wifi-iface[1].network="wwan"
                        uci set wireless.@wifi-iface[1].key="$key"
                        uci set wireless.@wifi-iface[1].macaddr="$macaddr"

                        uci commit wireless
                        /etc/init.d/network restart

                        #wait some seconds for everything to connect and configure
                        sleep $NewConnCheckTimer
                        logger "$APP": Checking connectivity...

                        #check for internet connection, 5 ping sends
                        net=$(ping -c5 ${ping_addr} | grep "time=")
                        if [ "$net" ]; then
                                #got ping response!
                                logger "$APP": Internet working! Searching ended
                                if [ "$1" ]; then
                                        echo Success!
                                fi
                                break
                        fi
                        #connect to freewifi
                        if [ "$ssid" = "$freewifi_ssid" ]; then
                                freewifi_do_connect
                        fi
                        if [ "$1" ]; then
                                echo Connection failed!
                                break
                        fi
                        logger "$APP": Failed! Searching next available network...
                fi
        done
}

freewifi_do_connect() {
        logger "$APP": Detect FreeWifi ssid
        if [ "$1" ]; then
                freewifi_login=$1
                if [ "$2" ]; then
                        freewifi_password=$2
                fi
        fi

        while [ "1" ]; do
                echo "Envoi des identifiants a l'interface FreeWifi..."
                WGET_OUT=$(curl -s -k -L -F "login=$freewifi_login" -F "password=$freewifi_password" --connect-timeout $freewifi_timeout --max-time $freewifi_timeout "$freewifi_url_auth" 2>/dev/null | grep -c "$freewifi_connexion_reussie")
                logger "$APP": FreeWifi credentials sent...
                ping -q -c2 ${ping_addr} 2>&1
                if [ $? -eq 0 ] && [ ${WGET_OUT} -eq 0 ]; then
                        # echo "Modification du MTU de l'interface wlan0..."
                        # ifconfig wlan0 mtu 1460 2>/dev/null
                        # echo "Le MTU a ete modifie : $(ifconfig wlan0 | sed -n 's/.*mtu \([0-9]*\).*$/\1/p')"
                        logger "$APP": Connection to FreeWifi is OK
                        return 0
                        exit 0
                else
                        logger "$APP": FreeWifi credentials was not accepted
                        sleep $ConnCheckTimer
                fi
        done
}

rand_mac_addr() {
        macaddr=$(dd if=/dev/urandom bs=1024 count=1 2>/dev/null|md5sum|sed 's/^\(..\)\(..\)\(..\)\(..\)\(..\)\(..\).*$/00:\2:\3:\4:\5:01/')
        # uci set wireless.radio0.macaddr="$macaddr"
        uci set wireless.@wifi-iface[1].macaddr="$macaddr"
        uci commit wireless
        /etc/init.d/network restart
}

if [ "$1" = "" ]; then
        echo "No arguments supplied"

elif [ "$1" = "--force" ]; then
        net_change $2

elif [ "$1" = "--daemon" ]; then

        if [ "$randMac" = "1" ]; then
                rand_mac_addr
        fi
        net_change

        while [ "1" ]; do
                sleep $ConnCheckTimer
                net_status
        done

elif [ "$1" = "--freewifi" ]; then
        freewifi_do_connect $2 $3

else
        echo "Wrong arguments"
fi
