function Get-PodeGameTemplatePath
{
    $path = Split-Path -Parent -Path ((Get-Module -Name 'Pode.Game').Path)
    return (Join-PodeGamePath $path 'Templates')
}

function Join-PodeGamePath
{
    param(
        [Parameter()]
        [string]
        $Path,

        [Parameter()]
        [string]
        $ChildPath,

        [switch]
        $ReplaceSlashes
    )

    if ([string]::IsNullOrWhiteSpace($Path)) {
        $result = $ChildPath
    }
    elseif ([string]::IsNullOrWhiteSpace($ChildPath)) {
        $result = $Path
    }
    else {
        $result = (Join-Path $Path $ChildPath)
    }

    if ($ReplaceSlashes) {
        $result = ($result -ireplace '\\', '/')
    }

    return $result
}

function Set-PodeGameState
{
    param(
        [Parameter(Mandatory=$true)]
        [string]
        $Name,

        [Parameter()]
        [object]
        $Value
    )

    Set-PodeState -Name "pode.game.$($Name)" -Value $Value -Scope 'pode.game' | Out-Null
}

function Get-PodeGameState
{
    param(
        [Parameter(Mandatory=$true)]
        [string]
        $Name
    )

    return (Get-PodeState -Name "pode.game.$($Name)")
}

function Protect-PodeGameValue
{
    param(
        [Parameter()]
        [string]
        $Value,

        [Parameter()]
        [string]
        $Default,

        [switch]
        $Encode
    )

    if ([string]::IsNullOrWhiteSpace($Value)) {
        if ($Encode) {
            return [System.Net.WebUtility]::HtmlEncode($Default)
        }
        else {
            return $Default
        }
    }

    if ($Encode) {
        return [System.Net.WebUtility]::HtmlEncode($Value)
    }
    else {
        return $Value
    }
}

function ConvertFrom-PodeGameColour
{
    param(
        [Parameter()]
        [string]
        $Colour,

        [switch]
        $AsHex,

        [switch]
        $AllowEmpty
    )

    if ([string]::IsNullOrWhiteSpace($Colour)) {
        if ($AllowEmpty) {
            return $null
        }

        $value = 0xFFFFFF
    }
    elseif (($Colour -ilike '0x*') -or ($Colour -match '^\d+$')) {
        $value = $Colour
    }
    else {
        $value = ([system.drawing.color]::FromKnownColor($Colour).ToArgb() -band 0x00FFFFFF)
    }

    if ($AsHex) {
        $value = "#$([System.Convert]::ToString($value, 16))"
    }

    return $value
}

function New-PodeGameSceneStarfield
{
    return Add-PodeGameScene -Name 'Starfield' -PassThru -Content {
        Add-PodeGameBlitter `
            -Name 'starfield' `
            -ImageId '_pg_image_particle_star_small_' `
            -Count 300 `
            -Speed 250 `
            -Distance 300 | Out-Null
    }
}