Attribute VB_Name = "modEvents"
'StealthBot Project - modEvents.bas
' Andy T (andy@stealthbot.net) March 2005

Option Explicit

Private Const MSG_FILTER_MAX_EVENTS As Long = 100 ' maximum number of storable events
Private Const MSG_FILTER_DELAY_INT  As Long = 500 ' interval for event count measuring
Private Const MSG_FILTER_MSG_COUNT  As Long = 3   ' message count maximums

Private Type MSGFILTER
    UserObj   As Object
    EventObj  As Object
    EventTime As Date
End Type

Private m_arrMsgEvents()  As MSGFILTER
Private m_eventCount      As Integer

Public Sub Event_FlagsUpdate(ByVal Username As String, ByVal Message As String, ByVal Flags As Long, _
    ByVal Ping As Long, ByVal Product As String, Optional QueuedEventID As Integer = 0)
    
    On Error GoTo ERROR_HANDLER

    Dim UserObj         As clsUserObj
    Dim PreviousUserObj As clsUserObj
    Dim UserEvent       As clsUserEventObj
    
    Dim UserIndex       As Integer  ' ...
    Dim I               As Integer  ' ...
    Dim PreviousFlags   As Long     ' ...
    Dim Clan            As String
    Dim parsed          As String
    Dim pos             As Integer  ' ...
    Dim doUpdate        As Boolean  ' ...
    Dim Displayed       As Boolean  ' stores whether this event has been displayed by another event in the RTB
    
    ' if our username is for some reason null, we don't
    ' want to continue, possibly causing further errors
    If (LenB(Username) < 1) Then
        Exit Sub
    End If
 
    ' ...
    UserIndex = _
        g_Channel.GetUserIndexEx(CleanUsername(Username))
    
    ' ...
    If (UserIndex > 0) Then
        ' ...
        Set UserObj = g_Channel.Users(UserIndex)
        
        ' ...
        If (QueuedEventID = 0) Then
            ' ...
            If (UserObj.Queue.Count > 0) Then
                ' ...
                Set UserEvent = New clsUserEventObj
                
                ' ...
                With UserEvent
                    .EventID = ID_USERFLAGS
                    .Flags = Flags
                    .Ping = Ping
                    .GameID = Product
                End With
                
                ' ...
                UserObj.Queue.Add UserEvent
            Else
                ' ...
                PreviousFlags = UserObj.Flags
            End If
        Else
            ' ...
            PreviousFlags = _
                UserObj.Queue(QueuedEventID - 1).Flags
        End If
        
        ' ...
        Clan = UserObj.Clan
    Else
        ' ...
        If (g_Channel.IsSilent = False) Then
            frmChat.AddChat vbRed, "Warning: There was a flags update received for a user that we do " & _
                    "not have a record for.  This may be indicative of a server split or other technical difficulty."
                    
            Exit Sub
        Else
            ' ...
            If (g_Channel.Users.Count >= 200) Then
                Exit Sub
            End If
        
            ' ...
            Set UserObj = New clsUserObj

            ' ...
            With UserObj
                .Name = Username
                .Statstring = Message
                .Stats.Statstring = Message
                .Clan = .Stats.Clan
                .game = Product
            End With
        End If
    End If
    
    ' ...
    With UserObj
        .Flags = Flags
        .Ping = Ping
    End With
    
    ' ...
    If (g_Channel.IsSilent) Then
        g_Channel.Users.Add UserObj
    End If

    ' convert username to appropriate
    ' display format
    Username = UserObj.DisplayName
    
    ' are we receiving a flag update for ourselves?
    If (StrComp(Username, GetCurrentUsername, vbBinaryCompare) = 0) Then
        ' assign my current flags to the
        ' relevant internal variable
        MyFlags = Flags
        
        ' assign my current flags to the
        ' relevant scripting variable
        SharedScriptSupport.BotFlags = MyFlags
    End If
    
    ' we aren't in a silent channel, are we?
    If (g_Channel.IsSilent) Then
        ' ...
        AddName Username, Product, Flags, Ping, UserObj.Stats.IconCode, _
            Clan
    Else
        ' ...
        If ((UserObj.Queue.Count = 0) Or (QueuedEventID > 0)) Then
            ' ...
            If (Flags <> PreviousFlags) Then
                ' ...
                If (g_Channel.Self.IsOperator) Then
                    If ((Username = GetCurrentUsername) And _
                            ((PreviousFlags And USER_CHANNELOP&) <> USER_CHANNELOP&)) Then
                            
                        g_Channel.CheckUsers
                    Else
                        g_Channel.CheckUser Username
                    End If
                End If
                
                ' ...
                pos = checkChannel(Username)
                
                ' ...
                If (pos) Then
                    ' ...
                    frmChat.lvChannel.ListItems.Remove pos
                
                    ' ...
                    If ((UserObj.IsOperator) And _
                            ((PreviousFlags And USER_CHANNELOP&) <> USER_CHANNELOP&)) Then
                            
                        ' ...
                        AddName Username, Product, Flags, Ping, UserObj.Stats.IconCode, _
                            Clan, 1
                        
                        ' default to display this event
                        Displayed = False
                        
                        ' check whether it has been
                        If QueuedEventID > 0 And UserObj.Queue.Count >= QueuedEventID Then
                            Set userevent = UserObj.Queue(QueuedEventID)
                            Displayed = userevent.Displayed
                        End If
                        
                        ' display if it has not
                        If Not Displayed Then
                            frmChat.AddChat RTBColors.JoinedChannelText, "-- ", RTBColors.JoinedChannelName, _
                                Username, RTBColors.JoinedChannelText, " has acquired ops."
                        End If
                    Else
                        ' ...
                        AddName Username, Product, Flags, Ping, UserObj.Stats.IconCode, _
                            Clan, pos
                    End If
                End If
            End If
        End If
    End If

    ' ...
    If ((UserObj.Queue.Count = 0) Or (QueuedEventID > 0)) Then
        ''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
        ' call event script function
        ''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
        
        On Error Resume Next
        
        ' ...
        RunInAll "Event_FlagUpdate", Username, Flags, Ping
    End If
    
    ' ...
    Exit Sub
    
ERROR_HANDLER:
    frmChat.AddChat vbRed, "Error: " & Err.description & " in Event_FlagsUpdate()"

    Exit Sub
End Sub

Public Sub Event_JoinedChannel(ByVal ChannelName As String, ByVal Flags As Long)
    On Error GoTo ERROR_HANDLER

    Dim mailCount As Integer ' ...
    Dim ToANSI    As String  ' ...
    
    ' if our channel is for some reason null, we don't
    ' want to continue, possibly causing further errors
    If (Len(ChannelName) < 1) Then
        Exit Sub
    End If
    
    ' ...
    Call frmChat.ClearChannel
    
    ' ...
    If (frmChat.mnuUTF8.Checked) Then
        ' ...
        ToANSI = UTF8Decode(ChannelName)
        
        ' ...
        If (Len(ToANSI) > 0) Then
            ChannelName = ToANSI
        End If
    End If
    
    ' ...
    With g_Channel
        .Name = ChannelName
        .Flags = Flags
        .JoinTime = UtcNow
    End With
    
    ' ...
    If (Len(g_Clan.Name) > 0) Then
        ' ...
        If (StrComp(g_Channel.Name, "Clan " & g_Clan.Name, vbTextCompare) = 0) Then
            RequestClanMOTD 1
        End If
    End If
    
    ' we want to reset our filter
    ' Values() when we join a new channel
    'BotVars.JoinWatch = 0
    
    ' ...
    'frmChat.tmrSilentChannel(0).Enabled = False

    
    'With gChannel
    '    .Current = ChannelName
    '    .Flags = Flags
    'End With
    
    SharedScriptSupport.MyChannel = ChannelName
    
    'If (StrComp(g_Channel.Name, "Clan " & Clan.Name, vbTextCompare) = 0) Then
    '    PassedClanMotdCheck = False
    'End If

    ' if we've just left another channel, call event script
    ' function indicating that we've done so.
    If (g_Channel.Name <> vbNullString) Then
        On Error Resume Next
        
        RunInAll "Event_ChannelLeave"
    End If

    frmChat.AddChat RTBColors.JoinedChannelText, "-- Joined channel: ", _
        RTBColors.JoinedChannelName, ChannelName, RTBColors.JoinedChannelText, " --"
    
    SetTitle GetCurrentUsername & ", online in channel " & _
        g_Channel.Name
        
    frmChat.ListviewTabs_Click 0
    
    ' have we just joined the void?
    If (g_Channel.IsSilent) Then
        ' lets inform user of potential lag issues while in this channel
        frmChat.AddChat RTBColors.InformationText, "If you experience a lot of lag while within " & _
                "this channel, try selecting 'Disable Silent Channel View' from the Window menu."
        
        ' if we've joined the void, lets try to grab the list of
        ' users within the channel by attempting to force a user
        ' update message using Battle.net's unignore command.
        If (frmChat.mnuDisableVoidView.Checked = False) Then
            ' ...
            frmChat.tmrSilentChannel(1).Enabled = True
        
            ' ...
            frmChat.AddQ "/unignore " & GetCurrentUsername
        End If
    Else
        ' ...
        frmChat.tmrSilentChannel(1).Enabled = False
    End If

    ' lets update our configuration file with the
    ' current channel name so that we join the channel
    ' again automatically if we disconnect or close the bot.
    Call WriteINI("Other", "LastChannel", ChannelName)
    
    ''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
    ' check for mail
    ''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
    
    mailCount = GetMailCount(GetCurrentUsername)
        
    If (mailCount) Then
        frmChat.AddChat RTBColors.ConsoleText, "You have " & _
            mailCount & " new message" & IIf(mailCount = 1, "", "s") & _
                ". Type /inbox to retrieve."
    End If
    
    ' Give a message to them if they're in Clan SBs.
    If ((StrComp(ChannelName, "Clan SBs", vbTextCompare) = 0) And _
        (IsStealthBotTech() = False)) Then
            frmChat.AddChat vbRed, "You have joined Clan SBs. For the consideration of the Technical Support Staff: greet, idle, and all scripted messages have been temporarily disabled."
    End If
    
    
    ''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
    ' call event script function
    ''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
    
    On Error Resume Next
    
    RunInAll "Event_ChannelJoin", ChannelName, Flags
    
    Exit Sub

ERROR_HANDLER:

    frmChat.AddChat vbRed, "Error (#" & Err.Number & "): " & Err.description & " in Event_JoinedChannel()."

    Exit Sub
    
End Sub

Public Sub Event_KeyReturn(ByVal KeyName As String, ByVal KeyValue As String)
    On Error Resume Next
    
    Dim ft  As FILETIME
    Dim sT  As SYSTEMTIME
    Dim s() As String
    Dim U   As String
    Dim I   As Integer
    
    'MsgBox PPL

    ' Some of the oldest code in this project lives right here
    If SuppressProfileOutput Then
        
        ' // We're receiving profile information from a scripter request
        ' // No need to do anything at all with it except set Suppress = False after
        ' // the description comes in, and of course hadn it over to the scripters
        RunInAll "Event_KeyReturn", KeyName, KeyValue
        
        If KeyName = "Profile\Description" Then
            SuppressProfileOutput = False
        End If
    
    ElseIf ProfileRequest = True Then
    
        'MsgBox "!!"
    
        If KeyName = "Profile\Age" Then
            frmWriteProfile.txtAge.Text = KeyValue
        ElseIf KeyName = "Profile\Location" Then
            frmWriteProfile.txtLoc.Text = KeyValue
        ElseIf KeyName = "Profile\Description" Then
            frmWriteProfile.txtDescr.Text = KeyValue
        ElseIf KeyName = "Profile\Sex" Then
            frmWriteProfile.txtSex.Text = KeyValue
        End If
        
        frmWriteProfile.SetFocus
        
        RunInAll "Event_KeyReturn", KeyName, KeyValue
        
    ' Public Profile Listing
    ElseIf PPL = True Then
    
        'MsgBox PPLRespondTo
        
        If LenB(PPLRespondTo) > 0 Then
            U = "/w " & PPLRespondTo & " "
        Else
            U = ""
        End If
        
        If KeyName = "Profile\Location" Then
Repeat2:
            I = InStr(1, KeyValue, Chr(13))
            
            If Len(KeyValue) > 90 Then
                If I <> 0 Then
                    frmChat.AddQ U & "[Location] " & Left$(KeyValue, Len(KeyValue) - I)
                    KeyValue = Right(KeyValue, Len(KeyValue) - I)
                    
                    GoTo Repeat2
                Else
                    frmChat.AddQ U & "[Location] " & KeyValue
                End If
            Else
                If I <> 0 Then
                    frmChat.AddQ U & "[Location] " & Left$(KeyValue, Len(KeyValue) - I)
                    KeyValue = Right(KeyValue, Len(KeyValue) - I)
                    GoTo Repeat2
                Else
                    frmChat.AddQ U & "[Location] " & KeyValue
                End If
            End If
            
        ElseIf KeyName = "Profile\Description" Then
        
            Dim x() As String
            
            x() = Split(KeyValue, Chr(13))
            ReDim s(0)
            
            For I = LBound(x) To UBound(x)
                s(0) = x(I)
                
                If Len(s(0)) > 200 Then s(0) = Left$(s(0), 200)
                
                If I = LBound(x) Then
                    frmChat.AddQ U & "[Descr] " & s(0)
                Else
                    frmChat.AddQ U & "[Descr] " & Right(s(0), Len(s(0)) - 1)
                End If
            Next I
            
            PPL = False
            
            If LenB(PPLRespondTo) > 0 Then
                PPLRespondTo = ""
            End If
            
        ElseIf KeyName = "Profile\Sex" Then
Repeat4:
            If Len(KeyValue) > 90 Then
                frmChat.AddQ U & "[Sex] " & Left$(KeyValue, 80) & " [more]"
                KeyValue = Right(KeyValue, Len(KeyValue) - 80)
                GoTo Repeat4
            Else
                frmChat.AddQ U & "[Sex] " & KeyValue
            End If
            
        ElseIf Left$(KeyName, 7) = "System\" Then
        
            If InStr(1, KeyValue, " ", vbTextCompare) > 0 Then '// If it's a FILETIME
            
                'Dim FT As FILETIME
                'Dim sT As SYSTEMTIME
                
                ft.dwHighDateTime = CLng(Left$(KeyValue, InStr(1, KeyValue, " ", vbTextCompare)))
                
                'On Error Resume Next
                
                KeyValue = Mid$(KillNull(KeyValue), InStr(1, KeyValue, " ", vbTextCompare) + 1)
                'keyvalue = Left$(keyvalue, Len(keyvalue) - 1)
                
                ft.dwLowDateTime = KeyValue 'CLng(KeyValue & "0")
                
                FileTimeToSystemTime ft, sT

                With sT
                    frmChat.AddQ U & Right$(KeyName, Len(KeyName) - 7) & ": " & _
                        SystemTimeToString(sT) & " (Battle.net time)"
                End With
                
            Else    '// it's a SECONDS type
                If StrictIsNumeric(KeyValue) Then
                    'On Error Resume Next
                    frmChat.AddQ U & "Time Logged: " & ConvertTime(KeyValue, 1)
                End If
            End If
            
        End If
        
    ElseIf Left$(KeyName, 7) = "System\" Then

        'frmchat.addchat RTBColors.ConsoleText, KeyName & ": " & KeyValue
        
        If InStr(1, KeyValue, " ", vbTextCompare) > 0 Then '// If it's a FILETIME
        
            'Dim FT As FILETIME
            'Dim sT As SYSTEMTIME
            
            ft.dwHighDateTime = CLng(Left$(KeyValue, InStr(1, KeyValue, " ", vbTextCompare)))
            
            'On Error Resume Next
            
            KeyValue = Mid$(KillNull(KeyValue), InStr(1, KeyValue, " ", vbTextCompare) + 1)
            'keyvalue = Left$(keyvalue, Len(keyvalue) - 1)
            
            ft.dwLowDateTime = KeyValue 'CLng(KeyValue & "0")
            
            FileTimeToSystemTime ft, sT
            
            With sT
                frmChat.AddChat RTBColors.ServerInfoText, Right$(KeyName, Len(KeyName) - 7) & ": " & _
                        SystemTimeToString(sT) & " (Battle.net time)"
            End With
            
        Else    '// it's a SECONDS type
            If StrictIsNumeric(KeyValue) Then
                'On Error Resume Next
                frmChat.AddChat RTBColors.ServerInfoText, "Time Logged: " & ConvertTime(KeyValue, 1)
            End If
        End If
        
    Else
        Dim rtb As RichTextBox
        
        With frmProfile
            .Show
            
            'frmChat.AddChat vbWhite, "[Profile] " & KeyName & " == " & KeyValue
            
            Select Case KeyName
                Case "Profile\Age"
                    Set rtb = .rtbAge
                Case "Profile\Location"
                    Set rtb = .rtbLocation
                Case "Profile\Description"
                    Set rtb = .rtbProfile
                Case "Profile\Sex"
                    Set rtb = .rtbSex
                Case Else
                    Exit Sub
            End Select
            
            rtb.Text = vbNullString
            
            rtb.selStart = 0
            rtb.selLength = 0
            rtb.SelColor = vbWhite
            rtb.SelText = KeyValue
            
            Call ColorModify(rtb, 0)
            
            .SetFocus
        End With
        
        RunInAll "Event_KeyReturn", KeyName, KeyValue
        
    End If
End Sub

Public Sub Event_LoggedOnAs(Username As String, Product As String)
    LastWhisper = vbNullString

    'If InStr(1, Username, "*", vbBinaryCompare) <> 0 Then
    '    Username = Right(Username, Len(Username) - InStr(1, Username, "*", vbBinaryCompare))
    'End If
    
    Call g_Queue.Clear
    
    g_Online = True
    
    DestroyNLSObject
    
    AttemptedFirstReconnect = False
    
    CurrentUsername = KillNull(Username)
    
    'RequestSystemKeys
    
    Call SetNagelStatus(frmChat.sckBNet.SocketHandle, True)
    
    Call EnableSO_KEEPALIVE(frmChat.sckBNet.SocketHandle)
    
    If (StrComp(Left$(CurrentUsername, 2), "w#", vbTextCompare) = 0) Then
        CurrentUsername = Mid(CurrentUsername, 3)
    End If

    SharedScriptSupport.myUsername = CurrentUsername
    
    With frmChat
        .InitListviewTabs
    
        .AddChat RTBColors.InformationText, "[BNET] Logged on as ", RTBColors.SuccessText, Username, _
            RTBColors.InformationText, "."
            
        .tmrAccountLock.Enabled = False
        
        .UpTimer.Interval = 1000
        
        .Timer.Interval = 30000
    
        .tmrClanUpdate.Enabled = True
    
        'If (Not (DisableMonitor)) Then
        '    .AddChat RTBColors.SuccessText, "User monitor initialized."
        '
        '    InitMonitor
        'End If
    End With
    
    If (frmChat.sckBNLS.State <> 0) Then
        frmChat.sckBNLS.Close
    End If
    
    Call frmChat.UpdateTrayTooltip
    
    If (ExReconnectTimerID > 0) Then
        Call KillTimer(0, ExReconnectTimerID)
        
        ExReconnectTimerID = 0
    End If
    
    If (BotVars.UsingDirectFList) Then
        Call frmChat.FriendListHandler.RequestFriendsList(PBuffer)
    End If
    
    Call FullJoin(BotVars.HomeChannel, 5)
    Call FullJoin(BotVars.HomeChannel, 2)
    
    'Call FullJoin(BotVars.HomeChannel)
    
    ''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
    ' call event script function
    ''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''

    On Error Resume Next
    
    RunInAll "Event_LoggedOn", Username, Product
End Sub

' updated 8-10-05 for new logging system
Public Sub Event_LogonEvent(ByVal Message As Byte, Optional ByVal ExtraInfo As String)
    Dim lColor       As Long
    Dim sMessage     As String
    'Dim UseExtraInfo As Boolean

    Select Case (Message)
        Case 0:
            lColor = RTBColors.ErrorMessageText
            
            sMessage = "Login error - account does not exist."
            
        Case 1:
            lColor = RTBColors.ErrorMessageText
            
            sMessage = "Login error - invalid password."
            
        Case 2:
            lColor = RTBColors.SuccessText
            
            sMessage = "Login successful."
            
            frmChat.tmrAccountLock.Enabled = False
            
        Case 3:
            lColor = RTBColors.InformationText
            
            sMessage = "Attempting to create account..."
            
        Case 4:
            lColor = RTBColors.SuccessText
            
            sMessage = "Account created successfully."
            
        Case 5:
            sMessage = ExtraInfo
            
            lColor = RTBColors.ErrorMessageText
    End Select
    
    frmChat.AddChat lColor, "[BNET] " & sMessage
End Sub

Public Sub Event_RealmConnected()
    frmChat.AddChat RTBColors.SuccessText, "Realm: Connected! Please wait, " & _
        "logging in to the Diablo II realm may take a moment."
End Sub

Public Sub Event_RealmConnecting()
    frmChat.AddChat RTBColors.InformationText, "Realm: Connecting..."
End Sub

Public Sub Event_RealmError(ErrorNumber As Integer, description As String)
    frmChat.AddChat RTBColors.ErrorMessageText, "Realm: Error " & _
        ErrorNumber & ": " & description
End Sub

Public Sub Event_ServerError(ByVal Message As String)
    frmChat.AddChat RTBColors.ErrorMessageText, Message
    
    ''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
    ' call event script function
    ''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
    
    On Error Resume Next
    
    RunInAll "Event_ServerError", Message
End Sub

Public Sub Event_ServerInfo(ByVal Username As String, ByVal Message As String)

    ' ...
    On Error GoTo ERROR_HANDLER

    Const MSG_BANNED      As String = " was banned by "
    Const MSG_UNBANNED    As String = " was unbanned by "
    Const MSG_SQUELCHED   As String = " has been squelched."
    Const MSG_UNSQUELCHED As String = " has been unsquelched."
    Const MSG_KICKEDOUT   As String = " kicked you out of the channel!"
    Const MSG_FRIENDS     As String = "Your friends are:"
    
    Dim I      As Integer
    Dim temp   As String
    Dim bHide  As Boolean
    Dim ToANSI As String
    
    ' ...
    If (Message = vbNullString) Then
        Exit Sub
    End If
    
    ' ...
    Username = convertUsername(Username)

    ' ...
    If (frmChat.mnuUTF8.Checked) Then
        ' ...
        ToANSI = UTF8Decode(Message)
        
        ' ...
        If (Len(ToANSI) > 0) Then
            Message = ToANSI
        End If
    End If
    
    ' ...
    If (StrComp(g_Channel.Name, "Clan " & Clan.Name, vbTextCompare) = 0) Then
        ' ...
        If (PassedClanMotdCheck = False) Then
            ' ...
            Call frmChat.AddChat(RTBColors.ServerInfoText, Message)

            ' ...
            Exit Sub
        End If
    End If
    
    ' ...
    If (g_request_receipt) Then ' for .cs and .cb commands
        ' ...
        Caching = True
    
        ' ...
        cache Message, 1
        
        ' ...
        'With frmChat.cacheTimer
        '    .Enabled = False
        '    .Enabled = True
        'End With
    End If
    
    ' what is our current gateway name?
    If (BotVars.Gateway = vbNullString) Then
        ' ...
        If (InStr(1, Message, "You are ", vbTextCompare) > 0) And (InStr(1, Message, ", using ", _
                vbTextCompare) > 0) Then
                
            ' ...
            If ((InStr(1, Message, "channel", vbTextCompare) = 0) And _
                    (InStr(1, Message, "game", vbTextCompare) = 0)) Then
                    
                ' ...
                I = InStrRev(Message, Space$(1))
                
                ' ...
                BotVars.Gateway = Mid$(Message, I + 1)
                
                ' ...
                SetTitle GetCurrentUsername & ", online in channel " & g_Channel.Name

                Exit Sub
            End If
        End If
    End If

    If (InStr(1, Message, Space$(1), vbBinaryCompare) <> 0) Then
        If (InStr(1, Message, "are still marked", vbTextCompare) <> 0) Then
            Exit Sub
        End If
        
        If ((InStr(1, Message, " from your friends list.", vbBinaryCompare) > 0) Or _
            (InStr(1, Message, " to your friends list.", vbBinaryCompare) > 0) Or _
            (InStr(1, Message, " in your friends list.", vbBinaryCompare) > 0) Or _
            (InStr(1, Message, " of your friends list.", vbBinaryCompare) > 0)) Then
            
            frmChat.lvFriendList.ListItems.Clear
            
            Call frmChat.FriendListHandler.RequestFriendsList(PBuffer)
        End If
        
        'Ban Evasion and banned-user tracking
        temp = Split(Message, " ")(1)
        
        ' added 1/21/06 thanks to
        ' http://www.stealthbot.net/forum/index.php?showtopic=24582
        
        If (Len(temp) > 0) Then
            Dim Banning    As Boolean
            Dim Unbanning  As Boolean
            Dim user       As String  ' ...
            Dim cOperator  As String  ' ...
            Dim msgPos     As Integer ' ...
            Dim pos        As Integer ' ...
            Dim tmp        As String
            Dim banpos     As Integer ' ...
            Dim j          As Integer
            Dim Reason     As String
            
            If (InStr(1, Message, MSG_BANNED, vbTextCompare) > 0) Then
                ' ...
                user = Left$(Message, _
                    (InStr(1, Message, MSG_BANNED, vbBinaryCompare) - 1))
                
                Reason = Mid$(Message, InStr(1, Message, MSG_BANNED, vbBinaryCompare) + Len(MSG_BANNED) + 1) ' trim out username and banned message
                If (InStr(1, Reason, " (", vbBinaryCompare)) Then 'Did they give a message?
                  Reason = Mid$(Reason, InStr(1, Reason, " (") + 2) 'trim out the banning name (Note, when banned by a rep using Len(Username) won't work as its banned "By a Blizzard Representative")
                  Reason = Left$(Reason, Len(Reason) - 2) 'Trim off the trailing ")."
                Else
                  Reason = vbNullString
                End If
                
                ' ...
                If (Len(user) > 0) Then
                    ' ...
                    pos = g_Channel.GetUserIndex(Username)
                    
                    ' ...
                    If (pos > 0) Then
                        ' ...
                        Dim BanlistObj As clsBanlistUserObj
                                                
                        ' ...
                        banpos = g_Channel.IsOnBanList(user, Username)
                        
                        ' ...
                        If (banpos > 0) Then
                            g_Channel.Banlist.Remove banpos
                        Else
                            g_Channel.BanCount = (g_Channel.BanCount + 1)
                        End If
                        
                        ' ...
                        If ((BotVars.StoreAllBans) Or _
                                (StrComp(Username, GetCurrentUsername, vbBinaryCompare) = 0)) Then
                            
                            ' ...
                            Set BanlistObj = New clsBanlistUserObj
                            
                            ' ...
                            With BanlistObj
                                .Name = user
                                .Operator = Username
                                .DateOfBan = UtcNow
                                .IsDuplicateBan = (g_Channel.IsOnBanList(user) > 0)
                                .Reason = Reason
                            End With
                        
                            ' ...
                            If (BanlistObj.IsDuplicateBan) Then
                                ' ...
                                With g_Channel.Banlist(g_Channel.IsOnBanList(user))
                                    .IsDuplicateBan = False
                                End With
                            End If
                            
                            ' ...
                            g_Channel.Banlist.Add BanlistObj
                        End If
                    End If
                    
                    ' ...
                    Call RemoveBanFromQueue(user)
                End If
                
                If (frmChat.mnuHideBans.Checked) Then
                    bHide = True
                End If
            ElseIf (InStr(1, Message, MSG_UNBANNED, vbTextCompare) > 0) Then
                ' ...
                user = Left$(Message, _
                    (InStr(1, Message, MSG_UNBANNED, vbBinaryCompare) - 1))
                                
                ' ...
                If (Len(user) > 0) Then
                    ' ...
                    g_Channel.BanCount = (g_Channel.BanCount - 1)
                    
                    ' ...
                    Do
                        ' ...
                        banpos = g_Channel.IsOnBanList(user)
                    
                        ' ...
                        If (banpos > 0) Then
                            g_Channel.Banlist.Remove banpos
                        End If
                    Loop While (banpos <> 0)
                End If
            End If
    
            '// backup channel
            If (InStr(1, Message, "kicked you out", vbTextCompare) > 0) Then
                If ((StrComp(g_Channel.Name, "Op [vL]", vbTextCompare) <> 0) And _
                    (StrComp(g_Channel.Name, "Op Fatal-Error", vbTextCompare) <> 0)) Then
                        
                    If (BotVars.UseBackupChan) Then
                        If (Len(BotVars.BackupChan) > 1) Then
                            frmChat.AddQ "/join " & BotVars.BackupChan
                        End If
                    Else
                        frmChat.AddQ "/join " & g_Channel.Name
                    End If
                End If
            End If
            
            ' ...
            If (InStr(1, Message, " has been unsquelched", vbTextCompare) > 0) Then
                'unsquelching = True
                
                ' ...
                If ((g_Channel.IsSilent) And (frmChat.mnuDisableVoidView.Checked = False)) Then
                    frmChat.lvChannel.ListItems.Clear
                End If
            End If
        End If
        
        ' ...
        If (InStr(1, Message, "designated heir", vbTextCompare) <> 0) Then
            g_Channel.OperatorHeir = Left$(Message, Len(Message) - 29)
        End If
        
        
        temp = "Your friends are:"
        
        If (StrComp(Left$(Message, Len(temp)), temp) = 0) Then
            If (Not (BotVars.ShowOfflineFriends)) Then
                Message = Message & _
                    "  �ci(StealthBot is hiding your offline friends)"
            End If
        End If
    
    End If ' message contains a space
    
    If (StrComp(Right$(Message, 9), ", offline", vbTextCompare) = 0) Then
        If (BotVars.ShowOfflineFriends) Then
            frmChat.AddChat RTBColors.ServerInfoText, Message
        End If
    Else
        If (Not (bHide)) Then
            frmChat.AddChat RTBColors.ServerInfoText, Message
        End If
    End If
    
    ''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
    ' call event script function
    ''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
    
    On Error Resume Next
    
    RunInAll "Event_ServerInfo", Message
    
    Exit Sub
    
ERROR_HANDLER:
    frmChat.AddChat vbRed, "Error: " & Err.description & " in Event_ServerInfo()."

    Exit Sub
End Sub

Public Sub Event_SomethingUnknown(ByVal UnknownString As String)
    frmChat.AddChat RTBColors.ErrorMessageText, "Something unknown has happened... " & _
        "Did Battle.Net change something? The Unknown Event is as follows:"
    frmChat.AddChat RTBColors.ErrorMessageText, "[" & UnknownString & "]"
    frmChat.AddChat RTBColors.ErrorMessageText, "Please report this event to Stealth as soon " & _
        "as possible, copy/paste this entire message."
End Sub

Public Sub Event_UserEmote(ByVal Username As String, ByVal Flags As Long, ByVal Message As String, _
    Optional QueuedEventID As Integer = 0)
    
    On Error GoTo ERROR_HANDLER
        
    Dim UserEvent   As clsUserEventObj
    Dim UserObj     As clsUserObj
    
    Dim I           As Integer ' ...
    Dim ToANSI      As String  ' ...
    Dim pos         As Integer ' ...
    Dim PassedQueue As Boolean ' ...
    
    ' ...
    pos = _
        g_Channel.GetUserIndexEx(CleanUsername(Username))
    
    ' ...
    If (pos > 0) Then
        ' ...
        Set UserObj = g_Channel.Users(pos)
        
        ' ...
        If (QueuedEventID = 0) Then
            ' ...
            UserObj.LastTalkTime = UtcNow
            
            ' ...
            If (UserObj.Queue.Count > 0) Then
                ' ...
                Set UserEvent = New clsUserEventObj
                
                ' ...
                With UserEvent
                    .EventID = ID_EMOTE
                    .Flags = Flags
                    .Message = Message
                End With
                
                ' ...
                UserObj.Queue.Add UserEvent
            End If
        End If
    Else
        ' create new user object for invisible representatives...
        Set UserObj = New clsUserObj
        
        ' store user name
        UserObj.Name = Username
    End If
    
    ' convert user name
    Username = UserObj.DisplayName
    
    ' ...
    If (frmChat.mnuUTF8.Checked) Then
        ' ...
        ToANSI = UTF8Decode(Message)
        
        ' ...
        If (Len(ToANSI) > 0) Then
            Message = ToANSI
        End If
    End If
    
    ' ...
    If (QueuedEventID = 0) Then
        ' ...
        If (g_Channel.Self.IsOperator) Then
            ' ...
            If (GetSafelist(Username) = False) Then
                ' ...
                CheckMessage Username, Message
            End If
        End If
    End If
    
    ' ...
    If ((UserObj.Queue.Count = 0) Or (QueuedEventID > 0)) Then
        ' ...
        If (AllowedToTalk(Username, Message)) Then
            ' ...
            'If (GetVeto = False) Then
                frmChat.AddChat RTBColors.EmoteText, "<", RTBColors.EmoteUsernames, Username & _
                    Space$(1), RTBColors.EmoteText, Message & ">"
            'End If
            
            ' ...
            If (Catch(0) <> vbNullString) Then
                CheckPhrase Username, Message, CPEMOTE
            End If
            
            ' ...
            If (frmChat.mnuFlash.Checked) Then
                FlashWindow
            End If
        End If
        
        ''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
        ' call event script function
        ''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
        
        On Error Resume Next
        
        ' ...
        If ((BotVars.NoSupportMultiCharTrigger) And (Len(BotVars.TriggerLong) > 1)) Then
            If (StrComp(Left$(Message, Len(BotVars.TriggerLong)), BotVars.TriggerLong, _
                vbBinaryCompare) = 0) Then
                
                Message = BotVars.Trigger & Mid$(Message, Len(BotVars.TriggerLong) + 1)
            End If
        End If
        
        ' ...
        RunInAll "Event_UserEmote", Username, Flags, Message
    End If
    
    Exit Sub
    
ERROR_HANDLER:
    frmChat.AddChat vbRed, "Error (" & Err.Number & "): " & Err.description & " in Event_UserEmote()."
    
    Exit Sub
End Sub

'Ping, Product, Clan, InitStatstring, W3Icon
Public Sub Event_UserInChannel(ByVal Username As String, ByVal Flags As Long, ByVal Message As String, _
    ByVal Ping As Long, ByVal Product As String, ByVal sClan As String, ByVal originalstatstring As String, _
        Optional ByVal w3icon As String, Optional QueuedEventID As Integer = 0)

    On Error GoTo ERROR_HANDLER

    Dim UserEvent    As clsUserEventObj
    Dim UserObj      As clsUserObj
    Dim found        As ListItem ' ...
    
    Dim UserIndex    As Integer ' ...
    Dim I            As Integer ' ...
    Dim strCompare   As String  ' ...
    Dim Level        As Byte    ' ...
    Dim StatUpdate   As Boolean ' ...
    Dim Index        As Long    ' ...
    Dim Stats        As String  ' ...
    Dim Clan         As String  ' ...
    Dim pos          As Integer ' ...
    Dim showUpdate   As Boolean ' ...
    Dim Displayed    As Boolean ' whether this event has been displayed in the RTB (if combined with another)

    If (LenB(Username) < 1) Then
        Exit Sub
    End If

    ' ...
    UserIndex = _
        g_Channel.GetUserIndexEx(CleanUsername(Username))

    ' ...
    If (UserIndex > 0) Then

        ' ...
        Set UserObj = g_Channel.Users(UserIndex)
        
        ' ...
        If (QueuedEventID = 0) Then
            ' ...
            If (UserObj.Queue.Count > 0) Then
                ' ...
                If (UserObj.Stats.Statstring = vbNullString) Then
                    showUpdate = True
                End If
                
                ' ...
                Set UserEvent = New clsUserEventObj
                
                ' ...
                With UserEvent
                    .EventID = ID_USER
                    .Flags = Flags
                    .Ping = Ping
                    .GameID = Product
                    .Clan = sClan
                    .Statstring = originalstatstring
                End With
                
                ' ...
                UserObj.Queue.Add UserEvent
            End If
        End If
        
        ' ...
        StatUpdate = True
    Else
        ' ...
        Set UserObj = New clsUserObj
    End If
    
    ' ...
    With UserObj
        .Name = Username
        .Flags = Flags
        .game = Product
        .Ping = Ping
        .JoinTime = g_Channel.JoinTime
        .Clan = sClan
        .Statstring = originalstatstring
        .Stats.Statstring = originalstatstring
    End With
    
    ' ...
    If (UserIndex = 0) Then
        g_Channel.Users.Add UserObj
    End If
    
    ' ...
    Username = UserObj.DisplayName
    
    ' ...
    'ParseStatstring OriginalStatstring, Stats, Clan
    
    ' ...
    If (StatUpdate = False) Then
        'frmChat.AddChat vbRed, UserObj.Stats.IconCode
    
        ' ...
        AddName Username, Product, Flags, Ping, UserObj.Stats.IconCode, sClan
            
        ' ...
        frmChat.lblCurrentChannel.Caption = frmChat.GetChannelString()
        
        ' ...
        frmChat.ListviewTabs_Click 0
        
        ' ...
        DoLastSeen Username
    Else
        ' ...
        If ((UserObj.Queue.Count = 0) Or (QueuedEventID > 0)) Then
            ' ...
            If (JoinMessagesOff = False) Then
                ' default to display this event
                Displayed = False
                
                ' check whether it has been
                If QueuedEventID > 0 And UserObj.Queue.Count >= QueuedEventID Then
                    Set userevent = UserObj.Queue(QueuedEventID)
                    Displayed = userevent.Displayed
                End If
                
                ' display if it has not already been
                If Not Displayed Then
                    frmChat.AddChat RTBColors.JoinText, "-- Stats updated: ", _
                        IIf(AcqOps, RTBColors.TalkUsernameOp, RTBColors.JoinUsername), Username, _
                        RTBColors.JoinUsername, " [" & Ping & "ms]", _
                        RTBColors.JoinText, " is using " & UserObj.Stats.ToString & "."
                End If
            End If
            
            ' ...
            pos = checkChannel(Username)

            ' ...
            If (pos > 0) Then
            
                ' ...
                Set found = frmChat.lvChannel.ListItems(pos)
                
                ' ...
                If (BotVars.ShowStatsIcons) Then
                    ' ...
                    I = g_Channel.GetUserIndex(Username)
                    
                    ' ...
                    If (I > 0) Then
                        
                        ' ...
                        If (UserObj.Stats.IconCode <> -1) Then
                            ' ...
                            If (g_Channel.Users(I).game = "WAR3") Then
                                ' ...
                                If (found.SmallIcon = ICWAR3) Then
                                    found.SmallIcon = UserObj.Stats.IconCode
                                End If
                            ElseIf (g_Channel.Users(I).game = "W3XP") Then
                                ' ...
                                If (found.SmallIcon = ICWAR3X) Then
                                    found.SmallIcon = UserObj.Stats.IconCode
                                End If
                            End If
                        End If
                    End If
                End If
                
                If (found.ListSubItems.Count > 0) Then
                    ' ...
                    found.ListSubItems(1).Text = sClan
                End If
                
                ' ...
                Set found = Nothing
            End If
        End If
    End If
    
    ' ...
    If ((UserObj.Queue.Count = 0) Or (QueuedEventID > 0)) Then
        ''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
        ' call event script function
        ''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
        
        On Error Resume Next
        
        RunInAll "Event_UserInChannel", Username, Flags, UserObj.Stats.ToString, Ping, _
            Product, StatUpdate
    End If
    
    ' ...
    If (MDebug("statstrings")) Then
        frmChat.AddChat vbMagenta, "Username: " & Username & ", Statstring: " & _
            originalstatstring
    End If
    
    Exit Sub
    
ERROR_HANDLER:
    Call frmChat.AddChat(vbRed, "Error: " & Err.description & " in Event_UserInChannel().")
    Call frmChat.AddChat(vbRed, "Error Source: " & Err.source)
    
    Exit Sub
End Sub

Public Sub Event_UserJoins(ByVal Username As String, ByVal Flags As Long, ByVal Message As String, _
    ByVal Ping As Long, ByVal Product As String, ByVal sClan As String, ByVal originalstatstring As String, _
        ByVal w3icon As String, Optional QueuedEventID As Integer = 0)
                
    On Error GoTo ERROR_HANDLER
    
    Dim UserObj     As clsUserObj
    Dim UserEvent   As clsUserEventObj
    
    Dim toCheck     As String
    Dim strCompare  As String
    Dim I           As Long
    Dim temp        As Byte
    Dim Level       As Byte
    Dim L           As Long
    Dim Banned      As Boolean
    Dim f           As Integer
    Dim UserIndex   As Integer ' ...
    Dim BanningUser As Boolean ' ...
    Dim pStats      As String
    Dim isbanned    As Boolean
    Dim AcqOps      As Boolean
    Dim ToDisplay   As Boolean
    
    If (Len(Username) < 1) Then
        Exit Sub
    End If
    
    ' ...
    UserIndex = _
        g_Channel.GetUserIndexEx(CleanUsername(Username))
    
    ' ...
    If (QueuedEventID > 0) Then
        ' ...
        If (UserIndex = 0) Then
            frmChat.AddChat vbRed, "Error: We have received a queued join event for a user that we " & _
                "couldn't find in the channel."
        
            Exit Sub
        End If
    
        ' ...
        Set UserObj = g_Channel.Users(UserIndex)
    Else
        ' ...
        If (UserIndex = 0) Then
            ' ...
            Set UserObj = New clsUserObj
            
            ' ...
            With UserObj
                .Name = Username
                .Flags = Flags
                .Ping = Ping
                .game = Product
                .JoinTime = UtcNow
                .Clan = sClan
                .Statstring = originalstatstring
                .Stats.Statstring = originalstatstring
            End With

            ' ...
            If (BotVars.ChatDelay > 0) Then
                ' ...
                Set UserEvent = New clsUserEventObj
                
                ' ...
                With UserEvent
                    .EventID = ID_JOIN
                    .Flags = Flags
                    .Ping = Ping
                    .GameID = Product
                    .Statstring = originalstatstring
                    .Clan = sClan
                    .IconCode = w3icon
                End With
                
                ' ...
                UserObj.Queue.Add UserEvent
            End If

            ' ...
            g_Channel.Users.Add UserObj
        Else
            frmChat.AddChat vbRed, "Warning: We have received a join event for a user that we had thought was " & _
                    "already present within the channel.  This may be indicative of a server split or other technical difficulty."
            
            Exit Sub
        End If
    End If
    
    ' ...
    Username = UserObj.DisplayName
    
    ' ...
    If ((UserObj.Queue.Count = 0) Or (QueuedEventID = 0)) Then
        If (g_Channel.Self.IsOperator) Then
            g_Channel.CheckUser Username, UserObj
        End If
    End If
    
    ' ...
    If ((UserObj.Queue.Count = 0) Or (QueuedEventID > 0)) Then
        ''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
        ' GUI
        ''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
    
        ' if we have join/leaves on
        If (JoinMessagesOff = False) Then
            Dim UserStats As clsUserStats ' ...
            
            ' create user stats object
            Set UserStats = New clsUserStats

            ' store o.s.s. in users stats object
            UserStats.Statstring = originalstatstring
            
            ' does this event have events delayed after it?
            If QueuedEventID > 0 And UserObj.Queue.Count > 0 Then
                
                ' loop through the events occuring after this one
                For I = QueuedEventID To UserObj.Queue.Count
                
                    ' get the event
                    Set userevent = UserObj.Queue(I)
                    
                    ' default to not combine with userjoins
                    ToDisplay = False
                    
                    Select Case userevent.EventID
                    
                        ' user flags update
                        Case ID_USERFLAGS
                            ' will combine with userjoins
                            ToDisplay = True
                            
                            ' is operator
                            If userevent.Flags And 2 Then
                                AcqOps = True
                            End If
                            
                        ' user stats update / user in channel
                        Case ID_USER
                            ' will combine with userjoins
                            ToDisplay = True
                            
                            ' is stats different / provided?
                            If LenB(userevent.Statstring) > 0 Then
                                If StrComp(userevent.Statstring, originalstatstring) Then
                                    ' create new stats object over other stats object
                                    Set UserStats = New clsUserStats
                                    
                                    ' store stats update stats in object used in userjoins message generation
                                    UserStats.Statstring = userevent.Statstring
                                End If
                            End If
                        
                    End Select
                    
                    ' if we're going to combine this event with userjoins ...
                    If ToDisplay Then
                        ' ... then set .displayed on the queue'd event so it is not displayed separately
                        userevent.Displayed = True
                        
                        ' also update in collection
                        UserObj.Queue.Remove I
                        UserObj.Queue.Add userevent, , , I - 1
                    End If
                    
                Next I
                
            End If
            
            ' display message
            frmChat.AddChat RTBColors.JoinText, "-- ", _
                IIf(AcqOps, RTBColors.TalkUsernameOp, RTBColors.JoinUsername), Username, _
                RTBColors.JoinUsername, " [" & Ping & "ms]", _
                RTBColors.JoinText, " has joined the channel using " & UserStats.ToString, _
                RTBColors.JoinUsername, IIf(AcqOps, " and acquired ops", vbNullString), RTBColors.JoinText, "."
                
            ' dispose user stats instance
            Set UserStats = Nothing
        End If
        
        ' add to user list
        AddName Username, Product, Flags, Ping, UserObj.Stats.IconCode, sClan
        
        ' update caption
        frmChat.lblCurrentChannel.Caption = frmChat.GetChannelString
        
        ' focus on channel tab
        frmChat.ListviewTabs_Click 0
        
        ' flash window
        If (frmChat.mnuFlash.Checked) Then
            FlashWindow
        End If
        
        ' update last seen info
        Call DoLastSeen(Username)
        
        ' check is banned
        isbanned = (UserObj.PendingBan)
        
        'frmChat.AddChat vbRed, IsBanned
        
        ' if not banned...
        If (isbanned = False) Then
            ''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
            ' Greet message
            ''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
    
            If (BotVars.UseGreet) Then
                ' ...
                If (LenB(BotVars.GreetMsg)) Then
                    ' ...
                    If ((StrComp(g_Channel.Name, "Clan SBs", vbTextCompare) <> 0) Or _
                        (IsStealthBotTech() = True)) Then
                        
                        ' ...
                        If (BotVars.WhisperGreet) Then
                            frmChat.AddQ "/w " & Username & _
                                Space$(1) & DoReplacements(BotVars.GreetMsg, Username, Ping)
                        Else
                            frmChat.AddQ DoReplacements(BotVars.GreetMsg, Username, Ping)
                        End If
                    End If
                End If
            End If
                
            ''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
            ' Botmail
            ''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
            
            If (mail) Then
                L = GetMailCount(Username)
                
                If (L > 0) Then
                    frmChat.AddQ "/w " & Username & " You have " & L & _
                        " new message" & IIf(L = 1, "", "s") & ". Type !inbox to retrieve."
                End If
            End If
        End If
            
        ' print their statstring, if desired
        If (MDebug("statstrings")) Then
            frmChat.AddChat RTBColors.ErrorMessageText, originalstatstring
        End If
        
        ''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
        ' call event script function
        ''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
        
        On Error Resume Next
        
        'frmChat.AddChat vbRed, frmChat.SControl.Error.Number
        
        RunInAll "Event_UserJoins", Username, Flags, UserObj.Stats.ToString, Ping, _
            Product, 0, originalstatstring, isbanned
    End If
    
    Exit Sub
    
ERROR_HANDLER:
    Call frmChat.AddChat(vbRed, "Error: " & Err.description & " in Event_UserJoins().")
    
    Exit Sub
End Sub

Public Sub Event_UserLeaves(ByVal Username As String, ByVal Flags As Long)
    On Error GoTo ERROR_HANDLER

    Dim UserObj   As clsUserObj
    
    Dim UserIndex As Integer
    Dim I         As Integer
    Dim ii        As Integer
    Dim Holder()  As Variant
    Dim pos       As Integer
    Dim bln       As Boolean
    
    ' ...
    UserIndex = _
        g_Channel.GetUserIndexEx(CleanUsername(Username))
    
    ' ...
    If (UserIndex > 0) Then
        ' ...
        If (g_Channel.Users(UserIndex).IsOperator) Then
            g_Channel.RemoveBansFromOperator Username
        End If
        
        ' ...
        If (g_Channel.Users(UserIndex).Queue.Count = 0) Then
            ' ...
            If (JoinMessagesOff = False) Then
                'If (GetVeto = False) Then
                    frmChat.AddChat RTBColors.JoinText, "-- ", _
                        IIf(g_Channel.Users(UserIndex).IsOperator, RTBColors.TalkUsernameOp, RTBColors.JoinUsername), g_Channel.Users(UserIndex).DisplayName, _
                        RTBColors.JoinText, " has left the channel."
                'End If
            End If
        End If
        
        g_Channel.Users.Remove UserIndex
    Else
        frmChat.AddChat vbRed, "Warning: We have received a leave event for a user that we didn't know " & _
                "was in the channel.  This may be indicative of a server split or other technical difficulty."
    
        Exit Sub
    End If
    
    ' ...
    If (StrComp(Username, g_Channel.OperatorHeir, vbTextCompare) = 0) Then
        ' ...
        g_Channel.OperatorHeir = vbNullString
        
        ' ...
        Call g_Channel.CheckUsers
    End If
    
    ' ...
    Username = convertUsername(Username)
    
    ' ...
    RemoveBanFromQueue Username
    
    ' ...
    pos = checkChannel(Username)
    
    ' ...
    If (pos > 0) Then
        ' ...
        If (frmChat.mnuFlash.Checked) Then
            FlashWindow
        End If
    
        ' ...
        With frmChat.lvChannel
            .ListItems.Remove pos

            .Refresh
        End With
        
        ' ...
        frmChat.lblCurrentChannel.Caption = frmChat.GetChannelString()
        
        ' ...
        frmChat.ListviewTabs_Click 0
        
        ''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
        ' call event script function
        ''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
        
        On Error Resume Next
        
        RunInAll "Event_UserLeaves", Username, Flags
    End If
    
    Exit Sub
    
ERROR_HANDLER:
    Call frmChat.AddChat(vbRed, "Error: " & Err.description & " in Event_UserLeaves().")
    
    Exit Sub
End Sub

Public Sub Event_UserTalk(ByVal Username As String, ByVal Flags As Long, ByVal Message As String, _
        ByVal Ping As Long, Optional QueuedEventID As Integer = 0)
    
    On Error GoTo ERROR_HANDLER
    
    Dim UserObj       As clsUserObj
    Dim UserEvent     As clsUserEventObj
    
    Dim strSend       As String
    Dim s             As String
    Dim U             As String
    Dim strCompare    As String
    Dim I             As Integer
    Dim ColIndex      As Integer
    Dim b             As Boolean
    Dim ToANSI        As String
    Dim BanningUser   As Boolean
    Dim UsernameColor As Long ' ...
    Dim TextColor     As Long ' ...
    Dim CaratColor    As Long ' ...
    Dim pos           As Integer
    Dim blnCheck      As Boolean
    
    ' ...
    pos = _
        g_Channel.GetUserIndexEx(CleanUsername(Username))
    
    ' ...
    If (pos > 0) Then
        ' ...
        Set UserObj = g_Channel.Users(pos)
        
        ' ...
        UserObj.LastTalkTime = UtcNow
        
        ' ...
        If (QueuedEventID = 0) Then
            ' ...
            If (UserObj.Queue.Count > 0) Then
                ' ...
                Set UserEvent = New clsUserEventObj
                
                ' ...
                With UserEvent
                    .EventID = ID_TALK
                    .Flags = Flags
                    .Ping = Ping
                    .Message = Message
                End With
                
                ' ...
                UserObj.Queue.Add UserEvent
            End If
        End If
    Else
        ' create new user object for invisible representatives...
        Set UserObj = New clsUserObj
        
        ' store user name
        UserObj.Name = Username
    End If
    
    ' convert user name
    Username = UserObj.DisplayName
    
    ' ...
    If (frmChat.mnuUTF8.Checked) Then
        ' ...
        ToANSI = UTF8Decode(Message)
        
        ' ...
        If (Len(ToANSI) > 0) Then
            Message = ToANSI
        End If
    End If
    
    ' ...
    If (QueuedEventID = 0) Then
        ' ...
        If (g_Channel.Self.IsOperator) Then
            ' ...
            If (GetSafelist(Username) = False) Then
                ' ...
                CheckMessage Username, Message
            End If
        End If
    End If
    
    ' ...
    If ((UserObj.Queue.Count = 0) Or (QueuedEventID > 0)) Then
        ' ...
        If (Message <> vbNullString) Then
            ' ...
            If (AllowedToTalk(Username, Message)) Then
                ' are we watching the user?
                'If (StrComp(WatchUser, Username, vbTextCompare) = 0) Then
                If (PrepareCheck(Username) Like PrepareCheck(WatchUser)) Then
                    ' ...
                    UsernameColor = RTBColors.ErrorMessageText
                    
                ' is user an operator?
                ElseIf ((Flags And USER_CHANNELOP&) = USER_CHANNELOP&) Then
                    ' ...
                    UsernameColor = RTBColors.TalkUsernameOp
                Else
                    ' ...
                    UsernameColor = RTBColors.TalkUsernameNormal
                End If
                
                ' ...
                If (((Flags And USER_BLIZZREP&) = USER_BLIZZREP&) Or ((Flags And USER_SYSOP&) = _
                        USER_SYSOP&)) Then
                        
                    ' ...
                    TextColor = RGB(97, 105, 255)
                    
                    ' ...
                    CaratColor = RGB(97, 105, 255)
                Else
                    ' ...
                    TextColor = RTBColors.TalkNormalText
                    
                    ' ...
                    CaratColor = RTBColors.Carats
                End If
                
                ' ...
                'If (GetVeto = False) Then
                    frmChat.AddChat CaratColor, "<", UsernameColor, Username, CaratColor, "> ", _
                        TextColor, Message
                'End If
                
                ' ...
                If (Catch(0) <> vbNullString) Then
                    CheckPhrase Username, Message, CPTALK
                End If
                    
                ' ...
                If (frmChat.mnuFlash.Checked) Then
                    FlashWindow
                End If
            End If
        End If
        
        ' ...
        If (VoteDuration > 0) Then
            ' ...
            If (InStr(1, LCase(Message), "yes", vbTextCompare) > 0) Then
                ' ...
                Call Voting(BVT_VOTE_ADD, BVT_VOTE_ADDYES, Username)
            ElseIf (InStr(1, LCase(Message), "no", vbTextCompare) > 0) Then
                ' ...
                Call Voting(BVT_VOTE_ADD, BVT_VOTE_ADDNO, Username)
            End If
        End If
        
        ' ...
        Call ProcessCommand(Username, Message, False, False)
        
        ''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
        ' call event script function
        ''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''

        On Error Resume Next
        
        ' ...
        If ((BotVars.NoSupportMultiCharTrigger) And (Len(BotVars.TriggerLong) > 1)) Then
            ' ...
            If (StrComp(Left$(Message, Len(BotVars.TriggerLong)), BotVars.TriggerLong, _
                    vbBinaryCompare) = 0) Then
                
                ' ...
                Message = BotVars.Trigger & Mid$(Message, Len(BotVars.TriggerLong) + 1)
            End If
        End If
    
        ' ...
        RunInAll "Event_UserTalk", Username, Flags, Message, Ping
    End If
    
    ' ...
    Exit Sub
    
ERROR_HANDLER:
    frmChat.AddChat vbRed, "Error (" & Err.Number & "): " & Err.description & " in Event_UserTalk()."
    
    Exit Sub
End Sub

Private Function CheckMessage(Username As String, Message As String) As Boolean
    
    Dim BanningUser As Boolean ' ...
    Dim I           As Integer ' ...
    
    ' ...
    If (PhraseBans) Then
        ' ...
        For I = LBound(Phrases) To UBound(Phrases)
            ' ...
            If ((Phrases(I) <> vbNullString) And (Phrases(I) <> Space$(1))) Then
                ' ...
                If ((InStr(1, Message, Phrases(I), vbTextCompare)) <> 0) Then
                    Ban Username & " Banned phrase: " & Phrases(I), _
                            (AutoModSafelistValue - 1)
                    
                    BanningUser = True
                    
                    Exit For
                End If
            End If
        Next I
    End If
    
    ' ...
    If (BanningUser = False) Then
        ' ...
        If (BotVars.QuietTime) Then
            ' ...
            Ban Username & " Quiet-time is enabled.", (AutoModSafelistValue - 1)
        Else
            ' ...
            If (BotVars.KickOnYell = 1) Then
                ' ...
                If (Len(Message) > 5) Then
                    ' ...
                    If (PercentActualUppercase(Message) > 90) Then
                        ' ...
                        Ban Username & " Yelling", (AutoModSafelistValue - 1), 1
                    End If
                End If
            End If
        End If
        
        ' ...
        If ((BotVars.QuietTime) Or (BotVars.KickOnYell = 1)) Then
            BanningUser = True
        End If
    End If
    
    ' ...
    CheckMessage = BanningUser
    
End Function

Public Sub Event_VersionCheck(Message As Long, ExtraInfo As String)
    'Dim L As Long

    Select Case (Message)
        Case 0:
            frmChat.AddChat RTBColors.SuccessText, "[BNET] Client version accepted!"
        
        Case 1:
            frmChat.AddChat RTBColors.ErrorMessageText, "[BNET] Version check failed! " & _
                "The version byte for this attempt was 0x" & Hex(GetVerByte(BotVars.Product)) & "."

            If (BotVars.BNLS) Then
                'Check the user has using BNLS server finder enabled
                If BotVars.UseAltBnls = True Then
                    LocatingAltBNLS = True
                    frmChat.sckBNet.Close
                    
                    Call frmChat.FindAltBNLS
                    Exit Sub
                ElseIf BotVars.UseAltBnls = False Then
                    frmChat.AddChat RTBColors.ErrorMessageText, "[BNET] BNLS has not been updated yet, " & _
                        "or you experienced an error. Try connecting again."
                        
                    If (askedBnls = False) Then
                        askedBnls = True
                    
                        'Ask the user if they would like to enable the BNLS Automatic Server finder
                        Dim msgResult As VbMsgBoxResult
                        msgResult = MsgBox("BNLS Server Error." & vbCrLf & vbCrLf & _
                                           "Would you like to enable the BNLS Automatic Server Finder?", _
                                           vbYesNo, "BNLS Error")
                        
                        'Save their answer to the config, and the call this procedure again to reevaluate what to do
                        WriteINI "Main", "UseAltBNLS", IIf(msgResult = vbYes, "Y", "N")
                        
                        If (msgResult = vbYes) Then
                            BotVars.UseAltBnls = True
                            
                            Call Event_VersionCheck(Message, ExtraInfo)
                        Else
                            BotVars.UseAltBnls = False
                        End If
                    End If
                End If
            Else
                frmChat.AddChat RTBColors.ErrorMessageText, "[BNET] Please ensure you " & _
                    "have updated your hash files using more current ones from the directory " & _
                        "of the game you're connecting with."
                
                frmChat.AddChat RTBColors.ErrorMessageText, "[BNET] In addition, you can try " & _
                    "choosing ""Update version bytes from StealthBot.net"" from the Bot menu."
                
                'Message = 0
            End If
        
        Case 2:
            frmChat.AddChat RTBColors.SuccessText, "[BNET] Version check passed!"
            
            frmChat.AddChat RTBColors.ErrorMessageText, "[BNET] Your CD-key is invalid!"
        
        Case 3:
            frmChat.AddChat RTBColors.ErrorMessageText, "[BNET] Version check failed! " & _
                "BNLS has not been updated yet.. Try reconnecting in an hour or two."
        
        Case 4:
            frmChat.AddChat RTBColors.SuccessText, "[BNET] Version check passed!"
            
            frmChat.AddChat RTBColors.ErrorMessageText, "[BNET] Your CD-key is for another game."
        
        Case 5:
            frmChat.AddChat RTBColors.SuccessText, "[BNET] Version check passed!"
            
            frmChat.AddChat RTBColors.ErrorMessageText, "[BNET] Your CD-key is banned. " & _
                "For more information, visit http://us.blizzard.com/support/article.xml?locale=en_US&articleId=20637 ."
        
        Case 6:
            frmChat.AddChat RTBColors.SuccessText, "[BNET] Version check passed!"
            
            frmChat.AddChat RTBColors.ErrorMessageText, "[BNET] Your CD-key is currently in " & _
                "use under the owner name: " & ExtraInfo & "."
        
        Case 7:
            frmChat.AddChat RTBColors.SuccessText, "[BNET] Version check passed!"
            
            frmChat.AddChat RTBColors.ErrorMessageText, "[BNET] Your expansion CD-key is invalid."
        
        Case 8:
            frmChat.AddChat RTBColors.SuccessText, "[BNET] Version check passed!"
            
            frmChat.AddChat RTBColors.ErrorMessageText, "[BNET] Your expansion CD-key is currently " & _
                "in use under the owner name: " & ExtraInfo & "."
        
        Case 9:
            frmChat.AddChat RTBColors.SuccessText, "[BNET] Version check passed!"
        
        Case 10:
            frmChat.AddChat RTBColors.SuccessText, "[BNET] Version check passed!"
            
            frmChat.AddChat RTBColors.ErrorMessageText, "[BNET] Your expansion CD-key is for the wrong game."
        
        Case Else
            frmChat.AddChat RTBColors.ErrorMessageText, "Unhandled 0x51 response! Value: " & Message
    End Select
    
    If (Message > 0) Then
        Call frmChat.DoDisconnect
    End If
End Sub

Public Sub Event_WhisperFromUser(ByVal Username As String, ByVal Flags As Long, ByVal Message As String, ByVal Ping As Long)
    'Dim s       As String
    Dim lCarats As Long
    Dim WWIndex As Integer
    Dim ToANSI  As String
    
    Username = convertUsername(Username)
    
    ' ...
    ToANSI = UTF8Decode(Message)
    
    ' ...
    If (Len(ToANSI) > 0) Then
        Message = ToANSI
    End If

    If (frmChat.mnuUTF8.Checked) Then
        Message = ToANSI
        
        If (Message = vbNullString) Then
            Exit Sub
        End If
    End If
    
    'If ((GetTickCount() - LastWhisperTime) > _
    '    BotVars.AutofilterMS) Then

    If (0 = 0) Then
        If (Not (CheckBlock(Username))) Then
            LastWhisper = Username
            LastWhisperFromTime = Now
            
        End If
        
        If (Catch(0) <> vbNullString) Then
            Call CheckPhrase(Username, Message, CPWHISPER)
        End If
        
        If (frmChat.mnuFlash.Checked) Then
            FlashWindow
        End If
        
        If (StrComp(Message, BotVars.ChannelPassword, vbTextCompare) = 0) Then
            lCarats = g_Channel.GetUserIndex(Username)
            
            If (lCarats > 0) Then
                ' ...
                With g_Channel.Users(lCarats)
                    .PassedChannelAuth = True
                End With
                
                frmChat.AddQ "/w " & Username & " Password accepted."
            End If
        End If
        
        If (VoteDuration > 0) Then
            If (InStr(1, Message, "yes", vbTextCompare) > 0) Then
                Call Voting(BVT_VOTE_ADD, BVT_VOTE_ADDYES, Username)
            ElseIf (InStr(Message, "no", vbTextCompare) > 0) Then
                Call Voting(BVT_VOTE_ADD, BVT_VOTE_ADDNO, Username)
            End If
        End If
                
        lCarats = RTBColors.WhisperCarats
        
        If (Flags And &H1) Then
            lCarats = COLOR_BLUE
        End If
        
        '####### Mail check
        If (mail) Then
            If (StrComp(Left$(Message, 6), "!inbox", vbTextCompare) = 0) Then
                Dim Msg As udtMail
                
                If (GetMailCount(Username) > 0) Then
                    Call GetMailMessage(Username, Msg)
                    
                    If (Len(RTrim(Msg.To)) > 0) Then
                        frmChat.AddQ "/w " & Username & " Message from " & _
                            RTrim$(Msg.From) & ": " & RTrim$(Msg.Message)
                    End If
                End If
            End If
        End If
        '#######
        
        If ((Not (CheckMsg(Message, Username, -5))) And (Not (CheckBlock(Username)))) Then
        
            If (Not (frmChat.mnuHideWhispersInrtbChat.Checked)) Then
                frmChat.AddChat lCarats, "<From ", RTBColors.WhisperUsernames, _
                    Username, lCarats, "> ", RTBColors.WhisperText, Message
            End If
            
            frmChat.AddWhisper lCarats, "<From ", RTBColors.WhisperUsernames, _
                Username, lCarats, "> ", RTBColors.WhisperText, Message
                
            frmChat.rtbWhispers.Visible = rtbWhispersVisible
                           
            If (frmChat.mnuToggleWWUse.Checked) Then
            'If ((frmChat.mnuToggleWWUse.Checked) And _
                '(frmChat.WindowState <> vbMinimized)) Then
                
                If (Not (IrrelevantWhisper(Message, Username))) Then
                    WWIndex = AddWhisperWindow(Username)
                    
                    With colWhisperWindows.Item(WWIndex)
                        If (.Shown = False) Then
                            'window was previously hidden
                            
                            ShowWW WWIndex
                        End If
                        
                        .Caption = "Whisper Window: " & Username
                        
                        .AddWhisper RTBColors.WhisperUsernames, "> " & Username, lCarats, _
                            ": ", RTBColors.WhisperText, Message
                    End With
                End If
            End If
        
            Call ProcessCommand(Username, Message, False, True)
        End If
        
        ''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
        ' call event script function
        ''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
        
        If BotIsClosing Then Exit Sub
        
        On Error Resume Next
        
        ' ...
        g_lastQueueUser = Username
        
        ' ...
        RunInAll "Event_WhisperFromUser", Username, Flags, Message, Ping
    End If
    
    LastWhisperTime = GetTickCount
End Sub

' Flags and ping are deliberately not used at this time
Public Sub Event_WhisperToUser(ByVal Username As String, ByVal Flags As Long, ByVal Message As String, ByVal Ping As Long)
    Dim WWIndex As Integer
    Dim ToANSI  As String
    
    ' ...
    ToANSI = UTF8Decode(Message)
    
    ' ...
    If (Len(ToANSI) > 0) Then
        Message = ToANSI
    End If
    
    'frmChat.AddChat vbRed, Username
    
    ' ...
    If (StrComp(Username, "your friends", vbTextCompare) <> 0) Then
        Username = convertUsername(Username)
        
        LastWhisperTo = Username
    Else
        LastWhisperTo = "%f%"
    End If

    If (Not (frmChat.mnuHideWhispersInrtbChat.Checked)) Then
        frmChat.AddChat RTBColors.WhisperCarats, "<To ", RTBColors.WhisperUsernames, _
            Username, RTBColors.WhisperCarats, "> ", RTBColors.WhisperText, Message
    End If
    
    If ((frmChat.mnuHideWhispersInrtbChat.Checked) Or _
        (frmChat.mnuToggleShowOutgoing.Checked)) Then
        
        frmChat.AddWhisper RTBColors.WhisperCarats, "<To ", RTBColors.WhisperUsernames, _
            Username, RTBColors.WhisperCarats, "> ", RTBColors.WhisperText, Message
    End If

    If (frmChat.mnuToggleWWUse.Checked) Then
        If ((InStr(1, Message, "�~�") = 0) And _
            (StrComp(Username, "your friends") <> 0)) Then
            
            WWIndex = AddWhisperWindow(Username)
            
            If (frmChat.WindowState <> vbMinimized) Then
                Call ShowWW(WWIndex)
            End If
            
            colWhisperWindows.Item(WWIndex).Caption = "Whisper Window: " & Username
            colWhisperWindows.Item(WWIndex).AddWhisper RTBColors.TalkBotUsername, "> " & _
                GetCurrentUsername, RTBColors.WhisperCarats, ": ", RTBColors.WhisperText, Message
        End If
    End If
    
    If (Not (rtbWhispersVisible)) Then
        If (frmChat.rtbWhispers.Visible = True) Then
            frmChat.rtbWhispers.Visible = False
        End If
    End If
End Sub

Public Function Event_AccountCreateResponse(ByVal Result As Long) As Boolean
    Dim Success As Boolean
    Dim sOut    As String
    
    Success = (Result = 0)
    
    Select Case (Result)
        Case 1, 6: sOut = "Your desired account name does not contain enough alphanumeric characters."
        Case 2:    sOut = "Your desired account name contains invalid characters."
        Case 3:    sOut = "Your desired account name contains a banned word."
        Case 4:    sOut = "Your desired account name already exists."
        Case Else: sOut = "Unknown response to 0x3D. Result code: " & Result
    End Select
    
    If (Success) Then
        frmChat.AddChat RTBColors.SuccessText, _
            "[BNET] Account created successfully!"
    Else
        frmChat.AddChat RTBColors.ErrorMessageText, _
            "There was an error in trying to create a new account."
        frmChat.AddChat RTBColors.ErrorMessageText, sOut
    End If
    
    Event_AccountCreateResponse = Success
End Function

Public Function Event_RealmStatusError(ByVal Status As Long)
    Select Case (Status)
        Case &H80000001:
            frmChat.AddChat RTBColors.ErrorMessageText, "[REALM] The Diablo II Realm is currently " & _
                "unavailable. Please try again later."
        Case &H80000002:
            frmChat.AddChat RTBColors.ErrorMessageText, "[REALM] Diablo II Realm logon has failed. " & _
                "Please try again later."
        Case Else:
            frmChat.AddChat RTBColors.ErrorMessageText, "[REALM] Login to the Diablo II Realm " & _
                "has failed for an unknown reason (0x" & ZeroOffset(Status, 8) & "). Please try again later."
    End Select
    
    RealmError = True
End Function

'11/22/07 - Hdx - Pass the channel listing (0x0B) directly off to scriptors for there needs. (What other use is there?)
Public Sub Event_ChannelList(sChannels() As String)
    Dim x As Integer
        
    If (MDebug("all")) Then
        frmChat.AddChat RTBColors.InformationText, "Received Channel List: "
    End If
    
    For x = 0 To UBound(sChannels)
        ' ...
        If (frmChat.mnuPublicChannels(0).Caption <> vbNullString) Then
            Call Load(frmChat.mnuPublicChannels(frmChat.mnuPublicChannels.Count))
        End If
        
        frmChat.mnuPublicChannels(frmChat.mnuPublicChannels.Count - 1).Caption = sChannels(x)
    Next x
    
    ''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
    ' call event script function
    ''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
    
    On Error Resume Next
    
    RunInAll "Event_ChannelList", ConvertStringArray(sChannels)
End Sub

Public Function CleanUsername(ByVal Username As String) As String
    
    Dim tmp As String  ' ...
    Dim pos As Integer ' ...
    
    ' ...
    tmp = Username
    
    ' ...
    If (tmp <> vbNullString) Then
        pos = InStr(1, tmp, "*", vbBinaryCompare)
    
        ' ...
        If (pos > 0) Then
            tmp = Mid$(tmp, pos + 1)
            
            ' ...
            If (Right$(tmp, 1) = ")") Then
                tmp = Left$(tmp, Len(tmp) - 1)
            End If
        End If
    End If

    ' ...
    CleanUsername = tmp
    
End Function

'Private Function GetDiablo2CharacterName(ByVal Username As String) As String
'
'    Dim tmp As String  ' ...
'    Dim Pos As Integer ' ...
'
'    ' ...
'    Pos = InStr(1, Username, "*", vbBinaryCompare)
'
'    ' ...
'    If (Pos > 0) Then
'        tmp = Mid$(Username, 1, Pos - 1)
'    End If
'
'    ' ...
'    GetDiablo2CharacterName = tmp
'
'End Function
