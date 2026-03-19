. /lib/functions.sh

ipq40xx_mikrotik_mac_address() {
	base_mac=$(cat /sys/firmware/mikrotik/hard_config/mac_base)
	counter=0
	if [ ! -d /sys/class/net/eth0/dsa ]; then
		return
	fi
	ip link set dev eth0 address $(macaddr_add "$base_mac" "$counter")
	# first port is WAN, and has mac_base MAC address
	if [ -d /sys/class/net/eth0/upper_wan ]; then
		iface=wan
		ip link set dev "$iface" address $(macaddr_add "$base_mac" "$counter")
		counter=$((counter+1))
	fi
	# each other port has a consecutive MAC address
	for member in /sys/class/net/eth0/upper*; do
		iface=${member#*_}
		case "$iface" in
		lan*|ether*|sw-eth*)
			ip link set dev "$iface" address $(macaddr_add "$base_mac" "$counter")
			counter=$((counter+1))
			;;
		esac
	done
}

preinit_set_mac_address() {
	case $(board_name) in
	asus,rt-ac42u)
		base_mac=$(mtd_get_mac_binary_ubi Factory 0x1006)
		ip link set dev eth0 address $base_mac
		ip link set dev lan1 address $base_mac
		ip link set dev lan2 address $base_mac
		ip link set dev lan3 address $base_mac
		ip link set dev lan4 address $base_mac
		ip link set dev wan address $(mtd_get_mac_binary_ubi Factory 0x9006)
		;;
	engenius,eap2200)
		base_mac=$(cat /sys/class/net/eth0/address)
		ip link set dev eth1 address $(macaddr_add "$base_mac" 1)
		;;
	extreme-networks,ws-ap3915i|\
	extreme-networks,ws-ap391x)
		ip link set dev eth0 address $(mtd_get_mac_ascii CFG1 ethaddr)
		;;
	mikrotik,wap-ac|\
	mikrotik,wap-ac-lte|\
	mikrotik,wap-r-ac)
		base_mac=$(cat /sys/firmware/mikrotik/hard_config/mac_base)
		ip link set dev sw-eth1 address "$base_mac"
		ip link set dev sw-eth2 address $(macaddr_add "$base_mac" 1)
		;;
	mikrotik,*)
		ipq40xx_mikrotik_mac_address
    ;;
	teltonika,rutx50)
		# Vendor Bootloader removes nvmem-cells from partition,
		# so this needs to be done here.
		base_mac="$(mtd_get_mac_binary 0:CONFIG 0x0)"
		ip link set dev eth0 address "$base_mac"
		ip link set dev lan1 address "$base_mac"
		ip link set dev lan2 address "$base_mac"
		ip link set dev lan3 address "$base_mac"
		ip link set dev lan4 address "$base_mac"
		ip link set dev wan address "$(macaddr_add "$base_mac" 1)"
		;;
	zyxel,nbg6617)
		base_mac=$(cat /sys/class/net/eth0/address)
		ip link set dev eth0 address $(macaddr_add "$base_mac" 2)
		ip link set dev eth1 address $(macaddr_add "$base_mac" 3)
		;;
	esac
}

boot_hook_add preinit_main preinit_set_mac_address
