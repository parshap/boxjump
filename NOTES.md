## Actions net delay


50ms latency

C1 req		punch		Tc=0			go to pending | do jump
S	recv	punch		Ts=100+50=150
S	exec	punch T=200	Ts=150			schedule punch | do jump
C1	recv	punch T=200	Tc=100			schedule punch | n/a

20 ms latency

C2	req		punch		Tc=0
S	recv	punch		Ts=100+20=120
S	exec	punch T=200	Ts=120
C1	recv	punch T=200	Tc=40


100ms latency

C1	req		punch		Tc=0
S	recv	punch		Ts=100+100=200
S	exec	punch T=200	Ts=200
C1 recv		punch T=200 Tc=200


120ms latency

C1	req		punch		Tc=0
S	recv	punch		Ts=100+120=220
S	exec	punch T=220	Ts=220
C1 recv		punch T=220 Tc=240


#

## Predict
Called by the client at the time the action request is sent.

Player emits `predict-action:actionid` event.

## S Perform (request time)
Called on the server in response to an action request.

Player emits `action:actionid`.

## C Perform (perform time)
Called on the client when the server broadcasts actions.

Player emits `action:actionid`.


## Time considerations

Predict - predicts outcome of action being requested, now

Schedule
 - the action request time
 - the current time
 - delay: how late we are to process the action request

Perform
 - The current time
 - delay: how late we are to perform the scheduled action

scheduleProxy
 - the action perform time
 - the current time

## Ability Examples


jab player proxy: none
jab proxy: do hit test

pucnh player proxy: perform
punch proxy: perform

### Jab


predict: do animation
s perform: do hit test
c perform:

### Punch

predict: do prelim animation
s perform: do hit test at t -> reduce hp
c perform: do animation at t; do hit test at t -> do animation

```coffeescript

class Punch

	predict: ->
		@trigger "predict-action" # prelim animation will trigger

	schedule: (time, requestTime, delay) ->
		requestTime + 500

	perform: (time, delay) ->
		# do hit test (for a couple frames or whatever)
		@trigger "action"

	scheduleProxy: (time, actionTime) ->
		actionTime

	proxy: (time, delay) ->
		# do hit test (for a couple frames or whatever)
		@trigger "action"


class Player

	# Predicts the outcome of client requesting the current action *now*.
	predictAction: (action) ->
		@actions.push action
		action.predict()

	# Schedules to perform an action at the given time.
	performAction: (time, action) ->
		

 # Client on action request
action = new Punch player
if action.predictCan()
	player.predictAction action
	queue action

 # Server on action request
player.performAction time, action

 # Server broadcast action
send time, action

 # Client proxy action on receive
player.proxyAction time, action

 # ## Other things need to happen outside of Punch

 # View - Prelim animation on "predict-action"
 # View - Animation on "action"
 # View - Animation on success hits

 # Game - Server should subtract health on success hits


```

### Jump

predict: do jump
s perform: do jump
c perform: n/a
