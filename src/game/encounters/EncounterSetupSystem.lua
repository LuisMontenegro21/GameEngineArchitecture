-- Initializes scene-local state for one final conversation. The shared
-- GameSession remains untouched until the encounter has been completed.
local EncounterDefinitions = require("src.game.encounters.EncounterDefinitions")

local EncounterSetupSystem = {}

function EncounterSetupSystem.install(scheduler)
    scheduler:addSystem({
        name = "encounterSetup",
        stage = "startup",
        readsResources = { "gameSession" },
        writesResources = {
            "encounterDefinition",
            "encounterState",
            "encounterCollectionSelection",
        },
        run = function(context)
            local world = context.world
            local definition = EncounterDefinitions.get()
            local session = world:requireResource("gameSession")
            local readinessBonus = EncounterDefinitions.readinessBonus(session.homecomingReadiness)
            world:setResource("encounterDefinition", definition)
            world:setResource("encounterState", {
                promptIndex = 1,
                focus = definition.startingFocus,
                rapport = readinessBonus,
                startingRapportBonus = readinessBonus,
                usedCollectionIndexes = {},
                feedback = readinessBonus > 0
                    and ("Your preparation adds +%d starting rapport. Choose a conversation card.")
                        :format(readinessBonus)
                    or "Choose a conversation card.",
                complete = false,
                transitionQueued = false,
            })
            world:setResource("encounterCollectionSelection", 1)
        end,
    })
end

return EncounterSetupSystem
