# Function to check if running as an administrator
function Test-IsAdmin {
    $admin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")
    return $admin
}

# Check for admin rights
if (-not (Test-IsAdmin)) {
    Write-Host "Please run this script as an Administrator!" -ForegroundColor Red
    return
}

function GetUserConsent {
    $userConsent = $null
    while ($userConsent -notmatch '^[yn]$') {
        $userConsent = Read-Host "Would you like to enable Hyper-V? (Y/N)"
        $userConsent = $userConsent.ToLower()
    }
    return $userConsent -eq 'y'
}

function CheckWindowsEdition {
    # Initialize variable for Windows edition
    $windowsEdition = $null

    # First try using Get-CimInstance
    try {
        $windowsEdition = (Get-CimInstance -ClassName Win32_OperatingSystem).Caption
    } catch {
        Write-Host "Failed using Get-CimInstance. Trying Get-WmiObject..."
    }

    # If the previous method failed, try using Get-WmiObject
    if (-not $windowsEdition) {
        try {
            $windowsEdition = (Get-WmiObject -Class Win32_OperatingSystem).Caption
        } catch {
            Write-Host "Failed using both Get-CimInstance and Get-WmiObject."
            return $null
        }
    }

    # Check if the edition is Pro or Enterprise
    $isProOrEnterprise = $windowsEdition -match 'Pro|Enterprise'

    # Return the result
    return $isProOrEnterprise, $windowsEdition
}


function CheckHyperVAvailability {
    $hyperVStates = Get-WindowsOptionalFeature -Online | Where-Object { $_.FeatureName -eq 'Microsoft-Hyper-V' -or $_.FeatureName -eq 'Microsoft-Hyper-V-All' }
    return ($hyperVStates | Where-Object { $_.State -eq 'Enabled' }).Count -gt 0
}


function CheckVirtualizationEnabled {
    return (Get-ComputerInfo).HyperVisorPresent
}

function GetWindowsEditionFeedback($isProOrEnterprise, $windowsEdition) {
    if ($isProOrEnterprise) {
        return "You have a Windows edition ($windowsEdition) that supports Hyper-V and Containers."
    } else {
        return "You have $windowsEdition, which doesn't natively support Hyper-V. Consider upgrading to Pro or Enterprise edition."
    }
}

function GetHyperVFeedback($hyperVAvailable) {
    if ($hyperVAvailable) {
        return "Hyper-V is available and enabled on your system."
    } else {
        return "Hyper-V is either unavailable or not enabled on your system."
    }
}

function GetVirtualizationFeedback($virtualizationEnabled) {
    if ($virtualizationEnabled) {
        return "Hardware-assisted virtualization is enabled on your system."
    } else {
        return "Hardware-assisted virtualization is not enabled. Please restart your computer, enter BIOS/UEFI settings, and enable virtualization. Consult your computer's manual or manufacturer for guidance."
    }
}

function EnableHyperV {
    Enable-WindowsOptionalFeature -Online -FeatureName Microsoft-Hyper-V -All
    return "Hyper-V is now being enabled. You might need to restart your computer to complete the process."
}

function CanInstallDocker {
    $isProOrEnterprise, $windowsEdition = CheckWindowsEdition
    $hyperVAvailable = CheckHyperVAvailability
    $virtualizationEnabled = CheckVirtualizationEnabled

    $results = @(
    GetWindowsEditionFeedback $isProOrEnterprise $windowsEdition
    GetHyperVFeedback $hyperVAvailable
    GetVirtualizationFeedback $virtualizationEnabled
    )

    $canInstall = $isProOrEnterprise -and $hyperVAvailable -and $virtualizationEnabled
    $complete_result = $results -join " "

    # Determine message and color
    if ($canInstall) {
        $message = "You can install Docker because $complete_result"
        $color = "Green"
    } else {
        $message = "You cannot install Docker because $complete_result"
        $color = "Red"
    }

    # Write colored output
    Write-Host $message -ForegroundColor $color

    if ($isProOrEnterprise -and -not $hyperVAvailable) {
        Write-Output "Hyper-V is not available on your system. We can enable it for you."
        $hyperV_result = ""
        if (GetUserConsent) {
            $hyperV_result += EnableHyperV
        } else {
            $hyperV_result += "You chose not to enable Hyper-V. If you change your mind later, run this script again."
        }
        Write-Output ($hyperV_result)
    }

    return
}

CanInstallDocker

