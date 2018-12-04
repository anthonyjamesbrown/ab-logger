Function Write-Log
{
    <#
        .SYNOPSIS
            Write messages to a log file
        .DESCRIPTION
            This function allows you to specify a logfile path to write log messages to.  This is for text based logging to a txt or log type file.
            The function has features for max log file size and for keeping a maxium number of previous log files.  You can control both behaviors by
            setting the appropriate parameters.
        
        .EXAMPLE
            This example uses a hash table called $LogProperties to hold all of the parameters.  You would only need to set this once in your script and 
            then reference it as @LogProperties when calling the Write-Log function.  Then you would only need to pass in values for Level and Message.

            $LogProperties = @{
                'Path'               = 'c:\support\logs\mylog.log'
                'Delimiter'          = '|'
                'MaxLogSize'         = 200KB
                'EnforceMaxLogFiles' = $true
                'MaxLogFiles'        = 10
                'Encoding'           = 'UTF8'
            }
            Write-Log @LogProperties -Level 'INFO' -Code 100 -Message "Operation completed successfully."

        .PARAMETER Path
            This parameter specifies the full path to the log file.  If the file does not exist in the specified location it will be created.
            e. g. 'c:\support\logs\mylog.log'
        .PARAMETER Level
            This parameter specifies the severity of the log level.  This parameter is configured to only accept 'INFO', 'WARNING', or 'ERROR'.
            Additional values could be added by editing the ValidateSet list for the Level parameter in the Params section.
        .PARAMETER Code
            This parameter specifies a custom code that can be assigned to this log message.  The default value is 0.
        .PARAMETER Message
            This parameter specifies the message you want to write to the log.
        .PARAMETER Delimiter
            This parameter allows you to specify what delimiter character to use between data elements in the log file.  The default is ','.  
            You should avoid using the delimiter character in Messages you write to the log.
        .PARAMETER MaxLogSize
            This parameter allows you to specify how large the log file can get before it gets rotated.  The current log file will be renamed with
            the date appended to the name.  Then a new empty log file will be created with the original name.  The default value for this is 100MB.
        .PARAMETER EnforceMaxLogFiles
            This parameter toggles the functionality to limit the number of log files keep before the oldest log is deleted when a new log is created.
            The number of Logs files kept at one time is controlled by the MaxLogFiles parameter.  This functionality is on by default.
        .PARAMETER MaxLogFiles
            This parameter only matters if EnforceMaxLogFiles is set to true.  When EnforceMaxLogFiles is enabled this parameter controls how many log
            files will be kept.  The default is 10.
        .PARAMETER Encoding
            This parameter allows you to specifiy the type of character encoding used in the file.  The acceptable values for this parameter are:
            - Unknown
            - String
            - Unicode
            - BigEndianUnicode
            - UTF8
            - UTF7
            - UTF32
            - ASCII
            - Default
            - OEM
            
            UTF8 is the default.
        .OUTPUTS
            None, Write-Log does not generate any output.
    #>
    [CmdletBinding()]
    Param(
        [Parameter(
            Mandatory = $true
        )]
        [String]
        $Path,

        [Parameter(
            Mandatory = $false
        )]
        [ValidateSet('INFO','WARNING','ERROR')]
        [String]
        $Level = 'INFO',

        [Parameter(
            Mandatory = $false
        )]
        [Int32]
        $Code = 0,

        [Parameter(
            Mandatory = $true
        )]
        [ValidateNotNullOrEmpty()]
        [String]
        $Message,

        [Parameter(
            Mandatory = $false
        )]
        [char]
        $Delimiter = ',',

        [Parameter(
            Mandatory = $false
        )]
        [long]
        $MaxLogSize = 100MB,

        [Parameter(
            Mandatory = $false
        )]
        [bool]
        $EnforceMaxLogFiles = $true,

        [Parameter(
            Mandatory = $false
        )]
        [int32]
        $MaxLogFiles = 10,

        [Parameter(
            Mandatory = $false
        )]
        [ValidateSet('Unkown','String','Unicode','BigEndianUnicode','UTF8','UTF7','UTF32','ASCII','Default','OEM')]
        [String]
        $Encoding = "UTF8"
    ) # End Paramters

    # Attempt to get the user calling the script
    try 
    {
        $CurrentUser = [Security.Principal.WindowsIdentity]::GetCurrent().Name
    } 
    catch
    {
        $CurrentUser = "UNKNOWN"
    }

    # Define date format for use in the log message
    $DateFormat = "yyyy-MM-dd HH:mm:ss.fff"
    $DateTime = Get-Date
    $LogDate = $DateTime.ToString($DateFormat)

    # Get Filename and Folder path
    $FileName = Split-Path -Path $Path -Leaf
    $ParentPath = Split-Path -Path $Path -Parent

    #
    # Order and name the header columns
    # Order the data elements
    #   Use these sections to reorder column if you like
    $Headers = "Level","User","Date","Code","LogMessage"
    $DataElements = $Level,$CurrentUser,$LogDate,$Code,$Message

    # Construct the Header row with delimiter
    $Header = ""
    $Headers | ForEach-Object {
        if($Header -eq "")
        {
            $Header = $_            
        }
        else
        {
            $Header += $Delimiter + $_    
        } # end if
    } # end for loop

    # Check for file existence
    if(Test-Path -Path $path)
    {
        $Size = (Get-Item -Path $Path).Length

        # Check that the file is writable from this process
        $Writable = try { [System.IO.File]::OpenWrite($Path).close(); $true } catch { $false }
        
        # Check if the file is over the MaxLogSize value
        if($Size -ge $MaxLogSize)
        {
            if($Writable)
            {   
                # Rename to current file and append date information to the name
                # Create a new current file with the Path name
                $Extension = [System.IO.Path]::GetExtension($Path)
                $File = [System.IO.Path]::GetFileNameWithoutExtension($FileName)
                $NewName = $File + "_" + $DateTime.ToString("yyyy-MM-dd-HH-mm-ss") + $Extension
                $null = Rename-Item -Path $Path -NewName $NewName
                $null = New-Item -Path $Path -ItemType File -Force
                (Get-ChildItem -Path $Path).CreationTime = $DateTime
                $Header | Out-File -FilePath $Path -Encoding $Encoding -Append 

                # Check if EnforceMaxLogFiles switch is enabled, it is on by default
                if($EnforceMaxLogFiles)
                {
                    # While the number of logfiles is greater than the max value delete the oldest file
                    # generally that should only be one file
                    $FileList = get-childitem -Path $ParentPath -Filter "$File*"
                    while(($FileList.Count) -gt $MaxLogFiles)
                    {
                        $Item = $FileList | Sort-Object CreationTime | Select-Object -First 1
                        $null = Remove-Item -Path ($Item.FullName)   
                        $FileList = get-childitem -Path $ParentPath -Filter "$File*"
                    } # End while
                } # End if EnforceMaxLogFiles
            }
            else
            {
                Write-Error "The path ($Path) was not accessable, check permissions. "    
            } # End if Writable
        } # End if Size exceeds Max
    }
    else
    {
        $Writable = try { [System.IO.File]::OpenWrite($Path).close(); $true } catch { $false }
        if($Writable)
        {
            $null = New-Item -Path $Path -ItemType File -Force
            $Header | Out-File -FilePath $Path -Encoding $Encoding -Append 
        } 
        else
        {
            Write-Error "The path ($ParentPath) was not accessable, check permissions. " 
        } # End if Writable       
    } # End if test path

    #Assume we have a writable file
    
    # Construct the data row with delimiter
    $Data = ""
    $DataElements | ForEach-Object {
        if($Data -eq "")
        {
            $Data = $_            
        }
        else
        {
            $Data += $Delimiter + $_    
        } # end if
    } # end for loop

    $Data | Out-File -FilePath $Path -Encoding $Encoding -Append 
} # End function



# SIG # Begin signature block
# MIINSwYJKoZIhvcNAQcCoIINPDCCDTgCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUKa39D0keGxlyYswj5EHp0U0+
# Zcigggq1MIIE4jCCAsqgAwIBAgIKYcAf1gABAAAABTANBgkqhkiG9w0BAQsFADAR
# MQ8wDQYDVQQDEwZyb290Y2EwHhcNMTIwODIxMjExNzUyWhcNMzIwODIxMTgyNjM0
# WjBRMRMwEQYKCZImiZPyLGQBGRYDb3JnMRcwFQYKCZImiZPyLGQBGRYHYXN1cmlv
# bjEUMBIGCgmSJomT8ixkARkWBHByb2QxCzAJBgNVBAMTAmNhMIIBIjANBgkqhkiG
# 9w0BAQEFAAOCAQ8AMIIBCgKCAQEAoir+W7wXr5t69GF+MvzUEvf8iExHxGtDYYDB
# WmeCjDjCZ3CqZHj3R0RsXjTV2laSl7l3RU/10OJrwcvSviG0QpHL26qVcUUF8W28
# /BsxE5h8GFiZlVX9NprG57BqHEPHTX56qUAeIHLhFdzhe7i0liRYm0sjsIYZL91a
# A8Y+9DfmKcIuMk3H9z462bKTFiRanVqY2HjV8W1fvCiiaJwAlkBqXpCOGxFpDGzQ
# kMfLYbglnPoSU9QFlo204cgVwGeMHO+41wKl42CN6ntsJkkRoCmss2fyGjJk2VmZ
# 9zUGMUMUw/Ho0NnitxHN434QHKngjk3VC0aK4kBTD9Qmwg/FIwIDAQABo4H7MIH4
# MBAGCSsGAQQBgjcVAQQDAgECMCMGCSsGAQQBgjcVAgQWBBQmx1NfgwBFPGcRjKvA
# ayZ8MEnFSjAdBgNVHQ4EFgQUxg/1Qnil8Omc/elB7U4O2y67ahowEQYDVR0gBAow
# CDAGBgRVHSAAMBkGCSsGAQQBgjcUAgQMHgoAUwB1AGIAQwBBMAsGA1UdDwQEAwIB
# hjAPBgNVHRMBAf8EBTADAQH/MB8GA1UdIwQYMBaAFL2N2atbQCf/s1FtqL/hYj/M
# 4UoIMDMGA1UdHwQsMCowKKAmoCSGImh0dHA6Ly93d3djYS9DZXJ0RW5yb2xsL3Jv
# b3RjYS5jcmwwDQYJKoZIhvcNAQELBQADggIBABk5hvw6rnrLNxZl2CQrH2qE5+O3
# 7PQKoRuwMRgly+2gWm9zHtHRNQyBlADR5iSAftw23YLDanlbq7VNQn75lhN//ZJ8
# FXXW4B9eOVLJ70XiR7bb8M4sXNk3Bnj2vOJ8OuBP1hNb5CkMtcDFcZsm6NFRcMBX
# ia9pke2X3XUnv/NUi1e4o330g+ErUZnqFr+NOm2+TZvhke17v/OkqU29eZInuKHM
# 06/i+jUwi78g4Ws87Gu+EXY/w4zRYBMaastPxj3xC2UBKW+FoGSxCD5i27pUCmme
# IRZF7ruPBon7FWeLsmT3PSESA+VK6Ma5NOdXQh4PjijmJenD5vOWkkTPix0vVdzI
# NPwDFBS6FeLejtQsuu+yn1AuqLDJ7ow/QcnmL6uKm11d4JRFFdh8jh4KCM1ShDaX
# GiqtQUS68piFJk/7+E1kDtY/SuOlPv/V2uUekULvm77szNNAUQcceYExpoV5XOAC
# Oi+s+Q0To535GgyEwYlThYwvsy4rEgthzxn5o2NhzMEVqt1SIBJ5ThOteOAMCsRi
# Be0KKP+dijFDYpkypJH/wNLlzWqHTf0gQiE2JlYQkBzZvxmn2iexysbfLzyocBve
# eTaxUpDot+G2OTZE0XVPRVxvXrfkDcQIIWkXSttFm26GjsYfX+6gYPh/tTv1O4ZP
# Amv10Oj3mC+ZTiURMIIFyzCCBLOgAwIBAgIKduCE2QACAJEgYDANBgkqhkiG9w0B
# AQsFADBRMRMwEQYKCZImiZPyLGQBGRYDb3JnMRcwFQYKCZImiZPyLGQBGRYHYXN1
# cmlvbjEUMBIGCgmSJomT8ixkARkWBHByb2QxCzAJBgNVBAMTAmNhMB4XDTE3MTAy
# NDE0MzEwOVoXDTE5MTAyNDE0MzEwOVowKjEoMCYGCSqGSIb3DQEJARYZYW50aG9u
# eS5icm93bkBhc3VyaW9uLmNvbTCCASIwDQYJKoZIhvcNAQEBBQADggEPADCCAQoC
# ggEBAJkF4PzpYtu+BjRT455tFroUSxXRE2vRIuOH+DO9LpFwYXadn+c15aEVrEAm
# FJQnIJ3cT5XCbXHh/IxCI5h/rA/D7ZkqJIQvXSuz0hflHpPRU8xqnXdmWknnczj6
# 4gLgACpJskO4U6T/4Q83wYHcAw9rgjcH023zXxSmHU9jEd+EKDgYtGX0wTpg8/Iz
# YQx3PRm+vYQwC16OEXj31oxoE6wk9NhsjAVnYVZwbRKY3YyIcv0x5dVSgBZMrg2+
# y+wAJZfe6sdFfXaNn/85fJh9ZhgiYL1uhe/WQPRPu8gDzccU9zr6tQTyRVp4MmkM
# bFTaQNbGcdBxC1QRB8XJJuEXJ9kCAwEAAaOCAsowggLGMDwGCSsGAQQBgjcVBwQv
# MC0GJSsGAQQBgjcVCIH00hKFgIk+h62BD4HQqHGCyMJgFqjTdYW49n4CAWQCAQQw
# EwYDVR0lBAwwCgYIKwYBBQUHAwMwDgYDVR0PAQH/BAQDAgeAMBsGCSsGAQQBgjcV
# CgQOMAwwCgYIKwYBBQUHAwMwHQYDVR0OBBYEFAUuJQNQDJqbIwce88jIkm3R9mCl
# MB8GA1UdIwQYMBaAFMYP9UJ4pfDpnP3pQe1ODtsuu2oaMIIBAwYDVR0fBIH7MIH4
# MIH1oIHyoIHvhoGsbGRhcDovLy9DTj1jYSxDTj1DQSxDTj1DRFAsQ049UHVibGlj
# JTIwS2V5JTIwU2VydmljZXMsQ049U2VydmljZXMsQ049Q29uZmlndXJhdGlvbixE
# Qz1wcm9kLERDPWFzdXJpb24sREM9b3JnP2NlcnRpZmljYXRlUmV2b2NhdGlvbkxp
# c3Q/YmFzZT9vYmplY3RDbGFzcz1jUkxEaXN0cmlidXRpb25Qb2ludIYeaHR0cDov
# L3d3d2NhL0NlcnRFbnJvbGwvY2EuY3Jshh5odHRwOi8vd3d3Y2EvQ2VydEVucm9s
# bC9jYS5jcmwwgfwGCCsGAQUFBwEBBIHvMIHsMIGpBggrBgEFBQcwAoaBnGxkYXA6
# Ly8vQ049Y2EsQ049QUlBLENOPVB1YmxpYyUyMEtleSUyMFNlcnZpY2VzLENOPVNl
# cnZpY2VzLENOPUNvbmZpZ3VyYXRpb24sREM9cHJvZCxEQz1hc3VyaW9uLERDPW9y
# Zz9jQUNlcnRpZmljYXRlP2Jhc2U/b2JqZWN0Q2xhc3M9Y2VydGlmaWNhdGlvbkF1
# dGhvcml0eTA+BggrBgEFBQcwAoYyaHR0cDovL3d3d2NhL0NlcnRFbnJvbGwvY2Eu
# cHJvZC5hc3VyaW9uLm9yZ19jYS5jcnQwDQYJKoZIhvcNAQELBQADggEBAACG4rJV
# FZowTpXBDEToE1EgOSzPswRStyhmxlitDIYKZTfY/Au7mH+gWY4EnPc5dSAgi/iF
# f1zOAOq/ZKeHNCcJCE5jtIPzgkEfrq3lxcIlV0n9fT1/jujsX+s+WDZA4vtykNl7
# ldkzipeF7FJQqkWWgT5vIPjq726yZwx/tO3iiFRis5rXeApeiy8IjaBD+9COLCP1
# UDTK10D9EAS3BO6Rsrc0a3VSX8M64nAQFtA26KgVE17jcS/EQlfQd90rTZt/scPc
# 7B11ouVa+BRTQNSMNvyAtDkp0B6Pwm+VvSkeZMy4dz9VVxwMUYYaHPZGj9pL4C28
# ygtDnkeG9iHfFxExggIAMIIB/AIBATBfMFExEzARBgoJkiaJk/IsZAEZFgNvcmcx
# FzAVBgoJkiaJk/IsZAEZFgdhc3VyaW9uMRQwEgYKCZImiZPyLGQBGRYEcHJvZDEL
# MAkGA1UEAxMCY2ECCnbghNkAAgCRIGAwCQYFKw4DAhoFAKB4MBgGCisGAQQBgjcC
# AQwxCjAIoAKAAKECgAAwGQYJKoZIhvcNAQkDMQwGCisGAQQBgjcCAQQwHAYKKwYB
# BAGCNwIBCzEOMAwGCisGAQQBgjcCARUwIwYJKoZIhvcNAQkEMRYEFMe6OVyQQhtX
# ncdQ4RI5YOYAluWRMA0GCSqGSIb3DQEBAQUABIIBAEB50/c6WQkmF2WFu5ws/pYH
# ID86cDmaV+sO5XQQ8s2RxJjcyAbpvChwOjQKoU/itDTHo3VoZKHslEnvQTBnFsGG
# jAeuQ/d0XNcKhpQcQZ0YC4EY03ckbnXpd9p6QBd25KPdBZLoNHN3ZZ/SN7CGK2dj
# iL1N8N+ZNg8vpd5L7NZexuzyYcY/BSjxBZrPFE9ujcZvQa8C7C0UxGQrW900mZLh
# lBvlLByFdtFuSLQr3fG8nObZouv9ocavYRqZJQBU7X/P4t09LS8QZdMzOpzX/+Ga
# bwMYwqYvfW1SIyNXFewm3jYx7RNX+5fTOhkkPfyLmfUoTtMx79mDtWJShEidOwA=
# SIG # End signature block
