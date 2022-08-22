#!/bin/bash
# Script to test how many requests per second based on the api log file

TIMEOUT=15
THRESHOLD1=4
THRESHOLD2=1
EXPECT_TIME=600
WHITE_LIST=("210.245.31.15" "210.245.31.16" "118.69.184.18" "42.119.252.79" "42.119.252.82" "183.80.199.34" "42.119.252.115" "210.211.126.26" "210.211.126.27" "42.119.252.117" "183.80.199.35" "42.117.9.173" "183.80.199.18" "183.80.199.19" "183.80.199.20" "183.80.199.21""183.80.199.120" "183.80.199.84" "210.245.25.147" "183.80.199.22" "118.69.252.67" "118.69.210.218" "183.80.199.237" "183.80.199.238" "42.117.9.175" "42.117.9.176" "183.80.199.52" "183.80.199.50" "118.69.184.18" "42.117.9.171" "118.68.171.42" "118.68.171.40" "118.68.171.25" "118.68.171.134" "118.68.171.122" "118.68.171.11" "118.68.171.107" "118.68.170.93" "118.68.170.251" "118.68.170.245" "118.68.170.200" "118.68.170.197" "118.68.170.189" "118.68.170.146" "118.68.170.143" "118.68.170.140" "118.68.170.121" "118.68.170.117" "118.68.169.218" "118.68.169.187" "118.68.168.80" "118.68.168.225" "118.68.168.224" "118.68.168.143" "42.118.166.35" "183.80.133.202" "42.112.3.214")
TELEGRAM_BOT_TOKEN=1297885445:AAERHTZUhawc2lcfY4-YEYf8LY2eegkCo1o
CHAT_ID=-415043178
URL="https://api.telegram.org/bot$TELEGRAM_BOT_TOKEN/sendMessage"
while true
do
  DAY=$(date +"%D %T")
  cd /opt/scripts/check_request/
  timeout $((TIMEOUT++)) tail -f /var/log/nginx/json_access/api.fptplay.net.json.log |timeout $TIMEOUT awk {'print $9" " $21" "  $7; fflush();'} |logtop -q |grep -E "([0-9]{1,3}\.){3}([0-9]{1,3})" | while read line
  do
    c=$(echo $line | awk '{print $2}')
    f=$(echo $line | awk '{print $3}')
    i=$(echo $line | awk '{print $4}' | grep -Eo "([0-9]{1,3}\.){3}([0-9]{1,3})")
    uri=$(echo $line | awk '{print $5}')
    h=$(echo $line | awk '{print $6}')
    if (( $(echo "$f > $THRESHOLD1" | bc -l) ))
    then
      echo "\"IP\": $i \"URI\": $uri \"Request/s\": $f" >> tmp.log
    fi
    if (( $(echo "$f > $THRESHOLD2" | bc -l) ))
    then
      check=0
      #echo $uri |grep -Eo "("user/otp/login"|"/chat/")"
      echo $uri |grep -Eo "("user/otp/login")"
      check=$?
      for ip in "${WHITE_LIST[@]}"
      do
        if [ "$ip" == "$i" ]
        then 
          check=1
        fi
      done
      if [ $check == "0" ]
      then
        echo "\"IP\": $i \"URI\": $uri \"Request/s\": $f \Host\": $h" >> tmp_block.log
        #sudo iptables -I INPUT -s $i -m time --datestart $(date -u +%FT%R)  --datestop $(date -u +%FT%R -d@$(expr $EXPECT_TIME + `date +%s`))  -j DROP
        sudo iptables -I INPUT -s $i -m time --datestart $(date -u +%FT%T)  --datestop $(date -u +%FT%T -d@$(expr $EXPECT_TIME + `date +%s`))  -j DROP
      fi
    fi
  done
  if [ -s tmp.log ]
  then
    sed  -i "1i $(date +"%D %T")" tmp.log
    cat tmp.log >> result.log
    curl -s -X POST $URL -d chat_id=$CHAT_ID -d text="$(cat tmp.log)" >> /dev/null
    truncate -s 0 tmp.log
  fi
  if [ -s tmp_block.log ]
    then
    sed  -i "1i Block-$(date +"%D %T")" tmp_block.log
#  cat tmp.log >> result.log
#  echo "" >> result.log
    curl -s -X POST $URL -d chat_id=$CHAT_ID -d text="Block IP for 10 minute $(cat tmp_block.log)" >> /dev/null
    truncate -s 0 tmp_block.log
  fi
sleep 1
done
