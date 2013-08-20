---
layout: post
title: "Slumlord Hosting with Docker"
date: 2013-08-19 13:17
comments: true
author: Hart Hoover
published: false
categories: 
- Docker
---
{% img right /images/2013-08-19-slumlord-hosting/diskman.GIF 150 %}
Since becoming a Racker back in 2007, one of my all time favorite websites has been [slumlordhosting.com][1]. Slumlord Hosting is a parody of really bad shared hosting environments, advertising some amazing features:

* Dedicated space on a "High Density Floppy Storage Area Network Device"
* A duel (sic) channel ISDN line for maximum bandwidth
* 10MB of dedicated space

On top of the features listed above, the website itself is glorious. Looking at it recently, I began to think to myself, "If I were running a business like this, what could I use to squeeze every possible resource out of a server and offer it up for shared hosting?" Enter [Cloud Servers][2] and [Docker][3]. My strategy is simple: build a Cloud Server, install Docker, and then create as many containers as possible. I've decided to use WordPress containers since WordPress is extrememly popular.<!--More-->

##What is Docker?

Docker is a very, VERY popular open source project. Since the project was open sourced only a few months ago, Docker has over 4800 stars, 490 forks, and over 300 watchers on GitHub. There are over 100 contributors. So what does Docker do? From the Docker website:

>Docker is an open-source engine that automates the deployment of any application as a lightweight, portable, self-sufficient container that will run virtually anywhere.

> Docker containers can encapsulate any payload, and will run consistently on and between virtually any server. The same container that a developer builds and tests on a laptop will run at scale, in production, on VMs, bare-metal servers, OpenStack clusters, public instances, or combinations of the above.

Now that we know what Docker is, let's look at how to implement it for our purposes as a hosting slumlord. 

##Installing Docker

To install Docker, I will need a Rackspace Cloud Server. I'm starting with Ubuntu 13.04 and my SSH key for easy login:

```
nova boot --image 1bbc5e56-ca2c-40a5-94b8-aa44822c3947 --flavor 2 --key-name mykey slumdock
```

Notice I am also using the smallest server available: 512M of RAM. This is way too much by slumlord standards, but at least I can have more containers. When the server is up, install Docker:

```
sudo apt-get update
sudo apt-get install linux-image-extra-`uname -r`
sudo apt-get install software-properties-common

# add the sources to your apt
sudo add-apt-repository ppa:dotcloud/lxc-docker

# update
sudo apt-get update

# install
sudo apt-get install lxc-docker

# You will also need git for later
sudo apt-get install git
```

If you want to know more about what you just did, take a look at the [Docker documentation][4]. Now that Docker is installed, I need to create a WordPress Docker container.

##Creating a WordPress Container

For this I'm using a project on GitHub called "[docker-wordpress-nginx][5]" written by Eugene Ware and John Fink. To create a WordPress container for my use, I 


[1]: http://slumlordhosting.com
[2]: http://www.rackspace.com/cloud/servers/
[3]: http://docker.io
[4]: http://docs.docker.io/en/latest/installation/ubuntulinux/#ubuntu-raring
[5]: https://github.com/eugeneware/docker-wordpress-nginx
