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

{% img /images/2013-08-13-bookstore-for-ipython-notebooks/IPy_header.png 'IPython logo' 'IPython logo' %}

If there is anything I love about the Python ecosystem, it's the scientific computing ecosystem. Standing on top of this stack for me is [IPython](http://ipython.org/), a robust tool for interactive computing. It has features like a simple navigable history, auto-completion, a brilliant [web based notebook](http://ipython.org/notebook.html) with inline plotting, an easy to use [parallel computing framework](http://ipython.org/ipython-doc/stable/parallel/parallel_intro.html), [magic](http://ipython.org/ipython-doc/stable/interactive/tutorial.html), and a well structured protocol that is being used to extend IPython for interactive computing with [other](https://github.com/minrk/iruby) [languages](http://nbviewer.ipython.org/4279371/node-kernel.ipynb) including [Julia](https://github.com/JuliaLang/IJulia.jl). If you haven't heard of IPython before, I recommend you watch [Fernando Perez's keynote talk on IPython](http://vimeo.com/63250251) from PyData Silicon Valley 2013.

As mentioned above, IPython contains a web based notebook for interactive computing called the IPython notebook. If you've ever used Mathematica, you'll feel right at home. IPython notebooks provide an easy way to interactively work with your code and data, all while visualizing and prototyping to your heart's content.

{% img /images/2013-08-13-bookstore-for-ipython-notebooks/ipython_plot.png 'Plot example' 'Plot example' %}

Each cell allows you to write Python, run a computation, view results, and plot data like a typical [Read-eval-print loop](http://en.wikipedia.org/wiki/Read%E2%80%93eval%E2%80%93print_loop). After writing a cell though, you can easily go back and edit your previous code. Cells can also be Markdown, headings, or raw text and even display <span class="texhtml" style="font-family: 'CMU Serif', cmr10, LMRoman10-Regular, 'Times New Roman', 'Nimbus Roman No9 L', Times, serif;">L<span style="text-transform: uppercase; font-size: 70%; margin-left: -0.36em; vertical-align: 0.3em; line-height: 0; margin-right: -0.15em;">a</span>T<span style="text-transform: uppercase; margin-left: -0.1667em; vertical-align: -0.5ex; line-height: 0; margin-right: -0.125em;">e</span>X</span>. This allows you to [create a narrative alongside your code](http://nbviewer.ipython.org/urls/raw.github.com/jakevdp/jakevdp.github.com/master/downloads/notebooks/sparse-graph.ipynb), useful for teaching and presenting. The [example below](http://nbviewer.ipython.org/urls/raw.github.com/jakevdp/jakevdp.github.com/master/downloads/notebooks/sparse-graph.ipynb) comes from [Jake Vanderplas' Python Perambulations blog](http://jakevdp.github.io/blog/2012/10/14/scipy-sparse-graph-module-word-ladders/).

{% img /images/2013-08-13-bookstore-for-ipython-notebooks/ipython_words.png 'IPython cells' 'IPython notebook cell example' %}

The greatest feature to the notebook is the ease to which you can share notebooks with others. This allows others to run through your code (👍 for reproducibility), change it locally, and see results for themselves. By default the notebooks are stored in the same directory IPython was invoked from and have a file extension of `.ipynb`. The easiest way to share them is to put the notebook file on the web, through a GitHub Gist or in a GitHub repo, then link to it through the [notebook viewer](http://nbviewer.ipython.org/).

There's another way to store and save these notebooks now, using OpenStack Swift or Rackspace CloudFiles: [Bookstore](http://github.com/rgbkrk/bookstore).

# Bookstore

[Bookstore](http://github.com/rgbkrk/bookstore) allows you to save your IPython notebooks to OpenStack Swift or CloudFiles, seamlessly, while interacting with the notebook. You can even CDN enable your notebooks so they can be downloaded or [viewed by others](http://nbviewer.ipython.org/).

Install bookstore via pip

```bash
$ pip install bookstore
```

Then add bookstore to your IPython configuration

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

*Note: if you're using Rackspace UK, set region to `'LON'`.*

This code just needs to be added to your IPython configuration, the default configuration being located at `~/.ipython/profile_default/ipython_notebook_config.py`. If you want it in a separate profile just run `ipython profile create <profile_name>`.

Bookstore was built with OpenStack in mind so that you can [store your notebooks to your own OpenStack Swift cluster](https://github.com/rgbkrk/bookstore#on-openstack-swift-using-keystone-authentication) (if it uses Keystone authentication -- no support for swauth yet).

Once configured, the IPython notebook will behave the same on the frontend but no `.ipynb` files will be created on your local box.

Launch the IPython notebook with your profile of choice (default used below)

```bash
$ ipython notebook
2013-08-14 11:18:16.513 [NotebookApp] Using existing profile dir: u'/Users/kyle6475/.ipython/profile_default'
2013-08-14 11:18:28.667 [NotebookApp] Using MathJax from CDN: http://cdn.mathjax.org/mathjax/latest/MathJax.js
2013-08-14 11:18:28.676 [NotebookApp] Serving rgbkrk's notebooks on Rackspace CloudFiles from container notebooks_demo in the DFW region.
2013-08-14 11:18:28.676 [NotebookApp] The IPython Notebook is running at: http://127.0.0.1:4242/
2013-08-14 11:18:28.676 [NotebookApp] Use Control-C to stop this server and shut down all kernels (twice to skip confirmation).
```

If you've configured it correctly, notebooks will be listed and read directly from CloudFiles.

{% img /images/2013-08-13-bookstore-for-ipython-notebooks/notebook_list.png 'Notebook List' 'List of IPython Notebooks' %}

It's worth noting that it will certainly be slower than interacting with your local filesystem, since it has to send the whole ipynb document to CloudFiles. If your IPython notebook server is running in the same data center though, this time difference may not be noticeable.

## Storage

Notebooks are stored by a UUID and checkpoints are stored relative to that UUID.

    {notebook_id} # Notebook itself
    {notebook_id}/checkpoints/{checkpoint_id} # Checkpoints for that notebook

Your notebooks will end up being stored like so:

{% img /images/2013-08-13-bookstore-for-ipython-notebooks/nb_storage.png 'Notebooks as UUIDs' 'Notebooks are stored using a UUID' %}

Currently only single checkpoints are stored, but multiple checkpoints will be enabled for [future versions of IPython and Bookstore](https://github.com/ipython/ipython/pull/3939).

## Beneath the covers

Bookstore extends the `NotebookManager` class from [IPython.html.services.notebooks.nbmanager](https://github.com/ipython/ipython/blob/master/IPython/html/services/notebooks/nbmanager.py) by simply overriding reading, writing, listing, and deleting both notebooks and checkpoints while conforming to the NotebookManager interface. The IPython team did an excellent job making it easy to extend from. All the generic OpenStack Swift code for manipulating the notebooks as objects is handled by a `SwiftNotebookManager` which is extended by the two classes that handle the current authentication types `KeystoneNotebookManager` for OpenStack Keystone authentication and `CloudFilesNotebookManager` for Rackspace authentication.

[Pyrax](https://github.com/rackspace/pyrax) does all the heavy lifting of working with Swift, allowing bookstore to work with Python objects rather than primitive types.



