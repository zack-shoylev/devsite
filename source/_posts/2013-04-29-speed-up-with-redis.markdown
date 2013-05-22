---
layout: post
title: "Improving your site speed with Redis"
date: 2013-04-29 8:00
comments: true
author: Hart Hoover
published: true
categories: 
- Redis
- RedisToGo
---
{% img right /images/2013-04-29-speed-up-with-redis/redis_logo.png 200 200 %}
Adding Redis to your application stack is a fantastic way to gain speed with existing applications. Many of our customers aren't running the latest and greatest new hotness NoSQL-using cloud thing. A lot of them port over a full stack of an existing applications that once only existed on bare metal servers, or use a hybrid environment with a big MySQL configuration on bare metal with web/app servers in the cloud.

In any case, we advise that customers use caching... EVERYWHERE. Adding Redis to your application stack can greatly improve site speeds when used as a cache.<!--More-->

##What's Redis?

From the "[Introduction to Redis](http://redis.io/topics/introduction)" page at [redis.io](http://redis.io):

> Redis is an open source, BSD licensed, advanced key-value store. It is often referred to as a data structure server since keys can contain strings, hashes, lists, sets and sorted sets. You can run atomic operations on these types, like appending to a string; incrementing the value in a hash; pushing to a list; computing set intersection, union and difference; or getting the member with highest ranking in a sorted set.

Want to try Redis? Check out [http://try.redis.io/](http://try.redis.io/)

##Why Redis?

There is a [ton](http://www.quora.com/Redis-vs-Memcached-which-one-should-I-use-for-a-web-based-application) of [debate](http://stackoverflow.com/questions/2873249/is-memcached-a-dinosaur-in-comparison-to-redis) out there on whether to use Redis or Memcached as a cache. Both are great, but Redis provides a few features over Memcached:

* Persistence: if you restart the memcached service, you have to warm up your cache again.
* Key/Value vs. Objects: Redis is more advanced in what it can store
* Selective deletion of cached items

##How do I set this up?

You can [install Redis](http://redis.io/download) on a Cloud Server if you like, but I recommend setting up a Redis instance at [RedisToGo](http://redistogo.com/). The instances are configured with Redis already, and RedisToGo makes Redis easy to scale. Other features of RedisToGo:

* Graphs of connections and memory use
* Monitoring notifications on memory use and connection limits
* 1-click upgrades to scale
* 1-click multi-zone redundancy.
* Hourly backups
* Paid plans persist data to disk on a RAM flush

Once Redis is installed and online, you need to configure your application to use it. The example below uses [Predis](https://github.com/nrk/predis/), a PHP client library. There are [plenty of clients](http://redistogo.com/documentation?language=en) to use with Redis, so you can pick and choose based on your preferred language.

The example below is from on a fantastic tutorial by [Jim Westgren](http://www.jimwestergren.com/wordpress-with-redis-as-a-frontend-cache/) and is specific to WordPress-based sites, but WordPress specific code can be stripped out for use with just about any website. Enjoy!

{% gist 3053250 %}