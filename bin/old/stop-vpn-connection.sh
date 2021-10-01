#!/bin/bash
sudo brew services stop openvpn > openvpn-stop.log 2>&1 &
sudo pkill openvpn
