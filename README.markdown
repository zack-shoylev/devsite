#Rackspace Developer Center


## How to contribute to the blog

**If you use Vagrant**: <https://github.com/raxdevblog/vagrant-blog>

Otherwise, there are several ways to contribute:

###Fork/Pull Request Method

1. Fork the repo, clone your fork to your local machine
2. Install Ruby with RVM: `$ curl -L https://get.rvm.io | bash -s stable --rails --autolibs=enabled --ruby=1.9.3`
3. In the `devsite` directory, run `bundle install`.
4. In the same directory, create a new post: `rake new_post['The title of your post']`
5. Edit the file that is created. See section below on how to write articles.
6. Be sure to leave "published: false" on your post so we can schedule content for posting.
7. Check your work with `rake generate && rake preview` (You can reach it at http://localhost:4000)
8. [Submit a pull request](https://help.github.com/articles/using-pull-requests) with your new post

###Gist/Issue Method

Create a private [gist](https://gist.github.com/) or your post in Markdown format and submit an issue [here](https://github.com/rackerlabs/devsite/issues).

**Writing articles**

* Posts are created in `/source/_posts` and are written in Markdown. [Here](http://daringfireball.net/projects/markdown/syntax) is a format guide for Markdown.
* Images should be placed in `/source/images`. Read [here](http://octopress.org/docs/plugins/image-tag/) on how to use the img tag in your posts.
* Posts with YouTube Videos: `{% youtube 12345678 %}` where "12345678" is the video ID.
* Further reading: [Blogging with Octopress](http://octopress.org/docs/blogging/)

## License
(The MIT License)

Copyright © 2009-2013 Brandon Mathis

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the ‘Software’), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED ‘AS IS’, WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
