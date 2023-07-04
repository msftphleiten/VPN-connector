# VPN-connector
VPN-Connector is a powershell script that connects to the MSFTVPN using the preexisting connection and then creates routes for the listed entries.

The script also checks if there is an active route from a previous session and deletes them.

The routes are configured through a CSV file.

Options in the config file are:
* DNS
* IP
* Subnet

## DNS
With DNS the script queries a DNS entry and then adds the route using the destination IP address.

## IP
With IP it will not require a DNS query, but use the IP address directly with an attached /32 as a host route

## Subnet
If you want to use a subnet specify it using a CIDR block, e.g. 192.168.1.0/24


