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
Invoke-Expression $(& $PATH_HELPER -c)
$env:PATH = $env:PATH,
            (
              $script:SAFE_HOME `
              | Join-Path -ChildPath 'node_modules' `
              | Join-Path -ChildPath 'livedown' `
              | Join-Path -ChildPath 'bin'
            ) `
            -join ':'


# #######################################
# Configure Personal Preferences
# #######################################

# Set Editor
$env:EDITOR = (Get-Command -Name vim | Select-Object -ExpandProperty Source)

# Disable List Truncation.
$FormatEnumerationLimit =-1

# Ensure that posh-git is loaded
Import-Module posh-git

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
