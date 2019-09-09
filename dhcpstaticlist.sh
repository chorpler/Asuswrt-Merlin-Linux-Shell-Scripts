#!/bin/sh
####################################################################################################
# Script: dhcpstaticlist.sh
# Original Author: Xentrk
# Last Updated Date: 10-Sept-2019
# Version 2.0.0
#
# Description:
#  Helpful utility to
#  1) Save dhcp_staticlist nvram values to /opt/tmp/dhcp_staticlist.txt. This will allow you to restore the values after performing a factory reset.
#  2) Restore dhcp_staticlist nvram values from /opt/tmp/dhcp_staticlist.txt after a factory reset
#  3) Preview current nvram dhcp static list in dnsmasq.conf format
#  4) Append Output DHCP Static List to /jffs/configs/dnsmasq.conf.add & Disable Manual Assignment in the WAN GUI. You will then be prompted to reboot the router to have the settings take effect.
#  5) Disable DHCP Manual Assignment
#  6) Enable DHCP Manual Assignment
#  7) Save nvram dhcp_staticlist to /opt/tmp/dhcp_staticlist.txt and clear the DHCP Manual Assignment nvram values from dhcp_staticlist
#  8) Display the character count of dhcp_staticlist
#
####################################################################################################

# Uncomment for debugging
#set -x

COLOR_WHITE='\033[0m'
COLOR_GREEN='\e[0;32m'
DHCP_STATICLIST="/opt/tmp/dhcp_staticlist.txt"
DHCP_HOSTNAMES="/opt/tmp/dhcp_hostnames.txt"

Menu_DHCP_Staticlist() {

  clear

  while true; do
    printf '\n\nUse this utility to save or restore dhcp static list nvram values\n\n'
    printf '%b[1]%b - Save nvram dhcp_staticlist and dhcp_hostnames to /opt/tmp/\n' "${COLOR_GREEN}" "${COLOR_WHITE}"
    printf '%b[2]%b - Restore nvram dhcp_staticlist and dhcp_hostnames from /opt/tmp/\n' "${COLOR_GREEN}" "${COLOR_WHITE}"
    printf '%b[3]%b - Preview DHCP Static List in dnsmasq format\n' "${COLOR_GREEN}" "${COLOR_WHITE}"
    printf '%b[4]%b - Append DHCP Static List to dnsmasq.conf.add & Disable DHCP Manual Assignment\n' "${COLOR_GREEN}" "${COLOR_WHITE}"
    printf '%b[5]%b - Disable DHCP Manual Assignment\n' "${COLOR_GREEN}" "${COLOR_WHITE}"
    printf '%b[6]%b - Enable DHCP Manual Assignment\n' "${COLOR_GREEN}" "${COLOR_WHITE}"
    printf '%b[7]%b - Backup nvram dhcp_staticlist and dhcp_hostnames to /opt/tmp/ and clear nvram values\n' "${COLOR_GREEN}" "${COLOR_WHITE}"
    printf '%b[8]%b - Display character size of dhcp_staticlist (2999 is the limit)\n' "${COLOR_GREEN}" "${COLOR_WHITE}"
    printf '%b[e]%b - Exit\n' "${COLOR_GREEN}" "${COLOR_WHITE}"
    echo
    printf "==> "
    read -r option
    echo
    case "$option" in
    1)
      Save_DHCP_Staticlist
      Save_DHCP_Hostnames
      echo
      echo "Press enter to continue"
      read -r
      Menu_DHCP_Staticlist
      break
      ;;
    2)
      Restore_DHCP_Staticlist
      Restore_DHCP_Hostnames
      echo
      echo "Press enter to continue"
      read -r
      Menu_DHCP_Staticlist
      break
      ;;
    3)
      Save_Dnsmasq_Format
      echo
      echo "Press enter to continue"
      read -r
      Menu_DHCP_Staticlist
      break
      ;;
    4)
      printf '\n' #add return in case no blank line exists at end of file
      echo " " >>/jffs/configs/dnsmasq.conf.add
      Save_Dnsmasq_Format >>/jffs/configs/dnsmasq.conf.add
      nvram set dhcp_static_x=0
      nvram commit
      echo "In order for the DHCP static reservations to take affect"
      echo "you must reboot the router. Do so now?"
      echo
      echo "[y] - Yes"
      echo "[n] - No"
      echo
      printf "==> "
      read -r menu_option

      case "$menu_option" in
      y)
        reboot
        ;;
      n)
        break
        ;;
      *)
        echo "[*] $option Isn't An Option!"
        ;;
      esac

      echo
      echo "Press enter to continue"
      read -r
      Menu_DHCP_Staticlist
      break
      ;;
    5)
      nvram set dhcp_static_x=0
      nvram commit
      echo
      echo "Press enter to continue"
      read -r
      Menu_DHCP_Staticlist
      break
      ;;
    6)
      nvram set dhcp_static_x=1
      nvram commit
      echo
      echo "Press enter to continue"
      read -r
      Menu_DHCP_Staticlist
      break
      ;;
    7)
      Save_DHCP_Staticlist
      Save_DHCP_Hostnames
      nvram unset dhcp_staticlist
      nvram set dhcp_static_x=0
      nvram commit
      echo
      echo "Press enter to continue"
      read -r
      Menu_DHCP_Staticlist
      break
      ;;
    8)
      word_count=$(nvram get dhcp_staticlist | wc -m)
      # wc appears to count line return or extra line?
      word_count=$((word_count - 1))
      echo
      echo "The current character size of dhcp_staticlist is: $word_count"
      echo
      echo "Press enter to continue"
      read -r
      Menu_DHCP_Staticlist
      break
      ;;

    e)
      exit 0
      ;;
    *)
      printf '\nOption choice %b%s%b is not a valid option!\n' "${COLOR_GREEN}" "$option" "${COLOR_WHITE}"
      echo
      echo "Press enter to continue"
      read -r
      Menu_DHCP_Staticlist
      ;;
    esac
  done
}

Make_Backup() {

  FILE="$1"
  TIMESTAMP="$(date +%Y-%m-%d_%H-%M-%S)"
  BACKUP_FILE="${FILE}.${TIMESTAMP}"

  if [ -s "$FILE" ]; then
    if ! mv "$FILE" "$BACKUP_FILE" >/dev/null 2>&1; then
      printf 'Error backing up existing %b%s%b to %b%s%b\n' "$COLOR_GREEN" "$FILE" "$COLOR_WHITE" "$COLOR_GREEN" "$BACKUP_FILE" "$COLOR_WHITE"
      printf 'Exiting %s\n' "$(basename "$0")"
      exit 1
    else
      printf 'Existing %b%s%b found\n' "$COLOR_GREEN" "$FILE" "$COLOR_WHITE"
      printf '%b%s%b backed up to %b%s%b\n' "$COLOR_GREEN" "$FILE" "$COLOR_WHITE" "$COLOR_GREEN" "$BACKUP_FILE" "$COLOR_WHITE"
    fi
  fi
}

Save_DHCP_Staticlist() {
  if [ -s "$DHCP_STATICLIST" ]; then
    Make_Backup "$DHCP_STATICLIST"
  fi

  nvram get dhcp_staticlist >"$DHCP_STATICLIST" && echo "dhcp_staticlist nvram values successfully stored in $DHCP_STATICLIST" || echo "Unknown error occurred trying to save $DHCP_STATICLIST"
}

Save_DHCP_Hostnames() {
  if [ -s "$DHCP_HOSTNAMES" ]; then
    Make_Backup "$DHCP_HOSTNAMES"
  fi

  nvram get dhcp_hostnames >"$DHCP_HOSTNAMES" && echo "dhcp_hostnames nvram values successfully stored in $DHCP_HOSTNAMES" || echo "Unknown error occurred trying to save $DHCP_HOSTNAMES"
}

Restore_DHCP_Staticlist() {

  nvram set dhcp_staticlist="$(cat "$DHCP_STATICLIST")"
  nvram commit
  if [ -n "$(nvram get dhcp_staticlist >/dev/null 2>&1)" ]; then
    echo "dhcp_staticlist successfully restored"
  else
    echo "Unknown error occurred trying to restore dhcp_staticlist"
  fi
}

Restore_DHCP_Hostnames() {

  nvram set dhcp_hostnames="$(cat "$DHCP_HOSTNAMES")"
  nvram commit
  if [ -n "$(nvram get dhcp_hostnames >/dev/null 2>&1)" ]; then
    echo "dhcp_hostnames successfully restored"
  else
    echo "Unknown error occurred trying to restore dhcp_hostnames"
  fi
}

Save_Dnsmasq_Format() {

  # Retrieve Static DHCP assignments MAC and IP Address; remove < and > symbols and separate fields with a space.
  nvram get dhcp_staticlist | sed 's/<//;s/>/ /g;s/</ /g' >/tmp/staticlist.$$

  # Retrieve Static DHCP assignments MAC and hostname; remove < and > symbols and separate fields with a space.

  if [ -s /jffs/nvram/dhcp_hostnames ]; then #HND Routers store hostnames in a file
    awk '{print $0}' /jffs/nvram/dhcp_hostnames | sed 's/<//;s/>/ /g;s/</ /g' >/tmp/hostnames.$$
  else
    nvram get dhcp_hostnames | sed 's/<//;s/>/ /g;s/</ /g' >/tmp/hostnames.$$
  fi
  # count number of fields in the file
  word_count_staticlist=$(head -1 /tmp/staticlist.$$ | wc -w)
  word_count_hostnames=$(head -1 /tmp/hostnames.$$ | wc -w)

  if [ "$word_count_staticlist" -ne "$word_count_hostnames" ]; then
    echo "Unexpected error condition dhcp_staticlist and dhcp_hostnames don't match"
  else
    # count number of static leases. This is the number of loops required to get IP address and client name
    # divide word_count by 2 since client information is listed in groups of 2 fields: MAC_Address and IP_Address
    static_leases_count=$((word_count_staticlist / 2))
  fi

  # write MAC and IP Addresses for Static DHCP LAN Clients to /tmp/MACIP.$$
  true >/tmp/MACIP.$$

  loop_count=1
  MAC=1
  IP=2

  while [ "$loop_count" -le "$static_leases_count" ]; do
    cut -d' ' -f"$MAC","$IP" </tmp/staticlist.$$ >>"/tmp/MACIP.$$"
    MAC=$((MAC + 2))
    IP=$((IP + 2))
    loop_count=$((loop_count + 1))
  done

  # write MAC and HOSTNAME for Static DHCP LAN Clients to /tmp/MACHOSTNAMES.$$
  true >/tmp/MACHOSTNAMES.$$

  loop_count=1
  MAC=1
  HOSTNAME=2

  while [ "$loop_count" -le "$static_leases_count" ]; do
    cut -d' ' -f"$MAC","$HOSTNAME" </tmp/hostnames.$$ >>"/tmp/MACHOSTNAMES.$$"
    MAC=$((MAC + 2))
    HOSTNAME=$((HOSTNAME + 2))
    loop_count=$((loop_count + 1))
  done

  # Join the two files together to form one file containing MAC, IP, HOSTNAME
  awk '
    NR==FNR { k[$1]=$2; next }
    { print $0, k[$1] }
  ' /tmp/MACIP.$$ /tmp/MACHOSTNAMES.$$ >/tmp/MACIPHOSTNAMES.$$

  # write dhcp-host entry to /jffs/configs/dnsmasq.conf.add
  #
  sort -t . -k 3,3n -k 4,4n /tmp/MACIPHOSTNAMES.$$ | awk '{ print "dhcp-host="$1","$2","$3; }'

  rm -rf /tmp/staticlist.$$
  rm -rf /tmp/hostnames.$$
  rm -rf /tmp/MACIP.$$
  rm -rf /tmp/MACHOSTNAMES.$$
  rm -rf /tmp/MACIPHOSTNAMES.$$
}

clear
Menu_DHCP_Staticlist
