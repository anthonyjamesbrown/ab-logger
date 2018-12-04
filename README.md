---
external help file: AB-Logger-help.xml
Module Name: AB-Logger
online version:
schema: 2.0.0
---

# Write-Log

## SYNOPSIS
Write messages to a log file

## SYNTAX

```
Write-Log [-Path] <String> [[-Level] <String>] [[-Code] <int32>] [-Message] <String> [[-Delimiter] <Char>]
 [[-MaxLogSize] <Int64>] [[-EnforceMaxLogFiles] <Boolean>] [[-MaxLogFiles] <Int32>] [[-Encoding] <String>]
 [<CommonParameters>]
```

## DESCRIPTION
This function allows you to specify a logfile path to write log messages to. 
This is for text based logging to a txt or log type file.
The function has features for max log file size and for keeping a maxium number of previous log files. 
You can control both behaviors by
setting the appropriate parameters.

## EXAMPLES

### EXAMPLE 1
```
This example uses a hash table called $LogProperties to hold all of the parameters.  You would only need to set this once in your script and then reference it as @LogProperties when calling the Write-Log function. 
Then you would only need to pass in values for Level and Message.


$LogProperties = @{
    'Path'               = 'c:\support\logs\mylog.log'
    'Delimiter'          = '|'
    'MaxLogSize'         = 200KB
    'EnforceMaxLogFiles' = $true
    'MaxLogFiles'        = 10
    'Encoding'           = 'UTF8'
}
Write-Log @LogProperties -Level 'INFO' -Code 100 -Message "Operation completed successfully."
```

## PARAMETERS

### -Path
This parameter specifies the full path to the log file. 
If the file does not exist in the specified location it will be created.
e.
g.
'c:\support\logs\mylog.log'

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: True
Position: 1
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Level
This parameter specifies the severity of the log level. 
This parameter is configured to only accept 'INFO', 'WARNING', or 'ERROR'.
Additional values could be added by editing the ValidateSet list for the Level parameter in the Params section.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 2
Default value: INFO
Accept pipeline input: False
Accept wildcard characters: False
```
### -Code
This parameter specifies a custom code that can be assigned to this log message.  The default value is 0.

```yaml
Type: Int32
Parameter Sets: (All)
Aliases:

Required: False
Position: 3
Default value: 0
Accept pipeline input: False
Accept wildcard characters: False
```

### -Message
This parameter specifies the message you want to write to the log.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: True
Position: 4
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Delimiter
This parameter allows you to specify what delimiter character to use between data elements in the log file. 
The default is ','.
 
You should avoid using the delimiter character in Messages you write to the log.

```yaml
Type: Char
Parameter Sets: (All)
Aliases:

Required: False
Position: 5
Default value: ,
Accept pipeline input: False
Accept wildcard characters: False
```

### -MaxLogSize
This parameter allows you to specify how large the log file can get before it gets rotated. 
The current log file will be renamed with
the date appended to the name. 
Then a new empty log file will be created with the original name. 
The default value for this is 100MB.

```yaml
Type: Int64
Parameter Sets: (All)
Aliases:

Required: False
Position: 6
Default value: 104857600
Accept pipeline input: False
Accept wildcard characters: False
```

### -EnforceMaxLogFiles
This parameter toggles the functionality to limit the number of log files keep before the oldest log is deleted when a new log is created.
The number of Logs files kept at one time is controlled by the MaxLogFiles parameter. 
This functionality is on by default.

```yaml
Type: Boolean
Parameter Sets: (All)
Aliases:

Required: False
Position: 7
Default value: True
Accept pipeline input: False
Accept wildcard characters: False
```

### -MaxLogFiles
This parameter only matters if EnforceMaxLogFiles is set to true. 
When EnforceMaxLogFiles is enabled this parameter controls how many log
files will be kept. 
The default is 10.

```yaml
Type: Int32
Parameter Sets: (All)
Aliases:

Required: False
Position: 8
Default value: 10
Accept pipeline input: False
Accept wildcard characters: False
```

### -Encoding
This parameter allows you to specifiy the type of character encoding used in the file. 
The acceptable values for this parameter are:
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

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 9
Default value: UTF8
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable.
For more information, see about_CommonParameters (http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### None, Write-log does not accept pipeline objects.

## OUTPUTS

### None, Write-Log does not generate any output.

## NOTES

## RELATED LINKS
