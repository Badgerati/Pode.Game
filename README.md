# <img src="https://github.com/Badgerati/Pode/blob/develop/images/icon.png?raw=true" width="25" /> Pode.Game

> This is still a work in progress, until v1.0.0 expect possible breaking changes in some releases.

[![MIT licensed](https://img.shields.io/badge/license-MIT-blue.svg)](https://raw.githubusercontent.com/Badgerati/Pode.Game/master/LICENSE.txt)
[![GitHub Actions](https://img.shields.io/endpoint.svg?url=https%3A%2F%2Factions-badge.atrox.dev%2Fbadgerati%2Fpode.game%2Fbadge&style=flat&label=GitHub)](https://actions-badge.atrox.dev/badgerati/pode.game/goto)
[![Discord](https://img.shields.io/discord/887398607727255642)](https://discord.gg/fRqeGcbF6h)
[![GitHub Sponsors](https://img.shields.io/github/sponsors/Badgerati?color=%23ff69b4&logo=github&style=flat&label=Sponsers)](https://github.com/sponsors/Badgerati)

> 💝 A lot of my free time, evenings, and weekends goes into making Pode happen; please do consider sponsoring as it will really help! 😊

This is a 2D game framework for use with the [Pode](https://github.com/Badgerati/Pode) PowerShell web server (v2.5.0+). It allows you to create 2D games purely with PowerShell!

## 📦 Libraries

The main library used by Pode.Game is [Phaser](https://phaser.io) ([GitHub](https://github.com/photonstorm/phaser)), and I highly recommend checking them out if you want to explore making games in more depth! 😄

## 📘 Documentation

Coming soon.

For now, see the examples below, in `./examples`, or explore the code 😀

## 🚀 Features

* Build 2D games with PowerShell!
* Images/Sprites support
* Music and Sounds
* Particle effects
* Keyboard/Mouse input support
* Scene support
* Custom logic on Events and Collision
* ...plus loads more to come!

## 📦 Install

Coming soon.

You'll need to install [Pode](https://github.com/Badgerati/Pode) (ie: `Install-Module -Name Pode`), and clone this repository. Once cloned, if you have InvokeBuild, run `Invoke-Build Build` at the root, and then directly import for `./src/Pode.Game.psm1` file.

## 🔥 Examples

### 🏓 Pong

Below you'll find an example of writing a simple version of the game Pong in Pode.Game. There are 2 paddles and 1 ball. The ball will bounce between the paddles, and hitting either side of the screen will reset the game and bump the relevant player's score:

```powershell
Import-Module Pode -MaximumVersion 2.99.99 -Force
Import-Module ..\src\Pode.Game.psm1 -Force

Start-PodeServer {
    # add a simple endpoint
    Add-PodeEndpoint -Address localhost -Port 8090 -Protocol Http

    # set the use of pode.game
    Use-PodeGame -Width 800 -Height 600

    # view engine, and default route
    Set-PodeViewEngine -Type Pode
    Add-PodeRoute -Method Get -Path '/' -ScriptBlock {
        Write-PodeViewResponse -Path 'index' -Data @{ Game = Get-PodeGameHtml }
    }

    # mount images
    Mount-PodeGameImage -Id 'ball' -Path '/assets/ball.png'
    Mount-PodeGameImage -Id 'paddle' -Path '/assets/paddle.png'
    Mount-PodeGameImage -Id 'midfield' -Path '/assets/midfield.png'

    # default scene
    Add-PodeGameScene -Name 'Default' -EnableInput -Content {
        # midfield - static ground - no collision
        Add-PodeGameGroup -Name 'midfield' -Static -Objects @(
            0..10 | ForEach-Object {
                New-PodeGameImage -ImageId 'midfield' -X 400 -Y ($_ * 140) |
                    Set-PodeGameScale -X 0.9 -Y 0.9
            }
        )

        # player 1
        $paddle1 = New-PodeGameImage -ImageId 'paddle' -X 70 -Y 300 |
            Set-PodeGameCollide -WorldBounds Collide -Immovable |
            Set-PodeGameScale -X 0.9 -Y 0.9

        $player1 = New-PodeGamePlayer -Name 'player1' -Texture $paddle1 -Up 'W' -Down 'S' -MoveSpeed 400 -Add

        New-PodeGameText -Name 'score1' -X 320 -Y 50 -FontSize '40px' -FontFamily 'monospace' -Add |
            Watch-PodeGameObject -Target $player1 -Property 'stats.score' |
            Out-Null

        # player 2
        $paddle2 = New-PodeGameImage -ImageId 'paddle' -X 730 -Y 300 |
            Set-PodeGameCollide -WorldBounds Collide -Immovable |
            Set-PodeGameScale -X 0.9 -Y 0.9

        $player2 = New-PodeGamePlayer -Name 'player2' -Texture $paddle2 -Up 'Up' -Down 'Down' -MoveSpeed 400 -Add

        New-PodeGameText -Name 'score2' -X 450 -Y 50 -FontSize '40px' -FontFamily 'monospace' -Add |
            Watch-PodeGameObject -Target $player2 -Property 'stats.score' |
            Out-Null

        # ball - world collide
        $ball = New-PodeGameImage -ImageId 'ball' -X 400 -Y 300 -Add |
            Set-PodeGameCollide -WorldBounds Collide -BoundingVolume Circle |
            Set-PodeGameBounce -X 1 -Y 1 |
            Set-PodeGameScale -X 0.9 -Y 0.9 |
            Set-PodeGameScore -Value 1 |
            Set-PodeGameVelocity -X 300 -Y (Get-Random -Minimum 100 -Maximum 300)

        # walls
        $wall1 = New-PodeGameImage -Name 'wall1' -ImageId 'paddle' -X -10 -Y 300 -Add |
            Set-PodeGameCollide -Immovable |
            Set-PodeGameScale -Y 6.0

        $wall2 = New-PodeGameImage -Name 'wall2' -ImageId 'paddle' -X 810 -Y 300 -Add |
            Set-PodeGameCollide -Immovable |
            Set-PodeGameScale -Y 6.0

        # collisions - paddles: bounce
        Add-PodeGameDetection -Type Collide -Source $player1 -Target $ball
        Add-PodeGameDetection -Type Collide -Source $player2 -Target $ball

        # collisions - walls: reset game
        $reset = @(
            Update-PodeGameImage -Name 'ball' -X 400 -Y 300 |
                Set-PodeGameVelocity -X -300,300 -Y @{ Min = -300; Max = 300 }
        )

        Add-PodeGameDetection -Type Collide -Source $wall1 -Target $ball -Reference $player2 -Score Reference -Actions $reset
        Add-PodeGameDetection -Type Collide -Source $wall2 -Target $ball -Reference $player1 -Score Reference -Actions $reset
    }
}
```

First, we mount the assets to be used, and then we create a Default scene for the game. In the scene, we create the player 1/2 paddles, and the ball. The player objects bind the up/down controls for each player (ie: Up/Down and W/S keys). The ball is set to collide and bounce with the world, and set to have a random velocity.

The walls are created to reset the game if the ball hits them. There's collision between the ball/paddles for bouncing, and when the ball hits a wall it's also set to bump the relevant player's score.

![pong](/images/pong.png)

### ☄ Asteroids

Now for a more crazy example, below is the Pode.Game script that will build a simple game of Asteroids. We have the ship in the middle, which rotates via the mouse; fire is left-click and thrust is right-click. The asteroids are added every few seconds, and break up into small chunks:

```powershell
Import-Module Pode -MaximumVersion 2.99.99 -Force
Import-Module ..\src\Pode.Game.psm1 -Force

Start-PodeServer {
    # add a simple endpoint
    Add-PodeEndpoint -Address localhost -Port 8090 -Protocol Http
    New-PodeLoggingMethod -Terminal | Enable-PodeErrorLogging

    # set the use of pode.game
    Use-PodeGame -Width 800 -Height 600 #-DebugMode

    # view engine
    Set-PodeViewEngine -Type Pode
    Add-PodeRoute -Method Get -Path '/' -ScriptBlock {
        Write-PodeViewResponse -Path 'index' -Data @{ Game = Get-PodeGameHtml }
    }

    # mount images
    Mount-PodeGameImage -Id 'ship' -Path '/assets/ship.png'
    Mount-PodeGameImage -Id 'asteroid' -Path '/assets/asteroid.png'
    Mount-PodeGameImage -Id 'laser' -Path '/assets/ball.png'

    # starfield scene
    $starfield = Add-PodeGameSceneInbuilt -Type Starfield

    # default scene
    Add-PodeGameScene -Name 'Default' -EnableInput -Scenes $starfield -Content {
        # lasers
        $lasers = Add-PodeGameGroup -Name 'lasers'

        # explosion
        New-PodeGameParticleExplosion -Name 'explosion' -Colour 'white' -Add | Out-Null

        # player - ship - mouse
        $ship = New-PodeGameImage -ImageId 'ship' -X 400 -Y 300 |
            Set-PodeGameCollide -WorldBounds Wrap -BoundingVolume Circle |
            Set-PodeGameScale -X 0.6 -Y 0.6 |
            Set-PodeGameDrag -X 0.6 -Y 0.6 -Damping |
            Set-PodeGameVelocity -Max 300 |
            Register-PodeGameEvent -Type Disable -Particles 'explosion' -Actions @(Suspend-PodeGame -Finish)

        # add laser
        $fire = @(
            Update-PodeGameGroup -Name 'lasers' -Objects @(
                New-PodeGameImage -ImageId 'laser' |
                    Set-PodeGamePosition -Target 'sender' |
                    Set-PodeGameAngle -Target 'sender' |
                    Set-PodeGameCollide -WorldBounds Disable -BoundingVolume Circle -Immovable |
                    Set-PodeGameVelocity -Angular 500 -Max 500 |
                    Set-PodeGameScale -X 0.2 -Y 0.2
            )
        )

        # player - toggle mouse/keyboard controls
        $player = New-PodeGamePlayer -Name 'player' -Texture $ship -ControlType Rotate -Mouse -Rotate 'Move' -Up 'Right' -Fire 'Left' -FireActions $fire -FireRate 200 -MoveSpeed 300 -Add
        #$player = New-PodeGamePlayer -Name 'player' -Texture $ship -ControlType Rotate -Up 'W' -Left 'A' -Right 'D' -Fire 'Space' -FireActions $fire -FireRate 200 -MoveSpeed 300 -Add

        New-PodeGameText -Name 'score' -X 20 -Y 10 -FontSize '32px' -FontFamily 'monospace' -Type Number -Add |
            Watch-PodeGameObject -Target $player -Property 'stats.score' |
            Out-Null

        # asteroids - dynamic group and child routine
        $asteroid = New-PodeGameImage -ImageId 'asteroid' |
            Set-PodeGamePosition -X 0,800 -Y 0,600 |
            Set-PodeGameCollide -WorldBounds Wrap -BoundingVolume Circle -WrapPadding 1.0 |
            Set-PodeGameScale -X 0.8 -Y 0.8 |
            Set-PodeGameScore -Value 5 |
            Set-PodeGameVelocity -X @{ Min = -80; Max = 80 } -Y @{ Min = -80; Max = 80 } |
            Set-PodeGameAngle -Value 0.4 -Spin |
            Set-PodeGameBounce -X 1 -Y 1 |
            Register-PodeGameEvent -Type Disable -Particles 'explosion' -Routines 'asteroids_stage2'

        $asteroids = Add-PodeGameGroup -Name 'asteroids' -Objects @(
            0..1 | ForEach-Object {
                $asteroid
            }
        )

        # routine to create 2nd stage asteroids
        Add-PodeGameRoutine -Name 'asteroids_stage2' -Actions @(
            Update-PodeGameGroup -Name 'asteroids' -Objects @(
                1..2 | ForEach-Object {
                    New-PodeGameImage -ImageId 'asteroid' |
                        Set-PodeGamePosition -Target 'sender' |
                        Set-PodeGameCollide -WorldBounds Wrap -BoundingVolume Circle -WrapPadding 1.0 |
                        Set-PodeGameScale -X 0.6 -Y 0.6 |
                        Set-PodeGameScore -Value 10 |
                        Set-PodeGameVelocity -X @{ Min = -80; Max = 80 } -Y @{ Min = -80; Max = 80 } |
                        Set-PodeGameAngle -Value 0.4 -Spin |
                        Set-PodeGameBounce -X 1 -Y 1 |
                        Register-PodeGameEvent -Type Disable -Particles 'explosion' -Routines 'asteroids_stage3'
                }
            )
        )

        # routine to create 3rd stage asteroids
        Add-PodeGameRoutine -Name 'asteroids_stage3' -Actions @(
            Update-PodeGameGroup -Name 'asteroids' -Objects @(
                1..4 | ForEach-Object {
                    New-PodeGameImage -ImageId 'asteroid' |
                        Set-PodeGamePosition -Target 'sender' |
                        Set-PodeGameCollide -WorldBounds Wrap -BoundingVolume Circle -WrapPadding 1.0 |
                        Set-PodeGameScale -X 0.4 -Y 0.4 |
                        Set-PodeGameScore -Value 15 |
                        Set-PodeGameVelocity -X @{ Min = -80; Max = 80 } -Y @{ Min = -80; Max = 80 } |
                        Set-PodeGameAngle -Value 0.4 -Spin |
                        Set-PodeGameBounce -X 1 -Y 1 |
                        Register-PodeGameEvent -Type Disable -Particles 'explosion'
                }
            )
        )

        # timer to add more asteroids
        Add-PodeGameTimer -Name 'add_asteroid' -Interval 3000 -Count 100 -Loop -Actions @(
            Update-PodeGameGroup -Name 'asteroids' -Objects @($asteroid)
        )

        # collision - asteroids/asteroids
        Add-PodeGameDetection -Type Collide -Source $asteroids -Target $asteroids

        # collision - lasers/asteroids
        Add-PodeGameDetection -Type Collide -Source $lasers -Target $asteroids -Reference $player -Disable Source, Target -Score Reference

        # collision - asteroids/ship
        Add-PodeGameDetection -Type Collide -Source $asteroids -Target $player -Disable Source, Target
    }
}
```

Plus a starfield background scene, and some explosion particle effects 😄

![asteroids](/images/asteroids.png)
