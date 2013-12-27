electric-imp
============

A catch-all for code that is running on my electric imps.  I use the [Xively Agent](https://github.com/beardedinventor/electricimp) to collect and aggregate data for both of them, with
the [specializations](https://github.com/jontg/electric-imp/tree/master/lib/agent/xively/) stored separately.

Brew Monitor
============

I have a simple control system for use in controlling my build of the popular [Son of Fermenter](http://home.roadrunner.com/~brewbeer/chiller/chiller.PDF) system originally designed by Ken
Schwartz back in 1997.  The circuit (will eventually be) shown below, and measures the temperature both in the ice chamber as well as in the carboy itself (via thermowell).  If the ice is cold
enough and the fermenting wort is warm enough then a fan is activated.  This fan moves air from the ice chamber into the main chamber, cooling the beer down.


Temp Bot
========

Temp bot is a battery-powered temperature sensor that measures data every 15 minutes and sends it to my Xively stream.
