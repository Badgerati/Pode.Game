Import-Module Pode -MaximumVersion 2.99.99 -Force
Import-Module ..\src\Pode.Game.psm1 -Force

<#
This is the Phaser example tutorial found here:
http://phaser.io/tutorials/making-your-first-phaser-3-game/part1
#>

Start-PodeServer -StatusPageExceptions Show {
    # add a simple endpoint
    Add-PodeEndpoint -Address localhost -Port 8090 -Protocol Http
    New-PodeLoggingMethod -Terminal | Enable-PodeErrorLogging

    # set the use of pode.game
    Use-PodeGame -Width 800 -Height 600 -GravityY 300

    # view engine
    Set-PodeViewEngine -Type Pode

    # add home route, with html
    Add-PodeRoute -Method Get -Path '/' -ScriptBlock {
        Write-PodeViewResponse -Path 'index' -Data @{ Game = Get-PodeGameHtml }
    }

    # add audio
    Mount-PodeGameMusic -Id 'background' -Path '/audio/background.mp3'
    Mount-PodeGameSound -Id 'electric' -Path '/audio/electric.mp3'
    Mount-PodeGameSound -Id 'explosion' -Path '/audio/explosion.mp3' -PoolSize 1

    # add images
    Mount-PodeGameImage -Id 'sky' -Path '/assets/sky.png'
    Mount-PodeGameImage -Id 'ground' -Path '/assets/platform.png'
    Mount-PodeGameImage -Id 'star' -Path '/assets/star.png'
    Mount-PodeGameImage -Id 'bomb' -Path '/assets/bomb.png'

    # add sprites
    Mount-PodeGameSpriteSheet -Id 'dude' -Path '/assets/dude.png' -Width 32 -Height 48



    # default scene
    Add-PodeGameScene -Name 'Default' -EnableInput -Content {
        # music/sounds
        Add-PodeGameMusic -AudioId 'background' -Volume 0.5 -Loop -Play | Out-Null
        Add-PodeGameSound -AudioId 'electric' -Volume 0.5 -Rate 1.5 | Out-Null
        Add-PodeGameSound -AudioId 'explosion' -Volume 0.5 -PoolSize 1 | Out-Null

        # sky
        New-PodeGameImage -ImageId 'sky' -X 400 -Y 300 -Static -Add | Out-Null

        # platforms
        $platforms = Add-PodeGameGroup -Name 'platforms' -Static -Objects @(
            New-PodeGameImage -ImageId 'ground' -X 400 -Y 568 | Set-PodeGameScale -X 2 -Y 2
            New-PodeGameImage -ImageId 'ground' -X 600 -Y 400
            New-PodeGameImage -ImageId 'ground' -X 50 -Y 250
            New-PodeGameImage -ImageId 'ground' -X 750 -Y 220
        )

        # particles
        New-PodeGameParticleExplosion -Name 'explosion' -Colour 'yellow' -Add | Out-Null
        New-PodeGameParticleFire -Name 'fire' -Colour 'orange' -Add | Out-Null

        # player
        # default anims: left, right, up, down, jump, crouch, stop
        $sprite = New-PodeGameSprite -SpriteId 'dude' -X 100 -Y 450 |
            Set-PodeGameCollide -WorldBounds Collide |
            Set-PodeGameBounce -X 0.2 -Y 0.2 |
            Add-PodeGameSpriteAnimation -Type 'left' -Start 0 -End 3 -Rate 10 |
            Add-PodeGameSpriteAnimation -Type 'right' -Start 5 -End 8 -Rate 10 |
            Add-PodeGameSpriteAnimation -Type 'stop' -Start 4 -Rate 20

        $player = New-PodeGamePlayer -Name 'player' -Texture $sprite -Left 'A' -Right 'D' -Jump 'Space' -MoveSpeed 160 -JumpSpeed 330 -Add

        # score
        New-PodeGameText -Name 'score' -Value 'Score: ' -X 16 -Y 16 -FontSize '32px' -FontFamily 'monospace' -Type Number -Add |
            Watch-PodeGameObject -Target $player -Property 'stats.score' |
            Out-Null

        #TODO: counter / variable

        # stars
        $stars = Add-PodeGameGroup -Name 'stars' -Objects @(
            foreach ($i in 1..12) {
                New-PodeGameImage -ImageId 'star' -X (12 + (70 * ($i - 1))) -Y 0 |
                    Set-PodeGameBounce -Y 0.5 |
                    Set-PodeGameScore -Value 10 |
                    Register-PodeGameEvent -Type Disable -Sound 'electric' -Particles 'explosion'
            }
        )

        # bombs
        $bombs = Add-PodeGameGroup -Name 'bombs'

        # collision
        Add-PodeGameDetection -Type Collide -Source $player -Target $platforms
        Add-PodeGameDetection -Type Collide -Source $stars -Target $platforms
        Add-PodeGameDetection -Type Collide -Source $bombs -Target $platforms

        # end game if bomb hits player
        Add-PodeGameDetection -Type Collide -Source $player -Target $bombs -Disable Target -ScriptBlock {
            param($source, $target)

            # update sprite
            Update-PodeGameSprite -Name 'dude' -Tint '0xff0000' -Animation 'stop'

            # end game
            Suspend-PodeGame -Finish
        }

        # collect stars
        Add-PodeGameDetection -Type Overlap -Source $player -Target $stars -Disable Target -Score Source -ScriptBlock {
            param($source, $target)

            # only drop bomb if all stars collected, and reset the stars
            if (($source.data.stats.score -gt 0) -and ($source.data.stats.score % 120 -eq 0)) {
                # drop bomb
                $x = 0
                if ($source.self.x -lt 400) {
                    $x = Get-Random -Minimum 400 -Maximum 800
                }
                else {
                    $x = Get-Random -Minimum 0 -Maximum 400
                }

                Update-PodeGameGroup -Name 'bombs' -Objects @(
                    New-PodeGameImage -ImageId 'bomb' -X $x -Y 16 |
                        Set-PodeGameCollide -WorldBounds Collide -BoundingVolume Circle |
                        Set-PodeGameGravity -Disable |
                        Set-PodeGameBounce -X 1 -Y 1 |
                        Set-PodeGameVelocity -Y 20 -X (Get-Random -Minimum -200 -Maximum 200) |
                        Register-PodeGameEvent -Type Disable -Sound 'explosion' -Particles 'explosion'
                )

                # reset stars
                Clear-PodeGameGroup -Name 'stars'

                Update-PodeGameGroup -Name 'stars' -Objects @(
                    foreach ($i in 1..12) {
                        New-PodeGameImage -ImageId 'star' -X (12 + (70 * ($i - 1))) -Y 0 |
                            Set-PodeGameBounce -Y 0.5 |
                            Set-PodeGameScore -Value 10 |
                            Register-PodeGameEvent -Type Disable -Sound 'electric' -Particles 'explosion'
                    }
                )
            }
        }
    }


}




<#

graphics
- Circle
- Ellipse
- Rect (add -Rounded to make RoundedRect, ie: "-Rounded 20", def=0)
- Triangle

#>

#New-PodeGameCircle -Name -Colour -Radius -X -Y -Add
#New-PodeGameRectangle -Name -Colour -Width -Height -X -Y [-Radius] -Add

<#

#TODO:

- setDrag (ie, space)
- setFriction
- setVisible
- setDepth


#TODO: debug option: show mouse co-ords

#>