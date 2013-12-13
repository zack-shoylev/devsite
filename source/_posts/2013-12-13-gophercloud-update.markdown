---
layout: post
title: "Gophercloud Update"
date: 2013-12-13 13:00
comments: true
author: Samuel A. Falvo II
published: true
categories:
 - gophercloud
---

I'm happy to report that Gophercloud has received some contributor interest recently.
In particular, Gophercloud now supports Rackspace API Keys for authentication.
The publicly-visible interface for using API keys follows the conventions set previously by the `AuthOptions` structure,
which means the *interface* should work with any provider that supports API keys.
In terms of *implementation*, it only works with Rackspace for now.
We welcome contributions, even if only as a feature-request, from others who'd like to see this work with other providers.

I also received several contributions for its Cloud Files support over the past several days.
While the Cloud Files API remains in flux, for it's still very new, we broke ground and we're hammering the details out now.
We won't merge to master until we have an API we're happy with;
however, folks interested in exercising the new API can do so by changing to the appropriate topic branch(es).
Interested in helping out?  Join us today and leave your mark!

We also expect to see [TravisCI](https://travis-ci.org) integration with Gophercloud soon,
so we'll have a readily accessible build status both on [our project](http://gophercloud.io) and on [our Github](https://github.com/rackspace/gophercloud) pages.

As usual, if anyone wishes to contribute to the project, we'd love to see you on our [developers group](https://groups.google.com/forum/#!forum/gophercloud-dev).
For those who have already contributed, I thank you deeply!

