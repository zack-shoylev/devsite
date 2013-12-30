#!/bin/bash

DATE=`date +"%Y-%m-%d"`
BRANCH=feeds-$DATE

cd /home/feeder/devsite
git checkout master
git pull
git checkout -b $BRANCH

cd /home/feeder/planet/api
planet planet.ini
cp output/atom.xml /home/feeder/devsite/source/feeds/api.atom

cd /home/feeder/planet/sdk
planet planet.ini
cp output/atom.xml /home/feeder/devsite/source/feeds/sdk.atom

cd /home/feeder/WebPageToAtomFeed/
mvn exec:java
cp /home/feeder/WebPageToAtomFeed/src/main/resources/WebPageToAtomFeed.log /home/feeder/devsite/source/feeds/

cd /home/feeder/devsite

CHANGES=`git diff-index --name-only HEAD --`
if git diff-index --quiet HEAD --; then
  git checkout master
  git branch --delete $BRANCH
else
  MESSAGE="Feeds update for $DATE"
  git add .
  git commit -m "$MESSAGE"
  git push -u origin $BRANCH
  hub pull-request -m "$MESSAGE"
fi
