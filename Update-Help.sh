#!/usr/bin/env bash
base="$HOME"
if ! [[ -d $base/help ]] 
	then mkdir $base/help
fi
msfvenom -l payloads > $base/help/msf-payloads.txt

if [[ `which enum4linux` ]]
	then enum4linux -h > $base/help/enum4linux
fi

if [[ `which onesixtyone` ]]
	then onesixyone > $base/help/onesixtyone
fi

if [[ `which snmp-check` ]]
	then snmp-check -h > $base/help/snmp-check
fi

if [[ `which tshark` ]] 
	then tshark -G > $base/help/tshark_G.txt
fi

if [[ `which hURL` ]]
	then hURL --help > $base/help/hurl
fi

if [[ `which commix` ]]
	then commix -h > $base/help/commix
fi
