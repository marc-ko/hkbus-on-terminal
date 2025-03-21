#!/bin/bash
# !! NOT TESTED !!

# !! NOT TESTED !!

# !! NOT TESTED !!

# !! NOT TESTED !!

# !! NOT TESTED !!



# Hong Kong Bus Terminal ETA Tool
# Allows checking bus arrival times from the terminal

# Configuration
CACHE_DIR="$HOME/.hkbus/cache"
mkdir -p "$CACHE_DIR"

# API Endpoints
KMB_API="https://data.etabus.gov.hk/v1/transport/kmb"
CTB_API="https://rt.data.gov.hk/v2/transport/citybus/eta/CTB"
NWFB_API="https://rt.data.gov.hk/v2/transport/citybus/eta/NWFB"

# Common stops
STOPS=(
  "UST:003130:B3E60EE895DBBF06:Hong Kong University of Science and Technology"
  "Hang Hau:001152:B5B65344997AD207:MTR Hang Hau Station"
  "HKUST North Gate:003130:B3E60EE895DBBF06:HKUST North Gate"
)

# Help message
print_usage() {
  echo "Hong Kong Bus Terminal Tool"
  echo ""
  echo "Usage:"
  echo "  bus list                      - List all predefined stops"
  echo "  bus search [keyword]          - Search for stops by name"
  echo "  bus routes [stop_name]        - List all routes for a stop"
  echo "  bus eta [stop_name] [route]   - Get ETA for a specific route at a stop"
  echo "  bus [i|o] [route]             - Legacy mode: Get inbound/outbound ETAs for UST"
  echo ""
  echo "Examples:"
  echo "  bus list"
  echo "  bus search hkust"
  echo "  bus routes UST"
  echo "  bus eta UST 91M"
  echo "  bus i 91M"
}

# Find a stop by name
find_stop() {
  local keyword=$1
  local found=false
  
  # Convert to lowercase for case-insensitive search
  keyword=$(echo "$keyword" | tr '[:upper:]' '[:lower:]')
  
  for stop in "${STOPS[@]}"; do
    IFS=':' read -r name ctb_id kmb_id description <<< "$stop"
    
    # Convert to lowercase for case-insensitive comparison
    local name_lower=$(echo "$name" | tr '[:upper:]' '[:lower:]')
    local description_lower=$(echo "$description" | tr '[:upper:]' '[:lower:]')
    
    if [[ "$name_lower" == *"$keyword"* || "$description_lower" == *"$keyword"* ]]; then
      echo "$name:$ctb_id:$kmb_id:$description"
      found=true
    fi
  done
  
  if [ "$found" = false ]; then
    return 1
  fi
  
  return 0
}

# List all stops
list_stops() {
  echo "Available Stops:"
  echo "----------------"
  for stop in "${STOPS[@]}"; do
    IFS=':' read -r name ctb_id kmb_id description <<< "$stop"
    echo "$name - $description"
  done
}

# Search for stops
search_stops() {
  local keyword=$1
  
  if [ -z "$keyword" ]; then
    echo "Please provide a search keyword"
    return 1
  fi
  
  echo "Searching for stops matching '$keyword':"
  echo "----------------------------------------"
  
  local results=$(find_stop "$keyword")
  
  if [ $? -ne 0 ]; then
    echo "No stops found matching '$keyword'"
    return 1
  fi
  
  echo "$results" | while IFS=: read -r name ctb_id kmb_id description; do
    echo "$name - $description"
  done
}

# Format time
format_time() {
  local eta_time=$1
  
  if [[ "$OSTYPE" != "darwin"* ]]; then
    arrival=$(date -d "${eta_time%+*}" +%s)
    now=$(date +%s)
    minutes=$(( (arrival - now) / 60 ))
    formatted=$(date -d "${eta_time%+*}" "+%H:%M:%S")
  else
    arrival=$(date -j -f "%Y-%m-%dT%H:%M:%S" "${eta_time%+*}" +%s) 
    now=$(date +%s)
    minutes=$(( (arrival - now) / 60 ))
    formatted=$(date -j -f "%Y-%m-%dT%H:%M:%S" "${eta_time%+*}" "+%H:%M:%S")
  fi
  
  echo "$minutes minutes ($formatted)"
}

# Get destination short name
destShort() {
  local dest="$1"
  local initials=""
  
  for word in $dest; do
    if [[ $word == "Station" ]]; then 
      break
    fi
    
    first_letter=${word:0:1}
    if [[ $first_letter == "(" ]]; then 
      break
    fi
    
    initials+=$first_letter
  done
  
  echo "$initials"
}

# Get ETA for KMB
get_kmb_eta() {
  local stop_id=$1
  local route=$2
  
  response=$(curl -s "$KMB_API/eta/$stop_id/$route/1")
  content=$(echo "$response" | jq '.data')
  
  if [ "$content" == "[]" ] || [ "$content" == "null" ]; then
    response=$(curl -s "$KMB_API/eta/$stop_id/$route/2")
    content=$(echo "$response" | jq '.data')
  fi
  
  if [ "$content" == "[]" ] || [ "$content" == "null" ]; then
    echo "No KMB buses for route $route at this stop."
    return 1
  fi
  
  echo "$content" | jq -c '.[]' | while read -r eta_data; do
    dest=$(echo "$eta_data" | jq -r '.dest_tc')
    eta_time=$(echo "$eta_data" | jq -r '.eta')
    dir=$(echo "$eta_data" | jq -r '.dir')
    
    # Skip if no ETA available
    if [ "$eta_time" == "null" ]; then
      continue
    fi
    
    formatted_time=$(format_time "$eta_time")
    direction=""
    
    if [ "$dir" == "I" ]; then
      direction="Inbound"
    elif [ "$dir" == "O" ]; then
      direction="Outbound"
    fi
    
    echo "🚌 $route to $dest ($direction)"
    echo "   ETA: $formatted_time"
  done
}

# Get ETA for CTB/NWFB
get_ctb_eta() {
  local company=$1
  local stop_id=$2
  local route=$3
  
  response=$(curl -s "$CTB_API/$stop_id/$route")
  content=$(echo "$response" | jq '.data')
  
  if [ "$content" == "[]" ] || [ "$content" == "null" ]; then
    echo "No CTB/NWFB buses for route $route at this stop."
    return 1
  fi
  
  echo "$content" | jq -c '.[]' | while read -r eta_data; do
    dest=$(echo "$eta_data" | jq -r '.dest_tc')
    eta_time=$(echo "$eta_data" | jq -r '.eta')
    dir=$(echo "$eta_data" | jq -r '.dir')
    
    # Skip if no ETA available
    if [ "$eta_time" == "null" ]; then
      continue
    fi
    
    formatted_time=$(format_time "$eta_time")
    direction=""
    
    if [ "$dir" == "I" ]; then
      direction="Inbound"
    elif [ "$dir" == "O" ]; then
      direction="Outbound"
    fi
    
    echo "🚌 $route to $dest ($direction)"
    echo "   ETA: $formatted_time"
  done
}

# Get ETA for a specific stop and route
get_eta() {
  local stop_name=$1
  local route=$(echo $2 | tr 'a-z' 'A-Z')
  
  # Find the stop
  stop_info=$(find_stop "$stop_name")
  
  if [ $? -ne 0 ]; then
    echo "Stop '$stop_name' not found. Try 'bus list' to see available stops."
    return 1
  fi
  
  IFS=':' read -r name ctb_id kmb_id description <<< "$stop_info"
  
  echo "🚏 $description"
  echo "Checking ETAs for route $route..."
  echo "--------------------------------"
  
  # Try KMB first
  get_kmb_eta "$kmb_id" "$route"
  
  # Then try CTB
  get_ctb_eta "CTB" "$ctb_id" "$route"
}

# Legacy mode for UST
legacy_mode() {
  local direction=$1
  local route=$(echo $2 | tr 'a-z' 'A-Z')
  
  # Constants for UST
  OurBelovedUSTCTB="003130"
  OurBelovedUSTKMB="B3E60EE895DBBF06"
  
  response=$(curl -s "$CTB_API/$OurBelovedUSTCTB/$route")
  content=$(echo $response | jq '.data')
  
  if [ "$content" == "[]" ] || [ "$content" == "null" ]; then
    if [ "$direction" == "i" ]; then
      response=$(curl -s "$KMB_API/eta/$OurBelovedUSTKMB/$route/1")
    else
      response=$(curl -s "$KMB_API/eta/$OurBelovedUSTKMB/$route/2")
    fi
    content=$(echo $response | jq '.data')
  fi
  
  if [ "$content" == "[]" ] || [ "$content" == "null" ]; then
    echo "There is no bus available at the moment. Seems it's not longer in service hours. Please try again later."
    return 1
  fi
  
  i=0
  echo "$content" | jq -c '.[]' | while read -r eta_data; do
    if [ -z "$eta_data" ]; then
      echo "There is no bus available at the moment. Seems it's not longer in service hours. Please try again later."
      return 1
    fi
    
    dir=$(echo "$eta_data" | jq -r '.dir')
    
    if [[ "$direction" == "i" && "$dir" == "I" ]] || [[ "$direction" == "o" && "$dir" == "O" ]]; then
      i=$((i + 1))
      
      eta_time=$(echo "$eta_data" | jq -r '.eta')
      dest=$(echo "$eta_data" | jq -r '.dest_en')
      route_num=$(echo "$eta_data" | jq -r '.route')
      
      if [[ "$OSTYPE" != "darwin"* ]]; then
        arrival=$(date -d "${eta_time%+*}" +%s)
        now=$(date +%s)
        buseta=$(date -d "${eta_time%+*}" "+%H:%M:%S")
      else
        arrival=$(date -j -f "%Y-%m-%dT%H:%M:%S" "${eta_time%+*}" +%s) 
        now=$(date +%s)
        buseta=$(date -j -f "%Y-%m-%dT%H:%M:%S" "${eta_time%+*}" "+%H:%M:%S")
      fi
      
      echo "The $i th bus will be arriving after $(( (arrival-now)/60 )) minute"
      echo "Route: $route_num"
      echo "ETA: $buseta"
      echo "GOING TO : $dest"
      echo "Bounding : $dir"
      echo "----------------"
    fi
  done
  
  if [ $i -eq 0 ]; then
    arg1=$direction
    if [ $arg1 == "i" ]; then
       arg1="inbound"
    elif [ $arg1 == "o" ]; then
       arg1="outbound"
    fi
    echo "$arg1 bus is not on the street yet. Or maybe ur input isn't correct"
    print_usage
  fi
}

# Main function
main() {
  # No arguments, show help
  if [ $# -eq 0 ]; then
    print_usage
    return 0
  fi
  
  # Process commands
  case $1 in
    list)
      list_stops
      ;;
    
    search)
      if [ $# -lt 2 ]; then
        echo "Please provide a search keyword"
        print_usage
        return 1
      fi
      search_stops "$2"
      ;;
    
    routes)
      if [ $# -lt 2 ]; then
        echo "Please provide a stop name"
        print_usage
        return 1
      fi
      echo "Feature not implemented yet"
      ;;
    
    eta)
      if [ $# -lt 3 ]; then
        echo "Please provide both stop name and route number"
        print_usage
        return 1
      fi
      get_eta "$2" "$3"
      ;;
    
    i|o)
      if [ $# -ne 2 ]; then
        echo "Please provide a route number"
        print_usage
        return 1
      fi
      legacy_mode "$1" "$2"
      ;;
    
    help|--help|-h)
      print_usage
      ;;
    
    *)
      echo "Unknown command: $1"
      print_usage
      return 1
      ;;
  esac
}

# Run main function with all arguments
main "$@"