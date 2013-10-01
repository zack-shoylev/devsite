---
layout: post
title: "My Head In the Clouds with Gophercloud and Cloud Files"
date: 2013-10-01 12:00
comments: true
author: Samuel A. Falvo II
published: false
categories: 
- OpenStack
- Gophercloud
- Cloud
- Files
---

What happened to Cloud Files support, you ask?
And when will Gophercloud finally become multi-vendor?
Sorry.  It's my fault.
I bit off more than I could chew.

<!-- more -->

First, let me cover my tardiness with Cloud Files support.
Working for any company, you're often pulled in a plurality of directions at once.
Some projects take priority over others, and even their relative priorities shift over time.
Such was the case with Gophercloud:
I've not been readily available to work on Gophercloud due to changing priorities with other projects I'm involved with.
While this doesn't pull me off of Gophercloud full-time,
it does severely cut into the time I can spend working on it.

Meanwhile, whenever I was able to sit down and work on Gophercloud,
I spent the time studying OpenStack, Microsoft, Amazon, and Google cloud-files-like services,
looking for any commonality between them that I could capitalize on when defining the Gophercloud cloud files API.
Support for OpenStack cloud files comes relatively easy.
Laying the plans to support the equivalent services from Amazon, Microsoft's Azure, and Google's AppEngine all using the same interfaces, however,
proved substantially more daunting than I anticipated.
It's not that each of these services particular APIs were all that hard to use.
Indeed, each of these services offers, superficially, the same class of service.
Their respective details differ, however; and, we all know that's where the devil lives.

To restore the parity of feet and terra firma,
and actually ship code instead of daydream,
I decided to punt on supporting everything from everyone,
and just focus once again on OpenStack.
It's what I know, and,
based on exchanges on the development mailing list and in Github tickets,
it's what those actually using Gophercloud seem to expect the most.

When, however, will the multi-vendor support become a reality?
On the one hand, I want to better support Gophercloud's current users by delivering more value to them.
Forget the other providers; they can always submit patches to Gophercloud themselves, right?
Just focus on the needs of Gophercloud's current userbase; deliver maximum value in the shortest possible time!
What could be better?
On the other hand, I feel, but cannot prove,
that I lack a wider user-base *precisely because* I haven't addressed support for their preferred platform provider yet.

I'm convinced the former view qualifies as selection bias.
Further, I feel mechanistically translating OpenStack APIs into Gophercloud APIs can,
in its own way, become rather boring.
Once I define the precedent for an API's design,
filling in the rest of the missing functionality involves a handful of lines of code for each end-point.
Indeed, macros could help trivially implement many of the compute-related functions,
if Go supported macros.
No, the real excitement lies with making Gophercloud multi-vendor capable,
for in there lies the more interesting problems to solve.

Unless I receive overwhelming support for the contrary view,
and can make convincing arguments to support your position,
I think the time has come that I should invest effort in widening support for multiple vendors.
(After I complete cloud files support first, of course.)
After all, this has always been part of Gophercloud's promise from day one,
and I'd feel disingenuous for going too long without addressing this feature.
Besides, having existing infrastructure for more platforms might provide the avenue by which additional contributions,
especially for non-OpenStack platforms, come.
"Build it and they will come," it turns out, is not always true.
Sometimes, folks just want a paved road to the construction site.

