
$dest_path = './src/Templates/Public'
$src_path = './pode_modules'


<#
# Dependency Versions
#>

$Versions = @{
    MkDocs = '1.1.2'
    MkDocsTheme = '7.1.6'
    PlatyPS = '0.14.0'
}

<#
# Helper Functions
#>

function Test-PodeBuildIsWindows
{
    $v = $PSVersionTable
    return ($v.Platform -ilike '*win*' -or ($null -eq $v.Platform -and $v.PSEdition -ieq 'desktop'))
}

function Test-PodeBuildCommand($cmd)
{
    $path = $null

    if (Test-PodeBuildIsWindows) {
        $path = (Get-Command $cmd -ErrorAction Ignore)
    }
    else {
        $path = (which $cmd)
    }

    return (![string]::IsNullOrWhiteSpace($path))
}

function Invoke-PodeBuildInstall($name, $version)
{
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

    if (Test-PodeBuildIsWindows) {
        if (Test-PodeBuildCommand 'choco') {
            choco install $name --version $version -y
        }
    }
    else {
        if (Test-PodeBuildCommand 'brew') {
            brew install $name
        }
        elseif (Test-PodeBuildCommand 'apt-get') {
            sudo apt-get install $name -y
        }
        elseif (Test-PodeBuildCommand 'yum') {
            sudo yum install $name -y
        }
    }
}

function Install-PodeBuildModule($name)
{
    if ($null -ne ((Get-Module -ListAvailable $name) | Where-Object { $_.Version -ieq $Versions[$name] })) {
        return
    }

    Write-Host "Installing $($name) v$($Versions[$name])"
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    Install-Module -Name "$($name)" -Scope CurrentUser -RequiredVersion "$($Versions[$name])" -Force -SkipPublisherCheck
}


<#
# Dependencies
#>

# Synopsis: Installs Chocolatey
task ChocoDeps -If (Test-PodeBuildIsWindows) {
    if (!(Test-PodeBuildCommand 'choco')) {
        Set-ExecutionPolicy Bypass -Scope Process -Force
        Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))
    }
}

# Synopsis: Install dependencies for documentation
task DocsDeps ChocoDeps, {
    # install mkdocs
    if (!(Test-PodeBuildCommand 'mkdocs')) {
        Invoke-PodeBuildInstall 'mkdocs' $Versions.MkDocs
    }

    $_installed = (pip list --format json --disable-pip-version-check | ConvertFrom-Json)
    if (($_installed | Where-Object { $_.name -ieq 'mkdocs-material' -and $_.version -ieq $Versions.MkDocsTheme } | Measure-Object).Count -eq 0) {
        pip install "mkdocs-material==$($Versions.MkDocsTheme)" --force-reinstall --disable-pip-version-check
    }

    # install platyps
    Install-PodeBuildModule PlatyPS
}


<#
# Building
#>

# Synopsis: Install the frontend libraries
task Build {
    yarn install --force --ignore-scripts --modules-folder pode_modules
}, MoveLibs

# Synopsis: Move the libraries to the public directory
task MoveLibs {
    $libs_path = "$($dest_path)/libs"
    if (Test-Path $libs_path) {
        Remove-Item -Path $libs_path -Recurse -Force | Out-Null
    }

    New-Item -Path $libs_path -ItemType Directory -Force | Out-Null

    # jquery
    New-Item -Path "$($libs_path)/jquery" -ItemType Directory -Force | Out-Null
    Copy-Item -Path "$($src_path)/jquery/dist/jquery.min.js" -Destination "$($libs_path)/jquery/" -Force

    # phaser
    New-Item -Path "$($libs_path)/phaser" -ItemType Directory -Force | Out-Null
    Copy-Item -Path "$($src_path)/phaser/dist/phaser.min.js" -Destination "$($libs_path)/phaser/" -Force
}


<#
# Docs
#>

# Synopsis: Run the documentation locally
task Docs DocsDeps, DocsHelpBuild, {
    mkdocs serve
}

# Synopsis: Build the function help documentation
task DocsHelpBuild DocsDeps, {
    # import the local module
    Remove-Module Pode.Game -Force -ErrorAction Ignore | Out-Null
    Import-Module ./src/Pode.Game.psm1 -Force | Out-Null

    # build the function docs
    $path = './docs/Functions'
    $map =@{}

    (Get-Module Pode.Game).ExportedFunctions.Keys | ForEach-Object {
        $type = [System.IO.Path]::GetFileNameWithoutExtension((Split-Path -Leaf -Path (Get-Command $_ -Module Pode.Game).ScriptBlock.File))
        New-MarkdownHelp -Command $_ -OutputFolder (Join-Path $path $type) -Force -Metadata @{ PodeType = $type } -AlphabeticParamsOrder | Out-Null
        $map[$_] = $type
    }

    # update docs to bind links to unlinked functions
    $path = Join-Path $pwd 'docs'
    Get-ChildItem -Path $path -Recurse -Filter '*.md' | ForEach-Object {
        $depth = ($_.FullName.Replace($path, [string]::Empty).trim('\/') -split '[\\/]').Length
        $updated = $false

        $content = (Get-Content -Path $_.FullName | ForEach-Object {
            $line = $_

            while ($line -imatch '\[`(?<name>[a-z]+\-podegame[a-z]+)`\](?<char>[^(])') {
                $updated = $true
                $name = $Matches['name']
                $char = $Matches['char']
                $line = ($line -ireplace "\[``$($name)``\][^(]", "[``$($name)``]($('../' * $depth)Functions/$($map[$name])/$($name))$($char)")
            }

            $line
        })

        if ($updated) {
            $content | Out-File -FilePath $_.FullName -Force -Encoding ascii
        }
    }

    # remove the module
    Remove-Module Pode.Game -Force -ErrorAction Ignore | Out-Null
}

# Synopsis: Build the documentation
task DocsBuild DocsDeps, DocsHelpBuild, {
    mkdocs build
}
