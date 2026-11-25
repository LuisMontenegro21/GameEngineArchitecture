-- Renderer-only card art paths. Gameplay cards retain plain IDs and never
-- store LOVE images or filesystem paths in the session.
local CardPresentationCatalog = {}

local bases = {
    confidence = { path = "assets/wizard_academia/cards/confidence.png", width = 64, height = 64 },
    empathy = { path = "assets/wizard_academia/cards/empathy.png", width = 64, height = 64 },
    knowledge = { path = "assets/wizard_academia/cards/knowledge.png", width = 64, height = 64 },
    balanced = { path = "assets/wizard_academia/cards/balanced.png", width = 64, height = 64 },
}

local icons = {
    dazzling_introduction = "dazzling-introduction.png",
    playfull_laugh = "playfull-laugh.png",
    honest_invitation = "honest-invitation.png",
    calming_charm = "calming-charm.png",
    thoughtful_question = "thoughtful-question.png",
    familiar_friend = "familiar-friend.png",
    shared_research = "shared-research.png",
    constellation_trivia = "constellation-trivia.png",
    ancient_riddle = "ancient-riddle.png",
    comfortable_silence = "comfortable-silence.png",
    stargazing_together = "stargazing-together.png",
    genuine_connection = "genuine-connection.png",
}

local function copyBase(base)
    return { path = base.path, width = base.width, height = base.height }
end

function CardPresentationCatalog.get(card)
    if type(card) ~= "table" then return nil end
    local base, icon = bases[card.category], icons[card.id]
    if not base or not icon then return nil end
    return {
        base = copyBase(base),
        icon = {
            path = "assets/wizard_academia/cards/icons/" .. icon,
            width = 32,
            height = 32,
        },
    }
end

return CardPresentationCatalog
