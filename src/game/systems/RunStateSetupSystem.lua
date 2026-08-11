local RunStateSystem = { name = "RunStateSetup"}


function RunStateSystem.setup(scene)
    local data = SaveFile.load()
    scene.registry.setResource({
        week = 1, day = 1,
        stats = { int = 1, charm = 1, sense = 1 }
    })
end


return RunStateSystem