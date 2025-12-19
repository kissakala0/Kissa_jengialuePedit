local jengialueet = {
    paleto_bay = {
        type = "box",
        center = vec3(-139.8724, 6375.8862, 31.4906),
        size = vec3(260.0, 560.0, 10.0),
    },
    airport = {
        type = "circle",
        center = vec3(-984.1541, -2640.4102, 13.9849),
        radius = 150.0,
    },
    mirror_park = {
        type = "circle",
        center = vec3(1151.0325, -564.4348, 64.1),
        radius = 200.0,
    },
    sandy_shores = {
        type = "box",
        center = vec3(1700.2517, 3788.2898, 34.7753),
        size = vec3(400.0, 250.0, 10.0),
    }
}

-- chekkaa onks pelaaja alueella
local function sisalalueetsssa(alueittencoordit, alueets)
    if alueets.type == "circle" then
        return #(alueittencoordit - alueets.center) <= alueets.radius
    else
        local diff = alueittencoordit - alueets.center
        return math.abs(diff.x) <= alueets.size.x / 2
            and math.abs(diff.y) <= alueets.size.y / 2
            and math.abs(diff.z) <= alueets.size.z / 2
    end
end

local function OnSallittualueets(alueittencoordit)
    for _, alueets in pairs(jengialueet) do
        if sisalalueetsssa(alueittencoordit, alueets) then
            return true
        end
    end
    return false
end

CreateThread(function()
    while true do
        local ped = PlayerPedId()
        local coords = GetEntityCoords(ped)
        local inside = OnSallittualueets(coords)

        if inside then
            SetPedDensityMultiplierThisFrame(0.6)
            SetScenarioPedDensityMultiplierThisFrame(0.6, 0.6)
            SetVehicleDensityMultiplierThisFrame(0.5)
            SetRandomVehicleDensityMultiplierThisFrame(0.5)
            SetParkedVehicleDensityMultiplierThisFrame(0.5)
            SetGarbageTrucks(true)
            SetRandomBoats(true)
        else
            SetPedDensityMultiplierThisFrame(1.0)
            SetScenarioPedDensityMultiplierThisFrame(1.0, 1.0)
            SetVehicleDensityMultiplierThisFrame(1.0)
            SetRandomVehicleDensityMultiplierThisFrame(1.0)
            SetParkedVehicleDensityMultiplierThisFrame(1.0)
            SetGarbageTrucks(false)
            SetRandomBoats(false)
        end

        Wait(0)
    end
end)

CreateThread(function()
    while true do
        Wait(15000)

        local ped = PlayerPedId()
        local coords = GetEntityCoords(ped)

        if not OnSallittualueets(coords) then
            local px, py, pz = table.unpack(coords)
            for veh in nistipaskaerateVehicles() do
                if DoesEntityExist(veh) then
                    local vx, vy, vz = table.unpack(GetEntityCoords(veh))
                    if #(vector3(px, py, pz) - vector3(vx, vy, vz)) < 200.0 then
                        local driver = GetPedInVehicleSeat(veh, -1)
                        if driver ~= 0 and not IsPedAPlayer(driver) then
                            DeleteEntity(veh)
                        end
                    end
                end
            end
        end
    end
end)

local pedmaarahampurilainen = {
    __gc = function(nistipaska)
        if nistipaska.destructor and nistipaska.handle then
            nistipaska.destructor(nistipaska.handle)
        end
    end
}

function nistipaskaerateVehicles()
    return coroutine.wrap(function()
        local iter, id = FindFirstVehicle()
        if not id or id == 0 then
            EndFindVehicle(iter)
            return
        end

        local nistipaska = { handle = iter, destructor = EndFindVehicle }
        setmetatable(nistipaska, pedmaarahampurilainen)

        repeat
            coroutine.yield(id)
            local ok
            ok, id = FindNextVehicle(iter)
        until not ok

        EndFindVehicle(iter)
    end)
end
