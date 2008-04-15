VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
  Persistable = 0  'NotPersistable
  DataBindingBehavior = 0  'vbNone
  DataSourceBehavior  = 0  'vbNone
  MTSTransactionMode  = 0  'NotAnMTSObject
END
Attribute VB_Name = "clsUserStats"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = True
Attribute VB_PredeclaredId = False
Attribute VB_Exposed = False
' clsUserStats.cls
' Copyright (C) 2008 Eric Evans
' ...

Option Explicit

Private m_stat_string     As String
Private m_game            As String
Private m_icon            As String
Private m_spawn           As Boolean
Private m_clan            As String
Private m_level           As Long
Private m_character_class As String
Private m_wins            As Long
Private m_ladder_rating   As Long
Private m_high_rating     As Long
Private m_ladder_rank     As Long
Private m_strength        As Long
Private m_dexterity       As Long
Private m_vitality        As Long
Private m_gold            As Long
Private m_magic           As Long
Private m_dots            As Long
Private m_expansion       As Boolean
Private m_hardcore        As Boolean
Private m_realm           As String

Public Property Let Game(str As String)

    ' ...
    m_game = str

End Property

Public Property Get Game() As String

    ' ...
    Game = m_game

End Property

Public Property Let Icon(str As String)

    ' ...
    m_icon = str

End Property

Public Property Get Icon() As String

    ' ...
    Icon = m_icon

End Property

Public Property Get Race() As String

    ' ...
    Icon = m_icon

End Property

Public Property Get RaceName() As String

    ' ...
    Icon = m_icon

End Property

Public Property Get Tier() As String

    ' ...

End Property

Public Property Get IconName() As String

    ' ...
    If ((Game = "WAR3") Or (Game = "W3XP")) Then
        ' ...
        Select Case (Mid$(Icon, 2, 1))
            Case "H" ' Human
                ' ...
                If (Game = "WAR3") Then
                    ' ...
                    Select Case (Val(Mid(Icon, 1, 1)))
                        Case 1: IconName = "peon"
                        Case 2: IconName = "footman"
                        Case 3: IconName = "knight"
                        Case 4: IconName = "Archmage"
                        Case 5: IconName = "Medivh"
                    End Select
                Else
                    ' ...
                    Select Case (Val(Mid(Icon, 1, 1)))
                        Case 1: IconName = "peon"
                        Case 2: IconName = "rifleman"
                        Case 3: IconName = "sorceress"
                        Case 4: IconName = "spellbreaker"
                        Case 5: IconName = "Blood Mage"
                        Case 6: IconName = "Jaina Proudmore"
                    End Select
                End If
            
            Case "N" ' Night Elf
                ' ...
                If (Game = "WAR3") Then
                    ' ...
                    Select Case (Val(Mid(Icon, 1, 1)))
                        Case 1: IconName = "peon"
                        Case 2: IconName = "archer"
                        Case 3: IconName = "druid of the claw"
                        Case 4: IconName = "Priestess of the Moon"
                        Case 5: IconName = "Furion"
                    End Select
                Else
                    ' ...
                    Select Case (Val(Mid(Icon, 1, 1)))
                        Case 1: IconName = "peon"
                        Case 2: IconName = "huntress"
                        Case 3: IconName = "druid of the talon"
                        Case 4: IconName = "dryad"
                        Case 5: IconName = "Keeper of the Grove"
                        Case 6: IconName = "Maiev"
                    End Select
                End If
                
            Case "U" ' Undead
                ' ...
                If (Game = "WAR3") Then
                    ' ...
                    Select Case (Val(Mid(Icon, 1, 1)))
                        Case 1: IconName = "peon"
                        Case 2: IconName = "ghoul"
                        Case 3: IconName = "abomination"
                        Case 4: IconName = "Lich"
                        Case 5: IconName = "Tichondrius"
                    End Select
                Else
                    ' ...
                    Select Case (Val(Mid(Icon, 1, 1)))
                        Case 1: IconName = "peon"
                        Case 2: IconName = "crypt fiend"
                        Case 3: IconName = "banshee"
                        Case 4: IconName = "destroyer"
                        Case 5: IconName = "Crypt Lord"
                        Case 6: IconName = "Sylvanas"
                    End Select
                End If
            
            Case "O" ' Orc
                ' ...
                If (Game = "WAR3") Then
                    ' ...
                    Select Case (Val(Mid(Icon, 1, 1)))
                        Case 1: IconName = "peon"
                        Case 2: IconName = "grunt"
                        Case 3: IconName = "tauren"
                        Case 4: IconName = "Far Seer"
                        Case 5: IconName = "Thrall"
                    End Select
                Else
                    ' ...
                    Select Case (Val(Mid(Icon, 1, 1)))
                        Case 1: IconName = "peon"
                        Case 2: IconName = "headhunter"
                        Case 3: IconName = "shaman"
                        Case 4: IconName = "Spirit Walker"
                        Case 5: IconName = "Shadow Hunter"
                        Case 6: IconName = "Rexxar"
                    End Select
                End If

            Case "R" ' Random
                ' ...
                If (Game = "WAR3") Then
                    ' ...
                    Select Case (Val(Mid(Icon, 1, 1)))
                        Case 1: IconName = "peon"
                        Case 2: IconName = "dragon whelp"
                        Case 3: IconName = "blue dragon"
                        Case 4: IconName = "red dragon"
                        Case 5: IconName = "Deathwing"
                    End Select
                Else
                    ' ...
                    Select Case (Val(Mid(Icon, 1, 1)))
                        Case 1: IconName = "peon"
                        Case 2: IconName = "myrmidon"
                        Case 3: IconName = "siren"
                        Case 4: IconName = "dragon turtle"
                        Case 5: IconName = "sea witch"
                        Case 6: IconName = "Illidan"
                    End Select
                End If

            Case "D" ' Tournament
                ' ...
                If (Game = "W3XP") Then
                    ' ...
                    Select Case (Val(Mid(Icon, 1, 1)))
                        Case 1: IconName = "peon"
                        Case 2: IconName = "Felguard"
                        Case 3: IconName = "infernal"
                        Case 4: IconName = "doomguard"
                        Case 5: IconName = "pit lord"
                        Case 6: IconName = "Archimonde"
                    End Select
                End If
        End Select
    Else

    End If

End Property

Public Property Let Statstring(str As String)

    ' ...
    If (Len(str) < 6) Then
        Exit Property
    End If

    ' ...
    Game = StrReverse$(Left$(str, 4))

    ' ...
    m_stat_string = Mid$(str, 6)

    ' ...
    Call Parse

End Property

Public Property Get Statstring() As String

    ' ...
    Statstring = m_stat_string

End Property

Public Property Get IsSpawn() As Boolean

    ' ...
    IsSpawn = m_spawn

End Property

Public Property Let IsSpawn(bln As Boolean)

    ' ...
    m_spawn = bln

End Property

Public Property Get Clan() As String

    ' ...
    Clan = m_clan

End Property

Public Property Let Clan(str As String)

    ' ...
    m_clan = str

End Property

Public Property Get Wins() As Long

    ' ...
    Wins = m_wins

End Property

Public Property Let Wins(lng As Long)

    ' ...
    m_wins = lng

End Property

Public Property Get LadderRating() As Long

    ' ...
    LadderRating = m_ladder_rating

End Property

Public Property Let LadderRating(lng As Long)

    ' ...
    m_ladder_rating = lng

End Property

Public Property Get HighLadderRating() As Long

    ' ...
    HighLadderRating = m_high_rating

End Property

Public Property Let HighLadderRating(lng As Long)

    ' ...
    m_high_rating = lng

End Property

Public Property Get LadderRank() As Long

    ' ...
    LadderRank = m_ladder_rank

End Property

Public Property Let LadderRank(lng As Long)

    ' ...
    m_ladder_rank = lng

End Property

Public Property Get Level() As Long

    ' ...
    Level = m_level

End Property

Public Property Let Level(lng As Long)

    ' ...
    m_level = lng

End Property

Public Property Get CharacterClass() As String

    ' ...
    CharacterClass = m_character_class

End Property

Public Property Let CharacterClass(str As String)

    ' ...
    m_character_class = str

End Property

Public Property Get IsHardcoreCharacter() As Boolean

    ' ...
    IsHardcoreCharacter = m_hardcore

End Property

Public Property Let IsHardcoreCharacter(bln As Boolean)

    ' ...
    m_hardcore = bln

End Property

Public Property Get IsExpansionCharacter() As Boolean

    ' ...
    IsExpansionCharacter = m_expansion

End Property

Public Property Let IsExpansionCharacter(bln As Boolean)

    ' ...
    m_expansion = bln

End Property

Public Property Get Dots() As Long

    ' ...
    Dots = m_dots

End Property

Public Property Let Dots(lng As Long)

    ' ...
    m_dots = lng

End Property

Public Property Get Strength() As Long

    ' ...
    Strength = m_strength

End Property

Public Property Let Strength(lng As Long)

    ' ...
    m_strength = lng

End Property

Public Property Get Magic() As Long

    ' ...
    Magic = m_magic

End Property

Public Property Let Magic(lng As Long)

    ' ...
    m_magic = lng

End Property

Public Property Get Gold() As Long

    ' ...
    Gold = m_gold

End Property

Public Property Let Gold(lng As Long)

    ' ...
    m_gold = lng

End Property

Public Property Get Dexterity() As Long

    ' ...
    Dexterity = m_dexterity

End Property

Public Property Let Dexterity(lng As Long)

    ' ...
    m_dexterity = lng

End Property

Public Property Get Vitality() As Boolean

    ' ...
    Vitality = m_vitality

End Property

Public Property Let Vitality(bln As Boolean)

    ' ...
    m_vitality = bln

End Property

Public Property Get Realm() As String

    ' ...
    Realm = m_realm

End Property

Public Property Let Realm(str As String)

    ' ...
    m_realm = str

End Property

Public Property Get ToString() As String

    ' ...

End Property

Private Sub Parse()

    ' ...
    If (Statstring = vbNullString) Then
        Exit Sub
    End If

    ' ...
    Select Case (Game)
        ' ...
        Case "SSHR", "STAR", "JSTR", "SEXP"
            Call ParseStarCraft
            
        ' ...
        Case "DSHR", "DRTL"
            Call ParseDiablo
            
        ' ...
        Case "D2DV", "D2XP"
            Call ParseDiabloII
            
        ' ...
        Case "W2BN"
            Call ParseWarCraftII
        
        ' ...
        Case "WAR3", "W3XP"
            Call ParseWarCraftIII
    End Select

End Sub

Private Sub ParseStarCraft()

    Dim values() As String ' ...

    ' ...
    values() = Split(Statstring, Space$(1))
    
    ' ...
    If (UBound(values) < 7) Then
        Exit Sub
    End If
            
    ' ....
    LadderRating = Val(values(0))
    LadderRank = Val(values(1))
    Wins = Val(values(2))
    IsSpawn = CBool(values(3))
    LadderRank = Val(values(5))
    Icon = values(8)

End Sub

Private Sub ParseDiablo()

    Dim values() As String ' ...

    ' ...
    values() = Split(Statstring, Space$(1))
    
    ' ...
    If (UBound(values) < 7) Then
        Exit Sub
    End If
    
    ' ...
    Level = Val(values(0))
    CharacterClass = Val(values(1))
    Dots = Val(values(2))
    Strength = Val(values(3))
    Magic = Val(values(4))
    Dexterity = Val(values(5))
    Vitality = Val(values(6))
    Gold = Val(values(7))
    
End Sub

Private Sub ParseDiabloII()

    Dim values() As String ' ...

    ' ...
    values() = Split(Statstring, Space$(1))

End Sub

Private Sub ParseWarCraftII()

    ' ...
    Call ParseStarCraft

End Sub

Private Sub ParseWarCraftIII()

    Dim values() As String ' ...

    ' ...
    values() = Split(Statstring, Space$(1))
    
    ' ...
    If (UBound(values) < 1) Then
        Exit Sub
    End If
    
    ' ...
    Icon = values(0)
    Level = Val(values(1))
    
    ' ...
    If (UBound(values) > 1) Then
        Clan = StrReverse$(values(2))
    End If

End Sub