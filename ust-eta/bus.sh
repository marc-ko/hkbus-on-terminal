# geteta.sh
# !/bin/bash
# echo "Getting eta value from rc.data.gov.hk"
# export 
# $PWD


#if [[ "$BUSETA" == "" ]]; then
#echo "#buseta" >> ~/.zshrc
#echo 'export $BUSETA=$PWD' >> ~/.zshrc
#echo 'alias bus=$BUSETA/geteta.sh' >>~/.zshrc
#fi
# if [[ "$SHELL" == '/bin/zsh']];then
#     echo 'export APP=/opt/tinyos-2.x/apps' >> ~/.zshrc 
# else
#     echo 'export APP=/opt/tinyos-2.x/apps' >> ~/.bashrc
# fi

#alias ustbus="bash $PWD/geteta.sh"
r_flag=""

printUsage() {
    echo "Usage: [i|o] [r] "
    echo "   i: stands for inbound bus"
    echo "   o: stands for outbound bus"
    echo "   r: route number (e.g. 8X,792M)"
}




destShort(){
initials=""
for word in $1; do
    if [[ $word == "Station" ]]; then 
        break
    fi
    
    first_letter=${word:0:1}
    if [[ $first_letter == "(" ]]; then break
    fi
    initials+=$first_letter
done
echo "$initials"
}

if [ "$#" -ne 2 ]; then
    echo "Here's how to use it uwu"
    printUsage
    exit 1
fi

OurBelovedUSTCTB="003130"
OurBelovedUSTKMB="B3E60EE895DBBF06"
temp="001152"
routeNumber=$(echo $2 | tr 'a-z' 'A-Z')
response=$(curl -X GET -H "Accept: application/json" -H "Content-Type: application/json" \
 "https://rt.data.gov.hk/v2/transport/citybus/eta/CTB/$OurBelovedUSTCTB/$routeNumber" -s )
content=$(echo $response | jq '.data')


# https://data.etabus.gov.hk/v1/transport/kmb/eta/B3E60EE895DBBF06/91m/2
if [ "$content" == [] ] || [ "$content" == "null" ]; then
    response=$(curl -X GET -H "Accept: application/json" -H "Content-Type: application/json" \
    "https://data.etabus.gov.hk/v1/transport/kmb/eta/$OurBelovedUSTKMB/${routeNumber}/1" -s )
    content=$(echo $response | jq '.data')
     [[ "$content" == [] ]] && response=$(curl -X GET -H "Accept: application/json" -H "Content-Type: application/json" \
    "https://data.etabus.gov.hk/v1/transport/kmb/eta/$OurBelovedUSTKMB/${routeNumber}/2" -s ) ||  echo " "
    content=$(echo $response | jq '.data')

if [ "$content" == [] ] || [ "$content" == "null" ]; then   
    echo "There is no bus available at the moment. Seems it's not longer in service hours. Please try again later."
    exit 1
fi
fi
i=0
for eta in $(echo $content | jq -r '.[] | @base64'); do
    _jq() {  
        if [[ -z "$eta" ]]; then
            echo "There is no bus available at the moment. Seems it's not longer in service hours. Please try again later."
            return 1
        fi
        echo ${eta} | base64 --decode | jq -r ${1}
    }
    case $1 in 
     i|I) 
     if [ "$(_jq '.dir')" == "I" ]; then
        i=$((i + 1))
        if [[ "$OSTYPE" != "darwin"* ]];then
            arrival=$(date -d "$(_jq '.eta'| sed 's/.\{6\}$//')" +%s)
            now=$(date +%s)
            buseta=$(date -d "$(_jq '.eta'| sed 's/.\{6\}$//')" "+%H:%M:%S")
        else
            arrival=$(date -j -f "%Y-%m-%dT%H:%M:%S" "$(_jq '.eta'| sed 's/.\{6\}$//')" +%s) 
            now=$(date +%s)
            buseta=$(date -j -f "%Y-%m-%dT%H:%M:%S" ""$(_jq '.eta'| sed 's/.\{6\}$//')"" "+%H:%M:%S")
        fi
        echo "The $i th bus will be arriving after $(( (arrival-now)/60 )) minute"
        echo "Route: $(_jq '.route')"
        echo "ETA: $buseta"
        echo "GOING TO : $(_jq '.dest_en')"
        echo "Bounding : $(_jq '.dir')"
        echo "----------------"
     fi
     ;;
     o|O) 
     if [ "$(_jq '.dir')" == "O" ]; then
        i=$((i + 1))
        if [[ "$OSTYPE" != "darwin"* ]];then
            arrival=$(date -d "$(_jq '.eta'| sed 's/.\{6\}$//')" +%s)
            now=$(date +%s)
            buseta=$(date -d "$(_jq '.eta'| sed 's/.\{6\}$//')" "+%H:%M:%S")
        else
            arrival=$(date -j -f "%Y-%m-%dT%H:%M:%S" "$(_jq '.eta'| sed 's/.\{6\}$//')" +%s) 
            now=$(date +%s)
            buseta=$(date -j -f "%Y-%m-%dT%H:%M:%S" ""$(_jq '.eta'| sed 's/.\{6\}$//')"" "+%H:%M:%S")
        fi
        echo "The $i th bus will be arriving after $(( (arrival-now)/60 )) minute"
        echo "Route: $(_jq '.route')"
        echo "ETA: $buseta"
        echo "GOING TO : $(_jq '.dest_en')"
        echo "Bounding : $(_jq '.dir')"
        echo "----------------"
     fi
     ;;
    *) 
    destRoute_short=$(destShort "$(_jq '.dest_en')"| tr '[:upper:]' '[:lower:]')

    if [[ $1 == $destRoute_short* ]]; then
        i=$((i + 1))
        if [[ "$OSTYPE" != "darwin"* ]];then
            arrival=$(date -d "$(_jq '.eta'| sed 's/.\{6\}$//')" +%s)
            now=$(date +%s)
            buseta=$(date -d "$(_jq '.eta'| sed 's/.\{6\}$//')" "+%H:%M:%S")
        else
            arrival=$(date -j -f "%Y-%m-%dT%H:%M:%S" "$(_jq '.eta'| sed 's/.\{6\}$//')" +%s) 
            now=$(date +%s)
            buseta=$(date -j -f "%Y-%m-%dT%H:%M:%S" ""$(_jq '.eta'| sed 's/.\{6\}$//')"" "+%H:%M:%S")
        fi
        echo "The $i th bus will be arriving after $(( (arrival-now)/60 )) minute"
        echo "Route: $(_jq '.route')"
        echo "ETA: $buseta"
        echo "GOING TO : $(_jq '.dest_en')"
        echo "Bounding : $(_jq '.dir')"
        echo "----------------"
    fi
    ;;
    esac
done
if [ $i -eq 0 ]; then
    arg1=$1
    if [ $arg1 == "i" ]; then
       arg1="inbound"
    elif [ $arg1 == "o" ]; then
       arg1="outbound"
    fi
    echo "$arg1 bus is not on the street yet. Or maybe ur input isn't correct"
    printUsage
fi

<<EOF

