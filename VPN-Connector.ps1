# Script to automatically connect to MSFTVPN-Manual and create routes for easier access to VMs and Bastion hosts

#requires -version 7.1
#Requires -RunAsAdministrator

$_VPNConnectionName = "MSFTVPN-Manual"
#$_RouteFileName = "routes.json"
$_RouteFileName = "routes.csv"
$_rasexecutable = "rasdial.exe"

# check if already connected to VPN
$_vpnconnection = Get-VpnConnection $_VPNConnectionName

if ($_vpnconnection.ConnectionStatus -eq "Connected") {
    Write-Host "Already connected"
}
else {
    Write-Host "Not connected - connecting"
    
    $_command = $_rasexecutable + " " + $_VPNConnectionName
    Write-Host "running $_command"
    Invoke-Expression $_command

    $_vpnconnection = Get-VpnConnection $_VPNConnectionName
    if ($_vpnconnection.ConnectionStatus -eq "Connected") {
        Write-Host "Connected."
    }
    else {
        Write-Host "Problem connecting"
        Write-Host "Please check your VPN connection manually"
        exit
    }
}

# get VPN IP address
$_ipaddress = (Get-NetIPAddress | where {$_.InterfaceAlias -eq "MSFTVPN-Manual" -and $_.AddressFamily -eq "IPv4"}).IPAddress
$_interfaceindex = (Get-NetIPAddress | where {$_.InterfaceAlias -eq "MSFTVPN-Manual" -and $_.AddressFamily -eq "IPv4"}).InterfaceIndex
Write-Host "IP address of VPN interface is $_ipaddress"

$_activeroutes = Get-NetRoute

# add routes 
#$_routes = Get-Content $_RouteFileName | ConvertFrom-Json
$_routes = Get-Content $_RouteFileName | ConvertFrom-Csv -Delimiter ","
#foreach ($_route in $_routes.VPNRoutes) {
foreach ($_route in $_routes) {

    if ($_route.Type -eq "DNS") {
        $_routeip = (Resolve-DnsName $_route.Value).IPAddress
        $_routeipprefix = $_routeip + "/32"
    }
    
    if ($_route.Type -eq "IP")
    {
        $_routeipprefix = $_route.Value + "/32"
    }

    if ($_route.Type -eq "Subnet") {
        $_routeipprefix = $_route.Value
    }

    if (($_activeroutes | where {$_.DestinationPrefix -eq $_routeipprefix}).Count -gt 0) {
        Write-Host "Route already exists, deleting it"
        Remove-NetRoute -DestinationPrefix $_routeipprefix -Confirm:$false
    }
    
    Write-Host "adding $_routeipprefix to $_ipaddress"
    New-NetRoute -DestinationPrefix $_routeipprefix -AddressFamily IPv4 -NextHop $_ipaddress -PolicyStore ActiveStore -InterfaceIndex $_interfaceindex

}

