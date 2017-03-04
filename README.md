# makeresearch
Database journalism tool for making pretty-printed PDF research reports from MySQL queries.
The idea is to write structured LaTEX code in comment blocks in the SQL script that will format well along
the tables output by each query.

This tool is inspired by the way common source code documentation tools work. It utilizes the commonly
used make tool to build the PDF from the SQL queries. Study the dummy source file reserach.sql and
the generated research.pdf to get the idea.

## Dependencies
This utility runs on Ubuntu 15.04 systems with the following packages installed:

  * texlive
  * texlive-fonts-extra
  * texlive-lang-norwegian (or whatever language you are using)
  * pcregrep
  * mysql-client

## Docker container
You may also use my Docker image espena/latex which have the above dependencies preinstalled.
You only need to mount a working volume and link mysql to the espena/latex container to get it going.
There'a docker-compose.yml file for you to adapt to your needs.

## Install
Run sudo make install. The script will be copied to your users home/bin directory.

## How to use
If you have a SQL file called research.sql, then run "makeres research". If all is good, the file
research.pdf will be generated alongside the source SQL script.
