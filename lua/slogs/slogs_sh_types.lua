SLogs.Logs 				= SLogs.Logs or {}
SLogs.LogsByTypes		= SLogs.LogsByTypes or {}

SLogs.Categories 		= {}
SLogs.Types 			= {}
SLogs.Translator = {
	Categories 		= {},
	Types 			= {},
}

function SLogs:GetID( Name, IsCategory )

	local tbl = IsCategory and SLogs.Translator.Categories or SLogs.Translator.Types
	return tbl[ Name ]

end

function SLogs:RegisterCategory( ID, Name )

	self.Categories[ ID ] = {}

	self.Translator.Categories[ Name ] = ID

end

function SLogs:RegisterType( ID, Category, Name )

	if isstring( Category ) then Category = self:GetID( Category, true ) end
	if !isnumber( Category ) or !self.Categories[ Category ] then return end

	table.insert( self.Categories[ Category ], ID )

	self.Types[ ID ] = {
		Category = Category
	}
	self.Translator.Types[ Name ] = ID
	self.LogsByTypes[ ID ] = self.LogsByTypes[ ID ] or {}

end


SLogs:RegisterCategory( 01, "Others" )
/**/SLogs:RegisterType( 001, 01, "Search" )
/**/SLogs:RegisterType( 002, 01, "Violations" )
/**/SLogs:RegisterType( 003, 01, "AntiCheat" )


SLogs:RegisterCategory( 02, "Main" )
/**/SLogs:RegisterType( 004, 02, "Damages" )
/**/SLogs:RegisterType( 005, 02, "Kills" )
/**/SLogs:RegisterType( 006, 02, "Connections" )
/**/SLogs:RegisterType( 007, 02, "Chat" )


SLogs:RegisterCategory( 04, "Buildings" )
/**/SLogs:RegisterType( 014, 04, "Props" )
/**/SLogs:RegisterType( 017, 04, "Tools" )

SLogs:RegisterCategory( 05, "Administrations" )
/**/SLogs:RegisterType( 015, 05, "ULX" )
/**/SLogs:RegisterType( 016, 05, "Warn" )
/**/SLogs:RegisterType( 018, 05, "Weapons" )