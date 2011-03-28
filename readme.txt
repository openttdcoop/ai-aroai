AroAI
----------------

Contents:

1 About
2 Usage and Parameters
3 Building from source
  3.1 Obtaining the source
4 Credits
5 License



-------
1 About
-------

AroAI - Lord Aro's feeble attempt at making an AI. Currently buses only.

Name of this Repo:  ai-aroai

Comments, bug reports, code optimisations and suggestions are always
welcome at: http://dev.openttdcoop.org/projects/ai-aroai/issues/

Releases will be announced at:
http://www.tt-forums.net/viewtopic.php?t=49496/



----------------------
2 Usage and Parameters
----------------------

As this AI uses version 1.1 of OpenTTD's NoAI framework, so to play
with this AI your version of OpenTTD should be at least r20563 or at
least v1.1.0beta-1.

This AI has 1 parameter, but this will disable the AI, so it should
not be used normally.
More parameters are planned.



----------------------
3 Building from source
----------------------

Usually there's not much which needs to be changed when you obtain the
source. Your friends will usually be 'make bundle_tar'.

A brief overview over all Makefile targets is given here:

all:
	This is the default target, if no parameter is given to make. It
	will simply build the tar file (including the AI).

bundle_tar
	This will tar the bundle directory into a tar archive for
	distribution or upload to bananas.

clean:
	This phony target will delete all files which this Makefile will
	create.

test:
	This will display all variables used in the Makefile, for example
	the repo revision. This should only need to be used for testing
	changes to the Makefile itself.

help:
	This displays the Makefile help, showing an even briefer overview
	of all make targets, along with the AI version itself.
	


3.1 Obtaining the source
------------------------

The source code can be obtained from the #openttdcoop DevZone at
    http://dev.openttdcoop.org/projects/ai-aroai
or via mercurial checkout
    hg clone http://hg.openttdcoop.org/ai-aroai



---------
4 Credits
---------

Author: Charles Pigott (aka Lord Aro)

Special thanks to #openttdcoop and especially Ammler who provides and
works a lot on maintaining the Development Zone where this repository is
hosted and who also frequently gives much valuable input.
Also on the thanks list are:
	* Those who helped me out:
		- Yexo;
		- Michiel;
		- planetmaker;
		- Morloth;
		- Dezmond_snz;
		- Steffl;
		- Dustin;
		- Kogut;
		
	* Those who I nicked bits of their AI from:
		- Maninthebox - OTVI, Rondje om de Kerk;
		- Team Rocket - RocketAI;
		
	* Those who I nicked bits of their AI AND they helped me out:
		- Xander - JAMI;
		- fanioz - Trans;
		- Brumi - SimpleAI;
		- Zuu - SuperLib;
		
	* and finally orudge, for his wonderful forums;



---------------
5 License
---------------

AroAI
Copyright (C) 2011 Lord Aro

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License along
with this NewGRF; if not, write to the Free Software Foundation, Inc.,
51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.
