---
layout: post
title: "Neutron Networking: Neutron Routers and the L3 Agent"
date: 2013-12-16 14:26
comments: true
author: James Denton
published: false
categories:
- OpenStack
- Networking
- Neutron
- Cloud Networks
---

In this multi-part blog series I intend to dive into the various components of the OpenStack Neutron project, and to also provide working examples of networking configurations for clouds built with [Rackspace Private Cloud](http://www.rackspace.com/cloud/private/) powered by [OpenStack](http://www.openstack.org) on Ubuntu 12.04 LTS. 

In the previous installment, [Neutron Networking: VLAN Provider Networks](http://developer.rackspace.com/blog/neutron-networking-vlan-provider-networks.html), I provided guidance on configuring tagged networks in Neutron using VLANs. In this fourth installment, I'll describe how to combine flat and VLAN provider networks with GRE-based tenant networks using the L3 agent and Neutron routers.<!--more-->

####Getting Started / Prerequisites

In the last two installments I covered the concept of provider networks, or networks that are somehow tied into the physical infrastructure. I highly recommend giving them a read if you haven't already done so, as this walkthough depends on a working provider network configuration.

[Neutron Networking: Simple Flat Network](http://developer.rackspace.com/blog/neutron-networking-simple-flat-network.html)

[Neutron Networking: VLAN Provider Networks](http://developer.rackspace.com/blog/neutron-networking-vlan-provider-networks.html)

####Neutron L3 Agent / What is it and how does it work?

Neutron has an API extension to allow administrators and tenants to create "routers" that connect to L2 networks. Known as the "neutron-l3-agent", it uses the Linux IP stack and iptables to perform L3 forwarding and NAT. In order to support multiple routers with potentially overlapping IP addresses, neutron-l3-agent defaults to using Linux [network namespaces](http://www.opencloudblog.com/?p=42) to provide isolated forwarding contexts. Like the DHCP namespaces that exist for every network defined in Neutron, each router will have its own namespace with a name based on its UUID.

####Network Design / Implementing Neutron Routers

While deploying instances using provider networks is suitable in many cases, there is a limit to the scalability of such environments. Multiple flat networks require corresponding bridge interfaces, and using VLANs may require manual switch and gateway configuration. All routing is handled by an upstream routing device such as a router or firewall, and said device may also be responsible for NAT as well. Any benefits are quickly outweighed by manual control and configuration processes.

Using the neutron-l3-agent allows admins and tenants to create routers that handle routing between directly-connected LAN interfaces (usually tenant networks, GRE or VLAN) and a single WAN interface (usually a FLAT or VLAN provider network). While it is possible to leverage a single bridge for this purpose (as is often the documented solution), the ability to use already-existing provider networks is my preferred solution.

####Neutron L3 Agent / Floating IPs

One of the limitations of strictly using provider networks to provide connectivity to instances is that a method to provide public connectivity directly to instances must be handled by a device outside of Neutron's control. In the previous walkthoughs, the Cisco ASA in the environment handled both 1:1 static NAT and a many-to-one PAT for outbound connectivity.

In nova-networking, the concept of a "floating ip" is best understood as a 1:1 NAT translation that could be modified on-the-fly and "float" between instances. The IP address used as the floating IP was an address in the same L2 domain as the bridge of the hypervisors (or something routed to the hypervisor.) Assuming multi_host was true, an iptables SNAT/DNAT rule was created on the hypervisor hosting the instance. If the user wanted to reassociate the floating IP with another instance, the rule was removed and reapplied on the appropriate hypervisor using the same floating IP and the newly-associated instance address. Instance IPs never changed - only NAT rules.

Neutron's implementation of floating IPs differs greatly from nova-networks, but retains many of the same concepts and functionailty. Neutron routers are created that serve as the gateway for instances and are scheduled to a node running neutron-l3-agent. Rather than manipulating iptables on the hypervisors themselves, iptables in the router namespace is modified to perform the appropriate NAT translations. The floating IPs themsevles are procured from the provider network that is providing the router with its public connectivity. This means floating IPs are limited to the same L3 network as the routers WAN IP address.

####Networking / Layout

For this installment, a Cisco ASA 5510 will once again serve as the lead gateway device. In fact, I’ll be building upon the configuration already in place from the flat and/or VLAN networking demonstration in the previous installments:

- [Simple Flat Network](http://developer.rackspace.com/blog/neutron-networking-simple-flat-network.html)
- [VLAN Provider Networks](http://developer.rackspace.com/blog/neutron-networking-vlan-provider-networks.html)

10.240.0.0/24 will continue to serve as the management network for hosts. A single VLAN network will be created to demonstrate the ability to use either a flat or VLAN network.

- VLAN 10 - MGMT - 10.240.0.0/24
- VLAN 20 – GATEWAY_NET – 10.239.0.0/22

A single interface on the servers will be used for both management and provider network connectivity.

{% img center /images/2013-11-21-neutron-networking-vlan-provider-networks/VLAN_Provider_1.5.png %}


####Networking / Configuration of Servers

If you followed the [previous installment](http://developer.rackspace.com/blog/neutron-networking-simple-flat-network.html) and successfully configured a bridge in OVS and a flat provider network, the proper server network configuration should already be in place. If you haven’t, there’s a good chance your servers have their IP configured directly on eth0. To utilize Neutron, the hosts must have a network bridge configured. This can be accomplished one of two ways:

- Utilize a single interface for both management of the hosts and the network bridge
- Utilize one interface for management of the hosts, and another for the network bridge(s)

For this example, I’ll use a single interface and move the IP address from eth0 to the bridge.

Below is what a default eth0 configuration might look like:

```
auto eth0 
 iface eth0 inet static     
  address 10.240.0.10     
  netmask 255.255.255.0     
  gateway 10.240.0.1     
  nameserver 8.8.8.8 
```
In order to configure the bridge, eth0 must be modified and the bridge interface configured:

```
auto eth0 
iface eth0 inet manual     
  up ip l s $IFACE up     
  down ip l s $IFACE down  

iface br-eth0 inet static     
  address 10.240.0.10     
  netmask 255.255.255.0     
  gateway 10.240.0.1     
  nameserver 8.8.8.8
```

TIP: Do not set br-eth0 to auto. Because of the order that processes are started at boot, the interface must be brought up using rc.local. Instead, edit the /etc/rc.local file of each machine and add the following line before the 'exit 0' statement:

```
ifup br-eth0 
```

####Networking / Open vSwitch Configuration

Creating the network bridge in Open vSwitch is a requirement for proper management of traffic. The previous installment covered this, so it may not be necessary to configure if it’s still in place.

The following will create a bridge called ‘br-eth0’ and place physical interface eth0 inside:

```
ovs-vsctl add-br br-eth0 
ovs-vsctl add-port br-eth0 eth0
```
The creation and configuration of the bridge enables the instances to communicate on the network. At a minimum, bridges must be configured on the compute and network nodes. Since we're running the network services on the controller instead of using a dedicated network node, the compute and controller nodes should have the bridge configured.

#####Changes to Environment (RPC v4)

When using RPC v4, most configuration changes are handled via Chef. A few changes must be made to the environment file to utilize the bridge for Neutron networking. **If using RPC v4.2 (Havana), all quantum references should be changed to neutron.**

```
knife environment edit grizzly
```

Look for the section 'quantum : ovs : provider_networks'

```
"quantum": {       
  "ovs": {         
    "provider_networks":
```

The bridge configuration should be modified to mirror the following example, if it doesn't already exist:

```
{    
  "label": "ph-eth0",    
  "bridge": "br-eth0",    
  "vlans": "" 
} 
```

The “vlans” value above represents a range of vlans available for the automatic provisioning of vlan segmentation IDs to networks created in Neutron. A range of IDs isn’t necessary if the intent is to always pass an ID manually with the net-create command. If you’d prefer Neutron to handle the ID assignment automatically, which includes networks created through Horizon, the “vlans” value can be modified appropriately:

```
{    
  "label": "ph-eth0",    
  "bridge": "br-eth0",    
  "vlans": "200:200,300:300" 
} 
```

In the above example, only vlans 200 and 300 are available for automatic assignment. Non-contiguous vlan ranges can be specified and separated by commas. Neutron will assign the next available ID from the list when a segmentation ID is not passed in the net-create command. 

The label ‘ph-eth0’ represents our provider interface, in this case the bridge ‘br-eth0’. It will be used during the creation of networks in Neutron.

The resulting file would look something like this:

```
{
  "name": "grizzly",
  "description": "",
  "cookbook_versions": {
  },
  "json_class": "Chef::Environment",
  "chef_type": "environment",
  "default_attributes": {
  },
  "override_attributes": {
    "nova": {
      "network": {
        "provider": "quantum"
      }
    },
    "quantum": {
      "ovs": {
	    "provider_networks": [
          {
            "label": "ph-eth0",
            "bridge": "br-eth0",
            "vlans":”200:200,300:300"
          }
	],
	"network_type": "gre"
      }
    },
    "mysql": {
      "allow_remote_root": true,
      "root_network_acl": "%"
    },
    "osops_networks": {
      "nova": "10.240.0.0/24",
      "public": "10.240.0.0/24",
      "management": "10.240.0.0/24"
    }
  }
}
```

Save the changes to the file and run chef-client on all the hosts to populate the changes.

#####Changes to Environment (Other)

When using something other than RPC v4, such as the vanilla OpenStack, configuration changes must be made to the appropriate configuration files and services restarted manually.

Within /etc/quantum/plugins/openvswitch/ovs_quantum_plugin.ini, update the following values:

```
[OVS]
tenant_network_type = gre
integration_bridge = br-int
enable_tunneling = True
tunnel_bridge = br-tun
tunnel_id_ranges = 1:1000
network_vlan_ranges = ph-eth0:200:200,ph-eth0:300:300
bridge_mappings = ph-eth0:br-eth0
```

The label ‘ph-eth0’ represents the provider bridge, in this case the bridge ‘br-eth0’. It will be used during the creation of networks in Neutron. It’s possible to have more than one provider bridge, especially when you have multiple switching infrastructures for various networks and services. Restart all Neutron and Open vSwitch services on all hosts for the changes to take effect. 

####Networking / OVS Confirmation

Remember the bridge (br-eth0) we created in OVS earlier? At a high level, it can be looked at as our bridge to the physical network infrastructure. Neutron requires an ‘Integration Bridge’ that serves as the bridge to our virtual instances. The integration bridge connects vNICs and Neutron DHCP and L3 agents with virtual networks. Overriding the default value of ‘br-int’ is not recommended, as the bridge must be named the same on each host (controller/network/compute). RPC v4 creates this bridge during the chef-client run.

```
[root@controller01 ~]# ovs-vsctl show
   Bridge "br-eth0"
        Port "eth0"
            Interface "eth0"
        Port "phy-br-eth0"
            Interface "phy-br-eth0"
        Port "br-eth0"
            Interface "br-eth0"
                type: internal
    Bridge br-int
        Port br-int
            Interface br-int
                type: internal
        Port "int-br-eth0"
            Interface "int-br-eth0"
```

For those installing from source, the name of the bridge is defined in /etc/quantum/plugins/openvswitch/ovs_quantum_plugin.ini:

```
[OVS]
integration_bridge = br-int
```

The bridge will need to be created manually in OVS if you are not using Chef:

```
ovs-vsctl add-br br-int
```

####Networking / Building a vlan provider network in Neutron

With the network devices and OVS configured, it’s time to build a vlan provider network in Neutron. Creating a vlan provider network requires at least two values: the name of the network and the provider bridge label. However, I recommend specifying the vlan segmentation ID to ensure parity with the infrastructure that was previously configured.


Syntax: 
```
quantum net-create --provider:physical_network=<provider label> --provider:network_type=vlan –provider:segmentation_id=<vlan id> <network name>
```

```
root@controller01:~# quantum net-create --provider:physical_network=ph-eth0 --provider:network_type=vlan --provider:segmentation_id=200 --shared INSIDE_NET

Created a new network:
+---------------------------+--------------------------------------+
| Field                     | Value                                |
+---------------------------+--------------------------------------+
| admin_state_up            | True                                 |
| id                        | ce316486-9c19-4c37-983b-e058cdcbd7fb |
| name                      | INSIDE_VLAN                          |
| provider:network_type     | vlan                                 |
| provider:physical_network | ph-eth0                              |
| provider:segmentation_id  | 200                                  |
| router:external           | False                                |
| shared                    | True                                 |
| status                    | ACTIVE                               |
| subnets                   |                                      |
| tenant_id                 | 30037ac916824dc1882d930407ab7e33     |
+---------------------------+--------------------------------------+


root@controller01:~# quantum net-create --provider:physical_network=ph-eth0 --provider:network_type=vlan --provider:segmentation_id=300 --shared DMZ_NET


Created a new network:
+---------------------------+--------------------------------------+
| Field                     | Value                                |
+---------------------------+--------------------------------------+
| admin_state_up            | True                                 |
| id                        | cc1c6a8d-7023-40a3-b1a7-5bbf1c2e0702 |
| name                      | DMZ_VLAN                             |
| provider:network_type     | vlan                                 |
| provider:physical_network | ph-eth0                              |
| provider:segmentation_id  | 300                                  |
| router:external           | False                                |
| shared                    | True                                 |
| status                    | ACTIVE                               |
| subnets                   |                                      |
| tenant_id                 | 30037ac916824dc1882d930407ab7e33     |
+---------------------------+--------------------------------------+
```

With the two networks created, it’s time to create the subnets. 


Syntax: 
```
quantum subnet-create <network_name> <subnet>  --name <subnet_name> --no-gateway --host-route destination=<dest_network>,nexthop=<nexthop_ip> --allocation-pool start=<dhcp_start_ip>,end=<dhcp_end_ip> --dns-nameservers list=true <dns_1> <dns_2>
```


It’s a good idea to provide values for the following options:

```
--no-gateway		Instructs Quantum not to provide a gateway IP.
--host-route		Provides route injection via DHCP. 
--allocation-pool		Defines the DHCP IP pool boundaries
--dns-nameservers		Defines DNS servers
```

_When a gateway is defined, Neutron assumes all metadata routes are handled by the specified gateway and will not inject the metadata route via DHCP to instances. By specifying the ```--no_gateway``` flag and defining a default route manually, we’re able to provide instances with a default route as well as an automatic metadata route to the namespace IP._

```
root@controller01:~# quantum subnet-create INSIDE_NET 192.168.100.0/24 --name INSIDE_SUBNET --no-gateway --host-route destination=0.0.0.0/0,nexthop=192.168.100.1 --allocation-pool start=192.168.100.100,end=192.168.100.199 --dns-nameservers list=true 8.8.8.7 8.8.8.8


Created a new subnet:
+------------------+----------------------------------------------------------+
| Field            | Value                                                    |
+------------------+----------------------------------------------------------+
| allocation_pools | {"start": "192.168.100.100", "end": "192.168.100.199"}   |
| cidr             | 192.168.100.0/24                                         |
| dns_nameservers  | 8.8.8.7                                                  |
|                  | 8.8.8.8                                                  |
| enable_dhcp      | True                                                     |
| gateway_ip       |                                                          |
| host_routes      | {"destination": "0.0.0.0/0", "nexthop": "192.168.100.1"} |
| id               | 059ef6be-59f4-4798-a183-6c40b13f63f3                     |
| ip_version       | 4                                                        |
| name             | INSIDE_SUBNET                                            |
| network_id       | ce316486-9c19-4c37-983b-e058cdcbd7fb                     |
| tenant_id        | 30037ac916824dc1882d930407ab7e33                         |
+------------------+----------------------------------------------------------+


root@controller01:~# quantum subnet-create DMZ_NET 172.16.0.0/24 --name DMZ_SUBNET --no-gateway --host-route destination=0.0.0.0/0,nexthop=172.16.0.1 
--allocation-pool start=172.16.0.100,end=172.16.0.199 --dns-nameservers list=true 8.8.8.7 8.8.8.8


Created a new subnet:
+------------------+-------------------------------------------------------+
| Field            | Value                                                 |
+------------------+-------------------------------------------------------+
| allocation_pools | {"start": "172.16.0.100", "end": "172.16.0.199"}      |
| cidr             | 172.16.0.0/24                                         |
| dns_nameservers  | 8.8.8.7                                               |
|                  | 8.8.8.8                                               |
| enable_dhcp      | True                                                  |
| gateway_ip       |                                                       |
| host_routes      | {"destination": "0.0.0.0/0", "nexthop": "172.16.0.1"} |
| id               | 7ecedb05-70eb-4c32-98c0-bdb01b165db3                  |
| ip_version       | 4                                                     |
| name             | DMZ_SUBNET                                            |
| network_id       | cc1c6a8d-7023-40a3-b1a7-5bbf1c2e0702                  |
| tenant_id        | 30037ac916824dc1882d930407ab7e33                      |
+------------------+-------------------------------------------------------+

```

####Networking / Testing Connectivity

Now that the networks have been built in Neutron, it’s time to test connectivity by spinning up some instances. Like the hosts, my instances are running [Ubuntu 12.04 LTS](http://cloud-images.ubuntu.com/precise/current/).

```
root@controller01:~# nova boot --flavor=m1.small --key_name=controller-id_rsa --image=3ee2e7d5-9d7a-4650-8f76-f8ad58a8c464 --nic net-id=ce316486-9c19-4c37-983b-e058cdcbd7fb INSIDE_INSTANCE


+-------------------------------------+--------------------------------------+
| Property                            | Value                                |
+-------------------------------------+--------------------------------------+
| status                              | BUILD                                |
| updated                             | 2013-11-19T14:27:38Z                 |
| OS-EXT-STS:task_state               | scheduling                           |
| OS-EXT-SRV-ATTR:host                | None                                 |
| key_name                            | controller-id_rsa                    |
| image                               | Ubuntu 12.04.1 Precise (cloudimg)    |
| hostId                              |                                      |
| OS-EXT-STS:vm_state                 | building                             |
| OS-EXT-SRV-ATTR:instance_name       | instance-0000011b                    |
| OS-EXT-SRV-ATTR:hypervisor_hostname | None                                 |
| flavor                              | m1.small                             |
| id                                  | 47b58f4c-6a0b-4e4c-b33d-6468acd275a8 |
| security_groups                     | [{u'name': u'default'}]              |
| user_id                             | 5b585fbd6d1747f89b4bff8995b9c441     |
| name                                | INSIDE_INSTANCE                      |
| adminPass                           | r2nXR8BqVspu                         |
| tenant_id                           | 30037ac916824dc1882d930407ab7e33     |
| created                             | 2013-11-19T14:27:38Z                 |
| OS-DCF:diskConfig                   | MANUAL                               |
| metadata                            | {}                                   |
| accessIPv4                          |                                      |
| accessIPv6                          |                                      |
| progress                            | 0                                    |
| OS-EXT-STS:power_state              | 0                                    |
| OS-EXT-AZ:availability_zone         | nova                                 |
| config_drive                        |                                      |
+-------------------------------------+--------------------------------------+

root@controller01:~# nova show INSIDE_INSTANCE


+-------------------------------------+---------------------------------------------+
| Property                            | Value                                       |
+-------------------------------------+---------------------------------------------+
| status                              | ACTIVE                                      |
| updated                             | 2013-11-19T14:27:44Z                        |
| OS-EXT-STS:task_state               | None                                        |
| OS-EXT-SRV-ATTR:host                | compute02                                   |
| key_name                            | controller-id_rsa                           |
| image                               | Ubuntu 12.04.1 Precise (cloudimg) (3ee2e7d5-|
| hostId                              | 496e6f036d3d0648f6cc32568196137e18e2d60f5393|
| INSIDE_NET network                  | 192.168.100.102                             |
| OS-EXT-STS:vm_state                 | active                                      |
| OS-EXT-SRV-ATTR:instance_name       | instance-0000011b                           |
| OS-EXT-SRV-ATTR:hypervisor_hostname | compute02.grizzly2.openstacksupport.com     |
| flavor                              | m1.small (2)                                |
| id                                  | 47b58f4c-6a0b-4e4c-b33d-6468acd275a8        |
| security_groups                     | [{u'name': u'default'}]                     |
| user_id                             | 5b585fbd6d1747f89b4bff8995b9c441            |
| name                                | INSIDE_INSTANCE                             |
| created                             | 2013-11-19T14:27:38Z                        |
| tenant_id                           | 30037ac916824dc1882d930407ab7e33            |
| OS-DCF:diskConfig                   | MANUAL                                      |
| metadata                            | {}                                          |
| accessIPv4                          |                                             |
| accessIPv6                          |                                             |
| progress                            | 0                                           |
| OS-EXT-STS:power_state              | 1                                           |
| OS-EXT-AZ:availability_zone         | nova                                        |
| config_drive                        |                                             |
+-------------------------------------+---------------------------------------------+
root@controller01:~# nova boot --flavor=m1.small --key_name=controller-id_rsa --image=3ee2e7d5-9d7a-4650-8f76-f8ad58a8c464 --nic net-id=cc1c6a8d-7023-40a3-b1a7-5bbf1c2e0702 DMZ_INSTANCE


+-------------------------------------+--------------------------------------+
| Property                            | Value                                |
+-------------------------------------+--------------------------------------+
| status                              | BUILD                                |
| updated                             | 2013-11-19T14:28:12Z                 |
| OS-EXT-STS:task_state               | scheduling                           |
| OS-EXT-SRV-ATTR:host                | None                                 |
| key_name                            | controller-id_rsa                    |
| image                               | Ubuntu 12.04.1 Precise (cloudimg)    |
| hostId                              |                                      |
| OS-EXT-STS:vm_state                 | building                             |
| OS-EXT-SRV-ATTR:instance_name       | instance-0000011d                    |
| OS-EXT-SRV-ATTR:hypervisor_hostname | None                                 |
| flavor                              | m1.small                             |
| id                                  | fb024367-d1c9-4570-8ad5-b8eb9915b569 |
| security_groups                     | [{u'name': u'default'}]              |
| user_id                             | 5b585fbd6d1747f89b4bff8995b9c441     |
| name                                | DMZ_INSTANCE                         |
| adminPass                           | XR98khnD2NpA                         |
| tenant_id                           | 30037ac916824dc1882d930407ab7e33     |
| created                             | 2013-11-19T14:28:12Z                 |
| OS-DCF:diskConfig                   | MANUAL                               |
| metadata                            | {}                                   |
| accessIPv4                          |                                      |
| accessIPv6                          |                                      |
| progress                            | 0                                    |
| OS-EXT-STS:power_state              | 0                                    |
| OS-EXT-AZ:availability_zone         | nova                                 |
| config_drive                        |                                      |
+-------------------------------------+--------------------------------------+


root@controller01:~# nova show DMZ_INSTANCE


+-------------------------------------+---------------------------------------------+
| Property                            | Value                                       |
+-------------------------------------+---------------------------------------------+
| status                              | ACTIVE                                      |
| updated                             | 2013-11-19T14:28:18Z                        |
| OS-EXT-STS:task_state               | None                                        |
| OS-EXT-SRV-ATTR:host                | compute02                                   |
| key_name                            | controller-id_rsa                           |
| image                               | Ubuntu 12.04.1 Precise (cloudimg) (3ee2e7d5-|
| hostId                              | 496e6f036d3d0648f6cc32568196137e18e2d60f5393|
| OS-EXT-STS:vm_state                 | active                                      |
| OS-EXT-SRV-ATTR:instance_name       | instance-0000011d                           |
| OS-EXT-SRV-ATTR:hypervisor_hostname | compute02.grizzly2.openstacksupport.com     |
| flavor                              | m1.small (2)                                |
| id                                  | fb024367-d1c9-4570-8ad5-b8eb9915b569        |
| security_groups                     | [{u'name': u'default'}]                     |
| user_id                             | 5b585fbd6d1747f89b4bff8995b9c441            |
| name                                | DMZ_INSTANCE                                |
| created                             | 2013-11-19T14:28:12Z                        |
| tenant_id                           | 30037ac916824dc1882d930407ab7e33            |
| OS-DCF:diskConfig                   | MANUAL                                      |
| metadata                            | {}                                          |
| accessIPv4                          |                                             |
| accessIPv6                          |                                             |
| DMZ_NET network                     | 172.16.0.102                                |
| progress                            | 0                                           |
| OS-EXT-STS:power_state              | 1                                           |
| OS-EXT-AZ:availability_zone         | nova                                        |
| config_drive                        |                                             |
+-------------------------------------+---------------------------------------------+
```

Check the Nova console logs to verify the instances received their IPs, routes and metadata. Success here indicates the instances are able to communicate with the network namespace residing on the network or controller nodes.

```
root@controller01:~# nova console-log INSIDE_INSTANCE
…
ci-info: lo    : 1 127.0.0.1       255.0.0.0       .
ci-info: eth0  : 1 192.168.100.102 255.255.255.0   fa:16:3e:6d:48:57
ci-info: route-0: 0.0.0.0         192.168.100.1   0.0.0.0         eth0   UG
ci-info: route-1: 169.254.169.254 192.168.100.101 255.255.255.255 eth0   UGH
ci-info: route-2: 192.168.100.0   0.0.0.0         255.255.255.0   eth0   U
cloud-init start running: Tue, 19 Nov 2013 14:28:09 +0000. up 4.71 seconds
…
Generating public/private rsa key pair.
Your identification has been saved in /etc/ssh/ssh_host_rsa_key.
Your public key has been saved in /etc/ssh/ssh_host_rsa_key.pub.
…

root@controller01:~# nova console-log DMZ_INSTANCE
…
ci-info: lo    : 1 127.0.0.1       255.0.0.0       .
ci-info: eth0  : 1 172.16.0.102    255.255.255.0   fa:16:3e:bc:95:bb
ci-info: route-0: 0.0.0.0         172.16.0.1      0.0.0.0         eth0   UG
ci-info: route-1: 169.254.169.254 172.16.0.101    255.255.255.255 eth0   UGH
ci-info: route-2: 172.16.0.0      0.0.0.0         255.255.255.0   eth0   U
…
Generating public/private rsa key pair.
Your identification has been saved in /etc/ssh/ssh_host_rsa_key.
Your public key has been saved in /etc/ssh/ssh_host_rsa_key.pub.
…
```

The ability to connect to the instances from the controller confirms that proper vlan tagging is taking place:

```
root@controller01:~# ssh -i .ssh/id_rsa ubuntu@172.16.0.102
The authenticity of host '172.16.0.102 (172.16.0.102)' can't be established.
ECDSA key fingerprint is 83:53:ce:06:11:7e:cb:0b:2c:0a:cf:4c:c9:a8:0b:8c.
Are you sure you want to continue connecting (yes/no)? yes
Warning: Permanently added '172.16.0.102' (ECDSA) to the list of known hosts.
Welcome to Ubuntu 12.04.2 LTS (GNU/Linux 3.2.0-49-virtual x86_64)
…
ubuntu@dmz-instance:~$

root@controller01:~# ssh -i .ssh/id_rsa ubuntu@192.168.100.102
The authenticity of host '192.168.100.102 (192.168.100.102)' can't be established.
ECDSA key fingerprint is 5f:ef:d2:16:02:c9:4d:a5:4f:5b:f8:65:d0:fb:17:1b.
Are you sure you want to continue connecting (yes/no)? yes
Warning: Permanently added '192.168.100.102' (ECDSA) to the list of known hosts.
Welcome to Ubuntu 12.04.2 LTS (GNU/Linux 3.2.0-49-virtual x86_64)
…
ubuntu@inside-instance:~$
```

Because the Cisco ASA is the gateway device, all NAT translations should be configured there to provide external connectivity to/from these instances. Neutron floating IPs cannot be used in this example as they require the use of a Neutron router. 

####Summary

With a limited amount of networking hardware one can create a functional private cloud based on [Rackspace Private Cloud](http://www.rackspace.com/cloud/private/) powered by [OpenStack](http://www.openstack.org). While the use of vlan provider networks allows for more flexibility over a ‘flat’ design, it still requires interaction with hardware routers and switches for every network and subnet that gets created. In the case where the use of the L3 agent isn’t possible or necessary, vlan-based configurations can still provide users with a secure and scalable cloud experience.


_Have questions or comments? Feel free to contact or follow me on Twitter [@jimmdenton](https://twitter.com/jimmdenton)_
