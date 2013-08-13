---
layout: post
title: "Bookstore for IPython Notebooks"
date: 2013-08-13 22:16
comments: true
author: Kyle Kelley
published: false
categories:
- Cloud Files
- OpenStack
- IPython
- OpenStack Swift
---

<!-- OUTLINE

* Describe IPython
* Demonstrate configuration
* CDN Enable a container
* Show where to get the API Key from

-->

{% img http://ipython.org/_static/IPy_header.png 'IPython logo' 'IPython logo' %}

If there is anything I love about the Python ecosystem, it's the scientific computing ecosystem. Standing on top of this stack for me is [IPython](http://ipython.org/), a robust tool for interactive computing. It has features like a simple navigable history, auto-completion, a brilliant [web based notebook](http://ipython.org/notebook.html) with inline plotting, an easy to use [parallel computing framework](http://ipython.org/ipython-doc/stable/parallel/parallel_intro.html), and a well structured protocol that is being used to extend IPython for interactive computing with [other languages](https://github.com/JuliaLang/IJulia.jl), like [Julia](http://julialang.org/). If you haven't heard of IPython before, I recommend you watch [Fernando Perez's keynote talk on IPython](http://vimeo.com/63250251) from PyData Silicon Valley 2013.

As mentioned above, IPython contains a web based notebook for interactive computing called the IPython notebook. If you've ever used Mathematica, you'll feel right at home. IPython notebooks provide an easy way to interactively work with your code and data, all while visualizing and prototyping to your heart's content.

Each cell allows you to write Python, run a computation, view results, and plot data like a typical [Read-eval-print loop](http://en.wikipedia.org/wiki/Read%E2%80%93eval%E2%80%93print_loop). After writing a cell though, you can easily go back and edit your previous code. Cells can also be Markdown, headings, or raw text and even display LaTeX. This allows you to create a narrative alongside your code, useful for teaching and presenting.

The greatest feature to the notebook is the ease to which you can share notebooks with others. This allows others to run through your code, even changing it locally, and seeing results for themselves (👍  for reproducibility!). The easiest way to share them is to put the notebook file (`.ipynb`) on the web, through a GitHub Gist or in a GitHub repo, then link to it through the [notebook viewer](http://nbviewer.ipython.org/).

There's another way to store and save these notebooks now, using OpenStack Swift or Rackspace CloudFiles -- Bookstore.

# Bookstore

[Bookstore](http://github.com/rgbkrk/bookstore) allows you to save your IPython notebooks to OpenStack Swift or CloudFiles, seamlessly, while interacting with the notebook. You can even CDN enable your notebooks so they can be viewed by others through the [notebook viewer](http://nbviewer.ipython.org/).

Install bookstore via pip:

```bash
$ pip install bookstore
```

then add bookstore to your IPython configuration

```python
# Setup IPython Notebook to write notebooks to CloudFiles
c.NotebookApp.notebook_manager_class = 'bookstore.cloudfiles.CloudFilesNotebookManager'

# Set up your user name and API Key
c.CloudFilesNotebookManager.account_name = 'USER_NAME'
c.CloudFilesNotebookManager.account_key = 'API_KEY'

# Container on CloudFiles
c.CloudFilesNotebookManager.container_name = u'notebooks'

# Optionally, the region
c.CloudFilesNotebookManager.region = u'DFW'
```

Your API Key is located in *Settings and Contacts* within the Cloud Control panel, underneath the security question.

{% img /images/2013-08-13-bookstore-for-ipython-notebooks/API_Key.png 'API Key location' 'The API Key is located in Settings and Contacts' %}

Note: if you're using Rackspace UK, set region to `'LON'`.

This code just needs to be added to your IPython configuration, the default configuration being located at `~/.ipython/profile_default/ipython_notebook_config.py`. If you want it in a separate profile just run `ipython profile create <profile_name>`

Bookstore was built with OpenStack in mind so that you can [store your notebooks to your own OpenStack Swift cluster](https://github.com/rgbkrk/bookstore#on-openstack-swift-using-keystone-authentication) (if it uses Keystone authentication -- no support for swauth yet).

## Beneath the covers



