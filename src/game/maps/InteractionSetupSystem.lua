-- Initializes transient map interaction state. It remains separate from the
-- session so a scene can be reconstructed without preserving an open panel.
local InteractionSetupSystem = {}

function InteractionSetupSystem.install(scheduler)
    scheduler:addSystem({
        name = "interactionSetup",
        stage = "startup",
        after = { "mapSetup" },
        writesResources = { "nearbyInteraction", "dialogueState" },
        run = function(context)
            context.world:setResource("nearbyInteraction", false)
            context.world:setResource("dialogueState", false)
            context.world:setResource("mapActivityFeedback", "")
            context.world:setResource("mapActivityTransitionQueued", false)
        end,
    })
end

return InteractionSetupSystem
