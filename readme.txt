V1.1.1

AroAI - Lord Aro's feeble attempt at making an AI. Currently buses only.

NOTE: This AI uses the 1.1 version of the API and due to recent changes in it,
	you now need OpenTTD r20563 or later for this AI to work properly

All code is released under GPL v2, as I have nicked a lot of code from others whose license is 
also GPL v2! 
N.B. I have no problem with releasing it as GPL v2 anyway!

Special thanks go to (in no particular order):
	* Those who helped me out:
		- Yexo;
		- Michiel;
		- planetmaker;
		- Morloth;
		- Dezmond_snz;
		- Steffl;
		- Dustin (if it were not for him, I might have 
				given up trying to make an AI altogether!);
		- Kogut;
		- Yexo (again, because he helped me so much);
		
	* Those who I nicked bits of their AI from:
		- Maninthebox - OTVI, Rondje om de Kerk;
		- Team Rocket - RocketAI;
		
	* Those who I nicked bits of their AI AND they helped me out:
		- Xander - JAMI;
		- fanioz - Trans;
		- Brumi - SimpleAI;
		- Zuu - SuperLib;
		
	* orudge - for his wonderful forums;
	* anybody else I've missed (please say if I have);
	* and finally, just to be cheesy, all the OpenTTD developers for making this wonderful game!


MINOR TODO: (x.x.x++)
	extra debugs
	tidy up Start()
	merge BuildBusStop() into BuildBusRouteObject()
	think of a better name for BuildBusRouteObject()

MAIN TODO: (x.x++.x) (in rough order)
	deal with tunnel/bridge build errors
	re-write town-finder (currently ignoring towns that have ben built through)
	remove failed bus stops (and depots)
	manage failing vehicles
	manage crashed vehicles
	deal with company merger ask - only if AI can handle the vehicle types
	autoreplace - crashed vehicles linked to this
	manage lost vehicles
	add check for towns being pre-connected (see wiki)
	add time limit for pathfinding
	add configurable no. of buses per town
	reform debug output (again)
	better vehicle and cargo selector (think NoCAB) - done in testai
	make stations build properly adjacent (easy)
	try to get subsidies
	respect town road layout (pathzilla does it)
	save/load support (?)

WISHFUL THINKING TODO: (x++.x.x) (in rough order)
	air support
	road cargo support
	rail support
		Double rail support
		Rail networks
	ship support
	write own pathfinders (road first)

	6.x.x by end :)


Comments, problems, code optimisations and suggestions are always welcome at:
http://www.tt-forums.net/viewtopic.php?t=49496/ (preferred)
OR
http://noai.openttd.org/projects/show/ai-aroai/

	Hope you enjoy the AI,
		Charles Pigott (Lord Aro)
