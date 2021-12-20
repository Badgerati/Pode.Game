function Use-PodeGame
{
    [CmdletBinding()]
    param(
        [Parameter()]
        [int]
        $Width = 800,

        [Parameter()]
        [int]
        $Height = 600,

        [Parameter()]
        [int]
        $GravityX = 0,

        [Parameter()]
        [int]
        $GravityY = 0,

        [switch]
        $DebugMode
    )

    # check pode version
    $mod = (Get-Module -Name Pode -ErrorAction Ignore | Sort-Object -Property Version -Descending | Select-Object -First 1)
    if (($null -eq $mod) -or ($mod.Version -lt [version]'2.5.0')) {
        throw "The Pode module is not loaded. You need at least Pode v2.5.0 to use this version of the Pode.Game module."
    }

    # ensure this module is exported into pode
    Export-PodeModule -Name Pode.Game

    # setup base state
    Set-PodeGameState -Name 'setup' -Value @{
        Size = @{
            Width = $Width
            Height = $Height
        }
        Physics = @{
            Gravity = @{
                X = $GravityX
                Y = $GravityY
            }
            Debug = $DebugMode.IsPresent
        }
        Scenes = @()
    }

    Set-PodeGameState -Name 'load' -Value @{
        Images = @()
        Sprites = @()
        BitmapFonts = @()
        Audio = @()
    }

    Set-PodeGameState -Name 'create' -Value @{
        Scenes = @{}
    }

    # get path to templates folder
    $templatePath = Get-PodeGameTemplatePath

    # add static route for libs
    Add-PodeStaticRoute -Path '/pode.game' -Source (Join-PodeGamePath $templatePath 'Public')

    # inbuilt asset mounts
    @('circle', 'rectangle', 'square', 'square_small', 'star', 'star_small') | ForEach-Object {
        Mount-PodeGameImage -Id "_pg_image_particle_$($_)_" -Path "/pode.game/assets/particles/$($_).png"
    }

    @('arcade') | ForEach-Object {
        Mount-PodeGameBitmapFont -Id "_pg_bitmap_font_$($_)_" -Path "/pode.game/assets/fonts/$($_).png" -XmlPath "/pode.game/assets/fonts/$($_).xml"
    }

    # setup and scenes
    Add-PodeRoute -Method Get -Path '/_pode_game_/setup' -ScriptBlock {
        Write-PodeJsonResponse -Value (Get-PodeGameState -Name 'setup')
    }

    # load
    Add-PodeRoute -Method Get -Path '/_pode_game_/load' -ScriptBlock {
        Write-PodeJsonResponse -Value (Get-PodeGameState -Name 'load')
    }
}

function Get-PodeGameHtml
{
    [CmdletBinding()]
    param()

    return "
        <script src='/pode.game/libs/phaser/phaser.min.js'></script>
        <script src='/pode.game/libs/jquery/jquery.min.js'></script>
        <script src='/pode.game/scripts/helpers.js'></script>
        <script src='/pode.game/scripts/scenes.js'></script>
        <script src='/pode.game/scripts/game.js'></script>
    "
}