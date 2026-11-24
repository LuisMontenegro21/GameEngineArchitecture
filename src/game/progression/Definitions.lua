-- Game-owned progression data contracts. The ECS engine remains unaware of
-- objectives, rewards, stages, and campaign rules.
local Definitions = {}
local GameSession = require("src.game.session.GameSession")
local CardCatalog = require("src.game.cards.CardCatalog")
local EncounterDefinitions = require("src.game.encounters.EncounterDefinitions")

local VALID_STATES = {
    available = true,
    active = true,
    failed = true,
    completed = true,
    rewarded = true,
    cycleCompleted = true,
}

local function integer(value)
    return type(value) == "number" and value >= 0 and value % 1 == 0
end

local function validReward(reward)
    if reward == nil then return true end
    return type(reward) == "table"
        and integer(reward.experience or 0)
        and integer(reward.currency or 0)
        and (reward.unlocks == nil or type(reward.unlocks) == "table")
end

local function validStage(stage)
    return type(stage) == "table"
        and type(stage.id) == "string" and stage.id ~= ""
        and integer(stage.required) and stage.required > 0
        and validReward(stage.reward)
end

local function validPlan(plan)
    if type(plan) ~= "table" or type(plan.id) ~= "string" or plan.id == ""
        or type(plan.stages) ~= "table" or #plan.stages == 0 then return false end
    local ids = {}
    for _, stage in ipairs(plan.stages) do
        if not validStage(stage) or ids[stage.id] then return false end
        ids[stage.id] = true
    end
    return true
end

local function validProgression(value)
    return type(value) == "table" and VALID_STATES[value.state] == true
        and integer(value.stageIndex) and value.stageIndex >= 1
        and type(value.objectiveId) == "string" and value.objectiveId ~= ""
        and integer(value.current) and integer(value.required) and value.required > 0
        and type(value.rewardGranted) == "boolean"
        and integer(value.experience) and integer(value.currency)
        and type(value.completedObjectives) == "table"
        and type(value.unlocks) == "table"
end

local function objectivePayload(value)
    return type(value) == "table" and type(value.objectiveId) == "string"
        and value.objectiveId ~= ""
end

function Definitions.register(world)
    world:registerResource("progressionPlan", { validate = validPlan })
    world:registerResource("progression", { validate = validProgression })

    world:registerEvent("progressionStartRequested", { maxQueue = 4 })
    world:registerEvent("progressionNextRequested", { maxQueue = 4 })
    world:registerEvent("objectiveProgress", {
        maxQueue = 128,
        validate = function(value)
            return objectivePayload(value) and integer(value.amount) and value.amount > 0
        end,
    })
    world:registerEvent("progressionFailed", {
        maxQueue = 4,
        validate = function(value)
            return value == nil or (type(value) == "table"
                and (value.reason == nil or type(value.reason) == "string"))
        end,
    })
    world:registerEvent("objectiveStarted", { validate = objectivePayload, maxQueue = 4 })
    world:registerEvent("objectiveCompleted", { validate = objectivePayload, maxQueue = 4 })
    world:registerEvent("rewardGranted", { validate = objectivePayload, maxQueue = 4 })
    world:registerEvent("progressionCycleCompleted", { maxQueue = 1 })
end

-- Arcane Hearts uses a scene-local World with a shared, application-owned
-- session value.  These registrations deliberately live alongside the older
-- generic progression contracts above: both game layers remain independently
-- usable while the project transitions to the new game.
local function plain(value, seen)
    local kind = type(value)
    if kind == "nil" or kind == "boolean" or kind == "number" or kind == "string" then
        return true
    end
    if kind ~= "table" then return false end
    seen = seen or {}
    if seen[value] then return false end
    seen[value] = true
    for key, item in pairs(value) do
        if not plain(key, seen) or not plain(item, seen) then return false end
    end
    seen[value] = nil
    return true
end

local function positiveIndex(value)
    return integer(value) and value >= 1
end

local function cardFocus(value)
    return value == "generated" or value == "collection"
end

local function activityRequest(value)
    return type(value) == "table"
        and type(value.activityId) == "string" and value.activityId ~= ""
        and plain(value)
end

local function activityResult(value)
    return type(value) == "table"
        and type(value.activityId) == "string" and value.activityId ~= ""
        and type(value.success) == "boolean"
        and (value.reason == nil or type(value.reason) == "string")
        and plain(value)
end

local function cardsGenerated(value)
    if type(value) ~= "table" or type(value.cards) ~= "table" or #value.cards ~= 3 then
        return false
    end
    local ids = {}
    for _, card in ipairs(value.cards) do
        if not CardCatalog.validate(card) or ids[card.id] then return false end
        ids[card.id] = true
    end
    return plain(value)
end

local function cardAcquired(value)
    return type(value) == "table" and CardCatalog.validate(value.card) and plain(value)
end

local function selectionChanged(value)
    return type(value) == "table" and positiveIndex(value.index) and plain(value)
end

local function sceneRequest(value)
    return type(value) == "table"
        and type(value.to) == "string" and value.to ~= ""
        and plain(value)
end

local function dayPhaseChanged(value)
    return type(value) == "table"
        and GameSession.isDayPhase(value.from)
        and GameSession.isDayPhase(value.to)
        and value.from ~= value.to
        and integer(value.day) and value.day >= 1
        and plain(value)
end

local function knownPromptId(promptId)
    if type(promptId) ~= "string" or promptId == "" then return false end
    for _, prompt in ipairs(EncounterDefinitions.get().prompts) do
        if prompt.id == promptId then return true end
    end
    return false
end

local function knownEndingId(endingId)
    if type(endingId) ~= "string" or endingId == "" then return false end
    for _, ending in ipairs(EncounterDefinitions.get().endings) do
        if ending.id == endingId then return true end
    end
    return false
end

local function cardPlayRequest(value)
    return type(value) == "table" and positiveIndex(value.collectionIndex) and plain(value)
end

local function cardPlayed(value)
    return type(value) == "table"
        and positiveIndex(value.collectionIndex)
        and type(value.cardId) == "string" and value.cardId ~= ""
        and knownPromptId(value.promptId)
        and type(value.categoryMatched) == "boolean"
        and integer(value.focusSpent)
        and integer(value.focusRemaining)
        and integer(value.rapportGained)
        and integer(value.rapport)
        and plain(value)
end

local function cardPlayRejected(value)
    return type(value) == "table"
        and positiveIndex(value.collectionIndex)
        and type(value.reason) == "string" and value.reason ~= ""
        and plain(value)
end

local function promptAdvanced(value)
    return type(value) == "table"
        and positiveIndex(value.round)
        and knownPromptId(value.promptId)
        and plain(value)
end

local function conversationCompleted(value)
    return type(value) == "table"
        and integer(value.finalRapport)
        and knownEndingId(value.endingId)
        and plain(value)
end

local function encounterState(value)
    if type(value) ~= "table"
        or not positiveIndex(value.promptIndex)
        or not integer(value.focus)
        or not integer(value.rapport)
        or not integer(value.startingRapportBonus)
        or type(value.usedCollectionIndexes) ~= "table"
        or type(value.feedback) ~= "string"
        or type(value.complete) ~= "boolean"
        or type(value.transitionQueued) ~= "boolean" then
        return false
    end
    for index, used in pairs(value.usedCollectionIndexes) do
        if not positiveIndex(index) or used ~= true then return false end
    end
    return plain(value)
end

function Definitions.registerArcaneHearts(world)
    assert(not world:hasResourceDefinition("gameSession"),
        "Arcane Hearts resources already registered")

    world:registerResource("gameSession", { validate = GameSession.validate })
    world:registerResource("trainingSelection", { validate = positiveIndex })
    world:registerResource("trainingTransitionQueued", {
        transient = true,
        validate = function(value) return type(value) == "boolean" end,
    })
    world:registerResource("generatedCardSelection", { validate = positiveIndex })
    world:registerResource("collectionSelection", { validate = positiveIndex })
    world:registerResource("cardFocus", { validate = cardFocus })
    world:registerResource("encounterDefinition", {
        transient = true,
        validate = EncounterDefinitions.validate,
    })
    world:registerResource("encounterState", {
        transient = true,
        validate = encounterState,
    })
    world:registerResource("encounterCollectionSelection", {
        transient = true,
        validate = positiveIndex,
    })

    world:registerEvent("keyPressed", {
        validate = function(value)
            return type(value) == "table" and type(value.key) == "string" and value.key ~= ""
        end,
        maxQueue = 32,
    })
    world:registerEvent("trainingSelectionChanged", { validate = selectionChanged, maxQueue = 8 })
    world:registerEvent("trainingActivityRequested", { validate = activityRequest, maxQueue = 8 })
    world:registerEvent("trainingActivityResolved", { validate = activityResult, maxQueue = 8 })
    world:registerEvent("cardGenerationRequested", {
        validate = function(value) return value == nil end,
        maxQueue = 2,
    })
    world:registerEvent("cardsGenerated", { validate = cardsGenerated, maxQueue = 2 })
    world:registerEvent("generatedCardSelectionChanged", { validate = selectionChanged, maxQueue = 8 })
    world:registerEvent("collectionSelectionChanged", { validate = selectionChanged, maxQueue = 8 })
    world:registerEvent("cardAcquisitionRequested", { validate = selectionChanged, maxQueue = 4 })
    world:registerEvent("cardAcquired", { validate = cardAcquired, maxQueue = 2 })
    world:registerEvent("dayAdvanceRequested", {
        validate = function(value) return value == nil end,
        maxQueue = 2,
    })
    world:registerEvent("cardPlayRequested", { validate = cardPlayRequest, maxQueue = 4 })
    world:registerEvent("cardPlayed", { validate = cardPlayed, maxQueue = 4 })
    world:registerEvent("cardPlayRejected", { validate = cardPlayRejected, maxQueue = 4 })
    world:registerEvent("conversationPromptAdvanced", { validate = promptAdvanced, maxQueue = 4 })
    world:registerEvent("conversationCompleted", { validate = conversationCompleted, maxQueue = 1 })
    world:registerEvent("dayPhaseChanged", { validate = dayPhaseChanged, maxQueue = 4 })
    world:registerEvent("sceneRequest", { validate = sceneRequest, maxQueue = 2 })
end

Definitions.validArcaneCard = CardCatalog.validate
Definitions.validArcaneSession = GameSession.validate

Definitions.validPlan = validPlan
Definitions.validProgression = validProgression
return Definitions
