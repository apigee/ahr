#!/bin/sh
# This scripts sets up peering to the Apigee tenant project where Apigee SaaS GKE cluster runs.
endpoint=$(curl -s http://metadata.google.internal/computeMetadata/v1/instance/attributes/ENDPOINT -H "Metadata-Flavor: Google")
if [ -x /bin/firewall-cmd ]
then
   sysctl -w net.ipv4.ip_forward=1
   firewall-cmd --permanent --add-masquerade
   firewall-cmd --permanent --add-forward-port=port=443:proto=tcp:toaddr="$endpoint"
   firewall-cmd --permanent --add-forward-port=port=15021:proto=tcp:toaddr="$endpoint"
   firewall-cmd --add-masquerade
   firewall-cmd --add-forward-port=port=443:proto=tcp:toaddr="$endpoint"
   firewall-cmd --add-forward-port=port=15021:proto=tcp:toaddr="$endpoint"
else
   sysctl -w net.ipv4.ip_forward=1
   iptables -t nat -A POSTROUTING -j MASQUERADE
   iptables -t nat -A PREROUTING -p tcp --dport 443 -j DNAT --to-destination "$endpoint"
   iptables -t nat -A PREROUTING -p tcp --dport 15021 -j DNAT --to-destination "$endpoint"
fi
sysctl -ew net.netfilter.nf_conntrack_buckets=1048576
sysctl -ew net.netfilter.nf_conntrack_max=8388608
