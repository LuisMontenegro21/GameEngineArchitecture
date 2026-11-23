local EncounterDefinitions = require("src.game.encounters.EncounterDefinitions")

return function()
    local definition = EncounterDefinitions.get()
    assert(EncounterDefinitions.validate(definition), "encounter definitions must validate")
    assert(definition.startingFocus == 5, "the encounter must define its starting Focus")
    assert(definition.categoryMatchBonus == 2, "the encounter must define its match bonus")
    assert(#definition.prompts == 3, "the encounter requires exactly three prompts")
    assert(#definition.endings >= 2, "the encounter requires multiple outcomes")
    assert(definition.endings[1].minimumRapport == 0,
        "the first ending must cover a zero-rapport result")
    assert(EncounterDefinitions.endingForRapport(0).id == "promising_friendship")
    assert(EncounterDefinitions.endingForRapport(7).id == "promising_friendship")
    assert(EncounterDefinitions.endingForRapport(8).id == "growing_connection")
    assert(EncounterDefinitions.endingForRapport(12).id == "arcane_hearts")
    assert(not pcall(function() EncounterDefinitions.endingForRapport(-1) end),
        "ending lookup must reject negative rapport")

    local originalText = EncounterDefinitions.get().prompts[1].text
    definition.prompts[1].text = "changed"
    assert(EncounterDefinitions.get().prompts[1].text == originalText,
        "callers must receive isolated encounter definitions")
    local endingCopy = EncounterDefinitions.endingForRapport(12)
    endingCopy.title = "changed"
    assert(EncounterDefinitions.endingForRapport(12).title ~= "changed",
        "ending lookup must return isolated records")

    local invalid = EncounterDefinitions.get()
    invalid.prompts[1].preferredCategory = "missing"
    assert(not EncounterDefinitions.validate(invalid), "unknown prompt categories must be rejected")
    invalid = EncounterDefinitions.get()
    invalid.prompts[2].id = invalid.prompts[1].id
    assert(not EncounterDefinitions.validate(invalid), "prompt identifiers must be unique")
    invalid = EncounterDefinitions.get()
    invalid.endings[1].minimumRapport = 1
    assert(not EncounterDefinitions.validate(invalid), "ending thresholds must start at zero")
    invalid = EncounterDefinitions.get()
    invalid.endings[2].minimumRapport = invalid.endings[1].minimumRapport
    assert(not EncounterDefinitions.validate(invalid), "ending thresholds must increase")
    invalid = EncounterDefinitions.get()
    invalid.categoryMatchBonus = function() end
    assert(not EncounterDefinitions.validate(invalid), "encounter definitions must remain plain data")
end
