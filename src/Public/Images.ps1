function Add-PodeGameScene
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $Name,

        [Parameter()]
        [scriptblock]
        $Content,

        [Parameter()]
        [hashtable[]]
        $Scenes,

        [switch]
        $Active,

        [switch]
        $EnableInput,

        [switch]
        $PassThru
    )

    # scene config
    $global:Scene = @{
        Name = $Name
        Active = $Active.IsPresent
        Input = @{
            Enabled = $EnableInput.IsPresent
        }
    }

    # setup content
    $create = (Get-PodeGameState -Name 'create')
    $create.Scenes[$Name] = @{
        Content = @()
        Collision = @()
        Input = @()
        Routine = @()
        Scene = $Scenes
    }

    Invoke-PodeScriptBlock -ScriptBlock $Content

    # add scene
    $setup = Get-PodeGameState -Name 'setup'
    $setup.Scenes += $global:Scene

    # setup create route for scene
    Add-PodeRoute -Method Get -Path "/_pode_game_/scenes/$($Name)/create" -ScriptBlock {
        Write-PodeJsonResponse -Value (Get-PodeGameState -Name 'create').Scenes[$using:Name] -Depth 20
    }

    if ($PassThru) {
        return $global:Scene
    }
}

function Add-PodeGameSceneInbuilt
{
    [CmdletBinding()]
    param(
        [Parameter()]
        [ValidateSet('Starfield')]
        [string]
        $Type
    )

    switch ($Type.ToLowerInvariant()) {
        'starfield' {
            return New-PodeGameSceneStarfield
        }
    }
}

function Mount-PodeGameImage
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]
        $Id,

        [Parameter(Mandatory=$true)]
        [string]
        $Path
    )

    $loader = Get-PodeGameState -Name 'load'
    $loader.Images += @{
        ID = $Id
        Path = $Path
    }
}

function Mount-PodeGameMusic
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]
        $Id,

        [Parameter(Mandatory=$true)]
        [string]
        $Path
    )

    $loader = Get-PodeGameState -Name 'load'
    $loader.Audio += @{
        ID = $Id
        Path = $Path
    }
}

function Mount-PodeGameSound
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]
        $Id,

        [Parameter(Mandatory=$true)]
        [string]
        $Path,

        [Parameter()]
        [ValidateRange(1, 10)]
        [int]
        $PoolSize = 3
    )

    $loader = Get-PodeGameState -Name 'load'
    $loader.Audio += @{
        ID = $Id
        Path = $Path
        Pool = @{
            Size = $PoolSize
        }
    }
}

function Mount-PodeGameBitmapFont
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]
        $Id,

        [Parameter(Mandatory=$true)]
        [string]
        $Path,

        [Parameter(Mandatory=$true)]
        [string]
        $XmlPath
    )

    $loader = Get-PodeGameState -Name 'load'
    $loader.BitmapFonts += @{
        ID = $Id
        Path = $Path
        XmlPath = $XmlPath
    }
}

function Mount-PodeGameSpriteSheet
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]
        $Id,

        [Parameter(Mandatory=$true)]
        [string]
        $Path,

        [Parameter()]
        [string]
        $NormalMap,

        [Parameter(Mandatory=$true)]
        [double]
        $Width,

        [Parameter(Mandatory=$true)]
        [double]
        $Height,

        [Parameter()]
        [double]
        $Start = 0,

        [Parameter()]
        [double]
        $End = 0
    )

    $loader = Get-PodeGameState -Name 'load'
    $loader.Sprites += @{
        ID = $Id
        Path = $Path
        Frames = @{
            Width = $Width
            Height = $Height
            Start = $Start
            End = $End
        }
    }
}

function New-PodeGameParticleExplosion
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]
        $Name,

        [Parameter()]
        [string]
        $Colour,

        [Parameter()]
        [ValidateSet('Circle', 'Rectangle', 'Square', 'Star')]
        [string]
        $Shape = 'Rectangle',

        [Parameter()]
        [string]
        $Image,

        [switch]
        $Add
    )

    $params = @{
        Name = $Name
        Colour = $Colour
        Image = $Image
        Shape = $Shape
        AlphaStart = 0.8
        ScaleStart = 0.4
        ScaleEnd = 0.1
        SpeedXMin = -50
        SpeedXMax = 50
        SpeedYMin = -50
        SpeedYMax = 50
        AngleMin = -85
        AngleMax = -95
        RotateMin = -180
        RotateMax = 180
        LifespanMin = 1000
        LifeSpanMax = 1500
        BlendMode = 'Screen'
        Frequency = 0
        MaxParticles = 20
        Quantity = 20
        Add = $Add
    }

    return (New-PodeGameParticle @params)
}

function New-PodeGameParticleFire
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]
        $Name,

        [Parameter()]
        [string]
        $Colour,

        [Parameter()]
        [ValidateSet('Circle', 'Rectangle', 'Square', 'Star')]
        [string]
        $Shape = 'Rectangle',

        [Parameter()]
        [string]
        $Image,

        [switch]
        $Add
    )

    $params = @{
        Name = $Name
        Colour = $Colour
        Image = $Image
        Shape = $Shape
        AlphaStart = 0.8
        ScaleStart = 0.4
        ScaleEnd = 0.1
        SpeedXMin = -20
        SpeedXMax = 20
        SpeedYMin = -5
        SpeedYMax = 5
        AccelerationY = -100
        AngleMin = -85
        AngleMax = -95
        RotateMin = -180
        RotateMax = 180
        LifespanMin = 1000
        LifeSpanMax = 1100
        BlendMode = 'None'
        Frequency = 40
        Quantity = 4
        Add = $Add
    }

    return (New-PodeGameParticle @params)
}

function New-PodeGameParticle
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]
        $Name,

        [Parameter()]
        [string]
        $Colour,

        [Parameter()]
        [ValidateSet('Circle', 'Rectangle', 'Square', 'Star')]
        [string]
        $Shape = 'Rectangle',

        [Parameter()]
        [string]
        $Image,

        [Parameter()]
        [ValidateSet('None', 'Add', 'Screen', 'Multiply', 'Erase')]
        [string]
        $BlendMode = 'None',

        [Parameter()]
        [ValidateRange(0.0, 1.0)]
        [double]
        $AlphaStart = 1.0,

        [Parameter()]
        [ValidateRange(0.0, 1.0)]
        [double]
        $AlphaEnd = 0.0,

        [Parameter()]
        [ValidateRange(0.0, 5.0)]
        [double]
        $ScaleStart = 1.0,

        [Parameter()]
        [ValidateRange(0.0, 5.0)]
        [double]
        $ScaleEnd = 0.0,

        [Parameter()]
        [double]
        $SpeedXMin = 0.0,

        [Parameter()]
        [double]
        $SpeedXMax = 0.0,

        [Parameter()]
        [double]
        $SpeedYMin = 0.0,

        [Parameter()]
        [double]
        $SpeedYMax = 0.0,

        [Parameter()]
        [double]
        $AccelerationX = 0.0,

        [Parameter()]
        [double]
        $AccelerationY = 0.0,

        [Parameter()]
        [ValidateRange(-360.0, 360.0)]
        [double]
        $AngleMin = 0.0,

        [Parameter()]
        [ValidateRange(-360.0, 360.0)]
        [double]
        $AngleMax = 360.0,

        [Parameter()]
        [ValidateRange(-360.0, 360.0)]
        [double]
        $RotateMin = 0.0,

        [Parameter()]
        [ValidateRange(-360.0, 360.0)]
        [double]
        $RotateMax = 0.0,

        [Parameter()]
        [int]
        $LifespanMin = 1000,

        [Parameter()]
        [int]
        $LifespanMax = 1000,

        [Parameter()]
        [int]
        $Frequency = 0,

        [Parameter()]
        [int]
        $Quantity = 1,

        [Parameter()]
        [int]
        $MaxParticles = 0,

        [Parameter()]
        [double]
        $GravityX = 0.0,

        [Parameter()]
        [double]
        $GravityY = 0.0,

        [switch]
        $Add
    )

    $particles += @{
        Action = 'New'
        Type = 'Particle'
        Metadata = @{
            Name = $Name
            Colour = (ConvertFrom-PodeGameColour -Colour $Colour -AllowEmpty)
            Shape = $Shape
            Image = $Image
            BlendMode = $BlendMode
            Alpha = @{
                Start = $AlphaStart
                End = $AlphaEnd
            }
            Scale = @{
                Start = $ScaleStart
                End = $ScaleEnd
            }
            Speed = @{
                X = @{ Min = $SpeedXMin; Max = $SpeedXMax }
                Y = @{ Min = $SpeedYMin; Max = $SpeedYMax }
            }
            Acceleration = @{
                X = $AccelerationX
                Y = $AccelerationY
            }
            Angle = @{
                Min = $AngleMin
                Max = $AngleMax
            }
            Rotate = @{
                Min = $RotateMin
                Max = $RotateMax
            }
            Lifespan = @{
                Min = $LifespanMin
                Max = $LifespanMax
            }
            Frequency = $Frequency
            Quantity = $Quantity
            MaxParticles = $MaxParticles
            Gravity = @{
                X = $GravityX
                Y = $GravityY
            }
        }
    }

    if ($Add) {
        $particles | Add-PodeGameContent
    }

    return $particles
}

function Show-PodeGameParticle
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]
        $Name,

        [Parameter()]
        [double]
        $X = [int]::MinValue,

        [Parameter()]
        [double]
        $Y = [int]::MinValue,

        [Parameter()]
        [hashtable]
        $Follow
    )

    $pos = $null
    if (($X -ne [int]::MinValue) -and ($Y -ne [int]::MinValue)) {
        $pos = @{
            X = $X
            Y = $Y
        }
    }

    $fol = $null
    if ($null -ne $Follow) {
        $fol = @{
            Type = $Follow.Type
            Name = $Follow.Metadata.Name
        }
    }

    return @{
        Action = 'Show'
        Type = 'Particle'
        Metadata = @{
            Name = $Name
            Position = $pos
            Follow = $fol
        }
    }
}

function Add-PodeGameMusic
{
    [CmdletBinding()]
    param(
        [Parameter()]
        [string]
        $Name,

        [Parameter(Mandatory=$true)]
        [string]
        $AudioId,

        [Parameter()]
        [ValidateRange(0.0, 1.0)]
        [double]
        $Volume = 1.0,

        [Parameter()]
        [double]
        $Rate = 1.0,

        [switch]
        $Loop,

        [switch]
        $Play
    )

    $audio = @{
        Action = 'Add'
        Type = 'Music'
        Metadata = @{
            Name = Protect-PodeGameValue -Value $Name -Default $AudioId
            AudioId = $AudioId
            Volume = $Volume
            Rate = $Rate
            Loop = $Loop.IsPresent
            Play = $Play.IsPresent
        }
    }

    $audio | Add-PodeGameContent
    return $audio
}

function Add-PodeGameSound
{
    [CmdletBinding()]
    param(
        [Parameter()]
        [string]
        $Name,

        [Parameter(Mandatory=$true)]
        [string]
        $AudioId,

        [Parameter()]
        [ValidateRange(0.0, 1.0)]
        [double]
        $Volume = 1.0,

        [Parameter()]
        [double]
        $Rate = 1.0,

        [Parameter()]
        [ValidateRange(1, 10)]
        [int]
        $PoolSize = 3,

        [switch]
        $Play
    )

    $audio = @{
        Action = 'Add'
        Type = 'Sound'
        Metadata = @{
            Name = Protect-PodeGameValue -Value $Name -Default $AudioId
            AudioId = $AudioId
            Volume = $Volume
            Pool = @{
                Size = $PoolSize
            }
            Rate = $Rate
            Play = $Play.IsPresent
        }
    }

    $audio | Add-PodeGameContent
    return $audio
}

function Start-PodeGameMusic
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]
        $Name,

        [switch]
        $Force
    )

    return @{
        Action = 'Start'
        Type = 'Music'
        Metadata = @{
            Name = $Name
            Force = $Force.IsPresent
        }
    }
}

function Start-PodeGameSound
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]
        $Name,

        [switch]
        $Force
    )

    return @{
        Action = 'Start'
        Type = 'Sound'
        Metadata = @{
            Name = $Name
            Force = $Force.IsPresent
        }
    }
}

function New-PodeGameImage
{
    [CmdletBinding()]
    param(
        [Parameter()]
        [string]
        $Name,

        [Parameter(Mandatory=$true)]
        [string]
        $ImageId,

        [Parameter()]
        [double]
        $X = 0,

        [Parameter()]
        [double]
        $Y = 0,

        [Parameter()]
        [string]
        $Tint,

        [switch]
        $Static,

        [switch]
        $Add
    )

    $img = @{
        Action = 'New'
        Type = 'Image'
        Metadata = @{
            Name = Protect-PodeGameValue -Value $Name -Default $ImageId
            ImageId = $ImageId
            Tint = (ConvertFrom-PodeGameColour -Colour $Tint -AllowEmpty)
            Position = @{
                X = $X
                Y = $Y
            }
            Static = $Static.IsPresent
        }
    }

    if ($Add) {
        $img | Add-PodeGameContent
    }

    return $img
}

function New-PodeGameRectangle
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]
        $Name,

        [Parameter()]
        [double]
        $X = 0,

        [Parameter()]
        [double]
        $Y = 0,

        [Parameter()]
        [string]
        $Colour = 0xFFFFFF,

        [Parameter()]
        [ValidateRange(0.0, 1.0)]
        [double]
        $Alpha = 1.0,

        [Parameter(Mandatory=$true)]
        [double]
        $Width,

        [Parameter(Mandatory=$true)]
        [double]
        $Height,

        [Parameter()]
        [double]
        $Radius = 0,

        [switch]
        $Add
    )

    $graph = @{
        Action = 'New'
        Type = 'Graphic'
        Metadata = @{
            Name = $Name
            Type = 'Rectangle'
            Colour = (ConvertFrom-PodeGameColour -Colour $Colour)
            Alpha = $Alpha
            Position = @{
                X = $X
                Y = $Y
            }
            Size = @{
                Width = $Width
                Height = $Height
                Radius = $Radius
            }
        }
    }

    if ($Add) {
        $graph | Add-PodeGameContent
    }

    return $graph
}

function New-PodeGameSprite
{
    [CmdletBinding()]
    param(
        [Parameter()]
        [string]
        $Name,

        [Parameter(Mandatory=$true)]
        [string]
        $SpriteId,

        [Parameter()]
        [double]
        $X = 0,

        [Parameter()]
        [double]
        $Y = 0,

        [Parameter()]
        [string]
        $Tint,

        [switch]
        $Static,

        [switch]
        $Add
    )

    $sprite = @{
        Action = 'New'
        Type = 'Sprite'
        Metadata = @{
            Name = Protect-PodeGameValue -Value $Name -Default $SpriteId
            SpriteId = $SpriteId
            Position = @{
                X = $X
                Y = $Y
            }
            Tint = (ConvertFrom-PodeGameColour -Colour $Tint -AllowEmpty)
            Animations = @()
            Static = $Static.IsPresent
        }
    }

    if ($Add) {
        $sprite | Add-PodeGameContent
    }

    return $sprite
}

function Add-PodeGameSpriteAnimation
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true, ValueFromPipeline=$true)]
        [hashtable]
        $Sprite,

        [Parameter(Mandatory=$true)]
        [string]
        $Type,

        [Parameter(Mandatory=$true)]
        [int]
        $Start,

        [Parameter()]
        [int]
        $End = -1,

        [Parameter()]
        [int]
        $Rate = 10
    )

    $Sprite.Metadata.Animations += @{
        Type = $Type
        Name = $Sprite.Metadata.Name
        Frames = @{
            Start = $Start
            End = $End
            Rate = $Rate
        }
    }

    return $Sprite
}

function Start-PodeGameSpriteAnimation
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]
        $Name,

        [Parameter(Mandatory=$true)]
        [string]
        $Type,

        [switch]
        $Force
    )

    return @{
        Action = 'Start'
        Type = 'SpriteAnimation'
        Metadata = @{
            Name = $Name
            Type = $Type
            Force = $Force.IsPresent
        }
    }
}

function Add-PodeGameContent
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true, ValueFromPipeline=$true)]
        [hashtable]
        $InputObject
    )

    $creator = (Get-PodeGameState -Name 'create').Scenes[$global:Scene.Name]
    $creator.Content += $InputObject
}

function Add-PodeGameGroup
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]
        $Name,

        [Parameter()]
        [hashtable[]]
        $Objects,

        [switch]
        $Static
    )

    $group = @{
        Action = 'Add'
        Type = 'Group'
        Metadata = @{
            Name = $Name
            Objects = $Objects
            Static = $Static.IsPresent
        }
    }

    $group | Add-PodeGameContent
    return $group
}

function Update-PodeGameGroup
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]
        $Name,

        [Parameter()]
        [hashtable[]]
        $Objects
    )

    return @{
        Action = 'Update'
        Type = 'Group'
        Metadata = @{
            Name = $Name
            Objects = $Objects
        }
    }
}

function Clear-PodeGameGroup
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]
        $Name
    )

    return @{
        Action = 'Clear'
        Type = 'Group'
        Metadata = @{
            Name = $Name
        }
    }
}

function Add-PodeGameDetection
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [ValidateSet('Collide', 'Overlap')]
        [string]
        $Type,

        [Parameter(Mandatory=$true, ValueFromPipeline=$true)]
        [hashtable]
        $Source,

        [Parameter(Mandatory=$true)]
        [hashtable]
        $Target,

        [Parameter()]
        [hashtable]
        $Reference,

        [Parameter()]
        [scriptblock]
        $ScriptBlock,

        [Parameter()]
        [hashtable[]]
        $Actions,

        [Parameter()]
        [ValidateSet('None', 'Source', 'Target', 'Reference')]
        [string[]]
        $Disable = 'None',

        [Parameter()]
        [string]
        $Sound,

        [Parameter()] #TODO: ScoreFrom, ScoreTo (if no from, then assume Target)
        [ValidateSet('None', 'Source', 'Target', 'Reference')]
        [string[]]
        $Score = 'None'
    )

    if ($null -ne $ScriptBlock) {
        $url = "/_pode_game_/detection/$(New-Guid)/$($Type.ToLowerInvariant())"
        Add-PodeRoute -Method Post -Path $url -ScriptBlock {
            $result = Invoke-PodeScriptBlock -ScriptBlock $using:ScriptBlock -Arguments $WebEvent.Data.source, $WebEvent.Data.target, $WebEvent.Data.reference -Splat -Return

            if ($null -ne $result) {
                Write-PodeJsonResponse -Value $result
            }
        }
    }

    $rf = $null
    if ($null -ne $Reference) {
        $rf = @{
            Type = $Reference.Type
            Name = $Reference.Metadata.Name
        }
    }

    $creator = (Get-PodeGameState -Name 'create').Scenes[$global:Scene.Name]
    $creator.Collision += @{
        Type = $Type
        Metadata = @{
            Source = @{
                Type = $Source.Type
                Name = $Source.Metadata.Name
            }
            Target = @{
                Type = $Target.Type
                Name = $Target.Metadata.Name
            }
            Reference = $rf
            Disable = $Disable
            Score = $Score
            Sound = $Sound
            Actions = $Actions
            Url = $url
        }
    }
}

function Add-PodeGameRoutine
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]
        $Name,

        [Parameter()]
        [scriptblock]
        $ScriptBlock,

        [Parameter()]
        [hashtable[]]
        $Actions
    )

    if ($null -ne $ScriptBlock) {
        $url = "/_pode_game_/routine/$(New-Guid)/$($Name.ToLowerInvariant())"
        Add-PodeRoute -Method Post -Path $url -ScriptBlock {
            $result = Invoke-PodeScriptBlock -ScriptBlock $using:ScriptBlock -Return

            if ($null -ne $result) {
                Write-PodeJsonResponse -Value $result
            }
        }
    }

    $creator = (Get-PodeGameState -Name 'create').Scenes[$global:Scene.Name]
    $creator.Routine += @{
        Action = 'Add'
        Type = 'Routine'
        Metadata = @{
            Name = $Name
            Actions = $Actions
            Url = $url
        }
    }
}

function Invoke-PodeGameRoutine
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]
        $Name
    )

    return @{
        Action = 'Invoke'
        Type = 'Routine'
        Metadata = @{
            Name = $Name
        }
    }
}

function Add-PodeGameTimer
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]
        $Name,

        [Parameter()]
        [int]
        $Interval = 1000,

        [Parameter()]
        [int]
        $Count = 0,

        [Parameter()]
        [scriptblock]
        $ScriptBlock,

        [Parameter()]
        [hashtable[]]
        $Actions,

        [switch]
        $Loop
    )

    if ($null -ne $ScriptBlock) {
        $url = "/_pode_game_/timer/$(New-Guid)/$($Name.ToLowerInvariant())"
        Add-PodeRoute -Method Post -Path $url -ScriptBlock {
            $result = Invoke-PodeScriptBlock -ScriptBlock $using:ScriptBlock -Return

            if ($null -ne $result) {
                Write-PodeJsonResponse -Value $result
            }
        }
    }

    if ($Interval -lt 0) {
        $Interval = 0
    }

    if ($Count -lt 0) {
        $Count = 0
    }

    $creator = (Get-PodeGameState -Name 'create').Scenes[$global:Scene.Name]
    $creator.Routine += @{
        Action = 'Add'
        Type = 'Timer'
        Metadata = @{
            Name = $Name
            Actions = $Actions
            Url = $url
            Loop = $Loop.IsPresent
            Count = $Count
            Interval = $Interval
        }
    }
}

function Select-PodeGameRandom
{
    [CmdletBinding()]
    param(
        [Parameter()]
        [hashtable[]]
        $Actions
    )

    return @{
        Action = 'Select'
        Type = 'Random'
        Metadata = @{
            Actions = $Actions
        }
    }
}

function Register-PodeGameKeyEvent
{
    [CmdletBinding()]
    param(
        [Parameter()]
        [hashtable]
        $InputObject = $null,

        [Parameter()]
        [ValidateSet('Down', 'Up')]
        [string]
        $Type = 'Down',

        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $Key,

        [Parameter()]
        [string]
        $Sound,

        [Parameter()]
        [hashtable]
        $Reference,

        [Parameter()]
        [scriptblock]
        $ScriptBlock,

        [Parameter()]
        [hashtable[]]
        $Actions,

        [Parameter()]
        [string[]]
        $Routines,

        [Parameter()]
        [double]
        $Duration
    )

    if ($null -ne $ScriptBlock) {
        $url = "/_pode_game_/keyboard/$(New-Guid)/$($Key.ToLowerInvariant())"
        Add-PodeRoute -Method Post -Path $url -ScriptBlock {
            $result = Invoke-PodeScriptBlock -ScriptBlock $using:ScriptBlock -Arguments $WebEvent.Data.reference -Splat -Return

            if ($null -ne $result) {
                Write-PodeJsonResponse -Value $result
            }
        }
    }

    $rf = $null
    if ($null -ne $Reference) {
        $rf = @{
            Type = $Reference.Type
            Name = $Reference.Metadata.Name
        }
    }

    if ($null -ne $InputObject) {
        $InputObject.Metadata.Interactive = $true

        if (!$InputObject.Metadata.Events) {
            $InputObject.Metadata.Events = @()
        }

        $InputObject.Metadata.Events += @{
            Type = $Type
            EventType = 'keyboard'
            Key = $Key
            Sound = $Sound
            Reference = $rf
            Duration = $Duration
            Actions = $Actions
            Routines = $Routines
            Url = $url
        }

        return $InputObject
    }
    else {
        $creator = (Get-PodeGameState -Name 'create').Scenes[$global:Scene.Name]
        $creator.Input += @{
            Type = 'Keyboard'
            Metadata = @{
                Type = $Type.ToLowerInvariant()
                EventType = 'keyboard'
                Key = $Key
                Sound = $Sound
                Reference = $rf
                Duration = $Duration
                Actions = $Actions
                Routines = $Routines
                Url = $url
            }
        }
    }
}

function Register-PodeGameMouseEvent
{
    [CmdletBinding()]
    param(
        [Parameter()]
        [hashtable]
        $InputObject = $null,

        [Parameter()]
        [ValidateSet('Down', 'Up', 'Move', 'Wheel')]
        [string]
        $Type = 'Down',

        [Parameter()]
        [ValidateSet('', 'Left', 'Middle', 'Right', 'Back', 'Forward')]
        [string]
        $Button = [string]::Empty,

        [Parameter()]
        [string]
        $Sound,

        [Parameter()]
        [string]
        $Particles,

        [Parameter()]
        [hashtable]
        $Reference,

        [Parameter()]
        [scriptblock]
        $ScriptBlock,

        [Parameter()]
        [hashtable[]]
        $Actions,

        [Parameter()]
        [string[]]
        $Routines
    )

    if ($null -ne $ScriptBlock) {
        $url = "/_pode_game_/mouse/$(New-Guid)/$($Type.ToLowerInvariant())"
        Add-PodeRoute -Method Post -Path $url -ScriptBlock {
            $result = Invoke-PodeScriptBlock -ScriptBlock $using:ScriptBlock -Arguments $WebEvent.Data.pointer, $WebEvent.Data.reference -Splat -Return

            if ($null -ne $result) {
                Write-PodeJsonResponse -Value $result
            }
        }
    }

    $rf = $null
    if ($null -ne $Reference) {
        $rf = @{
            Type = $Reference.Type
            Name = $Reference.Metadata.Name
        }
    }

    if ($Type -iin @('wheel', 'move')) {
        $Button = [string]::Empty
    }

    $buttonId = (@{
        ''      = -1
        Left    = 0
        Middle  = 1
        Right   = 2
        Back    = 3
        Forward = 4
    })[$Button]

    if ($null -ne $InputObject) {
        $InputObject.Metadata.Interactive = $true

        if (!$InputObject.Metadata.Events) {
            $InputObject.Metadata.Events = @()
        }

        $InputObject.Metadata.Events += @{
            Type = $Type
            EventType = 'mouse'
            Button = $buttonId
            Sound = $Sound
            Particles = $Particles
            Reference = $rf
            Actions = $Actions
            Routines = $Routines
            Url = $url
        }

        return $InputObject
    }
    else {
        $creator = (Get-PodeGameState -Name 'create').Scenes[$global:Scene.Name]
        $creator.Input += @{
            Type = 'Mouse'
            Metadata = @{
                Type = $Type.ToLowerInvariant()
                EventType = 'mouse'
                Button = $buttonId
                Sound = $Sound
                Particles = $Particles
                Reference = $rf
                Actions = $Actions
                Routines = $Routines
                Url = $url
            }
        }
    }
}

function Set-PodeGameBounce
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true, ValueFromPipeline=$true)]
        [hashtable]
        $InputObject,

        [Parameter()]
        [double]
        $X = 0,

        [Parameter()]
        [double]
        $Y = 0
    )

    $InputObject.Metadata.Bounce = @{
        X = $X
        Y = $Y
    }

    return $InputObject
}

function Set-PodeGameDrag
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true, ValueFromPipeline=$true)]
        [hashtable]
        $InputObject,

        [Parameter()]
        [double]
        $X = 0,

        [Parameter()]
        [double]
        $Y = 0,

        [switch]
        $Damping
    )

    $InputObject.Metadata.Drag = @{
        X = $X
        Y = $Y
        Damping = $Damping.IsPresent
    }

    return $InputObject
}

function Set-PodeGameGravity
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true, ValueFromPipeline=$true)]
        [hashtable]
        $InputObject,

        [Parameter()]
        [double]
        $X = 0,

        [Parameter()]
        [double]
        $Y = 0,

        [switch]
        $Disable
    )

    $InputObject.Metadata.Gravity = @{
        Enable = !$Disable.IsPresent
        X = $X
        Y = $Y
    }

    return $InputObject
}

function Set-PodeGameCollide
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true, ValueFromPipeline=$true)]
        [hashtable]
        $InputObject,

        [Parameter()]
        [ValidateSet('None', 'Collide', 'Wrap', 'Disable')]
        [string]
        $WorldBounds = 'None',

        [Parameter()]
        [ValidateSet('Rectangle', 'Circle')]
        [string]
        $BoundingVolume = 'Rectangle',

        [Parameter()]
        [double]
        $WrapPadding = 0.4,

        [switch]
        $Immovable
    )

    $InputObject.Metadata.Collide = @{
        WorldBounds = $WorldBounds.ToLowerInvariant()
        BoundingVolume = $BoundingVolume.ToLowerInvariant()
        WrapPadding = $WrapPadding
        Immovable = $Immovable.IsPresent
    }

    return $InputObject
}

function Set-PodeGameVelocity
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true, ValueFromPipeline=$true)]
        [hashtable]
        $InputObject,

        [Parameter()]
        $X = [int]::MinValue,

        [Parameter()]
        $Y = [int]::MinValue,

        [Parameter()]
        [double]
        $Angular = [int]::MinValue,

        [Parameter()]
        [double]
        $Max = [int]::MinValue
    )

    $InputObject.Metadata.Velocity = @{
        X = $X
        Y = $Y
        Angular = $Angular
        Max = $Max
    }

    return $InputObject
}

function Set-PodeGameAcceleration
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true, ValueFromPipeline=$true)]
        [hashtable]
        $InputObject,

        [Parameter()]
        [double]
        $X = [int]::MinValue,

        [Parameter()]
        [double]
        $Y = [int]::MinValue
    )

    $InputObject.Metadata.Acceleration = @{
        X = $X
        Y = $Y
    }

    return $InputObject
}

function Set-PodeGameDepth
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true, ValueFromPipeline=$true)]
        [hashtable]
        $InputObject,

        [Parameter()]
        [int]
        $Value = 0
    )

    $InputObject.Metadata.Depth = $Value
    return $InputObject
}

function Set-PodeGameAngle
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true, ValueFromPipeline=$true)]
        [hashtable]
        $InputObject,

        [Parameter()]
        [ValidateRange(-360, 360)]
        [double]
        $Value = 0,

        [Parameter()]
        $Target,

        [switch]
        $Spin
    )

    if ($null -ne $Target -and $Target -is [hashtable]) {
        $Target = @{
            Type = $Target.Type
            Name = $Target.Metadata.Name
        }
    }

    $InputObject.Metadata.Angle = @{
        Value = $Value
        Target = $Target
        Spin = $Spin.IsPresent
    }

    return $InputObject
}

function Set-PodeGamePosition
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true, ValueFromPipeline=$true)]
        [hashtable]
        $InputObject,

        [Parameter()]
        $X = [int]::MinValue,

        [Parameter()]
        $Y = [int]::MinValue,

        [Parameter()]
        $Target
    )

    if ($null -ne $Target -and $Target -is [hashtable]) {
        $Target = @{
            Type = $Target.Type
            Name = $Target.Metadata.Name
        }
    }

    if ($null -eq $InputObject.Metadata.Position) {
        $InputObject.Metadata.Position = @{}
    }

    if ($X -ne [int]::MinValue) {
        $InputObject.Metadata.Position.X = $X
    }

    if ($Y -ne [int]::MinValue) {
        $InputObject.Metadata.Position.Y = $Y
    }

    $InputObject.Metadata.Position.Target = $Target
    return $InputObject
}

function Set-PodeGameScale
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true, ValueFromPipeline=$true)]
        [hashtable]
        $InputObject,

        [Parameter()]
        [double]
        $X = 1,

        [Parameter()]
        [double]
        $Y = 1
    )

    $InputObject.Metadata.Scale = @{
        X = $X
        Y = $Y
    }

    return $InputObject
}

function Set-PodeGameScore
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true, ValueFromPipeline=$true)]
        [hashtable]
        $InputObject,

        [Parameter()]
        [double]
        $Value = 0
    )

    $InputObject.Metadata.Score = $Value
    return $InputObject
}

function Register-PodeGameEvent
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true, ValueFromPipeline=$true)]
        [hashtable]
        $InputObject,

        [Parameter()]
        [ValidateSet('Disable', 'Enable', 'Collide', 'Overlap', 'World_Bounds', 'Animation_Update', 'KeyUp', 'KeyDown')]
        [string]
        $Type,

        [Parameter()]
        [string]
        $Sound,

        [Parameter()]
        [string]
        $Particles,

        [Parameter()]
        [hashtable]
        $Reference,

        [Parameter()]
        [scriptblock]
        $ScriptBlock,

        [Parameter()]
        [hashtable[]]
        $Actions,

        [Parameter()]
        [string[]]
        $Routines
    )

    if ($null -ne $ScriptBlock) {
        $url = "/_pode_game_/event/$(New-Guid)/$($Type.ToLowerInvariant())"
        Add-PodeRoute -Method Post -Path $url -ScriptBlock {
            $result = Invoke-PodeScriptBlock -ScriptBlock $using:ScriptBlock -Arguments $WebEvent.Data.reference -Splat -Return

            if ($null -ne $result) {
                Write-PodeJsonResponse -Value $result
            }
        }
    }

    if (!$InputObject.Metadata.Events) {
        $InputObject.Metadata.Events = @()
    }

    $rf = $null
    if ($null -ne $Reference) {
        $rf = @{
            Type = $Reference.Type
            Name = $Reference.Metadata.Name
        }
    }

    $InputObject.Metadata.Events += @{
        Type = $Type
        EventType = 'general'
        Sound = $Sound
        Particles = $Particles
        Reference = $rf
        Actions = $Actions
        Routines = $Routines
        Url = $url
    }

    return $InputObject
}

function New-PodeGameText
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]
        $Name,

        [Parameter()]
        [ValidateSet('Plain', 'Number')]
        [string]
        $Type = 'Plain',

        [Parameter()]
        [string]
        $Value,

        [Parameter()]
        [double]
        $X = 0,

        [Parameter()]
        [double]
        $Y = 0,

        [Parameter()]
        [string]
        $FontSize = '12px',

        [Parameter()]
        [string]
        $FontFamily = 'monospace',

        [Parameter()]
        [string]
        $Colour = 0xFFFFFF,

        [switch]
        $Add
    )

    $txt = @{
        Action = 'New'
        Type = 'Text'
        Metadata = @{
            Name = $Name
            Type = $Type.toLowerInvariant()
            Value = $Value
            Position = @{
                X = $X
                Y = $Y
            }
            Style = @{
                Font = @{
                    Size = $FontSize
                    Family = $FontFamily
                }
                Colour = (ConvertFrom-PodeGameColour -Colour $Colour -AsHex)
            }
        }
    }

    if ($Add) {
        $txt | Add-PodeGameContent
    }

    return $txt
}

function New-PodeGameBitmapText
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]
        $Name,

        [Parameter(Mandatory=$true)]
        [string]
        $FontId,

        [Parameter()]
        [string]
        $Value,

        [Parameter()]
        [double]
        $Spacing = 0,

        [Parameter()]
        [double]
        $X = 0,

        [Parameter()]
        [double]
        $Y = 0,

        [Parameter()]
        [string]
        $Colour = 0xFFFFFF,

        [switch]
        $Add
    )

    $txt = @{
        Action = 'New'
        Type = 'BitmapText'
        Metadata = @{
            Name = $Name
            FontId = $FontId
            Value = $Value
            Spacing = $Spacing
            Position = @{
                X = $X
                Y = $Y
            }
            Tint = (ConvertFrom-PodeGameColour -Colour $Colour)
        }
    }

    if ($Add) {
        $txt | Add-PodeGameContent
    }

    return $txt
}

function Watch-PodeGameObject
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true, ValueFromPipeline=$true)]
        [hashtable]
        $InputObject,

        [Parameter(Mandatory=$true)]
        [hashtable]
        $Target,

        [Parameter()]
        [string]
        $Property = 'Value'
    )

    $InputObject.Metadata.Watch = @{
        Target = @{
            Type = $Target.Type
            Name = $Target.Metadata.Name
        }
        Property = $Property
    }

    return $InputObject
}

function Update-PodeGameSprite
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]
        $Name,

        [Parameter()]
        [double]
        $X = [int]::MinValue,

        [Parameter()]
        [double]
        $Y = [int]::MinValue,

        [Parameter()]
        [string]
        $Animation,

        [Parameter()]
        [string]
        $Tint
    )

    return @{
        Action = 'Update'
        Type = 'Sprite'
        Metadata = @{
            Name = $Name
            Position = @{
                X = $X
                Y = $Y
            }
            Animation = $Animation
            Tint = (ConvertFrom-PodeGameColour -Colour $Tint -AllowEmpty)
        }
    }
}

function Update-PodeGameImage
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]
        $Name,

        [Parameter()]
        [double]
        $X = [int]::MinValue,

        [Parameter()]
        [double]
        $Y = [int]::MinValue,

        [Parameter()]
        [string]
        $Tint
    )

    return @{
        Action = 'Update'
        Type = 'Image'
        Metadata = @{
            Name = $Name
            Position = @{
                X = $X
                Y = $Y
            }
            Tint = (ConvertFrom-PodeGameColour -Colour $Tint -AllowEmpty)
        }
    }
}

function Suspend-PodeGame
{
    [CmdletBinding()]
    param(
        [switch]
        $Finish
    )

    return @{
        Action = 'Suspend'
        Type = 'Game'
        Metadata = @{
            State = @{
                Finish = $Finish.IsPresent
            }
        }
    }
}

function New-PodeGamePlayer
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]
        $Name,

        [Parameter(Mandatory=$true)]
        [hashtable]
        $Texture,

        [Parameter()]
        [string]
        $Left,

        [Parameter()]
        [string]
        $Right,

        [Parameter()]
        [string]
        $Up,

        [Parameter()]
        [string]
        $Down,

        [Parameter()]
        [string]
        $Jump,

        [Parameter()]
        [string]
        $Fire,

        [Parameter()]
        [string]
        $Rotate,

        [Parameter()]
        [hashtable[]]
        $FireActions,

        [Parameter()]
        [double]
        $FireRate = 500,

        [Parameter()]
        [double]
        $MoveSpeed = 100,

        [Parameter()]
        [double]
        $JumpSpeed = [int]::MinValue,

        [Parameter()]
        [ValidateSet('Normal', 'Rotate')]
        [string]
        $ControlType = 'Normal',

        [switch]
        $Mouse,

        [switch]
        $Add
    )

    if ($Texture.Type -inotin @('sprite', 'image')) {
        throw "Player texture can only be a sprite or an image, but got: $($Texture.Type)"
    }

    if ($JumpSpeed -eq [int]::MinValue) {
        $JumpSpeed = $MoveSpeed * 1.2
    }

    $player = @{
        Action = 'New'
        Type = 'Player'
        Metadata = @{
            Name = $Name
            Stats = @{
                Score = 0
                Health = 100
            }
            ControlType = $ControlType.ToLowerInvariant()
            Mouse = $Mouse.IsPresent
            Controls = @{
                Left = $Left
                Right = $Right
                Up = $Up
                Down = $Down
                Jump = $Jump
                Fire = $Fire
                Rotate = $Rotate
            }
            FireActions = $FireActions
            FireRate = $FireRate
            Texture = $Texture
            Speed = @{
                Move = $MoveSpeed
                Jump = $JumpSpeed
            }
        }
    }

    if ($Add) {
        $player | Add-PodeGameContent
    }

    return $player
}

function Switch-PodeGameScene
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]
        $Name
    )

    return @{
        Action = 'Switch'
        Type = 'Scene'
        Metadata = @{
            Name = $Name
        }
    }
}

function Stop-PodeGameScene
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]
        $Name
    )

    return @{
        Action = 'Stop'
        Type = 'Scene'
        Metadata = @{
            Name = $Name
        }
    }
}

function Start-PodeGameScene
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]
        $Name
    )

    return @{
        Action = 'Start'
        Type = 'Scene'
        Metadata = @{
            Name = $Name
        }
    }
}

function Open-PodeGameScene
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]
        $Name
    )

    return @{
        Action = 'Open'
        Type = 'Scene'
        Metadata = @{
            Name = $Name
        }
    }
}

function Add-PodeGameBlitter
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]
        $Name,

        [Parameter(Mandatory=$true)]
        [string]
        $ImageId,

        [Parameter()]
        [int]
        $Count,

        [Parameter()]
        [double]
        $Speed,

        [Parameter()]
        [double]
        $Distance
    )

    $blitter = @{
        Action = 'Add'
        Type = 'Blitter'
        Metadata = @{
            Name = $Name
            ImageId = $ImageId
            Count = $Count
            Speed = $Speed
            Distance = $Distance
        }
    }

    $blitter | Add-PodeGameContent
    return $blitter
}

function Add-PodeGameTween
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [hashtable]
        $InputObject,

        [Parameter()]
        [ValidateRange(0.0, 1.0)]
        [double]
        $Alpha = 0.1,

        [Parameter()]
        [ValidateSet('Back', 'Bounce', 'Circular', 'Cubic', 'Elastic', 'Expo', 'Quadratic', 'Quartic', 'Quintic', 'Sine')]
        [string]
        $Ease = 'Sine',

        [Parameter()]
        [int]
        $Duration = 350,

        [Parameter()]
        [int]
        $Hold = 0,

        [Parameter()]
        [int]
        $Delay = 0,

        [switch]
        $Loop,

        [switch]
        $Yoyo
    )

    $InputObject.Metadata.Tween = @{
        Alpha = $Alpha
        Ease = $Ease
        Duration = $Duration
        Hold = $Hold
        Delay = $Delay
        Loop = $Loop.IsPresent
        Yoyo = $Yoyo.IsPresent
    }

    return $InputObject
}