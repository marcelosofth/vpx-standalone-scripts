' ***********************************************************************
'               VISUAL PINBALL X EM Script by JPSalas
'                  Basic EM script up to 4 players
'		          uses core.vbs for extra functions
'       Seven Winner / IPD No. 4407 / INDER 1973 / 1 Player
' ***********************************************************************

Option Explicit
Randomize
'
' DOF config - Swietlikowa - Outhere - leeoneil
'
' Option for more lights effects with DOF (Undercab effects on bumpers and slingshots) 
' "True" to activate (False by default)
Const Epileptikdof = False
'
' Flippers L/R - 101/102
' Slingshot L/R - 103/104
' Bumpers L/R - 105/106
' Targets L/R - 114/115
' Kickers - 107
' Knocker - 108
' BallRelease - 110 
' Chimes - 111/112/113
'
' LED backboard
' Flasher Outside Left - 203/214/216/220/225/240/250
' Flasher left - 212/213/217/221/227/240/250
' Flasher center - 207/222/226/240/250
' Flasher right - 208/209/210/218/223/227/240/250
' Flasher Outside - 205/211/215/219/224/240/250
' Flashers MX L/R - 204/206
' Start Button - 200
' Undercab - 201/202
' Strobe - 230



' core.vbs constants
Const BallSize = 50  ' 50 is the normal size
Const BallMass = 1   ' 1 is the normal ball mass.

' load extra vbs files
LoadCoreFiles

Sub LoadCoreFiles
    On Error Resume Next
    ExecuteGlobal GetTextFile("core.vbs")
    If Err Then MsgBox "Can't open core.vbs"
    On Error Resume Next
    ExecuteGlobal GetTextFile("controller.vbs")
    If Err Then MsgBox "Can't open controller.vbs"
End Sub

' Valores Constants
Const cGameName = "sevenwinner" ' B2S name
Const MaxPlayers = 1        ' 1 to 4 can play
Const MaxMultiplier = 2     ' limit bonus multiplier
Const BallsPerGame = 3      ' 3 or 5
Const FreePlay = False      ' Free play or coins
Const Special1 = 69000      ' extra ball or credit
Const Special2 = 81000
Const Special3 = 99000

' Global variables
Dim PlayersPlayingGame
Dim CurrentPlayer
Dim Credits
Dim Bonus
Dim BallsRemaining(4)
Dim BonusMultiplier
Dim ExtraBallsAwards(4)
Dim Special1Awarded(4)
Dim Special2Awarded(4)
Dim Special3Awarded(4)
Dim Score(4)
Dim HighScore
Dim Match
Dim Tilt
Dim TiltSensitivity
Dim Tilted
Dim Add10
Dim Add100
Dim Add1000
Dim x

' Control variables
Dim BallsOnPlayfield

' Boolean variables
Dim bAttractMode
Dim bFreePlay
Dim bGameInPlay
Dim bOnTheFirstBall
Dim bExtraBallWonThisBall
Dim bJustStarted
Dim bBallInPlungerLane
Dim bBallSaverActive

' core.vbs variables

' *********************************************************************
'                Common rutines to all the tables
' *********************************************************************

Sub Table1_Init()
    Dim x

    ' Init som objects, like walls, targets
    VPObjects_Init
    LoadEM

    ' load highscore
    Loadhs
    ScoreReel1.SetValue HSScore(1)
    If B2SOn then
        Controller.B2SSetScorePlayer 1, HSScore(1)
    End If
    UpdateCredits

    ' init all the global variables
    bFreePlay = FreePlay
    bAttractMode = False
    bOnTheFirstBall = False
    bGameInPlay = False
    bBallInPlungerLane = False
    BallsOnPlayfield = 0
    Tilt = 0
    TiltSensitivity = 6
    Tilted = False
    Match = 0
    bJustStarted = True
    Add10 = 0
    Add100 = 0
    Add1000 = 0

    ' setup table in game over mode
    EndOfGame

    'turn on GI lights
    vpmtimer.addtimer 1000, "GiOn '"

    ' Remove desktop items in FS mode
    If Table1.ShowDT then
        For each x in aReels
            x.Visible = 1
        Next
    Else
        For each x in aReels
            x.Visible = 0
        Next
    End If

    ' Start the RealTime timer
    RealTime.Enabled = 1

    ' Load table color
    LoadLut
End Sub

'******
' Keys
'******

Sub Table1_KeyDown(ByVal Keycode)

    If EnteringInitials then
        CollectInitials(keycode)
        Exit Sub
    End If

    If keycode = LeftMagnaSave Then bLutActive = True: Lutbox.text = "level of darkness " & LUTImage + 1
    If keycode = RightMagnaSave Then
        If bLutActive Then NextLUT:End If
    End If

    ' add coins
    If Keycode = AddCreditKey Then
        If(Tilted = False)Then
            AddCredits 1
            PlaySound "fx_coin"
            DOF 200, DOFOn
        End If
    End If

    ' plunger
    If keycode = PlungerKey Then
        Plunger.Pullback
        PlaySoundAt "fx_plungerpull", plunger
    End If

    ' tilt keys
    If keycode = LeftTiltKey Then Nudge 90, 8:PlaySound "fx_nudge", 0, 1, -0.1, 0.25:CheckTilt
    If keycode = RightTiltKey Then Nudge 270, 8:PlaySound "fx_nudge", 0, 1, 0.1, 0.25:CheckTilt
    If keycode = CenterTiltKey Then Nudge 0, 9:PlaySound "fx_nudge", 0, 1, 1, 0.25:CheckTilt

    ' keys during game

    If bGameInPlay AND NOT Tilted Then
        If keycode = LeftFlipperKey Then SolLFlipper 1
        If keycode = RightFlipperKey Then SolRFlipper 1

        If keycode = StartGameKey Then
            If((PlayersPlayingGame < MaxPlayers)AND(bOnTheFirstBall = True))Then

                If(bFreePlay = True)Then
                    PlayersPlayingGame = PlayersPlayingGame + 1
                'PlayersReel.SetValue, PlayersPlayingGame
                'PlaySound "so_fanfare1"
                Else
                    If(Credits > 0)then
                        PlayersPlayingGame = PlayersPlayingGame + 1
                        Credits = Credits - 1
                        UpdateCredits
                        UpdateBallInPlay
                    Else
                    DOF 200, DOFOff
                    ' Not Enough Credits to start a game.
                    'PlaySound "so_nocredits"
                    End If
                End If
            End If
        End If
        Else

            If keycode = StartGameKey Then
                If(bFreePlay = True)Then
                    If(BallsOnPlayfield = 0)Then
                        ResetScores
                        ResetForNewGame()
                    End If
                Else
                    If(Credits > 0)Then
                        If(BallsOnPlayfield = 0)Then
                            Credits = Credits - 1
                            UpdateCredits
                            ResetScores
                            ResetForNewGame()
                        End If
                    Else
                    DOF 200, DOFOff
                    ' Not Enough Credits to start a game.
                    'PlaySound "so_nocredits"
                    End If
                End If
            End If
    End If ' If (GameInPlay)
End Sub

Sub Table1_KeyUp(ByVal keycode)

    If EnteringInitials then
        Exit Sub
    End If

    If keycode = LeftMagnaSave Then bLutActive = False: LutBox.text = ""

    If bGameInPlay AND NOT Tilted Then
        ' teclas de los flipers
        If keycode = LeftFlipperKey Then SolLFlipper 0
        If keycode = RightFlipperKey Then SolRFlipper 0
    End If

    If keycode = PlungerKey Then
        Plunger.Fire
        If bBallInPlungerLane Then
            PlaySoundAt "fx_plunger", plunger
        Else
            PlaySoundAt "fx_plunger_empty", plunger
        End If
    End If
End Sub

'******************
' Table stop/pause
'******************

Sub table1_Paused
End Sub

Sub table1_unPaused
End Sub

Sub table1_Exit
    Savehs
'Controller.Stop
End Sub

'********************
'     Flippers
'********************

Sub SolLFlipper(Enabled)
    If Enabled Then
        PlaySoundAt SoundFXDOF ("fx_flipperup", 101, DOFOn, DOFFlippers), LeftFlipper
        LeftFlipper.EOSTorque = 0.65:LeftFlipper.RotateToEnd
    Else
        PlaySoundAt SoundFXDOF ("fx_flipperdown", 101, DOFOff, DOFFlippers), LeftFlipper
        LeftFlipper.EOSTorque = 0.15:LeftFlipper.RotateToStart
    End If
End Sub

Sub SolRFlipper(Enabled)
    If Enabled Then
        PlaySoundAt SoundFXDOF ("fx_flipperup", 102, DOFOn, DOFFlippers), RightFlipper
        RightFlipper.EOSTorque = 0.65:RightFlipper.RotateToEnd
    Else
        PlaySoundAt SoundFXDOF ("fx_flipperdown", 102, DOFOff, DOFFlippers), RightFlipper
        RightFlipper.EOSTorque = 0.15:RightFlipper.RotateToStart
    End If
End Sub

' flippers hit Sound

Sub LeftFlipper_Collide(parm)
    PlaySound "fx_rubber_flipper", 0, Vol(ActiveBall), pan(ActiveBall), 0, Pitch(ActiveBall), 0, 0, AudioFade(ActiveBall)
End Sub

Sub RightFlipper_Collide(parm)
    PlaySound "fx_rubber_flipper", 0, Vol(ActiveBall), pan(ActiveBall), 0, Pitch(ActiveBall), 0, 0, AudioFade(ActiveBall)
End Sub

'***********
' GI lights
'***********

Sub GiOn 'enciende las luces GI
    Dim bulb
    DOF 201, DOFOn
	PlaySound"fx_gion"
    For each bulb in aGiLights
        bulb.State = 1
    Next
End Sub

Sub GiOff 'apaga las luces GI
    Dim bulb
    DOF 201, DOFOff
	PlaySound"fx_gioff"
    For each bulb in aGiLights
        bulb.State = 0
    Next
End Sub

'**************
'    TILT
'**************

Sub CheckTilt
    Tilt = Tilt + TiltSensitivity
    TiltDecreaseTimer.Enabled = True
    If Tilt > 15 Then
        Tilted = True
        TiltReel.SetValue 1
        If B2SOn then
            Controller.B2SSetTilt 1
        end if
        DisableTable True
        ' BallsRemaining(CurrentPlayer) = 0 'player looses the game
        TiltRecoveryTimer.Enabled = True 'wait for all the balls to drain
    End If
End Sub

Sub TiltDecreaseTimer_Timer
    If Tilt > 0 Then
        Tilt = Tilt - 0.1
    Else
        TiltDecreaseTimer.Enabled = False
    End If
End Sub

Sub DisableTable(Enabled)
    If Enabled Then
        GiOff
        LeftFlipper.RotateToStart
        RightFlipper.RotateToStart
        DOF 101, DOFOff
        DOF 102, DOFOff
        Bumper001.Threshold = 100
        Bumper002.Threshold = 100
        LeftSlingshot.Disabled = 1
        RightSlingshot.Disabled = 1
    Else
        GiOn
        Bumper001.Threshold = 1
        Bumper002.Threshold = 1
        LeftSlingshot.Disabled = 0
        RightSlingshot.Disabled = 0
    End If
End Sub

Sub TiltRecoveryTimer_Timer()
    ' all the balls have drained
    If(BallsOnPlayfield = 0)Then
        EndOfBall()
        TiltRecoveryTimer.Enabled = False
    End If
' otherwise repeat
End Sub

'***************************************************************
'             Supporting Ball & Sound Functions v4.0
'***************************************************************

Dim TableWidth, TableHeight

TableWidth = Table1.width
TableHeight = Table1.height

Function Vol(ball) ' Calculates the Volume of the sound based on the ball speed
    Vol = Csng(BallVel(ball) ^2 / 2000)
End Function

Function Pan(ball) ' Calculates the pan for a ball based on the X position on the table. "table1" is the name of the table
    Dim tmp
    tmp = ball.x * 2 / TableWidth-1
    If tmp > 0 Then
        Pan = Csng(tmp ^10)
    Else
        Pan = Csng(-((- tmp) ^10))
    End If
End Function

Function Pitch(ball) ' Calculates the pitch of the sound based on the ball speed
    Pitch = BallVel(ball) * 20
End Function

Function BallVel(ball) 'Calculates the ball speed
    BallVel = (SQR((ball.VelX ^2) + (ball.VelY ^2)))
End Function

Function AudioFade(ball) 'only on VPX 10.4 and newer
    Dim tmp
    tmp = ball.y * 2 / TableHeight-1
    If tmp > 0 Then
        AudioFade = Csng(tmp ^10)
    Else
        AudioFade = Csng(-((- tmp) ^10))
    End If
End Function

Sub PlaySoundAt(soundname, tableobj) 'play sound at X and Y position of an object, mostly bumpers, flippers and other fast objects
    PlaySound soundname, 0, 1, Pan(tableobj), 0.2, 0, 0, 0, AudioFade(tableobj)
End Sub

Sub PlaySoundAtBall(soundname) ' play a sound at the ball position, like rubbers, targets, metals, plastics
    PlaySound soundname, 0, Vol(ActiveBall), pan(ActiveBall), 0.2, Pitch(ActiveBall) * 10, 0, 0, AudioFade(ActiveBall)
End Sub

Function RndNbr(n) 'returns a random number between 1 and n
    Randomize timer
    RndNbr = Int((n * Rnd) + 1)
End Function

'***********************************************
'   JP's VP10 Rolling Sounds + Ballshadow v4.0
'   uses a collection of shadows, aBallShadow
'***********************************************

Const tnob = 19   'total number of balls
Const lob = 0     'number of locked balls
Const maxvel = 28 'max ball velocity
ReDim rolling(tnob)
InitRolling

Sub InitRolling
    Dim i
    For i = 0 to tnob
        rolling(i) = False
    Next
End Sub

Sub RollingUpdate()
    Dim BOT, b, ballpitch, ballvol, speedfactorx, speedfactory
    BOT = GetBalls

    ' stop the sound of deleted balls
    For b = UBound(BOT) + 1 to tnob
        rolling(b) = False
        StopSound("fx_ballrolling" & b)
        aBallShadow(b).Y = 3000
    Next

    ' exit the sub if no balls on the table
    If UBound(BOT) = lob - 1 Then Exit Sub 'there no extra balls on this table

    ' play the rolling sound for each ball and draw the shadow
    For b = lob to UBound(BOT)
        aBallShadow(b).X = BOT(b).X
        aBallShadow(b).Y = BOT(b).Y
        aBallShadow(b).Height = BOT(b).Z -Ballsize/2

        If BallVel(BOT(b))> 1 Then
            If BOT(b).z <30 Then
                ballpitch = Pitch(BOT(b))
                ballvol = Vol(BOT(b))
            Else
                ballpitch = Pitch(BOT(b)) + 50000 'increase the pitch on a ramp
                ballvol = Vol(BOT(b)) * 10
            End If
            rolling(b) = True
            PlaySound("fx_ballrolling" & b), -1, ballvol, Pan(BOT(b)), 0, ballpitch, 1, 0, AudioFade(BOT(b))
        Else
            If rolling(b) = True Then
                StopSound("fx_ballrolling" & b)
                rolling(b) = False
            End If
        End If

        ' rothbauerw's Dropping Sounds
        If BOT(b).VelZ <-1 and BOT(b).z <55 and BOT(b).z> 27 Then 'height adjust for ball drop sounds
            PlaySound "fx_balldrop", 0, ABS(BOT(b).velz) / 17, Pan(BOT(b)), 0, Pitch(BOT(b)), 1, 0, AudioFade(BOT(b))
        End If

        ' jps ball speed control
        If BOT(b).VelX AND BOT(b).VelY <> 0 Then
            speedfactorx = ABS(maxvel / BOT(b).VelX)
            speedfactory = ABS(maxvel / BOT(b).VelY)
            If speedfactorx <1 Then
                BOT(b).VelX = BOT(b).VelX * speedfactorx
                BOT(b).VelY = BOT(b).VelY * speedfactorx
            End If
            If speedfactory <1 Then
                BOT(b).VelX = BOT(b).VelX * speedfactory
                BOT(b).VelY = BOT(b).VelY * speedfactory
            End If
        End If
    Next
End Sub

'*****************************
' Ball 2 Ball Collision Sound
'*****************************

Sub OnBallBallCollision(ball1, ball2, velocity)
    PlaySound("fx_collide"), 0, Csng(velocity) ^2 / 2000, Pan(ball1), 0, Pitch(ball1), 0, 0, AudioFade(ball1)
End Sub

'************************************
' Diverse Collection Hit Sounds v3.0
'************************************

Sub aMetals_Hit(idx):PlaySoundAtBall "fx_MetalHit":End Sub
Sub aMetalWires_Hit(idx):PlaySoundAtBall "fx_MetalWire":End Sub
Sub aRubber_Bands_Hit(idx):PlaySoundAtBall "fx_rubber_band":End Sub
Sub aRubber_LongBands_Hit(idx):PlaySoundAtBall "fx_rubber_longband":End Sub
Sub aRubber_Posts_Hit(idx):PlaySoundAtBall "fx_rubber_post":End Sub
Sub aRubber_Pins_Hit(idx):PlaySoundAtBall "fx_rubber_pin":End Sub
Sub aRubber_Pegs_Hit(idx):PlaySoundAtBall "fx_rubber_peg":End Sub
Sub aPlastics_Hit(idx):PlaySoundAtBall "fx_PlasticHit":End Sub
Sub aGates_Hit(idx):PlaySoundAtBall "fx_Gate":End Sub
Sub aWoods_Hit(idx):PlaySoundAtBall "fx_Woodhit":End Sub

'************************************************************************************************************************
' Only for VPX 10.2 and higher.
' FlashForMs will blink light or a flasher for TotalPeriod(ms) at rate of BlinkPeriod(ms)
' When TotalPeriod done, light or flasher will be set to FinalState value where
' Final State values are:   0=Off, 1=On, 2=Return to previous State
'************************************************************************************************************************

Sub FlashForMs(MyLight, TotalPeriod, BlinkPeriod, FinalState)
    If TypeName(MyLight) = "Light" Then
        If FinalState = 2 Then
            FinalState = MyLight.State
        End If
        MyLight.BlinkInterval = BlinkPeriod
        MyLight.Duration 2, TotalPeriod, FinalState
    ElseIf TypeName(MyLight) = "Flasher" Then
        Dim steps
        steps = Int(TotalPeriod / BlinkPeriod + .5)
        If FinalState = 2 Then
            FinalState = ABS(MyLight.Visible)
        End If
        MyLight.UserValue = steps * 10 + FinalState
        MyLight.TimerInterval = BlinkPeriod
        MyLight.TimerEnabled = 0
        MyLight.TimerEnabled = 1
        ExecuteGlobal "Sub " & MyLight.Name & "_Timer:" & "Dim tmp, steps, fstate:tmp=me.UserValue:fstate = tmp MOD 10:steps= tmp\10 -1:Me.Visible = steps MOD 2:me.UserValue = steps *10 + fstate:If Steps = 0 then Me.Visible = fstate:Me.TimerEnabled=0:End if:End Sub"
    End If
End Sub

'****************************************
' Init table for a new game
'****************************************

Sub ResetForNewGame()
    'debug.print "ResetForNewGame"
    Dim i

    bGameInPLay = True
    bBallSaverActive = False

    StopAttractMode
    If B2SOn then
        Controller.B2SSetGameOver 0
    end if

    GiOn
    DOF 250, DOFPulse
    CurrentPlayer = 1
    PlayersPlayingGame = 1
    bOnTheFirstBall = True
    For i = 1 To MaxPlayers
        Score(i) = 0
        ExtraBallsAwards(i) = 0
        Special1Awarded(i) = False
        Special2Awarded(i) = False
        Special3Awarded(i) = False
        BallsRemaining(i) = BallsPerGame
    Next
    BonusMultiplier = 1
    Bonus = 0
    UpdateBallInPlay

    Clear_Match

    ' init other variables
    Tilt = 0

    ' init game variables
    Game_Init()

    ' start a music?
    ' first ball
    vpmtimer.addtimer 2000, "FirstBall '"
End Sub

Sub FirstBall
    'debug.print "FirstBall"
    ' reset table for a new ball, rise droptargets ++
    ResetForNewPlayerBall()
    CreateNewBall()
    If Credits = 0 Then DOF 200, DOFOff End If
End Sub

' (Re-)init table for a new ball or player

Sub ResetForNewPlayerBall()
    'debug.print "ResetForNewPlayerBall"
    AddScore 0

    ' reset multiplier to 1x

    ' turn on lights, and variables
    bExtraBallWonThisBall = False
    ResetNewBallLights
    ResetNewBallVariables
End Sub

' Crete new ball

Sub CreateNewBall()
    BallRelease.CreateSizedBallWithMass BallSize / 2, BallMass
    BallsOnPlayfield = BallsOnPlayfield + 1
    UpdateBallInPlay
    PlaySoundAt SoundFXDOF ("fx_Ballrel", 110, DOFPulse, DOFContactors), BallRelease
    If Epileptikdof = True Then DOF 228, DOFPulse End If
    BallRelease.Kick 90, 4
End Sub

' player lost the ball

Sub EndOfBall()
    'debug.print "EndOfBall"
    Dim AwardPoints, TotalBonus, ii
    AwardPoints = 0
    TotalBonus = 0
    ' Lost the first ball, now it cannot accept more players
    bOnTheFirstBall = False

    'No bonus in this table

    ' add bonus if no tilt
    ' tilt system will take care of the next ball

    'If NOT Tilted AND LightShootAgain.State Then
    'If NOT Tilted Then
    '    Select Case BonusMultiplier
    '        Case 1:BonusCountTimer.Interval = 250
    '        Case 2:BonusCountTimer.Interval = 400
    '        Case 3:BonusCountTimer.Interval = 550
    '    End Select
    '    BonusCountTimer.Enabled = 1
    'Else
    vpmtimer.addtimer 400, "EndOfBall2 '"
'End If
End Sub

Sub BonusCountTimer_Timer
    'debug.print "BonusCount_Timer"
    If Bonus > 0 Then
        Bonus = Bonus -1
        AddScore 1000 * BonusMultiplier
        UpdateBonusLights
    Else
        BonusCountTimer.Enabled = 0
        vpmtimer.addtimer 1000, "EndOfBall2 '"
    End If
End Sub

Sub UpdateBonusLights
    Select Case Bonus
        Case 0:bl1.State = 1:bl2.State = 0:bl2a.State = 0:bl3.State = 0:bl3a.State = 0:bl4.State = 0:bl4a.State = 0:bl5.State = 0:bl5a.State = 0:bl5k.State = 0:bl10k.State = 0:bl15k.State = 0:bl20k.State = 0:SpecialL1.State = 0
        Case 1:bl1.State = 0:bl2.State = 10:bl2a.State = 1:bl3.State = 0:bl3a.State = 0:bl4.State = 0:bl4a.State = 0:bl5.State = 0:bl5a.State = 0:bl5k.State = 0:bl10k.State = 0:bl15k.State = 0:bl20k.State = 0:SpecialL1.State = 0
        Case 2:bl1.State = 0:bl2.State = 0:bl2a.State = 0:bl3.State = 1:bl3a.State = 1:bl4.State = 0:bl4a.State = 0:bl5.State = 0:bl5a.State = 0:bl5k.State = 0:bl10k.State = 0:bl15k.State = 0:bl20k.State = 0:SpecialL1.State = 0
        Case 3:bl1.State = 0:bl2.State = 0:bl2a.State = 0:bl3.State = 0:bl3a.State = 0:bl4.State = 1:bl4a.State = 1:bl5.State = 0:bl5a.State = 0:bl5k.State = 0:bl10k.State = 0:bl15k.State = 0:bl20k.State = 0:SpecialL1.State = 0
        Case 4:bl1.State = 0:bl2.State = 0:bl2a.State = 0:bl3.State = 0:bl3a.State = 0:bl4.State = 0:bl4a.State = 0:bl5.State = 1:bl5a.State = 1:bl5k.State = 0:bl10k.State = 0:bl15k.State = 0:bl20k.State = 0:SpecialL1.State = 0
        Case 5:bl1.State = 1:bl2.State = 0:bl2a.State = 0:bl3.State = 0:bl3a.State = 0:bl4.State = 0:bl4a.State = 0:bl5.State = 0:bl5a.State = 0:bl5k.State = 1:bl10k.State = 0:bl15k.State = 0:bl20k.State = 0:SpecialL1.State = 0
        Case 6:bl1.State = 0:bl2.State = 1:bl2a.State = 1:bl3.State = 0:bl3a.State = 0:bl4.State = 0:bl4a.State = 0:bl5.State = 0:bl5a.State = 0:bl5k.State = 1:bl10k.State = 0:bl15k.State = 0:bl20k.State = 0:SpecialL1.State = 0
        Case 7:bl1.State = 0:bl2.State = 0:bl2a.State = 0:bl3.State = 1:bl3a.State = 1:bl4.State = 0:bl4a.State = 0:bl5.State = 0:bl5a.State = 0:bl5k.State = 1:bl10k.State = 0:bl15k.State = 0:bl20k.State = 0:SpecialL1.State = 0
        Case 8:bl1.State = 0:bl2.State = 0:bl2a.State = 0:bl3.State = 0:bl3a.State = 0:bl4.State = 1:bl4a.State = 1:bl5.State = 0:bl5a.State = 0:bl5k.State = 1:bl10k.State = 0:bl15k.State = 0:bl20k.State = 0:SpecialL1.State = 0
        Case 9:bl1.State = 0:bl2.State = 0:bl2a.State = 0:bl3.State = 0:bl3a.State = 0:bl4.State = 0:bl4a.State = 0:bl5.State = 1:bl5a.State = 1:bl5k.State = 1:bl10k.State = 0:bl15k.State = 0:bl20k.State = 0:SpecialL1.State = 0
        Case 10:bl1.State = 1:bl2.State = 0:bl2a.State = 0:bl3.State = 0:bl3a.State = 0:bl4.State = 0:bl4a.State = 0:bl5.State = 0:bl5a.State = 0:bl5k.State = 0:bl10k.State = 1:bl15k.State = 0:bl20k.State = 0:SpecialL1.State = 0
        Case 11:bl1.State = 0:bl2.State = 1:bl2a.State = 1:bl3.State = 0:bl3a.State = 0:bl4.State = 0:bl4a.State = 0:bl5.State = 0:bl5a.State = 0:bl5k.State = 0:bl10k.State = 1:bl15k.State = 0:bl20k.State = 0:SpecialL1.State = 0
        Case 12:bl1.State = 0:bl2.State = 0:bl2a.State = 0:bl3.State = 1:bl3a.State = 1:bl4.State = 0:bl4a.State = 0:bl5.State = 0:bl5a.State = 0:bl5k.State = 0:bl10k.State = 1:bl15k.State = 0:bl20k.State = 0:SpecialL1.State = 0
        Case 13:bl1.State = 0:bl2.State = 0:bl2a.State = 0:bl3.State = 0:bl3a.State = 0:bl4.State = 1:bl4a.State = 1:bl5.State = 0:bl5a.State = 0:bl5k.State = 0:bl10k.State = 1:bl15k.State = 0:bl20k.State = 0:SpecialL1.State = 0
        Case 14:bl1.State = 0:bl2.State = 0:bl2a.State = 0:bl3.State = 0:bl3a.State = 0:bl4.State = 0:bl4a.State = 0:bl5.State = 1:bl5a.State = 1:bl5k.State = 0:bl10k.State = 1:bl15k.State = 0:bl20k.State = 0:SpecialL1.State = 0
        Case 15:bl1.State = 1:bl2.State = 0:bl2a.State = 0:bl3.State = 0:bl3a.State = 0:bl4.State = 0:bl4a.State = 0:bl5.State = 0:bl5a.State = 0:bl5k.State = 0:bl10k.State = 0:bl15k.State = 1:bl20k.State = 0:SpecialL1.State = 0
        Case 16:bl1.State = 0:bl2.State = 1:bl2a.State = 1:bl3.State = 0:bl3a.State = 0:bl4.State = 0:bl4a.State = 0:bl5.State = 0:bl5a.State = 0:bl5k.State = 0:bl10k.State = 0:bl15k.State = 1:bl20k.State = 0:SpecialL1.State = 0
        Case 17:bl1.State = 0:bl2.State = 0:bl2a.State = 0:bl3.State = 1:bl3a.State = 1:bl4.State = 0:bl4a.State = 0:bl5.State = 0:bl5a.State = 0:bl5k.State = 0:bl10k.State = 0:bl15k.State = 1:bl20k.State = 0:SpecialL1.State = 0
        Case 18:bl1.State = 0:bl2.State = 0:bl2a.State = 0:bl3.State = 0:bl3a.State = 0:bl4.State = 1:bl4a.State = 1:bl5.State = 0:bl5a.State = 0:bl5k.State = 0:bl10k.State = 0:bl15k.State = 1:bl20k.State = 0:SpecialL1.State = 0
        Case 19:bl1.State = 0:bl2.State = 0:bl2a.State = 0:bl3.State = 0:bl3a.State = 0:bl4.State = 0:bl4a.State = 0:bl5.State = 1:bl5a.State = 1:bl5k.State = 0:bl10k.State = 0:bl15k.State = 1:bl20k.State = 0:SpecialL1.State = 0
        Case 20:bl1.State = 0:bl2.State = 0:bl2a.State = 0:bl3.State = 0:bl3a.State = 0:bl4.State = 0:bl4a.State = 0:bl5.State = 0:bl5a.State = 0:bl5k.State = 0:bl10k.State = 0:bl15k.State = 0:bl20k.State = 1:SpecialL1.State = 1
    End Select
End Sub

' After bonus count go to the next step
'
Sub EndOfBall2()
    'debug.print "EndOfBall2"

    Tilted = False
    Tilt = 0
    TiltReel.SetValue 0
    If B2SOn then
        Controller.B2SSetTilt 0
    end if
    DisableTable False

    ' win extra ball?
    If(ExtraBallsAwards(CurrentPlayer) > 0)Then
        'debug.print "Extra Ball"

        ' if so then give it
        ExtraBallsAwards(CurrentPlayer) = ExtraBallsAwards(CurrentPlayer)- 1

        ' turn off light if no more extra balls
        If(ExtraBallsAwards(CurrentPlayer) = 0)Then
        'LightShootAgain.State = 0
        'If B2SOn then
        'Controller.B2SSetShootAgain 0
        'end if
        End If

        ' extra ball sound?

        ' reset as in a new ball
        ResetForNewPlayerBall()
        CreateNewBall()
    Else ' no extra ball

        BallsRemaining(CurrentPlayer) = BallsRemaining(CurrentPlayer)- 1

        ' last ball?
        If(BallsRemaining(CurrentPlayer) <= 0)Then
            CheckHighScore()
        End If

        ' this is not the last ball, chack for new player
        EndOfBallComplete()
    End If
End Sub

Sub EndOfBallComplete()
    'debug.print "EndOfBallComplete"
    Dim NextPlayer

    ' other players?
    If(PlayersPlayingGame > 1)Then
        NextPlayer = CurrentPlayer + 1
        ' if it is the last player then go to the first one
        If(NextPlayer > PlayersPlayingGame)Then
            NextPlayer = 1
        End If
    Else
        NextPlayer = CurrentPlayer
    End If

    'debug.print "Next Player = " & NextPlayer

    ' end of game?
    If((BallsRemaining(CurrentPlayer) <= 0)AND(BallsRemaining(NextPlayer) <= 0))Then

        ' match if playing with coins
        If bFreePlay = False Then
            Verification_Match
        End If

        ' end of game
        EndOfGame()
    Else
        ' next player
        CurrentPlayer = NextPlayer

        ' update score
        AddScore 0

        ' reset table for new player
        ResetForNewPlayerBall()
        CreateNewBall()
    End If
End Sub

' Called at the end of the game

Sub EndOfGame()
    'debug.print "EndOfGame"
    bGameInPLay = False
    bJustStarted = False
    UpdateBallInPlay
    If B2SOn then
        Controller.B2SSetGameOver 1
        Controller.B2SSetBallInPlay 0
        Controller.B2SSetPlayerUp 0
        Controller.B2SSetCanPlay 0
    end if
    ' turn off flippers
    SolLFlipper 0
    SolRFlipper 0
    DOF 250, DOFPulse
	DOF 201, DOFOff

    ' start the attract mode
    StartAttractMode
End Sub

' Fuction to calculate the balls left
Function Balls
    Dim tmp
    tmp = BallsPerGame - BallsRemaining(CurrentPlayer) + 1
    If tmp > BallsPerGame Then
        Balls = 0
    Else
        Balls = tmp
    End If
End Function

'******************
'     Match
'******************

Sub Verification_Match()
    PlaySound "fx_match"
    Match = INT(RND(1) * 10) * 10 ' random between 10 and 90
    Display_Match
    If(Score(CurrentPlayer)MOD 100) = Match Then
        PlaySound SoundFXDOF ("fx_knocker",108,DOFPulse,DOFKnocker)
        DOF 230, DOFPulse
        DOF 200, DOFOn
        AddCredits 1
    End If
End Sub

Sub Clear_Match()
    MatchReel.SetValue 0
    If B2SOn then
        Controller.B2SSetMatch 0
    end if
End Sub

Sub Display_Match()
    MatchReel.SetValue ((Match \ 10) + 1)
    If B2SOn then
        If Match = 0 then
            Controller.B2SSetMatch 100
        else
            Controller.B2SSetMatch Match
        end if
    end if
End Sub

' *********************************************************************
'                      Drain / Plunger Functions
' *********************************************************************

Sub Drain_Hit()
    Drain.DestroyBall
    If NOT bGameInPlay Then Exit Sub
    BallsOnPlayfield = BallsOnPlayfield - 1
    PlaySoundAt "fx_drain", Drain
    DOF 226, DOFPulse
    If Epileptikdof = True Then DOF 227, DOFPulse End If

    'tilted?
    If Tilted Then
        StopEndOfBallMode
    End If

    ' if still playing and not tilted
    If(bGameInPLay = True)AND(Tilted = False)Then

        ' ballsaver?
        If(bBallSaverActive = True)Then
            CreateNewBall()
        Else
            ' last ball?
            If(BallsOnPlayfield = 0)Then
                StopEndOfBallMode
                vpmtimer.addtimer 500, "EndOfBall '"
                Exit Sub
            End If
        End If
    End If
End Sub

Sub swPlungerRest_Hit()
    bBallInPlungerLane = True
End Sub

Sub swPlungerRest_UnHit()
    bBallInPlungerLane = False
End Sub

'******************************
'     DOF lights ball entrance
'******************************
'
Sub Trigger011_Hit
    DOF 240, DOFPulse
End sub

' ****************************************
'             Score functions
' ****************************************

Sub AddScore(Points)
    If Tilted Then Exit Sub
    Select Case Points
        Case 10, 100, 1000
            Score(CurrentPlayer) = Score(CurrentPlayer) + points
            UpdateScore points
            ' sounds
            If Points = 100 AND(Score(CurrentPlayer)MOD 1000) \ 100 = 0 Then  'new reel 1000
                PlaySound SoundFXDOF ("1000",113,DOFPulse,DOFChimes)
            ElseIf Points = 10 AND(Score(CurrentPlayer)MOD 100) \ 10 = 0 Then 'new reel 100
                PlaySound SoundFXDOF ("100",112,DOFPulse,DOFChimes)
            Else
                PlaySound SoundFXDOF ("Points",111,DOFPulse,DOFChimes)
               ' PlaySound Points
               ' DOF 111, DOFPulse
            End If
        Case 50
            Add10 = Add10 + 5
            AddScore10Timer.Enabled = TRUE
        Case 500
            Add100 = Add100 + 5
            AddScore100Timer.Enabled = TRUE
        Case 5000
            Add1000 = Add1000 + 5
            AddScore1000Timer.Enabled = TRUE
    End Select

    ' check for higher score and specials
    If Score(CurrentPlayer) >= Special1 AND Special1Awarded(CurrentPlayer) = False Then
        AwardSpecial
        Special1Awarded(CurrentPlayer) = True
    End If
    If Score(CurrentPlayer) >= Special2 AND Special2Awarded(CurrentPlayer) = False Then
        AwardSpecial
        Special2Awarded(CurrentPlayer) = True
    End If
   ' If Score(CurrentPlayer) >= Special3 AND Special3Awarded(CurrentPlayer) = False Then
   '     AwardSpecial
   '     Special3Awarded(CurrentPlayer) = True
   ' End If
End Sub

'************************************
'       Score sound Timers
'************************************

Sub AddScore10Timer_Timer()
    if Add10 > 0 then
        AddScore 10
        Add10 = Add10 - 1
    Else
        Me.Enabled = FALSE
    End If
End Sub

Sub AddScore100Timer_Timer()
    if Add100 > 0 then
        AddScore 100
        Add100 = Add100 - 1
    Else
        Me.Enabled = FALSE
    End If
End Sub

Sub AddScore1000Timer_Timer()
    if Add1000 > 0 then
        AddScore 1000
        Add1000 = Add1000 - 1
    Else
        Me.Enabled = FALSE
    End If
End Sub

'*******************
'     BONUS
'*******************

Sub AddBonus(bonuspoints)
    If(Tilted = False)Then
        Bonus = Bonus + bonuspoints
        PlaySound SoundFXDOF ("Bell2",111,DOFPulse,DOFChimes)
        If Bonus > 20 Then
            Bonus = 20
        End If
        UpdateBonusLights
    End if
End Sub

Sub AddBonusMultiplier(multi)
    If(Tilted = False)Then
        BonusMultiplier = BonusMultiplier + multi
        If BonusMultiplier > MaxMultiplier Then
            BonusMultiplier = MaxMultiplier
        End If
        UpdateMultiplierLights
    End if
End Sub

Sub UpdateMultiplierLights
    Select Case BonusMultiplier
    'Case 1:li2.State = 1:li3.State = 0:li4.State = 0
    'Case 2:li2.State = 0:li3.State = 1:li4.State = 0
    'Case 3:li2.State = 0:li3.State = 0:li4.State = 1
    End Select
End Sub

'**********************************
'        Score EM reels
'**********************************

Sub UpdateScore(playerpoints)
    Select Case CurrentPlayer
        Case 1:ScoreReel1.Addvalue playerpoints
        'Case 2:ScoreReel2.Addvalue playerpoints

    End Select
    If B2SOn then
        Controller.B2SSetScorePlayer CurrentPlayer, Score(CurrentPlayer)
        If Score(CurrentPlayer) >= 100000 then
            Controller.B2SSetScoreRollover 24 + CurrentPlayer, 1
        end if
    end if
End Sub

Sub ResetScores
    ScoreReel1.SetValue 10
    ScoreReel1.ResetToZero
    'ScoreReel2.ResetToZero
    If B2SOn then
        Controller.B2SSetScorePlayer1 0
        Controller.B2SSetScoreRolloverPlayer1 0
    'Controller.B2SSetScorePlayer2 0
    'Controller.B2SSetScoreRolloverPlayer2 0
    end if
End Sub

Sub AddCredits(value) 'limit to 15 credits
    If Credits < 15 Then
        Credits = Credits + value
        CreditsReel.SetValue Credits
        UpdateCredits
    end if
End Sub

Sub UpdateCredits
    PlaySound "fx_relay"
    CreditsReel.SetValue credits
    If B2SOn then
        Controller.B2SSetCredits Credits
    end if
End Sub

Sub UpdateBallInPlay
    Select Case Balls
        Case 0:BallDisplay.ImageA = "Ballnr0"
        Case 1:BallDisplay.ImageA = "Ballnr1"
        Case 2:BallDisplay.ImageA = "Ballnr2"
        Case 3:BallDisplay.ImageA = "Ballnr3"
        Case 4:BallDisplay.ImageA = "Ballnr4"
        Case 5:BallDisplay.ImageA = "Ballnr5"
    End Select
    If B2SOn then
        Controller.B2SSetBallInPlay Balls
    End If
End Sub

'*************************
'        Specials
'*************************

Sub AwardExtraBall()
    If NOT bExtraBallWonThisBall Then
        PlaySound SoundFXDOF ("fx_knocker",108,DOFPulse,DOFKnocker)
        DOF 230, DOFPulse
        ExtraBallsAwards(CurrentPlayer) = ExtraBallsAwards(CurrentPlayer) + 1
        bExtraBallWonThisBall = True
    Else
        Addscore 5000
    END If
End Sub

Sub AwardSpecial()
    PlaySound SoundFXDOF ("fx_knocker",108,DOFPulse,DOFKnocker)
        DOF 230, DOFPulse
        DOF 200, DOFOn
    AddCredits 1
End Sub

Sub AwardAddaBall()
    If BallsRemaining(CurrentPlayer) < 11 Then
        PlaySound SoundFXDOF ("fx_knocker",108,DOFPulse,DOFKnocker)
        DOF 230, DOFPulse
        BallsRemaining(CurrentPlayer) = BallsRemaining(CurrentPlayer) + 1
        UpdateBallInPlay
    End If
End Sub

' ********************************
'        Attract Mode
' ********************************
' use the"Blink Pattern" of each light

Sub StartAttractMode()
    Dim x
    bAttractMode = True
    For each x in aLights
        x.State = 2
    Next
    GameOverR.SetValue 1
'update current player and balls
End Sub

Sub StopAttractMode()
    Dim x
    bAttractMode = False
    TurnOffPlayfieldLights
    ResetScores
    GameOverR.SetValue 0
End Sub

'*************************************
'       Highscore Routines
' Based og Black's and GNMOD's code
'*************************************

Dim EnteringInitials 
EnteringInitials = False

Dim SelectedChar     ' character under the "cursor" when entering initials
Dim HSTimerCount: HSTimerCount = 0
Dim InitialString    ' the string holding the player's initials as they're entered
Dim AlphaString: AlphaString = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789_<"
Dim AlphaStringPos   ' pointer to AlphaString, move Forward and backward with flipper keys
Dim HSNewHigh        ' The new score to be recorded
Dim HSScore(5)       ' High Scores read in from config file
Dim HSName(5)        ' High Score Initials read in from config file

' default high scores
HSScore(1) = 50000
HSScore(2) = 40000
HSScore(3) = 30000
HSScore(4) = 20000
HSScore(5) = 10000

HSName(1) = "AAA"
HSName(2) = "ZZZ"
HSName(3) = "XXX"
HSName(4) = "ABC"
HSName(5) = "BBB"

' Load Highscores

Sub Loadhs
    Dim FileObj
    Dim ScoreFile, TextStr
    Dim check0, x

    Set FileObj = CreateObject("Scripting.FileSystemObject")
    If Not FileObj.FolderExists(UserDirectory)then
        Credits = 0
        Exit Sub
    End If
    If Not FileObj.FileExists(UserDirectory & cGameName& ".txt")then
        Credits = 0
        Exit Sub
    End If
    Set ScoreFile = FileObj.GetFile(UserDirectory & cGameName& ".txt")
    Set TextStr = ScoreFile.OpenAsTextStream(1, 0)
    If(TextStr.AtEndOfStream = True)then
        Exit Sub
    End If
    check0 = Int(textStr.readLine)
    If check0 = 0 then
        Credits = Int(textstr.readline)
        For x = 1 to 5
            HSScore(x) = Int(textstr.readline)
        Next
        For x = 1 to 5
            HSName(x) = textstr.readline
        Next
    End If
    TextStr.Close
    Set ScoreFile = Nothing
    Set FileObj = Nothing
    SortHighscore 'added to fix a previous error
End Sub

' Save Highscores

Sub Savehs
    Dim FileObj
    Dim ScoreFile
    Dim x
    Set FileObj = CreateObject("Scripting.FileSystemObject")
    If Not FileObj.FolderExists(UserDirectory)then
        Exit Sub
    End If
    Set ScoreFile = FileObj.CreateTextFile(UserDirectory & cGameName& ".txt", True)
    ScoreFile.WriteLine 0
    ScoreFile.WriteLine Credits
    For x = 1 to 5
        scorefile.writeline HSScore(x)
    Next
    For x = 1 to 5
        scorefile.writeline HSName(x)
    Next
    ScoreFile.Close
    Set ScoreFile = Nothing
    Set FileObj = Nothing
End Sub

' Sort Highscores

Sub SortHighscore
    Dim tmp, tmp2, i, j
    For i = 1 to 5
        For j = 1 to 4
            If HSScore(j) <HSScore(j + 1)Then
                tmp = HSScore(j + 1)
                tmp2 = HSName(j + 1)
                HSScore(j + 1) = HSScore(j)
                HSName(j + 1) = HSName(j)
                HSScore(j) = tmp
                HSName(j) = tmp2
            End If
        Next
    Next
End Sub

' check for new highscore

Sub CheckHighscore
    HighScoreTimer.Enabled = 1
    'If Score(CurrentPlayer)> HSSCore(1)Then
    '   AwardSpecial
    'End If
    If Score(CurrentPlayer)> HSSCore(5)Then
        NewHighScore Score(CurrentPlayer), CurrentPlayer
    End If

End Sub

' Highscore Timer

Sub HighScoreTimer_Timer
    If EnteringInitials then
        SetHSLine 3, InitialString & MID(AlphaString, AlphaStringPos, 1)
    ElseIf bGameInPlay then
        SetHSLine 1, "HIGH SCORE"
        SetHSLine 2, HSScore(1)
        SetHSLine 3, HSName(1)
        HighScoreTimer.Enabled = 0
    Else
        ' cycle through high scores
        SetHSLine 1, "HIGH SCORE" & (HSTimerCount + 1)
        SetHSLine 2, HSScore(HSTimerCount + 1)
        SetHSLine 3, HSName(HSTimerCount + 1)
        HSTimerCount = (HSTimerCount + 1)MOD 5
    End If
End Sub

' Enter Highscore initials

Function GetHSChar(String, Index)
    Dim ThisChar
    Dim FileName
    ThisChar = Mid(String, Index, 1)
    FileName = "PostIt"
    If ThisChar = " " or ThisChar = "" then
        FileName = FileName & "BL"
    ElseIf ThisChar = "<" then
        FileName = FileName & "LT"
    ElseIf ThisChar = "_" then
        FileName = FileName & "SP"
    Else
        FileName = FileName & ThisChar
    End If
    GetHSChar = FileName
End Function

Sub SetHsLine(LineNo, String)
    Dim StrLen
    Dim Index
    Dim StartHSArray
    Dim EndHSArray
    Dim xFor
    StartHSArray = array(0, 1, 12, 22)
    EndHSArray = array(0, 11, 21, 31)
    StrLen = len(string)
    Index = 1
    For xFor = StartHSArray(LineNo)to EndHSArray(LineNo)
        Eval("HS" &xFor).imageA = GetHSChar(String, Index)
        Index = Index + 1
    Next
End Sub

Sub NewHighScore(NewScore, PlayNum)
    If NewScore> HSScore(5)then
        HighScoreTimer.interval = 500
        AlphaStringPos = 1      ' start with first character "A"
        EnteringInitials = true ' intercept the control keys while entering initials
        InitialString = ""      ' initials entered so far, initialize to empty
        SetHSLine 1, "PLAYER " + FormatNumber(PlayNum, 0)
        SetHSLine 2, "ENTER NAME"
        SetHSLine 3, MID(AlphaString, AlphaStringPos, 1)
        HSNewHigh = NewScore
    End If
End Sub

Sub CollectInitials(keycode)
    Dim i
    If keycode = LeftFlipperKey Then
        ' back up to previous character
        AlphaStringPos = AlphaStringPos - 1
        If AlphaStringPos <1 then
            AlphaStringPos = len(AlphaString) ' handle wrap from beginning to End
            If InitialString = "" then
                ' Skip the backspace If there are no characters to backspace over
                AlphaStringPos = AlphaStringPos - 1
            End If
        End If
        SetHSLine 3, InitialString & MID(AlphaString, AlphaStringPos, 1)
        PlaySound "fx_Previous"
    ElseIf keycode = RightFlipperKey Then
        ' advance to Next character
        AlphaStringPos = AlphaStringPos + 1
        If AlphaStringPos> len(AlphaString)or(AlphaStringPos = len(AlphaString)and InitialString = "")then
            ' Skip the backspace If there are no characters to backspace over
            AlphaStringPos = 1
        End If
        SetHSLine 3, InitialString & MID(AlphaString, AlphaStringPos, 1)
        PlaySound "fx_Next"
    ElseIf keycode = StartGameKey or keycode = PlungerKey Then
        SelectedChar = MID(AlphaString, AlphaStringPos, 1)
        If SelectedChar = "_" then
            InitialString = InitialString & " "
            PlaySound("fx_Esc")
        ElseIf SelectedChar = "<" then
            InitialString = MID(InitialString, 1, len(InitialString)- 1)
            If len(InitialString) = 0 then
                ' If there are no more characters to back over, don't leave the < displayed
                AlphaStringPos = 1
            End If
            PlaySound("fx_Esc")
        Else
            InitialString = InitialString & SelectedChar
            PlaySound("fx_Enter")
        End If
        If len(InitialString) <3 then
            SetHSLine 3, InitialString & SelectedChar
        End If
    End If
    If len(InitialString) = 3 then
        EnteringInitials = False
        HSScore(5) = HSNewHigh
        HSName(5) = InitialString
        SortHighScore
        HighScoreTimer.interval = 2000
    End If
End Sub

'*******************
' Realtime updates
'*******************

Sub RealTime_Timer
    RollingUpdate
    LeftFlipperTop.RotZ = LeftFlipper.CurrentAngle
    RightFlipperTop.RotZ = RightFlipper.CurrentAngle
End Sub

'***************************
'   LUT - Darkness control 
'***************************

Dim bLutActive, LUTImage

Sub LoadLUT
    bLutActive = False
    x = LoadValue(cGameName, "LUTImage")
    If(x <> "")Then LUTImage = x Else LUTImage = 0
    UpdateLUT
End Sub

Sub SaveLUT
    SaveValue cGameName, "LUTImage", LUTImage
End Sub

Sub NextLUT:LUTImage = (LUTImage + 1)MOD 15:UpdateLUT:SaveLUT:Lutbox.text = "level of darkness " & LUTImage + 1:End Sub

Sub UpdateLUT
    Select Case LutImage
        Case 0:table1.ColorGradeImage = "LUT0":GiIntensity = 1:ChangeGIIntensity 1
        Case 1:table1.ColorGradeImage = "LUT1":GiIntensity = 1.05:ChangeGIIntensity 1
        Case 2:table1.ColorGradeImage = "LUT2":GiIntensity = 1.1:ChangeGIIntensity 1
        Case 3:table1.ColorGradeImage = "LUT3":GiIntensity = 1.15:ChangeGIIntensity 1
        Case 4:table1.ColorGradeImage = "LUT4":GiIntensity = 1.2:ChangeGIIntensity 1
        Case 5:table1.ColorGradeImage = "LUT5":GiIntensity = 1.25:ChangeGIIntensity 1
        Case 6:table1.ColorGradeImage = "LUT6":GiIntensity = 1.3:ChangeGIIntensity 1
        Case 7:table1.ColorGradeImage = "LUT7":GiIntensity = 1.35:ChangeGIIntensity 1
        Case 8:table1.ColorGradeImage = "LUT8":GiIntensity = 1.4:ChangeGIIntensity 1
        Case 9:table1.ColorGradeImage = "LUT9":GiIntensity = 1.45:ChangeGIIntensity 1
        Case 10:table1.ColorGradeImage = "LUT10":GiIntensity = 1.5:ChangeGIIntensity 1
        Case 11:table1.ColorGradeImage = "LUT11":GiIntensity = 1.55:ChangeGIIntensity 1
        Case 12:table1.ColorGradeImage = "LUT12":GiIntensity = 1.6:ChangeGIIntensity 1
        Case 13:table1.ColorGradeImage = "LUT13":GiIntensity = 1.65:ChangeGIIntensity 1
        Case 14:table1.ColorGradeImage = "LUT14":GiIntensity = 1.7:ChangeGIIntensity 1
    End Select
End Sub

Dim GiIntensity
GiIntensity = 1   'used by the LUT changing to increase the GI lights when the table is darker

Sub ChangeGiIntensity(factor) 'changes the intensity scale
    Dim bulb
    For each bulb in aGiLights
        bulb.IntensityScale = GiIntensity * factor
    Next
End Sub

'***********************************************************************
' *********************************************************************
'  *********     G A M E  C O D E  S T A R T S  H E R E      *********
' *********************************************************************
'***********************************************************************

Sub VPObjects_Init 'init objects
    TurnOffPlayfieldLights()
    kicker001k.IsDropped = 1
End Sub

' Dim all the variables

Sub Game_Init() 'called at the start of a new game
    'Start music?
    'Init variables?
    'Start or init timers
    TurnOffPlayfieldLights()
' turn on white lights
li027.State = 1
li029.State = 1
li030.State = 1
li031.State = 1
li032.State = 1
li033.State = 1
End Sub

Sub StopEndOfBallMode()     'called when the last ball is drained
End Sub

Sub ResetNewBallVariables() 'init variables new ball/player
End Sub

Sub ResetNewBallLights()    'init lights for new ball/player
' yellows
li026.State = 1
li025.State = 1
li010.State = 1
li009.State = 1
li012.State = 0
li011.State = 0
li013.State = 0
li014.State = 0
li015.State = 0
li016.State = 0
li017.State = 0
li018.State = 0

li028.State = 0
lBumper1a.State = 0:lBumper1b.State = 0:lBumper2a.State = 0:lBumper2b.State = 0
li006.State=0:li007.State=0:li008.State=0:li001.State=0
li005.State = 0
li004.State = 0
End Sub

Sub TurnOffPlayfieldLights()
    Dim a
    For each a in aLights
        a.State = 0
    Next
End Sub

' *********************************************************************
'                        Table Object Hit Events
' *********************************************************************
' Any target hit Sub will do this:
' - play a sound
' - do some physical movement
' - add a score, bonus
' - check some variables/modes this trigger is a member of
' - set the "LastSwicthHit" variable in case it is needed later
' *********************************************************************

' Slingshots
Dim LStep, RStep

Sub LeftSlingShot_Slingshot
    If Tilted Then Exit Sub
    PlaySoundAt SoundFXDOF ("fx_slingshot",103,DOFPulse,DOFcontactors), Lemk
    DOF 203, DOFPulse
    If Epileptikdof = True Then DOF 204, DOFPulse End If
    If Epileptikdof = True Then DOF 202, DOFPulse End If
    LeftSling004.Visible = 1
    Lemk.RotX = 26
    LStep = 0
    LeftSlingShot.TimerEnabled = True
    ' add points
    AddScore 10
' some effect?
End Sub

Sub LeftSlingShot_Timer
    Select Case LStep
        Case 1:LeftSLing004.Visible = 0:LeftSLing003.Visible = 1:Lemk.RotX = 14
        Case 2:LeftSLing003.Visible = 0:LeftSLing002.Visible = 1:Lemk.RotX = 2
        Case 3:LeftSLing002.Visible = 0:Lemk.RotX = -20:LeftSlingShot.TimerEnabled = 0
    End Select
    LStep = LStep + 1
End Sub

Sub RightSlingShot_Slingshot
    If Tilted Then Exit Sub
    PlaySoundAt SoundFXDOF ("fx_slingshot",104,DOFPulse,DOFcontactors), Remk
    DOF 205, DOFPulse
    If Epileptikdof = True Then DOF 206, DOFPulse End If
    If Epileptikdof = True Then DOF 202, DOFPulse End If
    RightSling004.Visible = 1
    Remk.RotX = 26
    RStep = 0
    RightSlingShot.TimerEnabled = True
    ' add points
    AddScore 10
' add effect?
End Sub

Sub RightSlingShot_Timer
    Select Case RStep
        Case 1:RightSLing004.Visible = 0:RightSLing003.Visible = 1:Remk.RotX = 14
        Case 2:RightSLing003.Visible = 0:RightSLing002.Visible = 1:Remk.RotX = 2
        Case 3:RightSLing002.Visible = 0:Remk.RotX = -20:RightSlingShot.TimerEnabled = 0
    End Select
    RStep = RStep + 1
End Sub

'***********************
'   Rubber animations
'***********************

Dim Rub1, Rub2, Rub3

Sub rlband004_Hit
    Rub1 = 1:rlband004_Timer
End Sub

Sub rlband004_Timer
    Select Case Rub1
        Case 1:Rubber008.Visible = 0:Rubber016.Visible = 1:rlband004.TimerEnabled = 1
        Case 2:Rubber016.Visible = 0:Rubber017.Visible = 1
        Case 3:Rubber017.Visible = 0:Rubber008.Visible = 1:rlband004.TimerEnabled = 0
    End Select
    Rub1 = Rub1 + 1
End Sub

Sub rlband005_Hit
    Rub2 = 1:rlband005_Timer
	AddScore 10
End Sub

Sub rlband005_Timer
    Select Case Rub2
        Case 1:Rubber010.Visible = 0:Rubber018.Visible = 1:rlband005.TimerEnabled = 1
        Case 2:Rubber018.Visible = 0:Rubber019.Visible = 1
        Case 3:Rubber019.Visible = 0:Rubber010.Visible = 1:rlband005.TimerEnabled = 0
    End Select
    Rub2 = Rub2 + 1
End Sub

Sub rlband008_Hit
    Rub3 = 1:rlband005_Timer
Addscore 100
End Sub

Sub rlband008_Timer
    Select Case Rub3
        Case 1:Rubber013.Visible = 0:Rubber020.Visible = 1:rlband008.TimerEnabled = 1
        Case 2:Rubber020.Visible = 0:Rubber021.Visible = 1
        Case 3:Rubber021.Visible = 0:Rubber013.Visible = 1:rlband008.TimerEnabled = 0
    End Select
    Rub3 = Rub3 + 1
End Sub

Sub rlband003_Hit:Addscore 100:End Sub
Sub rlband010_Hit:Addscore 100:End Sub

'*********
' Bumpers
'*********

Sub Bumper001_Hit
    If Tilted Then Exit Sub
    PlaySoundAt SoundFXDOF ("fx_Bumper",105,DOFPulse,DOFContactors), bumper001
    DOF 207, DOFPulse
    If Epileptikdof = True Then DOF 202, DOFPulse End If
    AddScore 100 + 900 * Lbumper1a.State
End Sub

Sub Bumper002_Hit
    If Tilted Then Exit Sub
    PlaySoundAt SoundFXDOF ("fx_Bumper",106,DOFPulse,DOFContactors), bumper002
    DOF 208, DOFPulse
    If Epileptikdof = True Then DOF 202, DOFPulse End If
    AddScore 10 + 90 * Lbumper2a.State
End Sub

'*****************
'     Lanes
'*****************

Sub Trigger001_Hit
    PlaySoundAt "fx_sensor", Trigger001
    If Tilted Then Exit Sub
    If li002.State Then
        AwardSpecial
    End If
    AddScore 5000
    DOF 216, DOFPulse
End Sub

Sub Trigger002_Hit
    PlaySoundAt "fx_sensor", Trigger002
    If Tilted Then Exit Sub
    li027.State = 0
    li024.State = 1
    CheckLights
    AddScore 1000
    DOF 217, DOFPulse
End Sub

Sub Trigger003_Hit
    PlaySoundAt "fx_sensor", Trigger003
    If Tilted Then Exit Sub
    AddScore 500
    DOF 218, DOFPulse
End Sub

Sub Trigger004_Hit
    PlaySoundAt "fx_sensor", Trigger004
    If Tilted Then Exit Sub
    AddScore 500 + 4500 * li001.State
    'li001.State = 1
    li001.State = 0
    DOF 219, DOFPulse
End Sub

Sub Trigger005_Hit
    PlaySoundAt "fx_sensor", Trigger005
    If Tilted Then Exit Sub
    Li029.State = 0
    li021.State = 1
    CheckLights
    AddScore 500 + 4500 * li006.State
    DOF 220, DOFPulse
End Sub

Sub Trigger006_Hit
    PlaySoundAt "fx_sensor", Trigger006
    If Tilted Then Exit Sub
    Li030.State = 0
    li022.State = 1
    CheckLights
    AddScore 500
    DOF 221, DOFPulse
End Sub

Sub Trigger007_Hit
    PlaySoundAt "fx_sensor", Trigger007
    If Tilted Then Exit Sub
    Li031.State = 0
    li020.State = 1
    CheckLights
    AddScore 500 + 4500 * li007.State
    DOF 222, DOFPulse
End Sub

Sub Trigger009_Hit
    PlaySoundAt "fx_sensor", Trigger009
    If Tilted Then Exit Sub
    Li032.State = 0
    li023.State = 1
    CheckLights
    AddScore 500
    DOF 223, DOFPulse
End Sub

Sub Trigger010_Hit
    PlaySoundAt "fx_sensor", Trigger010
    If Tilted Then Exit Sub
    Li033.State = 0
    li019.State = 1
    CheckLights
    AddScore 500 + 4500 * li008.State
    DOF 224, DOFPulse
End Sub

Sub Trigger008_Hit
    PlaySoundAt "fx_sensor", Trigger008
    If Tilted Then Exit Sub
    AddScore 500 + 4500 * li005.State
    If li004.State Then AwardSpecial
    DOF 225, DOFPulse
End Sub

'************************
'       Targets
'************************

Sub Target001_hit
    PlaySoundAtBall SoundFXDOF ("fx_target", 114, DOFPulse, DOFTargets)
    If Tilted Then Exit Sub
        Li026.State = 0
        li012.State = 1
        li015.State = 1
        CheckLights
    AddScore 100
    If Epileptikdof = True Then DOF 214, DOFPulse End If
End Sub

Sub Target002_hit
    PlaySoundAtBall SoundFXDOF ("fx_target", 114, DOFPulse, DOFTargets)
    If Tilted Then Exit Sub
        Li025.State = 0
        li011.State = 1
        li017.State = 1
        CheckLights
    AddScore 100
    If Epileptikdof = True Then DOF 214, DOFPulse End If
End Sub

Sub Target003_hit
    PlaySoundAtBall SoundFXDOF ("fx_target", 115, DOFPulse, DOFTargets)
    If Tilted Then Exit Sub
    If li003.State Then AwardSpecial
    AddScore 500
    If Epileptikdof = True Then DOF 215, DOFPulse End If
End Sub


'*****************
'    Setas
'*****************

Sub Seta1_hit
    PlaySoundAtBall "fx_passive_bumper"
    If Tilted Then Exit Sub
        Li010.State = 0
        li013.State = 1
        li018.State = 1
        CheckLights
    AddScore 500
    setap1.TransY = -3: Me.TimerEnabled = 1
    DOF 210,DOFPulse
End Sub

Sub Seta1_Timer:setap1.TransY = 0: Me.TimerEnabled = 0: End Sub

Sub Seta2_hit
    PlaySoundAtBall "fx_passive_bumper"
    If Tilted Then Exit Sub
    If li003.State Then AwardSpecial
    AddScore 500
    setap2.TransY = -3: Me.TimerEnabled = 1
    DOF 211,DOFPulse
End Sub

Sub Seta2_Timer:setap2.TransY = 0: Me.TimerEnabled = 0: End Sub

Sub Seta3_hit
    PlaySoundAtBall "fx_passive_bumper"
    If Tilted Then Exit Sub
        Li009.State = 0
        li014.State = 1
        li016.State = 1
        CheckLights
    AddScore 500
    setap3.TransY = -3: Me.TimerEnabled = 1
    DOF 212,DOFPulse
End Sub

Sub Seta3_Timer:setap3.TransY = 0: Me.TimerEnabled = 0: End Sub

Sub Seta4_hit
    PlaySoundAtBall "fx_passive_bumper"
    If Tilted Then Exit Sub
    AddScore 500
    setap4.TransY = -3: Me.TimerEnabled = 1
    DOF 213,DOFPulse
End Sub

Sub Seta4_Timer:setap4.TransY = 0: Me.TimerEnabled = 0: End Sub

'*****************
'    kickers
'*****************

Sub Kicker001_hit
    PlaySoundAtBall "fx_kicker_enter"
    If Tilted Then Exit Sub
    AddScore 500 + 4500 * li028.State
    vpmtimer.addtimer 1000, "kicker001k.TimerEnabled = 1:DOF 209, DOFPulse:DOF 230, DOFPulse:DOF 107, DOFPulse:PlaySoundAt SoundFX(""fx_kicker"",DOFContactors),kicker001:kicker001.kick 195,10:kicker001k.Isdropped=0 '"
End Sub

Sub kicker001k_Timer:PlaySoundAt "fx_solenoidoff", kicker001:kicker001k.Isdropped = 1:kicker001k.TimerEnabled = 0:End Sub

'*********************
' Check Center Lights
'*********************

Dim DivAwarded
DivAwarded = False

Dim SpecAwarded
SpecAwarded = False

Sub CheckLights
If li019.State AND li012.State Then li028.State = 1
If li020.State AND li011.State Then li028.State = 1
If li021.State AND li013.State Then lBumper1a.State = 1:lBumper1b.State = 1:lBumper2a.State = 1:lBumper2b.State = 1
If li022.State AND li014.State Then li006.State=1:li007.State=1:li008.State=1:li001.State=1
If li023.State AND li015.State AND li016.State Then li005.State = 1
If li023.State AND li017.State AND li018.State Then li005.State = 1
If li012.State AND li011.State AND li013.State AND li014.State Then li004.State = 1
If li019.State AND li020.State AND li021.State AND li022.State AND li023.State AND li024.State then li003.State = 1: li002.State = 1
End Sub
