#
# This profile is currently being written for MacOS, with cross-platform
# functionality intended in the future.
#


# ########################################
# Important Constants
# ########################################

# In some cases, I've found that $HOME does not exist on Windows (possibly AD
# related?). The following allows either HOME or HOMEPATH to be referred to
# implicitly later in the profile.
New-Variable -Name SAFE_HOME `
             -Option Constant `
             -Scope Script `
             -Value ($env:HOME,$env:HOMEPATH -ne $null)[0]

New-Variable -Name LIBEXEC `
             -Option Constant `
             -Scope Script `
             -Value (Join-Path -Path '/usr' -ChildPath 'libexec')

New-Variable -Name PATH_HELPER `
             -Option Constant `
             -Scope Script `
             -Value (Join-Path -Path $LIBEXEC -ChildPath 'path_helper')

New-Variable -Name PATH_VARIABLE_SEPARATOR `
             -Option Constant `
             -Scope Script `
             -Value $(If ($IsWindows) {';'} else {':'})


# ########################################
# Functions
# ########################################
function Set-EnvironmentVariable
{
  Param
  (
    [String] $variable,
    [String] $value
  )

  [Environment]::SetEnvironmentVariable($variable, $value)
}
Set-Alias -Name setenv -Value Set-EnvironmentVariable


# ########################################
# Configure the PATH Environment Variable
# ########################################

######################
# macOS specific setup
######################
If ($IsMacOS)
{
  # Add all paths from /etc/paths[.d]
  Invoke-Expression $(& $PATH_HELPER -c)

  # Ensure that rbenv is in front of /usr/local/bin.
  $env:PATH = (
                $script:SAFE_HOME `
                | Join-Path -ChildPath '.rbenv' `
                | Join-Path -ChildPath 'shims'
              ),
              $env:PATH `
              -join $PATH_VARIABLE_SEPARATOR

  $env:PATH = $env:PATH,
              (
                $script:SAFE_HOME `
                | Join-Path -ChildPath 'node_modules' `
                | Join-Path -ChildPath 'livedown' `
                | Join-Path -ChildPath 'bin'
              ) `
              -join $PATH_VARIABLE_SEPARATOR

  # Add XDG bin directory to the PATH
  $env:PATH = $env:PATH,
              (
                $script:SAFE_HOME `
                | Join-Path -ChildPath '.local' `
                | Join-Path -ChildPath 'bin'
              ) `
              -join $PATH_VARIABLE_SEPARATOR

  # Add GO to the path
  $env:PATH = $env:PATH,
              (
                ($env:GOPATH | Join-Path -ChildPath 'bin')
              ) `
              -join $PATH_VARIABLE_SEPARATOR
}

########################
# Windows specific setup
########################
If ($IsWindows)
{
  # Add node.js to the PATH.
  $env:PATH = $env:PATH,
              (
                $env:LocalAppData `
                | Join-Path -ChildPath 'Programs' `
                | Join-Path -ChildPath 'Node' `
                | Join-Path -ChildPath 'node-v8.11.4-win-x64'
              ) `
              -join $PATH_VARIABLE_SEPARATOR

  $env:PATH = $env:PATH,
              (
                $env:LocalAppData `
                | Join-Path -ChildPath 'Yarn' `
                | Join-Path -ChildPath 'bin'
              ) `
              -join $PATH_VARIABLE_SEPARATOR


  # Add Python3 to the PATH.
  $env:PATH = $env:PATH,
              (
                $env:LocalAppData `
                | Join-Path -ChildPath 'Programs' `
                | Join-Path -ChildPath 'Python' `
                | Join-Path -ChildPath 'Python37'
              ) `
              -join $PATH_VARIABLE_SEPARATOR

  $env:PATH = $env:PATH,
              (
                $env:LocalAppData `
                | Join-Path -ChildPath 'Programs' `
                | Join-Path -ChildPath 'Python' `
                | Join-Path -ChildPath 'Python37' `
                | Join-Path -ChildPath 'Scripts'
              ) `
              -join $PATH_VARIABLE_SEPARATOR
}

##############
# Configure Go
##############
$env:GOPATH = $script:SAFE_HOME | Join-Path -ChildPath 'Projects'


###############
# Configure Git
###############

# Ensure that Git is using the system ssh
Get-Command ssh `
| Select-Object -ExpandProperty Source `
| Set-Content Env:/GIT_SSH

# Ensure that posh-git is loaded
Import-Module posh-git


# #######################################
# Configure Personal Preferences
# #######################################

# Set Editor
$env:EDITOR = (Get-Command -Name nvim | Select-Object -ExpandProperty Source)

# Disable List Truncation.
$FormatEnumerationLimit =-1

# Add SSH Keys
If ($IsMacOS) { ssh-add -K }

# Work around an issue with Chef on PowerShell
function knife { bash -c "knife $($args -join ' ')" }
function chef { bash -c "chef $($args -join ' ')" }

# Configure the Prompt
$GitPromptSettings.DefaultPromptAbbreviateHomeDirectory = $true
$GitPromptSettings.DefaultPromptPrefix =
  '$((Get-AWSSession) -split "@" | Select-Object -Last 1) '

# Configure PSReadline

Set-PSReadlineOption -EditMode Vi
Set-PSReadlineOption -ViModeIndicator Cursor
Set-PSReadlineKeyHandler -Key Ctrl+r -Function ReverseSearchHistory -ViMode Insert
Set-PSReadlineKeyHandler -Key Tab -Function Complete -ViMode Insert
