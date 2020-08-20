#!/bin/bash
. wlan.config
cp ./servo.ino.tpl ./servo.ino
sed -i "/wifi_ssid = /c\const char* wifi_ssid = \"$SSID\";" ./servo.ino
sed -i "/wifi_passwd = /c\const char* wifi_passwd = \"$PASS\";" ./servo.ino
