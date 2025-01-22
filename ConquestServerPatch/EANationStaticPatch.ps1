# May needed: Set-ExecutionPolicy -ExecutionPolicy RemoteSigned
# Confirm with "A"
# Or just within a single session:
# Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
# Confirm with "A"


# Add WPF functionality
Add-Type -AssemblyName "PresentationFramework"

# Function to show a message box
function Show-Message {
    param (
        [string]$message,
        [string]$title
    )
    [System.Windows.MessageBox]::Show($message, $title)
}

# Function to show a Yes/No dialog box
function Show-YesNoDialog {
    param (
        [string]$message,
        [string]$title
    )
    return [System.Windows.MessageBox]::Show($message, $title, [System.Windows.MessageBoxButton]::YesNo, [System.Windows.MessageBoxImage]::Question)
}

# Function to show an OpenFileDialog (WPF)
function Show-OpenFileDialog {
    $dialog = New-Object -TypeName Microsoft.Win32.OpenFileDialog
    $dialog.Filter = "Executable Conquest file (Conquest.exe)|*.exe|All files (*.*)|*.*"
    $dialog.Title = "Select the Executable Conquest File"
    # Show the dialog and check if the user selected a file
    if ($dialog.ShowDialog()) {
        return $dialog.FileName
    } else {
        return $null  # Return $null if no file was selected
    }
}

# Open file dialog to select an .exe file
$filePath = Show-OpenFileDialog

if ($filePath -eq $null) {
    Show-Message "No file selected, exiting." "File Selection"
    exit
}

# Check if the file exists
if (-Not (Test-Path $filePath)) {
    Show-Message "File does not exist." "Error"
    exit
}

# Check if the file size is exactly 6.7MB
$fileInfo = Get-Item $filePath
if (($fileInfo.Length -ne 6660740) -and ($fileInfo.Length -ne 6657688)) {
    Show-Message "File size does not match the expected 6.7MB (6,660,740 (decrypted/cracked V1.1) or 6,657,688 (decrypted/cracked V1.0) bytes). File size is $($fileInfo.Length) bytes." "Error"
    exit
}


# Define the byte patterns and their complementary replacements
$patterns = @(
    # Remove SSL check
    @{
        Description = "SSL check"
        Pattern = [byte[]](0x81, 0xe1, 0xee, 0x0f, 0x00, 0x00, 0x83, 0xc1, 0x15, 0x8b, 0xc1);
        Replacement = [byte[]](0x81, 0xe1, 0xee, 0x0f, 0x00, 0x00, 0xb8, 0x15, 0x00, 0x00, 0x00)
    },
    # Patch 'fesl.ea.com\x00' (6665736c2e65612e636f6d00) -> 'mordorwi.de\x00' (6d6f72646f7277692e646500)
    @{
        Description = "EA Nation endpoint (1)"
        Pattern = [byte[]](0x66, 0x65, 0x73, 0x6c, 0x2e, 0x65, 0x61, 0x2e, 0x63, 0x6f, 0x6d, 0x00);
        Replacement = [byte[]](0x6d, 0x6f, 0x72, 0x64, 0x6f, 0x72, 0x77, 0x69, 0x2e, 0x64, 0x65, 0x00)
    },
    # Patch '.fesl\x00' (2e6665736c00) -> '.mord\x00' (2e6d6f726400)
    @{
        Description = "EA Nation endpoint (2)"
        Pattern = [byte[]](0x2e, 0x66, 0x65, 0x73, 0x6c, 0x00);
        Replacement = [byte[]](0x2e, 0x6d, 0x6f, 0x72, 0x64, 0x00)
    },
    # Patch '.ea.com\x00' (2e65612e636f6d00) to 'ordorwi.de\x00' intro (6f7277692e646500)
    @{
        Description = "EA Nation endpoint (3)"
        Pattern = [byte[]](0x2e, 0x65, 0x61, 0x2e, 0x63, 0x6f, 0x6d, 0x00);
        Replacement = [byte[]](0x6f, 0x72, 0x77, 0x69, 0x2e, 0x64, 0x65, 0x00)
    }
)

# Ask for the Razor 1911 removal only if the file size is 6660740
if ($fileInfo.Length -eq 6660740) {
    $razor1911DialogResult = Show-YesNoDialog "Do you want to remove the Razor1911 intro?" "Razor1911 Intro Removal"
    if ($razor1911DialogResult -eq [System.Windows.MessageBoxResult]::Yes) {
        # Patch Razor1911 intro (ffd0e995d31900) -> (e995d319009090)
        $patterns += @{
            Description = "Razor1911 intro"
            Pattern = [byte[]](0xff, 0xd0, 0xe9, 0x95, 0xd3, 0x19, 0x00);
            Replacement = [byte[]](0xe9, 0x95, 0xd3, 0x19, 0x00, 0x90, 0x90)
        }
    }
}

# Function to search and replace byte patterns
function Replace-BytePatterns {
    param(
        [string]$filePath,
        [array]$patterns
    )

    # Read all bytes from the file
    $bytes = [System.IO.File]::ReadAllBytes($filePath)

    # Iterate over each pattern and replace it
    foreach ($pattern in $patterns) {
        $patternBytes = $pattern.Pattern
        $replacementBytes = $pattern.Replacement
        $description = $pattern.Description

        $patternLength = $patternBytes.Length
        $indexes = @()

        # Search for the pattern in the byte array
        for ($i = 0; $i -le $bytes.Length - $patternLength; $i++) {
            $bytesSlice = $bytes[$i..($i + $patternLength - 1)]
            # Compare byte arrays
            $found = $true
            for ($ib = 0; $ib -lt ($patternLength); $ib++) {
                if ($bytes[$i + $ib] -ne $patternBytes[$ib]) {
                    $found = $false
                    break
                }
            }
            # Add to index, if the byte slices matched
            if ($found -eq "true") {
                $indexes += $i
            }
        }

        # Replace the found patterns with the replacement bytes
        foreach ($index in $indexes) {
            for ($ib = 0; $ib -lt ($patternLength); $ib++) {
                $bytes[$index + $ib] = $replacementBytes[$ib]
            }
            Show-Message "Patch for $($description): Replaced pattern at offset 0x$($index.ToString('X'))." "Pattern Replaced"
        }
        if ($indexes.Count -eq 0) {
            Show-Message "No replacements found for patch: $($description)" "Pattern Not Found"
        }
    }

    # Make a backup first
    $backupFile = "$filePath.bak"

    # Check if a backup file already exists, and increment the backup suffix until a unique filename is found
    $counter = 1
    while (Test-Path $backupFile) {
        $backupFile = "$filePath.bak$counter"
        $counter++
    }
    Copy-Item -Path $filePath -Destination $backupFile

    # Save the modified bytes back to the file
    [System.IO.File]::WriteAllBytes($filePath, $bytes)
    Show-Message "File patched successfully. An untouched copy is saved to: $backupFile" "Success"
}

# Call the function to replace patterns in the selected file
Replace-BytePatterns -filePath $filePath -patterns $patterns
