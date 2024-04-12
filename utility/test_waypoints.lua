--[[ This file can be used with LuaJIT to test the Waypoint object ]]

dofile("mods/kae_waypoint/files/waypoint.lua")
wp = Waypoints:new()
wp:add{"First", {0, 0}}
wp:add{"One", {1, 1}, category="Numbers", order=2}
wp:add{"Two", {1, 1}, category="Numbers", order=1}
wp:add{"Second", {1, 1}}

poi = {}
wp:merge(poi)
print(smallfolk.dumps(poi))

wp:save_data()
wp = Waypoints:new()
wp:add{"New", {2, 2}, category="New", order=0, extra={"Extra"}}
poi = {}; wp:merge(poi); print(smallfolk.dumps(poi))
wp:load_data(true)
poi = {}; wp:merge(poi); print(smallfolk.dumps(poi))
