--[[---------------------------------------------------------
    ShouldBlink Material Proxy
        Determines whether an entity is alive and should blink or not 
		Credit: anonymous_moose
-----------------------------------------------------------]]

if matproxy then
    matproxy.Add( {
        name = "ShouldBlink",

        init = function( self, mat, values )
            -- Store the name of the variable we want to set
            self.ResultTo = values.resultvar
        end,

        bind = function( self, mat, ent )
            if ( !IsValid( ent ) ) then return end

            -- If entity is a ragdoll, do not blink
            -- ( this applies to their corpses )
            if ( ent:IsRagdoll() ) then
                mat:SetInt( self.ResultTo, 0 )
            else
                mat:SetInt( self.ResultTo, 1 )
            end
        end
    } )
end