Config                  = {}
Config.Locale           = 'nl'
Config.DrawDistance     = 100
Config.Marker = {                           -- Markers
    Type = 1,                               -- Type

    Default = {                             -- Default Marker
        x = 1.5,    y = 1.5,    z = 0.5,    -- > Size
        r = 0,      g = 0,      b = 255     -- > Color
    },
    Garage = {                              -- Despawn Marker Garage
        x = 5.0,    y = 5.0,    z = 0.5,    -- > Size
        r = 255,    g = 0,      b = 0       -- > Color
    },
    Clothing = {                            -- Clothing Marker
        x = 1.5,    y = 1.5,    z = 0.5,    -- > Size
        r = 255,    g = 128,    b = 0       -- > Color
    },
    Safe = {                                -- Safe Marker
        x = 1.5,    y = 1.5,    z = 0.5,    -- > Size
        r = 75,     g = 75,     b = 255     -- > Color
    },
    Boss = {                                -- Boss Action Menu Marker
        x = 1.5,    y = 1.5,    z = 0.5,    -- > Size
        r = 255,    g = 255,    b = 0       -- > Color
    },
    Warehouse = {                           -- Boss Action Menu Marker
        x = 5.0,    y = 5.0,    z = 0.5,    -- > Size
        r = 0,      g = 255,    b = 0       -- > Color
    },
}