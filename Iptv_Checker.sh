#!/bin/bash

# =====================================================
# IPTV Server Checker - WITH AUTO REFRESH
# Automatically refreshes all plugins after saving
# =====================================================

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# =====================================================
# PATHS
# =====================================================

# EStalker path - uses e-portals.txt
ESTALKER_PATH="/etc/enigma2/estalker/"
ESTALKER_FILE="${ESTALKER_PATH}e-portals.txt"

# XKlass path
XKLASS_PATH="/etc/enigma2/xklass/"
XKLASS_FILE="${XKLASS_PATH}playlists.txt"

# X-Streamity path
XSTREAMITY_PATH="/etc/enigma2/xstreamity/"
XSTREAMITY_FILE="${XSTREAMITY_PATH}playlists.txt"

# BouquetMakerXtream path
BOUQUET_PATH="/etc/enigma2/bouquetmakerxtream/"
BOUQUET_FILE="${BOUQUET_PATH}playlists.txt"

TEMP_LINKS="/tmp/iptv_links.txt"
WORKING_M3U="/tmp/working_m3u.txt"
WORKING_MAC="/tmp/working_mac.txt"

clear_screen() {
    printf "\033[2J\033[H"
}

show_banner() {
    echo -e "${BLUE}╔══════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║     ${CYAN}IPTV Server Checker v13.0 - WITH AUTO REFRESH${BLUE}               ║${NC}"
    echo -e "${BLUE}║       ${GREEN}(Auto refresh plugins after saving)${BLUE}                      ║${NC}"
    echo -e "${BLUE}╚══════════════════════════════════════════════════════════╝${NC}"
    echo ""
}

create_directories() {
    echo -e "${CYAN}📁 Checking directories...${NC}"
    
    if [ -d "$ESTALKER_PATH" ]; then
        echo -e "${GREEN}   ✓ Exists: $ESTALKER_PATH${NC}"
    else
        mkdir -p "$ESTALKER_PATH"
        echo -e "${YELLOW}   📁 Created: $ESTALKER_PATH${NC}"
    fi
    
    if [ -d "$XKLASS_PATH" ]; then
        echo -e "${GREEN}   ✓ Exists: $XKLASS_PATH${NC}"
    else
        mkdir -p "$XKLASS_PATH"
        echo -e "${YELLOW}   📁 Created: $XKLASS_PATH${NC}"
    fi
    
    if [ -d "$XSTREAMITY_PATH" ]; then
        echo -e "${GREEN}   ✓ Exists: $XSTREAMITY_PATH${NC}"
    else
        mkdir -p "$XSTREAMITY_PATH"
        echo -e "${YELLOW}   📁 Created: $XSTREAMITY_PATH${NC}"
    fi
    
    if [ -d "$BOUQUET_PATH" ]; then
        echo -e "${GREEN}   ✓ Exists: $BOUQUET_PATH${NC}"
    else
        mkdir -p "$BOUQUET_PATH"
        echo -e "${YELLOW}   📁 Created: $BOUQUET_PATH${NC}"
    fi
    
    echo ""
}

check_m3u() {
    local url="$1"
    echo -e "${YELLOW}🔍 Checking M3U:${NC} $url"
    
    content=$(curl -s --max-time 5 --connect-timeout 5 "$url" 2>/dev/null | head -300)
    
    if [ -z "$content" ]; then
        echo -e "${RED}   ✗ No response (Server down)${NC}\n"
        return 1
    fi
    
    channels=$(echo "$content" | grep -c "#EXTINF" 2>/dev/null)
    
    if [ "$channels" -gt 0 ]; then
        echo -e "${GREEN}   ✓✓✓ WORKING! ✓✓✓${NC}"
        echo -e "${GREEN}   📺 Channels: $channels${NC}"
        echo "$url" >> "$WORKING_M3U"
        echo -e ""
        return 0
    else
        echo -e "${RED}   ✗ Not working${NC}\n"
        return 1
    fi
}

check_mac() {
    local portal_url="$1"
    local mac_address="$2"
    
    base_url=$(echo "$portal_url" | sed 's:/c/*$::' | sed 's:/$::')
    full_url="${base_url}/c/"
    
    echo -e "${YELLOW}🔍 Checking MAC Portal:${NC} $full_url"
    echo -e "${YELLOW}   📍 MAC:${NC} $mac_address"
    
    response=$(curl -s --max-time 5 --connect-timeout 5 -L "$full_url" 2>/dev/null)
    
    if echo "$response" | grep -qiE "stalker|portal|login|auth|api"; then
        echo -e "${GREEN}   ✓✓✓ WORKING! ✓✓✓${NC}"
        echo "$full_url" >> "$WORKING_MAC"
        echo "$mac_address" >> "$WORKING_MAC"
        echo -e ""
        return 0
    else
        echo -e "${RED}   ✗ Not working${NC}\n"
        return 1
    fi
}

save_m3u_results() {
    echo ""
    echo -e "${BLUE}╔══════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║                 💾 SAVING TO PLUGINS 💾                    ║${NC}"
    echo -e "${BLUE}╚══════════════════════════════════════════════════════════╝${NC}"
    echo ""
    
    if [ ! -s "$WORKING_M3U" ]; then
        echo -e "${RED}❌ No working M3U servers to save${NC}"
        return 1
    fi
    
    local total_working=$(wc -l < $WORKING_M3U)
    
    # Save to XKlass
    echo -e "${CYAN}📝 Saving to XKlass:${NC} $XKLASS_FILE"
    mkdir -p "$XKLASS_PATH"
    if [ -f "$XKLASS_FILE" ] && [ -s "$XKLASS_FILE" ]; then
        echo "" >> "$XKLASS_FILE"
    fi
    cat "$WORKING_M3U" >> "$XKLASS_FILE"
    echo -e "${GREEN}   ✓ Saved $total_working M3U link(s) to XKlass${NC}"
    
    # Save to X-Streamity
    echo -e "${CYAN}📝 Saving to X-Streamity:${NC} $XSTREAMITY_FILE"
    mkdir -p "$XSTREAMITY_PATH"
    if [ -f "$XSTREAMITY_FILE" ] && [ -s "$XSTREAMITY_FILE" ]; then
        echo "" >> "$XSTREAMITY_FILE"
    fi
    cat "$WORKING_M3U" >> "$XSTREAMITY_FILE"
    echo -e "${GREEN}   ✓ Saved $total_working M3U link(s) to X-Streamity${NC}"
    
    # Save to BouquetMakerXtream
    echo -e "${CYAN}📝 Saving to BouquetMakerXtream:${NC} $BOUQUET_FILE"
    mkdir -p "$BOUQUET_PATH"
    if [ -f "$BOUQUET_FILE" ] && [ -s "$BOUQUET_FILE" ]; then
        echo "" >> "$BOUQUET_FILE"
    fi
    cat "$WORKING_M3U" >> "$BOUQUET_FILE"
    echo -e "${GREEN}   ✓ Saved $total_working M3U link(s) to BouquetMakerXtream${NC}"
    
    echo ""
    echo -e "${GREEN}✅ M3U results saved successfully!${NC}"
}

save_mac_results() {
    echo ""
    echo -e "${BLUE}╔══════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║                 💾 SAVING TO PLUGINS 💾                    ║${NC}"
    echo -e "${BLUE}╚══════════════════════════════════════════════════════════╝${NC}"
    echo ""
    
    if [ ! -s "$WORKING_MAC" ]; then
        echo -e "${RED}❌ No working MAC portals to save${NC}"
        return 1
    fi
    
    local added=$(($(wc -l < $WORKING_MAC) / 2))
    
    echo -e "${CYAN}📝 Saving to EStalker:${NC} $ESTALKER_FILE"
    mkdir -p "$ESTALKER_PATH"
    if [ -f "$ESTALKER_FILE" ] && [ -s "$ESTALKER_FILE" ]; then
        echo "" >> "$ESTALKER_FILE"
    fi
    cat "$WORKING_MAC" >> "$ESTALKER_FILE"
    echo -e "${GREEN}   ✓ Saved $added MAC portal(s) to EStalker${NC}"
    
    echo ""
    echo -e "${GREEN}✅ MAC results saved to EStalker only!${NC}"
}

# =====================================================
# REFRESH FUNCTION - Auto refresh plugins
# =====================================================

auto_refresh() {
    echo ""
    echo -e "${BLUE}╔══════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║                 🔄 AUTO REFRESH PLUGINS 🔄                 ║${NC}"
    echo -e "${BLUE}╚══════════════════════════════════════════════════════════╝${NC}"
    echo ""
    
    echo -e "${YELLOW}📁 Cleaning cache files...${NC}"
    
    # XStreamity cache
    if [ -d "/tmp/xstreamity" ]; then
        rm -rf /tmp/xstreamity
        echo -e "${GREEN}   ✓ XStreamity cache cleared${NC}"
    fi
    
    # XKlass cache
    if [ -d "/tmp/xklass" ]; then
        rm -rf /tmp/xklass
        echo -e "${GREEN}   ✓ XKlass cache cleared${NC}"
    fi
    
    # BouquetMakerXtream temp
    if [ -f "/etc/enigma2/bouquetmakerxtream/bmx_playlists.json" ]; then
        rm -f /etc/enigma2/bouquetmakerxtream/bmx_playlists.json
        echo -e "${GREEN}   ✓ BouquetMakerXtream temp cleared${NC}"
    fi
    
    echo ""
    echo -e "${YELLOW}🔄 Refreshing Enigma2 GUI...${NC}"
    echo -e "${GREEN}   ✓ GUI will restart in 2 seconds${NC}"
    echo ""
    
    sleep 2
    
    # إعادة تشغيل الواجهة
    init 4 && init 3
}

paste_links() {
    local type_name="$1"
    local example="$2"
    
    echo -e "${CYAN}╔══════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║  📝 PASTE YOUR ${type_name} LINKS${NC}"
    echo -e "${CYAN}║                                                          ║${NC}"
    echo -e "${CYAN}║  💡 Instructions:${NC}"
    echo -e "${CYAN}║     1. Copy all your links${NC}"
    echo -e "${CYAN}║     2. Paste them here (all at once)${NC}"
    echo -e "${CYAN}║     3. Press Enter${NC}"
    echo -e "${CYAN}║     4. Type ${GREEN}DONE${CYAN} and press Enter${NC}"
    echo -e "${CYAN}║                                                          ║${NC}"
    echo -e "${CYAN}║  📌 Example:${NC}"
    echo -e "${CYAN}║     $example${NC}"
    echo -e "${CYAN}╚══════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "${YELLOW}📋 Paste your links now:${NC}"
    echo -e "${BLUE}────────────────────────────────────────────────────────${NC}"
    
    > "$TEMP_LINKS"
    
    while IFS= read -r line; do
        [[ "$line" == "DONE" || "$line" == "done" ]] && break
        [[ -n "$line" ]] && echo "$line" >> "$TEMP_LINKS"
    done
    
    echo -e "${BLUE}────────────────────────────────────────────────────────${NC}"
    echo ""
    
    if [ ! -s "$TEMP_LINKS" ]; then
        echo -e "${RED}❌ No links entered!${NC}"
        exit 1
    fi
    
    echo -e "${GREEN}📋 Received $(wc -l < $TEMP_LINKS) link(s)${NC}"
    echo ""
}

show_summary() {
    echo ""
    echo -e "${BLUE}╔══════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║                    🏆 FINAL SUMMARY 🏆                    ║${NC}"
    echo -e "${BLUE}╚══════════════════════════════════════════════════════════╝${NC}"
    echo ""
    
    if [ "$CHOICE" == "1" ]; then
        echo -e "${CYAN}📊 M3U Check Results:${NC}"
        echo -e "   Total checked: $TOTAL"
        echo -e "   Working: ${GREEN}$WORKING${NC}"
        echo ""
        echo -e "${CYAN}📁 Saved to:${NC}"
        echo -e "   ${GREEN}✓${NC} $XKLASS_FILE"
        echo -e "   ${GREEN}✓${NC} $XSTREAMITY_FILE"
        echo -e "   ${GREEN}✓${NC} $BOUQUET_FILE"
    else
        echo -e "${CYAN}📊 MAC Portal Check Results:${NC}"
        echo -e "   Total checked: $TOTAL"
        echo -e "   Working: ${GREEN}$WORKING${NC}"
        echo ""
        echo -e "${CYAN}📁 Saved to:${NC}"
        echo -e "   ${GREEN}✓${NC} $ESTALKER_FILE"
    fi
    
    echo ""
    echo -e "${YELLOW}💡 Auto refresh will start in 3 seconds...${NC}"
    sleep 3
}

# =====================================================
# MAIN PROGRAM
# =====================================================

while true; do
    clear_screen
    show_banner
    create_directories

    echo -e "${CYAN}╔══════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║                    🎯 SELECT CHECK TYPE 🎯                ║${NC}"
    echo -e "${CYAN}╠══════════════════════════════════════════════════════════╣${NC}"
    echo -e "${CYAN}║                                                          ║${NC}"
    echo -e "${CYAN}║     ${GREEN}1${CYAN})  M3U Links (Xtream Codes)                       ║${NC}"
    echo -e "${CYAN}║        → Saves to: XKlass + X-Streamity + BMX          ║${NC}"
    echo -e "${CYAN}║                                                          ║${NC}"
    echo -e "${CYAN}║     ${GREEN}2${CYAN})  MAC Portal (Stalker)                         ║${NC}"
    echo -e "${CYAN}║        → Saves to: EStalker ONLY (e-portals.txt)        ║${NC}"
    echo -e "${CYAN}║                                                          ║${NC}"
    echo -e "${CYAN}║     ${GREEN}3${CYAN})  Exit                                        ║${NC}"
    echo -e "${CYAN}║                                                          ║${NC}"
    echo -e "${CYAN}╚══════════════════════════════════════════════════════════╝${NC}"
    echo ""

    while true; do
        echo -ne "${YELLOW}➤ Enter your choice [1-3]: ${NC}"
        read -r CHOICE
        if [[ "$CHOICE" == "1" || "$CHOICE" == "2" || "$CHOICE" == "3" ]]; then
            break
        else
            echo -e "${RED}❌ Invalid choice! Please enter 1, 2, or 3.${NC}"
        fi
    done

    if [ "$CHOICE" == "3" ]; then
        echo -e "${GREEN}👋 Goodbye!${NC}"
        exit 0
    fi

    case $CHOICE in
        1)
            TYPE_NAME="M3U (Xtream Codes)"
            EXAMPLE="http://mag.123tv.to:8080/get.php?username=user&password=pass&type=m3u_plus"
            
            clear_screen
            show_banner
            paste_links "$TYPE_NAME" "$EXAMPLE"
            
            echo -e "${BLUE}╔══════════════════════════════════════════════════════════╗${NC}"
            echo -e "${BLUE}║                    🔍 CHECKING M3U 🔍                      ║${NC}"
            echo -e "${BLUE}╚══════════════════════════════════════════════════════════╝${NC}"
            echo ""
            
            > "$WORKING_M3U"
            TOTAL=0
            WORKING=0
            
            while IFS= read -r link; do
                [[ -z "$link" ]] && continue
                ((TOTAL++))
                check_m3u "$link"
                [ $? -eq 0 ] && ((WORKING++))
                sleep 0.5
            done < "$TEMP_LINKS"
            
            save_m3u_results
            show_summary
            auto_refresh
            ;;
            
        2)
            TYPE_NAME="MAC Portal (Stalker)"
            EXAMPLE="http://elt.ipfr.tv:80/c/ 00:1E:B8:CA:1E:E6"
            
            clear_screen
            show_banner
            paste_links "$TYPE_NAME" "$EXAMPLE"
            
            echo -e "${BLUE}╔══════════════════════════════════════════════════════════╗${NC}"
            echo -e "${BLUE}║                 🔍 CHECKING MAC PORTAL 🔍                  ║${NC}"
            echo -e "${BLUE}╚══════════════════════════════════════════════════════════╝${NC}"
            echo ""
            
            > "$WORKING_MAC"
            TOTAL=0
            WORKING=0
            
            while IFS= read -r line; do
                [[ -z "$line" ]] && continue
                ((TOTAL++))
                
                portal_url=$(echo "$line" | awk '{print $1}')
                mac_address=$(echo "$line" | grep -oEi '[0-9A-F]{2}:[0-9A-F]{2}:[0-9A-F]{2}:[0-9A-F]{2}:[0-9A-F]{2}:[0-9A-F]{2}')
                
                if [ -z "$mac_address" ]; then
                    echo -e "${RED}   ✗ Invalid MAC address format: $line${NC}\n"
                else
                    check_mac "$portal_url" "$mac_address"
                    [ $? -eq 0 ] && ((WORKING++))
                fi
                sleep 0.5
            done < "$TEMP_LINKS"
            
            save_mac_results
            show_summary
            auto_refresh
            ;;
    esac

    rm -f "$TEMP_LINKS" "$WORKING_M3U" "$WORKING_MAC"
    
done
