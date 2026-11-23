-- Authored Academy Garden terrain. Paths are cells rather than decorative
-- rectangles, but remain intentionally non-solid.
return {
    cell = 32,
    origin = { x = 32, y = 56 },
    legend = {
        G = "grass",
        P = "path",
    },
    rows = {
        "GGGGGGGGGGGGGGGGGGGGGGGGGGGG",
        "GGGGGGGGGGGGGGGGGGGGGGGGGGGG",
        "GGGGGGGGGGGGGGGGGGGGGGGGGGGG",
        "GGGGGGGGGGGGGGGGGGGGGGGGGGGG",
        "GGGGPPPPPPGGGGGGGGPPPPGGGGGG",
        "GGGGPPPPPPGGGGGGGGPPPPGGGGGG",
        "GGGGGGGGGPPPPGGGGGPPGGGGGGGG",
        "GGGGGGGGGPGGGGGGGGPPGGGGGGGG",
        "GGGGGGGGGPGGGGGGGGPPGGGGGGGG",
        "GGGGGGGPPPPPPPPPPPPPGGGGGGGG",
        "GGGGGGGGGGGGGPPGGGGGGGGGGGGG",
        "GGGGGGGGGGGGGPPGGGGGGGGGGGGG",
        "GGGGGGGGGGGGGPPGGGGGGGGGGGGG",
        "GGGGGGGGGGGGGPPGGGGGGGGGGGGG",
    },
    -- These cells sit in the Academy Entrance and each current POI trigger.
    -- They also make the intended visual route connectivity testable.
    connections = {
        entrance = { x = 15, y = 14 },
        ancientLibrary = { x = 8, y = 10 },
        studentCommons = { x = 20, y = 9 },
        astralCourt = { x = 6, y = 5 },
        quietGarden = { x = 22, y = 6 },
    },
}
