V1.1.0.1

AroAI - Lord Aro's feeble attempt at making an AI. Currently buses only.

NOTE: This AI uses the 1.1.0 version of the AI and due to recent changes in it,
      you now need at least r20563 for this AI to work properly

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
		- Dustin;
		- Kogut;
		- Yexo (again, because he helped me so much);
		
	* Those who I nicked bits of their AI from:
		- ManInTheBox - OTVI/Rondje om de Kerk;
		- Team Rocket - RocketAI;
		
	* Those who I nicked bits of their AI AND they helped me out:
		- Xander - JAMI;
		- fanioz - Trans;
		- Brumi - SimpleAI;
		- Zuu - SuperLib;
		
	* orudge - for his wonderful forums;
	* anybody else I've missed (please say if i have);
	* and finally, just to be cheesy, all the OpenTTD developers for making this wonderful game!

MINOR TODO: (x.x.x++)
	extra debugs
	properly manageonly when no towns left to build in
	less debugs while not enough money for road
	merge BuildDepot() and BuildBusStation()
	simplify Builder_BusRoute.Main()
	deal with company merger ask

MAIN TODO: (x.x++.x) (in rough order)
	re-write town-finder (currently ignoring towns that have ben built through)
	save/load support
	remove failed bus stops (and depots)
	better vehicle+cargo selector (think NoCAB)
	add check for towns being pre-connected (see wiki)
	add time limit for pathfinding
	add configurable no. of buses per town
	autoreplace
	make stations build properly adjacent
	respect town road layout

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

	Hope you enjoy the AI (like that's likely),
		Charles Pigott (Lord Aro)
