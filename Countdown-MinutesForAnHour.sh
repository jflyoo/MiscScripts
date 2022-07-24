x=60; while [ true ] ; do sleep 60; x=$(($x-1));  spd-say "$x minutes remaining"; done ;
