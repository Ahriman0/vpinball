
'======================================================================================
' This code may be freely distributed, but is not to be included with any profit-making
' software or product without the express permission from the scripting author, Steely.
'======================================================================================
'	 /			  /				 /				/			   /			  /		  '
'	/			<<<-->>>		/			   /			  /				 /		  '
'  /		 <<< ------- >@>   /			  /				 /				/		  '
' /		   <</	  Ball --- >@@/				 /				/			   /		  '
'/		  </	   - to --- >@@				/			   /			  /			  '
'		 </			- Ball - >@@		   /			  /				 /			  '
'		 </		   Collision >@@>		  /				 /				/			  '
'		 </		   - for ---- @@@		 /				/			   /			  '
'		 <</	 Visual ----- @@@		/			   /			  /				 /'
'		/<<<   Pinball ----- >@@>	   /			  /				 /				/ '
'	   /  <<< -------------- @@@> A	  /				 /				/			   /  '
'	  /	   <<<< ---------- >@@@> PinballKen			/			   /			  /	  '
'	 /		 <<<<< ----- >@@@> & Steely			   /			  /				 /	  '
'	/			<<<<->>@@> Production			  /				 /	Ver 1.0 beta/	  '
'  /			   /			  /				 /				/			   /	  '
'======================================================================================
' Many thanks go to Randy Davis and to all the multitudes of people who have
' contributed to VP over the years, keeping it alive!!! Enjoy, Steely & PK
'======================================================================================
'
' This code will currently only work with vp9 tables. It uses a kicker's
' UnHit event which is not available in vp8. Options for vp8 are being explored.

' To add B2B collision sounds to a VP9 table follow these few steps...

' 1) Create a new timer in the VP playfield editor and name it ==> XYdata
'	 DO NOT ENABLE this timer, it automatically turns on/off when needed.
' 2) Import the ten provided collide*.wav files (0-9) with the sound manager.
'	 If you choose to use your own sound files, they must be named collide0.wav
'	 thru whatever number. Example: collide0.wav to collide7.wav (8 files)
' 3) Copy/paste the next few lines into your table script.
'	 NOTE: these four lines should be placed before any other table script.
'	 Set the quantites for tnopb and nosf.
'
' This "B2Bcollision.vbs" file must be placed in the same folder as the table.
'
'Dim tnopb, nosf
'
'tnopb = 4	' <<<<< SET to the "Total Number Of Possible Balls" in play at any one time
'nosf = 10	' <<<<< SET to the "Number Of Sound Files" used / B2B collision volume levels
'
'ExecuteGlobal GetTextFile("B2Bcollision.vbs")
'
' The following allows this table to be run in VP9 or VP8
'Dim trig	' For a VP9 or VP8 option
'If VPBuildVersion = 902 Then
'	For Each trig in Newb
'		trig.enabled = False ' If VP9, turn off triggers and use kicker_UnHit events
'	Next
'End If
'
' 4) For each and every kicker that creates and/or destroys balls you must add a command
'	 for ball identification... This is very important when adapting a table. If you get
'	 an error while playing during a multiball sequence, you may have missed adding code
'	 to a kicker's Hit or unHit event or the command code was not placed in the proper
'	 location. Also note that not all kickers create and destroy balls.
'
'	 First: Determine which kickers destroy balls and insert "ClearBallid" into the kicker's
'	 Hit sub. This must be placed before a ball is destroyed to clear the ball object ID.
'
' Example below:
'
'Sub Kicker1_Hit() ClearBallid : AddBall me : End Sub	'AddBall - simulating a VPM command
'Sub Kicker2_Hit() ClearBallid : Kicker2.DestroyBall : End Sub
'Sub Drain_Hit()
'	PlaySound "drain"
'	ClearBallid
'	Drain.DestroyBall
'End Sub
'
'	Second: for each kicker that creates balls, you need to call"NewBallid".
'	Note: Two options below, "A" is for VP9, "B" is for VP8 or earlier versions.
'
'	A) VP9 kickers UnHit sub do not exist, create them "Sub kickername_UnHit"
'Sub Kicker1_UnHit() NewBallid : End Sub
'Sub Kicker2_UnHit() NewBallid : End Sub
'Sub Kicker3_UnHit() NewBallid : End Sub
'
'	B) VP8 kickers do not have UnHit events so create a trigger upon each kicker.
'Sub Newb_UnHit(index) NewBallid : End Sub	' Use a collection of the triggers.
'Sub TriggerK1_UnHit() NewBallid : End Sub	' Or individual subs for each trigger.
'Sub TriggerK2_UnHit() NewBallid : End Sub
'Sub TriggerK3_UnHit() NewBallid : End Sub
'
' Note: In VP9, if a kicker is disabled, its UnHit event will not work! You must create a trigger (at ' the kicker) and a "Sub trigger_UnHit" event to call the "NewBallid" command when a new ball is kicked.
'
'______________________________________________________________________________________
'
'		================================================
'		======== Ball to Ball Collision Effects ========
'		================================================
'			A brief description of operation
'
' Features...
'
' * This code senses ball-to-ball proximity to determine a collision and then calculates
' the collision force (cForce) to select a varying sound level or volume.
'
' * Any number of sound levels/files can be used and set by the table author.
'
' * Any number of balls can be set by the author, however the quantity is limited by what
' the individual computer can handle. The majority of tables use only a few balls at
' one time, so hopefully this shouldn't be an issue for most people.
'
' To combat this, the XYdata_Timer interval is self regulating to help retain performance.
' There is also an auto-shutoff, "coff" collision off variable, which is triggered by
' the timer interval if it should go too high.
'
' The main elements or commands used for this B2B collision sound effects are...
' 1) PlaySound("collide" & cForce)
'	This line selects and plays the proper wav file, combining "collide" with the
'	collision force for a variable sound level or volume. So the files are named...
'		"collide0", "collide1"... thru "collide9".
'
' 2) cForce = Cint((abs(TotalVel(cb1,id3)*Cos(cAngle-bAngle1))+abs(TotalVel(cb2,id3)*Cos(cAngle-bAngle2))))
'	There are more lines for the cForce calculations, but this main equation works by
'	taking the total velocity of each ball and multiplying it by the difference between
'	the collision angle and the angle of the traveling ball. In other words, a head on
'	collision and/or higher velocity produces a louder sound than a glancing blow.
'
' 3) XYdata_Timer...
'	This timer collects the balls' coordinates and velocities. It then determines
'	if two balls are close enough for a collision to occur.
'
' 4) Identifying the balls for reading the ball coordinates and velocities...
'	Unfortunately balls don't have scriptable hit events, so they must be identified
'	and set as an object whenever they are created. Balls then need to be marked as
'	inactive when one is destroyed. This is taken care of by the "NewBallID" and
'	"ClearBallid" subs.
'
'=======================================================
' Detailed descriptions are given below within the code
'=======================================================

Option Explicit

ReDim cball(tnopb), ballStatus(tnopb)
Dim iball, cnt, coff, errMessage

XYdata.interval = 1			' Timer interval starts at 1 for the highest ball data sample rate
coff = False				' Collision off set to false

For cnt = 0 to ubound(ballStatus)	' Initialize/clear all ball stats, 1 = active, 0 = non-existant
	ballStatus(cnt) = 0
Next

'======================================================
' <<<<<<<<<<<<<< Ball Identification >>>>>>>>>>>>>>
'======================================================
' Call this sub from every kicker(or plunger) that creates a ball.
Sub NewBallID						' Assign new ball object and give it ID for tracking
	For cnt = 1 to ubound(ballStatus)	' Loop through all possible ball IDs
	If ballStatus(cnt) = 0 Then		' If ball ID is available...
	Set cball(cnt) = ActiveBall		' Set ball object with the first available ID
	cball(cnt).uservalue = cnt		' Assign the ball's uservalue to it's new ID
	ballStatus(cnt) = 1				' Mark this ball status active
	ballStatus(0) = ballStatus(0)+1 ' Increment ballStatus(0), the number of active balls
	If coff = False Then			' If collision off, overrides auto-turn on collision detection
									' If more than one ball active, start collision detection process
	If ballStatus(0) > 1 and XYdata.enabled = False Then XYdata.enabled = True
	End If
	Exit For					' New ball ID assigned, exit loop
	End If
	Next
'	Debugger					' For demo only, display stats
End Sub

' Call this sub from every kicker that destroys a ball, before the ball is destroyed.
Sub ClearBallid
	On Error Resume Next				' Error handling for debugging purposes
	iball = ActiveBall.uservalue		' Get the ball ID to be cleared
	cball(iball).UserValue = 0			' Clear the ball ID
	If Err Then Msgbox Err.description & vbCrLf & iball
		ballStatus(iBall) = 0			' Clear the ball status
	ballStatus(0) = ballStatus(0)-1		' Subtract 1 ball from the # of balls in play
	On Error Goto 0
End Sub

'=====================================================
' <<<<<<<<<<<<<<<<< XYdata_Timer >>>>>>>>>>>>>>>>>
'=====================================================
' Ball data collection and B2B Collision detection.
ReDim baX(tnopb,4), baY(tnopb,4), bVx(tnopb,4), bVy(tnopb,4), TotalVel(tnopb,4)
Dim cForce, bDistance, nosf, xyTime, cFactor, id, id2, id3, B1, B2

Sub XYdata_Timer()
	' xyTime... Timers will not loop or start over 'til it's code is finished executing. To maximize
	' performance, at the end of this timer, if the timer's interval is shorter than the individual
	' computer can handle this timer's interval will increment by 1 millisecond.
	xyTime = Timer+(XYdata.interval*.001)	' xyTime is the system timer plus the current interval time
	' Ball Data... When a collision occurs a ball's velocity is often less than it's velocity before the
	' collision, if not zero. So the ball data is sampled and saved for four timer cycles.
	If id2 >= 4 Then id2 = 0						' Loop four times and start over
	id2 = id2+1										' Increment the ball sampler ID
	For id = 1 to ubound(ballStatus)				' Loop once for each possible ball
	If ballStatus(id) = 1 Then						' If ball is active...
		baX(id,id2) = round(cball(id).x,2)			' Sample x-coord
		baY(id,id2) = round(cball(id).y,2)			' Sample y-coord
		bVx(id,id2) = round(cball(id).velx,2)		' Sample x-velocity
		bVy(id,id2) = round(cball(id).vely,2)		' Sample y-velocity
		TotalVel(id,id2) = (bVx(id,id2)^2+bVy(id,id2)^2)		' Calculate total velocity
		If TotalVel(id,id2) > TotalVel(0,0) Then TotalVel(0,0) = int(TotalVel(id,id2))
	End If
	Next
	' Collision Detection Loop - check all possible ball combinations for a collision.
	' bDistance automatically sets the distance between two colliding balls. Zero milimeters between
	' balls would be perfect, but because of timing issues with ball velocity, fast-traveling balls
	' prevent a low setting from always working, so bDistance becomes more of a sensitivity setting,
	' which is automated with calculations using the balls' velocities.
	' Ball x/y-coords plus the bDistance determines B2B proximity and triggers a collision.
	id3 = id2 : B2 = 2 : B1 = 1						' Set up the counters for looping
	Do
	If ballStatus(B1) = 1 and ballStatus(B2) = 1 Then	' If both balls are active...
		bDistance = int((TotalVel(B1,id3)+TotalVel(B2,id3))^1.04)
		If ((baX(B1,id3)-baX(B2,id3))^2+(baY(B1,id3)-baY(B2,id3))^2)<2800+bDistance Then collide B1,B2 : Exit Sub
		End If
		B1 = B1+1							' Increment ball1
		If B1 >= ubound(ballStatus) Then Exit Do		' Exit loop if all ball combinations checked
		If B1 >= B2 then B1 = 1:B2 = B2+1				' If ball1 >= reset ball1 and increment ball2
	Loop

	If ballStatus(0) <= 1 Then XYdata.enabled = False	' Turn off timer if one ball or less

	If XYdata.interval >= 40 Then coff = True : XYdata.enabled = False	' Auto-shut off
	If Timer > xyTime * 3 Then coff = True : XYdata.enabled = False		' Auto-shut off
	If Timer > xyTime Then XYdata.interval = XYdata.interval+1			' Increment interval if needed
End Sub

'=========================================================
' <<<<<<<<<<< Collide(ball id1, ball id2) >>>>>>>>>>>
'=========================================================
'Calculate the collision force and play sound accordingly.
Dim cTime, cb1,cb2, avgBallx, cAngle, bAngle1, bAngle2

Sub Collide(cb1,cb2)
' The Collision Factor(cFactor) uses the maximum total ball velocity and automates the cForce calculation, maximizing the
' use of all sound files/volume levels. So all the available B2B sound levels are automatically used by adjusting to a
' player's style and the table's characteristics.
	If TotalVel(0,0)/1.8 > cFactor Then cFactor = int(TotalVel(0,0)/1.8)
' The following six lines limit repeated collisions if the balls are close together for any period of time
	avgBallx = (bvX(cb2,1)+bvX(cb2,2)+bvX(cb2,3)+bvX(cb2,4))/4
	If avgBallx < bvX(cb2,id2)+.1 and avgBallx > bvX(cb2,id2)-.1 Then
	If ABS(TotalVel(cb1,id2)-TotalVel(cb2,id2)) < .000005 Then Exit Sub
	End If
	If Timer < cTime Then Exit Sub
	cTime = Timer+.1				' Limits collisions to .1 seconds apart
' GetAngle(x-value, y-value, the angle name) calculates any x/y-coords or x/y-velocities and returns named angle in radians
	GetAngle baX(cb1,id3)-baX(cb2,id3), baY(cb1,id3)-baY(cb2,id3),cAngle	' Collision angle via x/y-coordinates
	id3 = id3 - 1 : If id3 = 0 Then id3 = 4	' Step back one xyData sampling for a good velocity reading
	GetAngle bVx(cb1,id3), bVy(cb1,id3), bAngle1	' ball 1 travel direction, via velocity
	GetAngle bVx(cb2,id3), bVy(cb2,id3), bAngle2	' ball 2 travel direction, via velocity
' The main cForce formula, calculating the strength of a collision
	cForce = Cint((abs(TotalVel(cb1,id3)*Cos(cAngle-bAngle1))+abs(TotalVel(cb2,id3)*Cos(cAngle-bAngle2))))
		If cForce < 4 Then Exit Sub			' Another collision limiter
	cForce = Cint((cForce)/(cFactor/nosf))	' Divides up cForce for the proper sound selection.
	If cForce > nosf-1 Then cForce = nosf-1	' First sound file 0(zero) minus one from number of sound files
	PlaySound("collide" & cForce)			' Combines "collide" with the calculated sound level and play sound
End Sub

'=================================================
' <<<<<<<< GetAngle(X, Y, Anglename) >>>>>>>>
'=================================================
' A repeated function which takes any set of coordinates or velocities and calculates an angle in radians.
Dim Xin,Yin,rAngle,Radit,wAngle,Pi
Pi = Round(4*Atn(1),6)			'3.1415926535897932384626433832795

Sub GetAngle(Xin, Yin, wAngle)
	If Sgn(Xin) = 0 Then
		If Sgn(Yin) = 1 Then rAngle = 3 * Pi/2 Else rAngle = Pi/2
		If Sgn(Yin) = 0 Then rAngle = 0
	Else
		rAngle = atn(-Yin/Xin)			' Calculates angle in radians before quadrant data
	End If
	If sgn(Xin) = -1 Then Radit = Pi Else Radit = 0
	If sgn(Xin) = 1 and sgn(Yin) = 1 Then Radit = 2 * Pi
	wAngle = round((Radit + rAngle),4)		' Calculates angle in radians with quadrant data
	'"wAngle = round((180/Pi) * (Radit + rAngle),4)" ' Will convert radian measurements to degrees - to be used in future
End Sub
