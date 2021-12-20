Import-Module Pode -MaximumVersion 2.99.99 -Force
Import-Module ..\src\Pode.Game.psm1 -Force

Start-PodeServer -StatusPageExceptions Show {
    # add a simple endpoint
    Add-PodeEndpoint -Address localhost -Port 8090 -Protocol Http
    New-PodeLoggingMethod -Terminal | Enable-PodeErrorLogging

    # set the use of pode.game
    Use-PodeGame -Width 800 -Height 600 #-DebugMode

    # view engine
    Set-PodeViewEngine -Type Pode

    # add home route, with html
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


#TODO: game reset
#TODO: high-score