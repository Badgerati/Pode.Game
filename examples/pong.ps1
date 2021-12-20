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

        # collisions - paddles
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