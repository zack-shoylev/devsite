---
layout: post
title: "Understanding the Chef Environment File in Rackspace Private Cloud"
date: 2013-12-10 11:01
comments: true
author: James Thorne
published: true
categories:
 - chef
 - devops
 - private cloud
 - OpenStack
---

Rackspace Private Cloud uses Chef to deploy an OpenStack environment. Chef
provides the ability to quickly configure and deploy an OpenStack environment
on one to many nodes. An integral part of deployment is the Chef Environment
file. This file can be difficult to understand as a newcomer to Chef.

In the following post, I am going to break down each part of two typical Chef
Environment files specific to Rackspace Private Cloud v4.1.x powered by
OpenStack Grizzly.

<!-- more -->

Typical Chef Environments
-------------------------

Below are two typical Chef Environment files to install Rackspace Private
Cloud v4.1.x with nova-network or Quantum Networking.

Each Chef Environment file will differ slightly depending on which OpenStack
Networking model you chose. Each of the following Chef Environment files
represent an OpenStack environment with a single controller node and single
compute node where the controller and compute nodes each have two NICs (eth0
and eth1). eth0 on each node will be assigned an IP address in the
192.168.236.0/24 subnet and eth1 will be active but will be un-configured;
Chef will configure it during the chef-client run.

#### Rackspace Private Cloud v4.1.x using nova-network Chef Environment File:

    {
        "name": "rpc-grizzly",
        "description": "Rackspace Private Cloud",
        "cookbook_versions": {},
        "json_class": "Chef::Environment",
        "chef_type": "environment",
        "default_attributes": {},
        "override_attributes": {
            "nova": {
                "network": {
                    "provider": "nova",
                    "public_interface": "br-eth1"
                },
                "networks": {
                    "public": {
                        "label": "public",
                        "bridge_dev": "eth1",
                        "bridge": "br-eth1",
                        "ipv4_cidr": "192.168.100.0/24",
                        "dns1": "8.8.4.4",
                        "dns2": "8.8.8.8"
                    }
                }
            },
            "mysql": {
                "allow_remote_root": true,
                "root_network_acl": "%"
            },
            "osops_networks": {
                "nova": "192.168.236.0/24",
                "public": "192.168.236.0/24",
                "management": "192.168.236.0/24"
            }
        }
    }

#### Rackspace Private Cloud v4.1.x using Quantum Networking Chef Environment File:

    {
        "name": "rpc-grizzly",
        "description": "Rackspace Private Cloud",
        "cookbook_versions": {},
        "json_class": "Chef::Environment",
        "chef_type": "environment",
        "default_attributes": {},
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
                            "label": "ph-eth1",
                            "bridge": "br-eth1"
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
                "nova": "192.168.236.0/24",
                "public": "192.168.236.0/24",
                "management": "192.168.236.0/24"
            }
        }
    }

#### Default Chef Environment File:


    {
        "name": "rpc-grizzly",
        "description": "Rackspace Private Cloud",
        "cookbook_versions": {},
        "json_class": "Chef::Environment",
        "chef_type": "environment",
        "default_attributes": {},
        "override_attributes": {}
    }

Above is a new Chef Environment file. There isn't much going on here.

When using Rackspace Private Cloud, the main part of the Chef Environment
file exists within the __override_attributes__ JSON block. Inside the
__override_attributes__ JSON block is where you will override the default
attributes in the Chef Cookbooks to match your environment. So, let's break
it all down.

The nova JSON Block
-------------------

Below are two different nova JSON blocks, one for nova-network and one for
Quantum Networking. One or the other will be used depending on which
OpenStack Networking model you want to use.

#### Using nova-network

    "nova": {
        "network": {
            "provider": "nova",
            "public_interface": "br-eth1"
        },
        "networks": {
            "public": {
                "label": "public",
                "bridge_dev": "eth1",
                "bridge": "br-eth1",
                "ipv4_cidr": "192.168.100.0/24",
                "dns1": "8.8.4.4",
                "dns2": "8.8.8.8"
            }
        }
    },

Above is the nova JSON block if you are using nova-network.

In our example, there are two JSON blocks within the nova JSON block:
__network__ and __networks__.

Inside the network JSON block are two parameters: __provider__ and
__public_interface__.

The __provider__ parameter specifies what OpenStack Networking model to use.
In this case __nova-network__ will be used instead of Quantum Networking.
The __public_interface__ parameter specifies what network interface on the
compute nodes nova-network floating IP addresses will be assigned to. This
parameter can be found in the __/etc/nova/nova.conf__ file on the controller
and compute nodes.

Inside the __networks__ JSON block is another JSON block called __public__.
The __networks__ JSON block will accept two JSON blocks: a JSON block labeled
__public__, as shown above, and an optional JSON block labeled __private__.
The __public__ and __private__ JSON blocks are labeled this way because the
__public__ JSON block is meant to setup a nova-network that allows outbound
network access from the instances and the __private__ JSON block is meant to
setup a nova-network that only allows instance-to-instance communication.
Now, __public__ and __private__ are just labels, you could setup a private
network in the __public__ JSON block or a public network in the __private__
JSON block. However, adhering to the intended convention will make everything
easier to understand. A more appropriate name for the __public__ label would
be __fixed__ because an instance will always be assigned, or __"fixed"__, an
IP address from this nova-network. In addition, the __public__ label is
commonly confused with the public label in the __osops_networks__ JSON block,
, which you will read about later, and has no relation to it.

When the chef-client command is run on the compute node, it will use the
parameters in the __public__ JSON block, and the __private__ JSON block if
you set it up, to create a nova-network using the __nova-manage network create__
command. A bridge interface named __br-eth1__ will be created and the physical
network interface, __eth1__, will be attached to it. In addition, a dnsmasq
process will be spawned serving IP addresses in the __192.168.100.0/24__
subnet from __192.168.168.100.2 - 192.168.100.254__; __192.168.100.1__ is
skipped because this is usually the gateway IP address for the network
terminated elsewhere on a router or firewall. OpenStack instances will have
their virtual network interfaces attached to the __br-eth1__ bridge interface
so they can communicate on the __192.168.100.0/24__ network.

#### Using Quantum

    "nova": {
        "network": {
            "provider": "quantum"
        }
    },

Above is the nova JSON block if you are using Quantum Networking.

In our example, there is one JSON block within the nova JSON block: __network__.

Inside the network JSON block is one parameter: __provider__.

The __provider__ parameter specifies what OpenStack Networking mode to use.
In this case __quantum__ will be used instead of nova-network. By specifying
__quantum__ as the OpenStack Networking model, Chef knows to install the
necessary additional components such as __quantum-server__.

Be aware that when using Quantum Networking, there are additional steps
required after running __chef-client__ on each node.

The quantum JSON Block
----------------------

    "quantum": {
        "ovs": {
            "provider_networks": [
                {
                    "label": "ph-eth1",
                    "bridge": "br-eth1"
                }
            ],
            "network_type": "gre"
        }
    },

Above is the quantum JSON block. This would only be in the Chef Environment
file if you are using Quantum Networking.

In our example, there is one JSON block within the quantum JSON block: __ovs__.

Inside of the ovs JSON block are two parameters: __provider_networks__ and
__network_type__.

The __provider_networks__ parameter has two variables: __label__ and __bridge__.
The __label__ parameter is just that, a label for the subsequent __bridge__ 
parameter that indicates the particular bridge interface where Quantum Provider
Networks can be created from. In our example, __br-eth1__ is a bridge interface
for the physical network interface __eth1__. eth1 could be configured as a trunk
port on the managed network switch it is connected to. Quantum Provider Networks
could then be created from the VLANs within that trunk. These parameters are found
in the __/etc/quantum/plugins/openvswitch/ovs_quantum_plugin.ini__ file on the 
controller and compute nodes.

The __network_type__ parameter sets the default type of Quantum Tenant Network
created when it is not specified in the __quantum net-create__ command. The
different types of Quantum Tenant Networks you can create are __gre__ and __vlan__.
Both GRE and VLAN based Quantum Tenant Networks can be created and used at the same
time. This parameter is found in the 
__/etc/quantum/plugins/openvswitch/ovs_quantum_plugin.ini__ file on the controller 
and compute nodes.

The mysql JSON Block
--------------------

    "mysql": {
      "allow_remote_root": true,
      "root_network_acl": "%"
    },

Above is the mysql JSON block.

In our example, the mysql JSON block has two parameters:
__allow_remote_root__ and __root_network_acl__.

The __allow_remote_root__ parameter set to __true__ allows remote root
connections to the MySQL service.

The __root_network_acl__ defines the network where the root user can login
from. With this set to __%__, which is a wild card in MySQL, the root user of
the MySQL service can be logged into from any host.

The osops_networks JSON Block
-----------------------------

            "osops_networks": {
                "nova": "192.168.236.0/24",
                "public": "192.168.236.0/24",
                "management": "192.168.236.0/24"
            }
        }
    }

Above is the osops_networks JSON block.

Inside this block are three labels: __nova__, __public__, and __management__.

There are additional labels that can be specified but these are the
minimum needed.

Each label maps to certain OpenStack services and each label is expecting a
subnet, not a specific IP address. When __chef-client__ is run on a node, the
Chef Cookbooks will search for a network interface assigned an IP address
within the specified subnet. That IP address is then used as the listening
address for each OpenStack service mapped to that osops_network label.

In our example, assume eth0 on the controller node is assigned IP address
192.168.236.10 and eth0 on the compute node is assigned IP address
192.168.236.11. When __chef-client__ is run on a node, the Chef Cookbooks
will search for a network interface on the controller and compute nodes
assigned an IP address within the 192.168.236.0/24 subnet; in our case it is
eth0. The IP address of eth0 is then used as the listening address for each
OpenStack service mapped to that osops_network label.

Below is a rough list of what services map to which label:

__rabbitmq-server, rsyslog, and ntpd__ listen on all interfaces and do not map to
any label.

__nova__

The following services were found by running the following command on the Chef
Server (the command assumes the Chef Cookbooks are in root's home directory):

    grep -r '\["network"\] = "nova"' /root/chef-cookbooks

* keystone-admin-api
* nova-xvpvnc-proxy
* nova-novnc-proxy
* nova-novnc-server

__public__

The following services were found by running the following command on the Chef
Server (the command assumes the Chef Cookbooks are in root's home directory):

    grep -r '\["network"\] = "public"' /root/chef-cookbooks

* graphite-api
* keystone-service-api
* glance-api
* glance-registry
* nova-api
* nova-ec2-admin
* nova-ec2-public
* nova-volume
* quantum-api
* cinder-api
* ceilometer-api
* horizon-dash
* horizon-dash_ssl

__management__

The following services were found by running the following command on the Chef
Server (the command assumes the Chef Cookbooks are in root's home directory):

    grep -r '\["network"\] = "management"' /root/chef-cookbooks

* graphite-statsd
* graphite-carbon-line-receiver
* graphite-carbon-pickle-receiver
* graphite-carbon-cache-query
* memcached
* collectd
* mysql
* keystone-internal-api
* glance-admin-api
* glance-internal-api
* nova-internal-api
* nova-admin-api
* cinder-internal-api
* cinder-admin-api
* cinder-volume
* ceilometer-internal-api
* ceilometer-admin-api
* ceilometer-central

Diving Deeper
-------------

I have gone through two typical Chef Environment files that can be used to
install Rackspace Private Cloud v4.1.x powered by OpenStack Grizzly with
nova-network or Quantum Networking.

If you want to dive deeper, there are many other override attributes that can
be set in the Chef Environment file. You can see all the different attributes
that can be overridden by logging into your Chef Server (I am assuming the
Rackspace Private Cloud Chef Cookbooks are downloaded there), changing into
the __chef-cookbooks__ directory, changing into the particular Chef Cookbook
directory you want to change the default attributes of, changing into the
__attributes__ directory, and finally opening the __default.rb__ file.

For questions, I encourage you to visit the [Rackspace Private Cloud Community Forums](https://community.rackspace.com/products/f/45).

For comments, feel free to get in touch with me [@jameswthorne](https://twitter.com/jameswthorne).