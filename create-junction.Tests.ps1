$scriptPath = Join-Path $PSScriptRoot "create-junction.ps1"

function Get-ThrownMessage {
    param([scriptblock]$Operation)

    try {
        & $Operation
        return $null
    }
    catch {
        return $_.Exception.Message
    }
}

Describe "create-junction.ps1" {
    It "exists" {
        Test-Path -LiteralPath $scriptPath | Should Be $true
    }
}

if (Test-Path -LiteralPath $scriptPath) {
    . $scriptPath

    Describe "Resolve-ClipboardSourcePath" {
        It "returns the only copied path" {
            Resolve-ClipboardSourcePath -ClipboardItems @("D:\Repos\Payment") |
                Should Be "D:\Repos\Payment"
        }

        It "rejects an empty clipboard" {
            Get-ThrownMessage { Resolve-ClipboardSourcePath -ClipboardItems @() } |
                Should Match "exactly one copied folder"
        }

        It "rejects multiple copied items" {
            Get-ThrownMessage {
                Resolve-ClipboardSourcePath -ClipboardItems @(
                    "D:\Repos\Payment",
                    "D:\Repos\Identity"
                )
            } | Should Match "exactly one copied folder"
        }
    }

    Describe "New-RepositoryJunction" {
        It "creates a junction named after the source folder" {
            $caseRoot = Join-Path $TestDrive ([guid]::NewGuid().ToString("N"))
            $source = New-Item -ItemType Directory -Path (Join-Path $caseRoot "source\Payment") -Force
            $destinationRoot = New-Item -ItemType Directory -Path (Join-Path $caseRoot "consumer") -Force
            Set-Content -LiteralPath (Join-Path $source.FullName "marker.txt") -Value "linked"

            $junction = New-RepositoryJunction -Source $source.FullName -DestinationRoot $destinationRoot.FullName

            $junction.FullName | Should Be (Join-Path $destinationRoot.FullName "Payment")
            $junction.LinkType | Should Be "Junction"
            (Get-Content -Raw -LiteralPath (Join-Path $junction.FullName "marker.txt")).Trim() |
                Should Be "linked"
        }

        It "rejects a missing source" {
            $caseRoot = Join-Path $TestDrive ([guid]::NewGuid().ToString("N"))
            $destinationRoot = New-Item -ItemType Directory -Path (Join-Path $caseRoot "consumer") -Force

            Get-ThrownMessage {
                New-RepositoryJunction -Source (Join-Path $caseRoot "missing") -DestinationRoot $destinationRoot.FullName
            } | Should Match "Source folder was not found"
        }

        It "rejects a file source" {
            $caseRoot = Join-Path $TestDrive ([guid]::NewGuid().ToString("N"))
            $source = New-Item -ItemType File -Path (Join-Path $caseRoot "Payment.txt") -Force
            $destinationRoot = New-Item -ItemType Directory -Path (Join-Path $caseRoot "consumer") -Force

            Get-ThrownMessage {
                New-RepositoryJunction -Source $source.FullName -DestinationRoot $destinationRoot.FullName
            } | Should Match "Source is not a folder"
        }

        It "does not replace an occupied destination" {
            $caseRoot = Join-Path $TestDrive ([guid]::NewGuid().ToString("N"))
            $source = New-Item -ItemType Directory -Path (Join-Path $caseRoot "source\Payment") -Force
            $destinationRoot = New-Item -ItemType Directory -Path (Join-Path $caseRoot "consumer") -Force
            $occupied = New-Item -ItemType Directory -Path (Join-Path $destinationRoot.FullName "Payment") -Force
            Set-Content -LiteralPath (Join-Path $occupied.FullName "keep.txt") -Value "keep"

            Get-ThrownMessage {
                New-RepositoryJunction -Source $source.FullName -DestinationRoot $destinationRoot.FullName
            } | Should Match "Destination already exists"

            (Get-Content -Raw -LiteralPath (Join-Path $occupied.FullName "keep.txt")).Trim() |
                Should Be "keep"
            (Get-Item -LiteralPath $occupied.FullName).LinkType | Should BeNullOrEmpty
        }
    }
}
