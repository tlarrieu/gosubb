GosuBB
======

Blood Bowl implementation with ruby / chingu

DISCLAIMER
==========

Many resources included in the project are there only for test and I do not own rights on them. Thus, feel free
to contact me if you think that I am breaking any copyright by doing so.

GOAL
====

This repository holds the sources for my MD year project, entitled GosuBB.
My main goal here is to develop a Blood Bowl client, featuring a decent AI, using ruby.
If I would ever have the time to use Rubinius in order to get benefits from JIT, I will, but this
is cleary not a main priority as for now.

INSTALLATION
============

In addition to the files you will find on this repository, you will also need 2 additional gems : 
* gem install chingu
* gem install gosu

Please refer to the following page : https://github.com/jlnr/gosu/wiki

It contains additionnal information on steps to follow to install gosu properly (the library needs a few more packages, which depends on the OS you are running)

RUN
===

Just run main.rb. If you are lazy enough, you can also call rake at the root of the project, which will run it for you!

/!\ The project has only been tested with ruby-1.9.3, gosu-0.7.45 and chingu-0.8.1.
