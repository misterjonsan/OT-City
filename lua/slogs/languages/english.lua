SLogs.Dictionary = {
	[ 404 ] = "Something went wrong",

	Other = {
		[ 404 ] = "Something went wrong"
	},

	Logs = {
		[ SLogs:GetID "Violations" ] = {
			[ 0 ] = {"test0"}
		},				-- "Violations" 
		[ SLogs:GetID "Damages" ] = {
			[ 0 ] = { "{ply1}", " damaged ", "{ply2}", " с помощью ", "{str}", ", ", "{int}", " damage" },
			[ 1 ] = { "{ply1}", " shot at ", "{ply2}", " с помощью ", "{str}", ", ", "{int}", " damage" },
			[ 2 ] = { "{ply1}", " blew up ", "{ply2}", " с помощью ", "{str}", ", ", "{int}", " damage" },
			[ 3 ] = { "{ply1}", " получил урон от машины ", "{ply2}", ", ", "{int}", " damage" },

			[ 4 ] = { "{ply1}", " received ", "{int}", " damage от падения" },
			[ 5 ] = { "{ply1}", " received ", "{int}", " damage от взрыва" },
			[ 6 ] = { "{ply1}", " received ", "{int}", " damage от голода" }
		},				-- "Damages" 
		[ SLogs:GetID "Kills" ] = {
			[ 0 ] = { "{ply1}", " killed ", "{ply2}", " с помощью ", "{str}" },
			[ 1 ] = { "{ply1}", " shot ", "{ply2}", " с помощью ", "{str}" },
			[ 2 ] = { "{ply1}", " blew up ", "{ply2}", " с помощью ", "{str}" },
			[ 3 ] = { "{ply1}", " был убит машиной ", "{ply2}" },

			[ 4 ] = { "{ply1}", " fell and died" },
			[ 5 ] = { "{ply1}", " blew up" },
			[ 6 ] = { "{ply1}", " starved to death" }
		},				-- "Kills" 
		[ SLogs:GetID "Connections" ] = {
			[ 0 ] = { "{ply1}", " connects" },
			[ 1 ] = { "{ply1}", " disconnected" },
			[ 2 ] = { "{ply1}", " was kicked, reason: '", "{str}", "'" },
			[ 3 ] = { "{ply1}", " disconnected, timed out" },
			[ 4 ] = { "{ply1}", " disconnected by yourself" },
			[ 5 ] = { "{ply1}", " spawned" },
		},			  	-- "Connections" 
		[ SLogs:GetID "Chat" ] = {
			[ 0 ] = { "{ply1}", " said ", "{str}" },
		},				-- "Chat" 
		[ SLogs:GetID "Commands" ] = {
			[ 0 ] = { "{ply1}", " run ", "{str}" },
		},				-- "Commands" 
		[ SLogs:GetID "Hits" ] = {
			[ 0 ] = { "{ply1}", " ordered ", "{ply2}", " for ", "{int}", "$ because of", "{str}" },
		},				-- "Hits" 
		[ SLogs:GetID "Robbings" ] = {
			[ 0 ] = { "{ply1}", " hacked the car ", "{str}" },
			[ 1 ] = { "{ply1}", " broke the door" },
		},				-- "Robbings" 
		[ SLogs:GetID "Jobs" ] = {
			[ 0 ] = { "{ply1}", " changed his job from ", "{str1}", " to ", "{str2}" },
		},				-- "Jobs" 
		[ SLogs:GetID "Warrants" ] = {
			[ 0 ] = { "{ply1}", " took warrant for ", "{ply2}", ", reason: ", "{str}" }
		},				-- "Warrants" 
		[ SLogs:GetID "Wants" ] = {
			[ 0 ] = { "{ply1}", " wanted ", "{ply2}", ", reason: ", "{str}" },
			[ 1 ] = { "{ply1}", " unwanted ", "{ply2}" },
		},				-- "Wants" 
		[ SLogs:GetID "Cuffs" ] = {
			[ 0 ] = { "{ply1}", " handcuffed ", "{ply2}" },
			[ 1 ] = { "{ply1}", " took off the handcuffs ", "{ply2}" }
		},				-- "Cuffs" 
		[ SLogs:GetID "Laws" ] = {
			[ 0 ] = { "{ply1}", " set new laws" },
			--[ 1 ] = { "Установлены новые законы" }
		},				-- "Laws" 
		[ SLogs:GetID "Arrests" ] = {
			[ 0 ] = { "{ply1}", " arrested ", "{ply2}" },
		},	
		[ SLogs:GetID "Fines" ] = {
			[ 0 ] = { "{ply1}", " выписал штраф ", "{ply2}", " за ", "{str}", ", ", "{int}", "$" }
		},				-- "Arrests" 
		[ SLogs:GetID "Props" ] = {
			[ 0 ] = { "{ply1}", " заспаунил проп ", "{str}" }
		},				-- "Props" 
		[ SLogs:GetID "Entities" ] = {
			[ 0 ] = { "{ply1}", " заспаунил энтити ", "{str}" }
		},				-- "Entities" 
		[ SLogs:GetID "Tools" ] = {
			[ 0 ] = { "{ply1}", " использовал тулган ", "{str1}", " на ", "{str2}" }
		},				-- "Tools" 
		[ SLogs:GetID "FAdmin" ] = {
			[ 0 ] = { "test1" }
		},				-- "FAdmin" 
		[ SLogs:GetID "Penalties" ] = {
			[ 0 ] = { "test2" }
		}				-- "Penalties" 
	},

	LogCategories = {
		[ SLogs:GetID( "Others", true ) ]			 = "Others",
		[ SLogs:GetID( "Main", true ) ]				 = "Main",
		[ SLogs:GetID( "DarkRP", true ) ]			 = "DarkRP",
		[ SLogs:GetID( "Buildings", true ) ]		 = "SandBox",
		[ SLogs:GetID( "Administrations", true ) ]	 = "Admin",
	},
	LogTypes = {
		[ SLogs:GetID "Violations" ]	 = "Violations",
		[ SLogs:GetID "Search" ]		 = "Search",
		[ SLogs:GetID "Damages" ]		 = "Damages", 
		[ SLogs:GetID "Kills" ]			 = "Kills", 
		[ SLogs:GetID "Connections" ]	 = "Connections", 
		[ SLogs:GetID "Chat" ]			 = "Chat", 
		[ SLogs:GetID "Commands" ]		 = "Commands", 
		[ SLogs:GetID "Hits" ]			 = "Hits", 
		[ SLogs:GetID "Robbings" ]		 = "Robbings", 
		[ SLogs:GetID "Jobs" ]			 = "Jobs", 
		[ SLogs:GetID "Warrants" ]		 = "Warrants", 
		[ SLogs:GetID "Wants" ]			 = "Wants", 
		[ SLogs:GetID "Cuffs" ]			 = "Cuffs", 
		[ SLogs:GetID "Laws" ]			 = "Laws", 
		[ SLogs:GetID "Arrests" ]		 = "Arrests", 
		[ SLogs:GetID "Fines" ]			 = "Fines",
		[ SLogs:GetID "Props" ]			 = "Props", 
		[ SLogs:GetID "Entities" ]		 = "Entities", 
		[ SLogs:GetID "Tools" ]			 = "Tools", 
		[ SLogs:GetID "FAdmin" ]		 = "FAdmin",
	},

	-- c - content
	-- d - description
	-- n - name
	Settings = {
		Categories = {
			Visual 	= "Visual",
			Net 	= "Networking",
			Fonts 	= "Fonts",
			Colors 	= "Colors ( soon )"
		},
		BackGR  	= {
			n 			= "Background",
			d 			= "Menu background",

			c1			= "Without background",

			c2			= "Blurred background",
			--c2d 		= "Blurred background, nothing special.",

			c3			= "Black background",
			c3d 		= "High fps boost, +(40-100) fps.",
		},
		Sync 		= {
			n 	 		= "Synchronization",
			d 			= "Soon...",

			c1			= "Manual sync",
			c1d			= "Sync after opening main menu",

			--c2			= "Auto-sync",
			--c2d			= "Log will be immediately sent to the player.",
		},

		F_Log			= "Log line",
		F_Category		= "Category",
		F_Button 		= "Button"

	}
}