A site for browsing PSN games

Requirements
============

This project uses a combination of Ruby and Node to build the site. If using
[asdf](https://asdf-vm.com/) run:

    asdf install

This will install the right version of both languages. Next you need yarn and
Bundler to install the dependencies. Install those with:

    gem install bundler
    npm -g install yarn


Finally install all library dependencies for both systems using:

    bundle install
    yarn install

Building
========

    rake download
    rake dist

Open `index.html` in the `build/` directory.

Build artifacts are reused by default. To completely start over:

    rake clobber

License
=======

This software is released to the public domain. See the file UNLICENSE for more
information. Note this only applies to the source code. The data pulled from
IGDB is still governed by their license.
