local wifiManager = require "plugin.wifiManager"
local json = require "json"
local widget = require "widget"
local bg = display.newRect( display.contentCenterX, display.contentCenterY, display.actualContentWidth, display.actualContentHeight )
bg:setFillColor(0,1,.1)
local title = display.newText("Wifi Manager Plugin", display.contentCenterX, 40,native.systemFontBold, 25)
title:setFillColor(0)
local passwordField = native.newTextField( display.contentCenterX, 80, 180, 30 )
passwordField.placeholder = "Password for Network"
local function onRowRenderNetworkList( event )

    -- Get reference to the row group
    local row = event.row
    row.x = -5
    -- Cache the row "contentWidth" and "contentHeight" because the row bounds can change as children objects are added
    local rowHeight = row.contentHeight
    local rowWidth = row.contentWidth

    local rowTitle = display.newText( row, row.params.ssid, 0, 0, nil, 14 )
    rowTitle:setFillColor( 0 )

    -- Align the label left and vertically centered
    rowTitle.anchorX = 0
    rowTitle.x = 20
    rowTitle.y = rowHeight * 0.5
end
local networksList = widget.newTableView(
    {
        x = display.contentCenterX,
        y = display.contentCenterY,
        height = 200,
        width = 200,
        onRowRender = onRowRenderNetworkList,
        onRowTouch = function  (e)
          if e.phase == "release" then
            print( "Connecting" )
            print( "---------------------" )
            if (e.row.params.networkType == "WPA") then
              print(wifiManager.addNetwork(e.row.params.networkType ,e.row.params.ssid , passwordField.text))
            else
              print(wifiManager.addNetwork(e.row.params.networkType ,e.row.params.ssid))
            end
            print( json.encode(wifiManager.listNetworks() ))
            print( wifiManager.connectNetwork(e.row.params.ssid) )
            print( "---------------------" )
          end
        end,
    }
)
--start scan
wifiManager.startScan()
--refresh rate

local howOftenWeShouldCheck =1000 --every one second
local currentResults = {}
local function doesContainSameNetworks (old, new)
  if #old ~= #new then
    return false
  end
  local matches = 0
  for i=1,#old do
    for j=1,#new do
      if old[i]["bssid"] == new[j]["bssid"] then
        matches = matches+1
      end
    end
  end
  if matches == #old then
    
    return true
  else
  end
  return false
end
local wifiEnabled = display.newText("Wifi", display.contentCenterX, display.actualContentHeight-60, native.systemFont, 20)
local wifiSSID = display.newText("Wifi", display.contentCenterX, display.actualContentHeight-90, native.systemFont, 20)
local isWifiEnabled = false
wifiEnabled:addEventListener( "tap", function (  )
  if (isWifiEnabled == false) then
    wifiManager.setEnabled(true)
  end
end )
timer.performWithDelay( howOftenWeShouldCheck, function  ()
  --check if wifi is enabled
  isWifiEnabled = wifiManager.isEnabled()
  if (isWifiEnabled == true) then
    wifiEnabled.text = "Wifi enabled"
  else
    wifiEnabled.text = "Wifi disabled, click to enabled"
  end
  local currentSSID, currentBSSID = wifiManager.getCurrentNetwork()
  if (currentSSID == "0x") then
    wifiSSID.text = "Not connected to wifi"
  else
    wifiSSID.text = "Wifi name: "..currentSSID
  end
  --
  local results = wifiManager.getScanResults()
  if doesContainSameNetworks(currentResults , results) == false then
    if results and #results > 0 then
      networksList:deleteAllRows()
      for i=1,#results do
        if (currentBSSID ~= results[i]["bssid"]) then
          local networkType
          if string.find( results[i]["capabilities"], "WPA" ) ~= nil then
            networkType = "WPA"
          else -- none is default if not WPA
            networkType = "NONE"
          end
          local rowHeight = 36
          local rowColor = { default={ 1, 1, 1 }, over={ 1, 0.5, 0, 0.2 } }
          local lineColor = { 0.5, 0.5, 0.5 }
          networksList:insertRow(
          {
              rowHeight = rowHeight,
              rowColor = rowColor,
              lineColor = lineColor,
              params = {index = i, bssid = results[i]["bssid"],ssid = results[i]["ssid"], networkType = networkType},
          }
          )
        end
      end
    else
      networksList:deleteAllRows()
    end
  end
  currentResults = results
end,0 )