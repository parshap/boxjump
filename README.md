Box Jump is an experiment with HTML5 games. It is an online multiplayer
action game using the DOM for rendering and WebSockets for
communication. Players move around, jump between platforms, and attack
opponent players. The objective is to stay alive and kill other players.
The vision is for Box Jump to be a persistent massively-multiplayer game
with an automatically-scaling programatically-generated map.

Interesting parts of the source include:

 * [2D physics simulation](lib/physics) with collision detection and
   resolution for AABBs
 * [Client-server game state
   synchronization](https://developer.valvesoftware.com/wiki/Source_Multiplayer_Networking)
   using interpolation, prediction, and other techniques
   [[1]](lib/server.coffee) [[2]](lib/client.coffee)
   [[3]](lib/game/actions/action.coffee)
 * [Node.js game server](lib/net) using [MessagePack](http://msgpack.org) over
   WebSockets
 * Model-View decoupling of [game logic](lib/game) and
   [rendering](lib/view) using events to communicate

# Components

 * App
 * Game
 * Physics
 * Renderer
 * Net


## Application

The *Application* component sets up the other components, handles application
states and the update loop. The *Server* and *Client* each have a separate
implementation of this component

While the client and server both run a game world, there exist some
fundamental differences in their behaviors.

 * The server is authoritative over the state of the game and processes
   all input to the game state. As the game state changes, the server
   sends updates to clients, which are simulating (as best as possible)
   the server's version of the world.

 * The client and server employ different techniques for hiding and
   lessening the affects of network latency.

 * The client sends input directly to the server instead of processing
   it with the local game state. To give immediate response to the user,
   it may also predict the outcome of the sent input.


### Server
In each update, the server will:

 * Process input from clients
 * Update the game state
 * Send any output to clients


### Client

Set up the network, connecting to the server.

In each update, the client will:

 * Process any input from input devices
 * Process any input from the server
 * Interpolate/extrapolate any game state from updates
 * Update the game state
 * Send any output to the server
 * Render the current game state


#### Interpolating
The client simulates the world at some point in the past. This amount of time
is referred to as the *lerp* time. This is done in an attempt to disguise the
affects of network latency.

When the client is updating the world at some time, it should already know
about the game's state at some other time in the future. It uses this future
state and a previously known one (from the past) to interpolate the state at
the current time.

Only a subset of the client's game state is updated this special manner. The
rest is updated normally.

#### Rendering
In practice, updating and rendering are more tightly coupled. The rendering
system (views) listen for events from the game state (models) to update the
visual state. The render step will perform any additional tasks to output
the updated visual state.

## Game

The *Game* component represents the game simulation (the world, models, logic,
etc.).

This component uses the *Physics* component to simulate the physical
properties of the game (e.g., collision).


### Prediction
While the client is designed to send its input to the game state
directly to the server, it may also attempt to predict the outcome of
that input and render it immediately to the client.

As the server receives the input and sends game updates as a response,
the client should correct any error in the prediction and conform to the
server's authoritative response.

## Physics

The *Physics* component simulates a subset of the game state that requires
physics calculations (e.g., collision tests, movement, gravity).

## Renderer

## Net

The *Net* component handles communication between the client and the server.
This component is split into two sub-components: the server and the client.

### Server

 * Listens for new connections from clients
 * Sends and receives messages from clients

### Client

 * Opens and maintains a connection to the server
 * Send and receive messages from the server

### Messages

All messages share a common format. They have a 1-byte message ID, and
optional additional typed parameters.


#### JoinRequest (`0x01`)

#### JoinResponse (`0x02`)
This message is sent as a successful reply to a Join Request message.
The only parameter is given the joining player's playerid.

#### ChatMessage (`0x0A`)
This message is sent to relay chat messages. The client sends this to
the server when the client enters a chat message, and the server
broadcasts it to all clients (including the original sender).

There are two arguments:

 * Player ID
 * Message (string)

#### GameState (`0x10`)
This message is sent from the server to the clients to inform them about
the current game state. This message contains the positions and
velocities of each player in the game.

The first parameter is the game time this state information is from.
An additional five parameters are sent for each player:

 * Player ID
 * X position
 * Y position
 * X velocity
 * Y velocity

#### PlayerLeave (`0x12`)
This message is sent from the server to all clients when a player
leaves. The only argument is the leaving player's id.

#### ActionRequest (`0x13`)
This message is sent from a client to the server to request performing
an action. The arguments are the action id and any additional action
arguments.

#### Action (`0x14`)
This message is sent from the server to clients to inform them about an
action taking place. Message arguments are:

 * The time the action was performed
 * The id of the player performing the action
 * The action id
 * Additional action arguments...

#### Health (`0x15`)
This message is sent from the server to clients to update a player's
current health. Message arguments are:

 * The time
 * Player id
 * Health value

### Encoding

All messages are encoded using the [MessagePack](http://msgpack.org)
format. Each message is represented as an array with the first element
being the 1-byte message ID and the remaining elements being any message
parameters.


### Time Synchronization


# Todo

 * Some game state needs to be advanced client-side to account for latency.
    * What about other players? If a rocket is advanced to account for the
      player's movement, it won't look right colliding with another player.
    * Should the person creating the rocket see it advanced? They need to see
      it collide with other players!

# Network

lerp=100ms
trip=50ms

 - None
 - Interpolation
 - Lag Compensation
 - Interpolation & Lag Compensation


## TODO

 * Synchronized time http://www.codewhore.com/howto1.html

 * The server needs to send periodic state updates, but also needs to send
   a packet *NOW* - should they piggyback? when?



# Physics

Body - a rigid body with the shape of an aabb (x, y, w, h)
    - filter what it can collide with
    - ? restitution (1: reverse velocity on collision, 0: velocity=0)
    - sensor: detect collision, but no response
    - have position and velocity; can apply force and impulse
    - contact vs touch

ContactConstraint - prevents penetration of bodies
World - collection of bodies and constraints that interact togethe


physics advance algorithm:

 - for each body
   move body
   - pos = pos + 0.5 * v * dt
   - v = v + a * dt
   - pos = pos + 0.5 * v * dt

   check for collisions at new position (and fire collision:before?)

   if not sensor
       resolve any broken contact constraints

       fire any touch/notouch events (for changes)

   if sensor
       fire any collision/nocollision events (for changes)


Challenges:

## left/right controls

moveRightV = body.velocity({x: 500, y: 0})

right = (active) ->
    if active then moveRightV.enable() else moveRightV.disable()


## jump velocity mechanics

must consider how left/right controls work for initial velocity

@todo

## collision start and end events

## client needs to store two states at a time
and interpolate between them

world.state() for getting/setting ?

## server does hit tests against rewinded world (- rtt - lerp)
