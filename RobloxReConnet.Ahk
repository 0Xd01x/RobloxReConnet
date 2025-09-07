; Roblox Auto-Reconnect GUI Script (AutoHotkey v2)
; Script with UI for managing automatic Roblox reconnection
; Added save/load functionality for VIP server link

#Requires AutoHotkey v2.0
#SingleInstance Force
Persistent()

; Important variables
VIP_SERVER_LINK := ""
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
myGui := Gui("+Resize", "Roblox Auto-Reconnect Tool")
myGui.MarginX := 10
myGui.MarginY := 10

myGui.Add("Text", "x10 y10 w150", "VIP Server Link:")
VipLinkEdit := myGui.Add("Edit", "x10 y30 w300 h20 vVipLink", VIP_SERVER_LINK)
VipLinkEdit.OnEvent("Change", UpdateVipLink)
TestBtn := myGui.Add("Button", "x320 y29 w80 h22", "Test")
TestBtn.OnEvent("Click", TestConnection)

; Add Save and Clear buttons
SaveBtn := myGui.Add("Button", "x10 y55 w60 h22", "Save")
SaveBtn.OnEvent("Click", SaveSettings)
ClearBtn := myGui.Add("Button", "x75 y55 w60 h22", "Clear")
ClearBtn.OnEvent("Click", ClearLink)

myGui.Add("Text", "x10 y85 w150", "Monitoring Status:")
StatusText := myGui.Add("Text", "x160 y85 w150 cRed", "Disabled")

MonitoringCheck := myGui.Add("Checkbox", "x10 y110 w200", "Enable Auto Monitoring")
MonitoringCheck.OnEvent("Click", ToggleMonitoring)

myGui.Add("Text", "x10 y140 w150", "Auto Rejoin every:")
RejoinHours := myGui.Add("DropDownList", "x160 y137 w60", ["1", "2", "3", "4", "5", "6", "12", "24"])
RejoinHours.OnEvent("Change", UpdateRejoinHours)
myGui.Add("Text", "x230 y140 w50", "hours")
AutoRejoinCheck := myGui.Add("Checkbox", "x290 y138 w100", "Enable Auto Rejoin")
AutoRejoinCheck.OnEvent("Click", ToggleAutoRejoin)

myGui.Add("Text", "x10 y170 w150", "Check every:")
CheckIntervalEdit := myGui.Add("Edit", "x160 y167 w60 h20 Number", "5")
myGui.Add("Text", "x230 y170 w50", "seconds")

StartBtn := myGui.Add("Button", "x10 y200 w100 h30", "Start Monitoring")
StartBtn.OnEvent("Click", StartMonitoring)
StopBtn := myGui.Add("Button", "x120 y200 w100 h30", "Stop Monitoring")
StopBtn.OnEvent("Click", StopMonitoring)
ReconnectBtn := myGui.Add("Button", "x230 y200 w80 h30", "Reconnect")
ReconnectBtn.OnEvent("Click", ManualReconnect)
ExitBtn := myGui.Add("Button", "x320 y200 w80 h30", "Exit")
ExitBtn.OnEvent("Click", ExitScript)

LogText := myGui.Add("Edit", "x10 y240 w390 h80 ReadOnly VScroll", "Welcome to Roblox Auto-Reconnect Tool v1.2`nDeveloped by: INNIE`nReady to use...`nVIP Server link loaded from saved settings")

; Set default values
RejoinHours.Text := "1"
CheckIntervalEdit.Text := "5"

myGui.OnEvent("Close", ExitScript)
myGui.Show("w410 h330")

; Variables for Timer
CheckTimer := ""
RejoinTimer := ""

; Settings Functions
LoadSettings() {
    global VIP_SERVER_LINK, CONFIG_FILE
    try {
        if (FileExist(CONFIG_FILE)) {
            VIP_SERVER_LINK := IniRead(CONFIG_FILE, "Settings", "VipServerLink", "")
        }
    } catch Error as e {
        ; If config file doesn't exist or error reading, use empty string
        VIP_SERVER_LINK := ""
    }
}

SaveSettings(*) {
    global VIP_SERVER_LINK, CONFIG_FILE
    vipLink := VipLinkEdit.Text
    VIP_SERVER_LINK := vipLink
    
    try {
        ; Create config directory if it doesn't exist
        if (!FileExist(A_ScriptDir))
            DirCreate(A_ScriptDir)
            
        ; Save to ini file
        IniWrite(vipLink, CONFIG_FILE, "Settings", "VipServerLink")
        UpdateLog("✅ Settings saved successfully!")
        MsgBox("VIP Server link saved successfully!", "Saved", 64)
    } catch Error as e {
        UpdateLog("❌ Error saving settings: " . e.Message)
        MsgBox("Error saving settings: " . e.Message, "Error", 16)
    }
}

ClearLink(*) {
    result := MsgBox("Are you sure you want to clear the saved VIP Server link?", "Confirm Clear", 4)
    if (result = "Yes") {
        VipLinkEdit.Text := ""
        VIP_SERVER_LINK := ""
        try {
            if (FileExist(CONFIG_FILE)) {
                IniWrite("", CONFIG_FILE, "Settings", "VipServerLink")
            }
            UpdateLog("🗑️ VIP Server link cleared")
        } catch Error as e {
            UpdateLog("❌ Error clearing settings: " . e.Message)
        }
    }
}

; GUI Event Functions
UpdateVipLink(*) {
    global VIP_SERVER_LINK
    VIP_SERVER_LINK := VipLinkEdit.Text
    UpdateLog("VIP Server link updated")
}

TestConnection(*) {
    vipLink := VipLinkEdit.Text
    if (vipLink = "") {
        UpdateLog("Please enter VIP Server link before testing")
        MsgBox("Please enter VIP Server link before testing!", "Warning", 48)
        return
    }
    
    UpdateLog("Testing connection...")
    try {
        Run(vipLink)
        Sleep(2000)
        
        ; Check if Roblox opened
        if (ProcessExist("RobloxPlayerBeta.exe")) {
            UpdateLog("✓ Test successful! Roblox opened")
            MsgBox("Test successful! Roblox opened", "Success", 64)
        } else {
            UpdateLog("✗ Test failed, please check the link")
            MsgBox("Test failed, please check the link again", "Failed", 48)
        }
    } catch Error as e {
        UpdateLog("✗ Error during test: " . e.Message)
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
    global VIP_SERVER_LINK, CHECK_INTERVAL, IsMonitoringActive, CheckTimer
    
    vipLink := VipLinkEdit.Text
    checkInterval := CheckIntervalEdit.Text
    
    if (vipLink = "") {
        UpdateLog("Please enter VIP Server link before starting monitoring")
        MsgBox("Please enter VIP Server link before starting monitoring!", "Warning", 48)
        MonitoringCheck.Value := 0
        return
    }
    
    VIP_SERVER_LINK := vipLink
    CHECK_INTERVAL := Integer(checkInterval) * 1000
    IsMonitoringActive := true
    
    CheckTimer := SetTimer(CheckRobloxStatusFunc, CHECK_INTERVAL)
    StatusText.Text := "Enabled"
    StatusText.Opt("+cGreen")
    MonitoringCheck.Value := 1
    
    UpdateLog("Started monitoring every " . checkInterval . " seconds")
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
    global VIP_SERVER_LINK
    vipLink := VipLinkEdit.Text
    if (vipLink = "") {
        UpdateLog("Please enter VIP Server link before reconnecting")
        MsgBox("Please enter VIP Server link before reconnecting!", "Warning", 48)
        return
    }
    
    VIP_SERVER_LINK := vipLink
    UpdateLog("Starting manual reconnection...")
    ReconnectToGame()
}

ExitScript(*) {
    ; Auto-save settings before exit
    try {
        if (VipLinkEdit.Text != "") {
            IniWrite(VipLinkEdit.Text, CONFIG_FILE, "Settings", "VipServerLink")
        }
    }
    ExitApp()
}

; Timer Functions
CheckRobloxStatusFunc() {
    ; Check if RobloxPlayerBeta.exe is running
    if (!ProcessExist("RobloxPlayerBeta.exe")) {
        UpdateLog("⚠ Detected Roblox is not running, reconnecting...")
        ReconnectToGame()
        return
    }
    
    ; Check for error windows
    try {
        if (WinExist("ahk_class #32770 ahk_exe RobloxPlayerBeta.exe")) {
            errorText := WinGetText("ahk_class #32770 ahk_exe RobloxPlayerBeta.exe")
            if (InStr(errorText, "disconnected") || InStr(errorText, "lost connection") || InStr(errorText, "error") || InStr(errorText, "Disconnected")) {
                UpdateLog("⚠ Connection error detected, reconnecting...")
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
                    UpdateLog("⚠ Game disconnection detected, reconnecting...")
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
        UpdateLog("🔄 Auto Rejoin: Scheduled reconnection time (" . AUTO_REJOIN_HOURS . " hours)")
        ReconnectToGame()
    }
}

; Core Functions
ReconnectToGame() {
    global VIP_SERVER_LINK, RECONNECT_DELAY
    if (VIP_SERVER_LINK = "") {
        UpdateLog("❌ Cannot reconnect: No VIP Server link")
        return
    }
    
    UpdateLog("🔄 Starting reconnection process...")
    
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
        
        ; Open VIP Server link
        UpdateLog("🚀 Opening Roblox...")
        Run(VIP_SERVER_LINK)
        
        ; Wait for Roblox to open
        Loop 30 {
            if (ProcessExist("RobloxPlayerBeta.exe")) {
                UpdateLog("✅ Roblox opened successfully, loading game...")
                Sleep(8000)  ; Wait for game to load
                UpdateLog("🎮 Successfully joined game!")
                
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
                UpdateLog("✓ Closed " . browser)
                Sleep(500)
            }
        } catch Error as e {
            UpdateLog("⚠ Error closing " . browser . ": " . e.Message)
        }
    }
    
    if (closedAny) {
        UpdateLog("🌐 All browsers closed successfully")
    } else {
        UpdateLog("ℹ No browsers found to close")
    }
}

UpdateLog(message) {
    currentTime := FormatTime(, "HH:mm:ss")
    newLog := "[" . currentTime . "] " . message . "`n"
    
    currentLog := LogText.Text
    newContent := newLog . currentLog
    
    ; Limit log lines (keep only last 20 lines)
    lines := StrSplit(newContent, "`n")
    if (lines.Length > 20) {
        newContent := ""
        Loop 20 {
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
