; Enhanced Roblox Auto-Reconnect GUI Script (AutoHotkey v2)
; Script with UI for managing automatic Roblox reconnection
; Enhanced with Public/Private Server selection options
; Added save/load functionality for both server types

#Requires AutoHotkey v2.0
#SingleInstance Force
Persistent()

; Important variables
SERVER_LINK := ""
GAME_ID := ""
SERVER_TYPE := "private"  ; "public" or "private"
CHECK_INTERVAL := 5000  ; 5 seconds
RECONNECT_DELAY := 3000  ; 3 seconds
AUTO_REJOIN_HOURS := 1  ; Rejoin every 1 hour
IsMonitoringActive := false
IsAutoRejoinActive := false

; Config file path
CONFIG_FILE := A_ScriptDir . "\roblox_config.ini"

; Load saved settings
LoadSettings()

; Create GUI
myGui := Gui("+Resize", "Enhanced Roblox Auto-Reconnect Tool v2.0")
myGui.MarginX := 10
myGui.MarginY := 10

; Server Type Selection
myGui.Add("Text", "x10 y10 w100", "Server Type:")
ServerTypeRadio1 := myGui.Add("Radio", "x120 y10 w80 Checked", "Private/VIP")
ServerTypeRadio2 := myGui.Add("Radio", "x210 y10 w60", "Public")
ServerTypeRadio1.OnEvent("Click", (*) => SelectServerType("private"))
ServerTypeRadio2.OnEvent("Click", (*) => SelectServerType("public"))

; Private Server Section
PrivateGroup := myGui.Add("GroupBox", "x10 y35 w390 h85", "Private/VIP Server Settings")
myGui.Add("Text", "x20 y55 w150", "VIP Server Link:")
PrivateLinkEdit := myGui.Add("Edit", "x20 y75 w280 h20 vPrivateLink", SERVER_LINK)
PrivateLinkEdit.OnEvent("Change", UpdatePrivateLink)
PrivateTestBtn := myGui.Add("Button", "x310 y74 w80 h22", "Test")
PrivateTestBtn.OnEvent("Click", TestPrivateConnection)

; Public Server Section
PublicGroup := myGui.Add("GroupBox", "x10 y125 w390 h85 Disabled", "Public Server Settings")
myGui.Add("Text", "x20 y145 w150", "Game ID:")
PublicGameEdit := myGui.Add("Edit", "x20 y165 w280 h20 vPublicGame Disabled", GAME_ID)
PublicGameEdit.OnEvent("Change", UpdateGameId)
PublicTestBtn := myGui.Add("Button", "x310 y164 w80 h22 Disabled", "Test")
PublicTestBtn.OnEvent("Click", TestPublicConnection)
myGui.Add("Text", "x20 y185 w370 cGray", "Example: 142823291 (from roblox.com/games/142823291/...)")

; Save and Clear buttons
SaveBtn := myGui.Add("Button", "x10 y220 w60 h22", "Save")
SaveBtn.OnEvent("Click", SaveSettings)
ClearBtn := myGui.Add("Button", "x75 y220 w60 h22", "Clear")
ClearBtn.OnEvent("Click", ClearSettings)

; Status and Controls
myGui.Add("Text", "x10 y250 w150", "Monitoring Status:")
StatusText := myGui.Add("Text", "x160 y250 w150 cRed", "Disabled")

MonitoringCheck := myGui.Add("Checkbox", "x10 y275 w200", "Enable Auto Monitoring")
MonitoringCheck.OnEvent("Click", ToggleMonitoring)

myGui.Add("Text", "x10 y305 w150", "Auto Rejoin every:")
RejoinHours := myGui.Add("DropDownList", "x160 y302 w60", ["1", "2", "3", "4", "5", "6", "12", "24"])
RejoinHours.OnEvent("Change", UpdateRejoinHours)
myGui.Add("Text", "x230 y305 w50", "hours")
AutoRejoinCheck := myGui.Add("Checkbox", "x290 y303 w100", "Enable Auto Rejoin")
AutoRejoinCheck.OnEvent("Click", ToggleAutoRejoin)

myGui.Add("Text", "x10 y335 w150", "Check every:")
CheckIntervalEdit := myGui.Add("Edit", "x160 y332 w60 h20 Number", "5")
myGui.Add("Text", "x230 y335 w50", "seconds")

; Control buttons
StartBtn := myGui.Add("Button", "x10 y365 w100 h30", "Start Monitoring")
StartBtn.OnEvent("Click", StartMonitoring)
StopBtn := myGui.Add("Button", "x120 y365 w100 h30", "Stop Monitoring")
StopBtn.OnEvent("Click", StopMonitoring)
ReconnectBtn := myGui.Add("Button", "x230 y365 w80 h30", "Reconnect")
ReconnectBtn.OnEvent("Click", ManualReconnect)
ExitBtn := myGui.Add("Button", "x320 y365 w80 h30", "Exit")
ExitBtn.OnEvent("Click", ExitScript)

LogText := myGui.Add("Edit", "x10 y405 w390 h100 ReadOnly VScroll", "Welcome to Enhanced Roblox Auto-Reconnect Tool v2.0`nDeveloped by: INNIE (Enhanced Version)`nNew Features:`n- Public/Private server selection`n- Game ID support for public servers`n- Enhanced UI and controls`nReady to use...")

; Set default values
RejoinHours.Text := "1"
CheckIntervalEdit.Text := "5"

; Apply loaded settings
ApplyLoadedSettings()

myGui.OnEvent("Close", ExitScript)
myGui.Show("w410 h520")

; Variables for Timer
CheckTimer := ""
RejoinTimer := ""

; Settings Functions
LoadSettings() {
    global SERVER_LINK, GAME_ID, SERVER_TYPE, CONFIG_FILE
    try {
        if (FileExist(CONFIG_FILE)) {
            SERVER_LINK := IniRead(CONFIG_FILE, "Settings", "ServerLink", "")
            GAME_ID := IniRead(CONFIG_FILE, "Settings", "GameId", "")
            SERVER_TYPE := IniRead(CONFIG_FILE, "Settings", "ServerType", "private")
        }
    } catch Error as e {
        ; If config file doesn't exist or error reading, use defaults
        SERVER_LINK := ""
        GAME_ID := ""
        SERVER_TYPE := "private"
    }
}

ApplyLoadedSettings() {
    global SERVER_TYPE, SERVER_LINK, GAME_ID
    
    if (SERVER_TYPE = "public") {
        ServerTypeRadio2.Value := 1
        ServerTypeRadio1.Value := 0
        SelectServerType("public")
        PublicGameEdit.Text := GAME_ID
    } else {
        ServerTypeRadio1.Value := 1
        ServerTypeRadio2.Value := 0
        SelectServerType("private")
        PrivateLinkEdit.Text := SERVER_LINK
    }
}

SelectServerType(type) {
    global SERVER_TYPE
    SERVER_TYPE := type
    
    if (type = "private") {
        ; Enable Private Server controls
        PrivateGroup.Enabled := true
        PrivateLinkEdit.Enabled := true
        PrivateTestBtn.Enabled := true
        
        ; Disable Public Server controls
        PublicGroup.Enabled := false
        PublicGameEdit.Enabled := false
        PublicTestBtn.Enabled := false
        
        UpdateLog("🔒 Switched to Private/VIP Server mode")
    } else {
        ; Enable Public Server controls
        PublicGroup.Enabled := true
        PublicGameEdit.Enabled := true
        PublicTestBtn.Enabled := true
        
        ; Disable Private Server controls
        PrivateGroup.Enabled := false
        PrivateLinkEdit.Enabled := false
        PrivateTestBtn.Enabled := false
        
        UpdateLog("🌐 Switched to Public Server mode")
    }
}

SaveSettings(*) {
    global SERVER_LINK, GAME_ID, SERVER_TYPE, CONFIG_FILE
    
    if (SERVER_TYPE = "private") {
        SERVER_LINK := PrivateLinkEdit.Text
    } else {
        GAME_ID := PublicGameEdit.Text
    }
    
    try {
        ; Create config directory if it doesn't exist
        if (!FileExist(A_ScriptDir))
            DirCreate(A_ScriptDir)
            
        ; Save to ini file
        IniWrite(SERVER_LINK, CONFIG_FILE, "Settings", "ServerLink")
        IniWrite(GAME_ID, CONFIG_FILE, "Settings", "GameId")
        IniWrite(SERVER_TYPE, CONFIG_FILE, "Settings", "ServerType")
        
        UpdateLog("✅ Settings saved successfully!")
        MsgBox("Settings saved successfully!", "Saved", 64)
    } catch Error as e {
        UpdateLog("❌ Error saving settings: " . e.Message)
        MsgBox("Error saving settings: " . e.Message, "Error", 16)
    }
}

ClearSettings(*) {
    result := MsgBox("Are you sure you want to clear all saved settings?", "Confirm Clear", 4)
    if (result = "Yes") {
        PrivateLinkEdit.Text := ""
        PublicGameEdit.Text := ""
        SERVER_LINK := ""
        GAME_ID := ""
        try {
            if (FileExist(CONFIG_FILE)) {
                IniWrite("", CONFIG_FILE, "Settings", "ServerLink")
                IniWrite("", CONFIG_FILE, "Settings", "GameId")
            }
            UpdateLog("🗑️ All settings cleared")
        } catch Error as e {
            UpdateLog("❌ Error clearing settings: " . e.Message)
        }
    }
}

; GUI Event Functions
UpdatePrivateLink(*) {
    global SERVER_LINK
    SERVER_LINK := PrivateLinkEdit.Text
    UpdateLog("Private server link updated")
}

UpdateGameId(*) {
    global GAME_ID
    GAME_ID := PublicGameEdit.Text
    UpdateLog("Game ID updated: " . GAME_ID)
}

TestPrivateConnection(*) {
    serverLink := PrivateLinkEdit.Text
    if (serverLink = "") {
        UpdateLog("Please enter VIP Server link before testing")
        MsgBox("Please enter VIP Server link before testing!", "Warning", 48)
        return
    }
    
    UpdateLog("Testing private server connection...")
    TestConnection(serverLink)
}

TestPublicConnection(*) {
    gameId := PublicGameEdit.Text
    if (gameId = "") {
        UpdateLog("Please enter Game ID before testing")
        MsgBox("Please enter Game ID before testing!", "Warning", 48)
        return
    }
    
    ; Validate Game ID (should be numbers only)
    if (!RegExMatch(gameId, "^\d+$")) {
        UpdateLog("❌ Invalid Game ID format. Use numbers only.")
        MsgBox("Invalid Game ID format. Please use numbers only (e.g., 142823291)", "Error", 48)
        return
    }
    
    gameUrl := "https://www.roblox.com/games/" . gameId
    UpdateLog("Testing public server connection...")
    TestConnection(gameUrl)
}

TestConnection(url) {
    try {
        Run(url)
        Sleep(2000)
        
        ; Check if Roblox opened
        if (ProcessExist("RobloxPlayerBeta.exe")) {
            UpdateLog("✅ Test successful! Roblox opened")
            MsgBox("Test successful! Roblox opened", "Success", 64)
        } else {
            UpdateLog("❌ Test failed, please check the link/ID")
            MsgBox("Test failed, please check the link/ID again", "Failed", 48)
        }
    } catch Error as e {
        UpdateLog("❌ Error during test: " . e.Message)
        MsgBox("Error during test: " . e.Message, "Error", 16)
    }
}

ToggleMonitoring(*) {
    if (MonitoringCheck.Value) {
        StartMonitoring()
    } else {
        StopMonitoring()
    }
}

ToggleAutoRejoin(*) {
    global IsAutoRejoinActive, AUTO_REJOIN_HOURS, RejoinTimer
    
    if (AutoRejoinCheck.Value) {
        IsAutoRejoinActive := true
        AUTO_REJOIN_HOURS := Integer(RejoinHours.Text)
        rejoinInterval := AUTO_REJOIN_HOURS * 3600000  ; Convert to milliseconds
        RejoinTimer := SetTimer(AutoRejoinTimerFunc, rejoinInterval)
        UpdateLog("Auto Rejoin enabled every " . AUTO_REJOIN_HOURS . " hours")
    } else {
        IsAutoRejoinActive := false
        if (RejoinTimer) {
            RejoinTimer.Delete()
            RejoinTimer := ""
        }
        UpdateLog("Auto Rejoin disabled")
    }
}

UpdateRejoinHours(*) {
    global AUTO_REJOIN_HOURS, IsAutoRejoinActive, RejoinTimer
    AUTO_REJOIN_HOURS := Integer(RejoinHours.Text)
    
    ; Update Timer if Auto Rejoin is active
    if (IsAutoRejoinActive) {
        if (RejoinTimer) {
            RejoinTimer.Delete()
        }
        rejoinInterval := AUTO_REJOIN_HOURS * 3600000
        RejoinTimer := SetTimer(AutoRejoinTimerFunc, rejoinInterval)
        UpdateLog("Updated Auto Rejoin to every " . AUTO_REJOIN_HOURS . " hours")
    }
}

StartMonitoring(*) {
    global SERVER_LINK, GAME_ID, SERVER_TYPE, CHECK_INTERVAL, IsMonitoringActive, CheckTimer
    
    ; Validate inputs based on server type
    if (SERVER_TYPE = "private") {
        serverLink := PrivateLinkEdit.Text
        if (serverLink = "") {
            UpdateLog("Please enter VIP Server link before starting monitoring")
            MsgBox("Please enter VIP Server link before starting monitoring!", "Warning", 48)
            MonitoringCheck.Value := 0
            return
        }
        SERVER_LINK := serverLink
    } else {
        gameId := PublicGameEdit.Text
        if (gameId = "" || !RegExMatch(gameId, "^\d+$")) {
            UpdateLog("Please enter valid Game ID before starting monitoring")
            MsgBox("Please enter valid Game ID (numbers only) before starting monitoring!", "Warning", 48)
            MonitoringCheck.Value := 0
            return
        }
        GAME_ID := gameId
    }
    
    checkInterval := CheckIntervalEdit.Text
    CHECK_INTERVAL := Integer(checkInterval) * 1000
    IsMonitoringActive := true
    
    CheckTimer := SetTimer(CheckRobloxStatusFunc, CHECK_INTERVAL)
    StatusText.Text := "Enabled (" . SERVER_TYPE . ")"
    StatusText.Opt("+cGreen")
    MonitoringCheck.Value := 1
    
    UpdateLog("Started monitoring " . SERVER_TYPE . " server every " . checkInterval . " seconds")
}

StopMonitoring(*) {
    global IsMonitoringActive, CheckTimer
    IsMonitoringActive := false
    if (CheckTimer) {
        CheckTimer.Delete()
        CheckTimer := ""
    }
    StatusText.Text := "Disabled"
    StatusText.Opt("+cRed")
    MonitoringCheck.Value := 0
    
    UpdateLog("Stopped monitoring")
}

ManualReconnect(*) {
    global SERVER_LINK, GAME_ID, SERVER_TYPE
    
    if (SERVER_TYPE = "private") {
        serverLink := PrivateLinkEdit.Text
        if (serverLink = "") {
            UpdateLog("Please enter VIP Server link before reconnecting")
            MsgBox("Please enter VIP Server link before reconnecting!", "Warning", 48)
            return
        }
        SERVER_LINK := serverLink
    } else {
        gameId := PublicGameEdit.Text
        if (gameId = "" || !RegExMatch(gameId, "^\d+$")) {
            UpdateLog("Please enter valid Game ID before reconnecting")
            MsgBox("Please enter valid Game ID before reconnecting!", "Warning", 48)
            return
        }
        GAME_ID := gameId
    }
    
    UpdateLog("Starting manual reconnection...")
    ReconnectToGame()
}

ExitScript(*) {
    ; Auto-save settings before exit
    try {
        if (SERVER_TYPE = "private" && PrivateLinkEdit.Text != "") {
            IniWrite(PrivateLinkEdit.Text, CONFIG_FILE, "Settings", "ServerLink")
        } else if (SERVER_TYPE = "public" && PublicGameEdit.Text != "") {
            IniWrite(PublicGameEdit.Text, CONFIG_FILE, "Settings", "GameId")
        }
        IniWrite(SERVER_TYPE, CONFIG_FILE, "Settings", "ServerType")
    }
    ExitApp()
}

; Timer Functions
CheckRobloxStatusFunc() {
    ; Check if RobloxPlayerBeta.exe is running
    if (!ProcessExist("RobloxPlayerBeta.exe")) {
        UpdateLog("⚠️ Detected Roblox is not running, reconnecting...")
        ReconnectToGame()
        return
    }
    
    ; Check for error windows
    try {
        if (WinExist("ahk_class #32770 ahk_exe RobloxPlayerBeta.exe")) {
            errorText := WinGetText("ahk_class #32770 ahk_exe RobloxPlayerBeta.exe")
            if (InStr(errorText, "disconnected") || InStr(errorText, "lost connection") || InStr(errorText, "error") || InStr(errorText, "Disconnected")) {
                UpdateLog("⚠️ Connection error detected, reconnecting...")
                WinClose("ahk_class #32770 ahk_exe RobloxPlayerBeta.exe")
                Sleep(1000)
                ReconnectToGame()
                return
            }
        }
        
        ; Check Roblox window titles
        robloxWindows := WinGetList("ahk_exe RobloxPlayerBeta.exe")
        for hwnd in robloxWindows {
            try {
                windowTitle := WinGetTitle("ahk_id " . hwnd)
                if (InStr(windowTitle, "Disconnected") || InStr(windowTitle, "Lost connection") || InStr(windowTitle, "Error")) {
                    UpdateLog("⚠️ Game disconnection detected, reconnecting...")
                    ReconnectToGame()
                    return
                }
            }
        }
    }
}

AutoRejoinTimerFunc() {
    global IsAutoRejoinActive, AUTO_REJOIN_HOURS
    if (IsAutoRejoinActive) {
        UpdateLog("🔥 Auto Rejoin: Scheduled reconnection time (" . AUTO_REJOIN_HOURS . " hours)")
        ReconnectToGame()
    }
}

; Core Functions
ReconnectToGame() {
    global SERVER_LINK, GAME_ID, SERVER_TYPE, RECONNECT_DELAY
    
    ; Determine URL based on server type
    targetUrl := ""
    if (SERVER_TYPE = "private") {
        if (SERVER_LINK = "") {
            UpdateLog("❌ Cannot reconnect: No VIP Server link")
            return
        }
        targetUrl := SERVER_LINK
    } else {
        if (GAME_ID = "") {
            UpdateLog("❌ Cannot reconnect: No Game ID")
            return
        }
        targetUrl := "https://www.roblox.com/games/" . GAME_ID
    }
    
    UpdateLog("🔥 Starting " . SERVER_TYPE . " server reconnection process...")
    
    ; Close all Roblox processes
    try {
        ProcessClose("RobloxPlayerBeta.exe")
        UpdateLog("⏳ Roblox closed, waiting...")
        Sleep(2000)
        
        ; Wait for complete shutdown
        Loop 10 {
            if (!ProcessExist("RobloxPlayerBeta.exe"))
                break
            Sleep(500)
        }
        
        ; Wait before reopening
        Sleep(RECONNECT_DELAY)
        
        ; Open target URL
        UpdateLog("🚀 Opening Roblox...")
        Run(targetUrl)
        
        ; Wait for Roblox to open
        Loop 30 {
            if (ProcessExist("RobloxPlayerBeta.exe")) {
                UpdateLog("✅ Roblox opened successfully, loading game...")
                Sleep(8000)  ; Wait for game to load
                UpdateLog("🎮 Successfully joined " . SERVER_TYPE . " server!")
                
                ; Close web browsers after successful reconnection
                CloseBrowsers()
                break
            }
            Sleep(1000)
        }
    } catch Error as e {
        UpdateLog("❌ Error during reconnection: " . e.Message)
    }
}

; Function to close web browsers
CloseBrowsers() {
    UpdateLog("🌐 Closing web browsers...")
    
    ; List of common browsers
    browsers := [
        "chrome.exe",
        "firefox.exe", 
        "msedge.exe",
        "opera.exe",
        "brave.exe",
        "vivaldi.exe",
        "iexplore.exe"
    ]
    
    closedAny := false
    
    ; Close each browser process
    for browser in browsers {
        try {
            if (ProcessExist(browser)) {
                ProcessClose(browser)
                closedAny := true
                UpdateLog("✅ Closed " . browser)
                Sleep(500)
            }
        } catch Error as e {
            UpdateLog("⚠️ Error closing " . browser . ": " . e.Message)
        }
    }
    
    if (closedAny) {
        UpdateLog("🌐 All browsers closed successfully")
    } else {
        UpdateLog("ℹ️ No browsers found to close")
    }
}

UpdateLog(message) {
    currentTime := FormatTime(, "HH:mm:ss")
    newLog := "[" . currentTime . "] " . message . "`n"
    
    currentLog := LogText.Text
    newContent := newLog . currentLog
    
    ; Limit log lines (keep only last 25 lines)
    lines := StrSplit(newContent, "`n")
    if (lines.Length > 25) {
        newContent := ""
        Loop 25 {
            if (A_Index <= lines.Length)
                newContent .= lines[A_Index] . "`n"
        }
    }
    
    LogText.Text := newContent
}

; Hotkeys
F1:: {
    global IsMonitoringActive
    if (IsMonitoringActive) {
        StopMonitoring()
    } else {
        StartMonitoring()
    }
}

F2:: {
    ManualReconnect()
}
