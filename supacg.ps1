function Sup-Codegen {
    [CmdletBinding()]
    [Alias("codegen", "supcode")]
    param(
        [ValidateSet("DataGenerator", "hilfe")]
        $Module = "DataGenerator"
    )

    if ($Module -eq "hilfe") {
        Write-Host "JSON Formate (JSON beginnt IMMER mit einem [ ):`n"
        Write-Host "  - UUID: '`$uuid16', '`$uuid36', '`$uuid32', '`$uuid26', '`$uuid22'"
        Write-Host "  - UUID Bytes: '`$uuid16b', '`$uuid36b', '`$uuid32b', '`$uuid26b', '`$uuid22b'"
        Write-Host "  - Datum: '2021-12-31T00:00:00', '20211231' (ABAP Format)"
        Write-Host "  - Boolesch: true, false, 'abap_true', 'abap_false'"
        Write-Host "  - Zahlen: 123, 123.45"
        Write-Host "  - Text: 'Text'"
        Write-Host "`nZum Beispiel:"
        Write-Host "[`n  {`n    `"id`": `"`$uuid16`",`n    `"Birthday`": `"1990-05-22T00:00:00`",`n    `"name`": `"Name`",`n    `"active`": true,`n    `"PIN`": 1234`n  }`n]"
    }
    if ($Module -eq "DataGenerator") {
        # Tabellenname Z...
        while($true) {
            $tableName = ReadString "Tabellenname (mit Prefix)"
            if ($tableName.ToUpper().StartsWith("Z")) {
                Write-Host "  Gültiger Tabellenname" -ForegroundColor Green
                break;
            }
            else {
                Write-Host "  Ungültiger Tabellenname. Muss mit Z beginnen!" -ForegroundColor Red
                $nochmal = ReadYesNo "  Tabellennamen ändern?"
                if (!$nochmal) {
                    break
                }
            }
        }

        # Klassenname ZCL_...
        $tableDefault = "ZCL_" + $tableName.ToUpper() + "_DATA"
        while($true) {
            $className = ReadString "Klassenname (mit Prefix)" $tableDefault
            if ($className.ToUpper().StartsWith("ZCL_")) {
                Write-Host "  Gültiger Klassenname" -ForegroundColor Green
                break;
            }
            else {
                Write-Host "  Ungültiger Klassenname. Muss mit ZCL_ beginnen!" -ForegroundColor Red
                $nochmal = ReadYesNo "  Klassennamen ändern?"
                if (!$nochmal) {
                    break
                }
            }
        }


        $deleteContent = ReadYesNo "Inhalt der Tabelle löschen?"
        $existDraftTable = ReadYesNo "Existiert eine Draft-Tabelle?" -NoDefault
        if ($existDraftTable) {
            $tableDefault = $tableName + "_D"

            # Tabellenname Z...
            while($true) {
                $draftTableName = ReadString "Draft-Tabellenname (mit Prefix)" $tableDefault
                if ($draftTableName.ToUpper().StartsWith("Z")) {
                    Write-Host "  Gültiger Tabellenname" -ForegroundColor Green
                    break;
                }
                else {
                    Write-Host "  Ungültiger Tabellenname. Muss mit Z beginnen!" -ForegroundColor Red
                    $nochmal = ReadYesNo "  Tabellennamen ändern?"
                    if (!$nochmal) {
                        break
                    }
                }
            }

            $deleteDraftContent = ReadYesNo "Inhalt der Draft-Tabelle löschen?"
        }

        $writeLog = ReadYesNo "Log Zeile mit Anzahl Einträge ausgeben?"

        $data = ""
        Write-Host
        $isCSV = $false
        $dataFromClip = ReadYesNo "Daten aus Zwischenablage verwenden (JSON, CSV)?"
        if (!($dataFromClip)) {
            while($true) {
                $dataFile = ReadString "Dateipfad (JSON, CSV)"
                if (!(Test-Path $dataFile)) {
                    Write-Host "  Datei nicht gefunden" -ForegroundColor Red
                    $nochmal = ReadYesNo "  Dateipfad ändern?"
                    if (!$nochmal) {
                        break
                    }
                }
                else {
                    break
                }
            }
            if (Test-Path $dataFile) {
                $data = Get-Content $dataFile -Raw
            }
            else {
                Write-Host "Datei nicht gefunden" -ForegroundColor Red
                Write-Host "Nur Grundgerüst wird erstellt"
            }
            
        }
        else {
            $data = Get-Clipboard -Raw
        }
        $dataObject = @()
        if ($data -ne "") {
            if ($data.StartsWith("[")) {
                $dataObject = $data | ConvertFrom-Json
            }
            else {
                $isCSV = $true
                $dataObject = $data | ConvertFrom-Csv
                while($true) {
                    if ($dataObject.Count -gt 0) 
                    {
                        $properties = ($dataObject[0] | Get-Member -MemberType NoteProperty).Name
                        $propertyCount = $properties.Count
                        if ($propertyCount -eq 1) {
                            Write-Host "Nur eine Spalte $($properties) gefunden!" -ForegroundColor Red
                            $changeDelimiter = ReadYesNo "Spaltentrenner ändern (,;...)?"
                            if ($changeDelimiter) {
                                $delimiter = ReadString "Spaltentrenner"
                                $dataObject = $data | ConvertFrom-Csv -Delimiter $delimiter
                            }
                            else {
                                break;
                            }
                        }
                        else {
                            break;
                        }
                    }
                    else {
                        Write-Host "Keine Daten gefunden - Es wird nur Grundgerüst erstellt" -ForegroundColor Red
                        break
                    }
                }
            }
        }
        $ready = ReadYesNo "Code generieren (N=Abbruch)"

        if ($ready) {
            $codePre = "CLASS $($className.ToLower()) DEFINITION`n"
            $codePre += "  PUBLIC`n"
            $codePre += "  FINAL`n"
            $codePre += "  CREATE PUBLIC .`n"
            $codePre += "`n"
            $codePre += "  PUBLIC SECTION.`n"
            $codePre += "`n"
            $codePre += "    INTERFACES if_oo_adt_classrun .`n"
            $codePre += "  PROTECTED SECTION.`n"
            $codePre += "  PRIVATE SECTION.`n"
            $codePre += "ENDCLASS.`n"
            $codePre += "`n"
            $codePre += "`n"
            $codePre += "`n"
            $codePre += "CLASS $($className.ToLower()) IMPLEMENTATION.`n"
            $codePre += "`n"
            $codePre += "`n"
            $codePre += "  METHOD if_oo_adt_classrun~main.`n"
            $codePre += "  DATA itab TYPE TABLE OF $($tableName.ToLower()).`n"
            $codePre += "`n"
            $codePre += "  itab = VALUE #(`n"

            $code = ""
            foreach ($row in $dataObject) {
                $code += "    (`n"
                $properties = ($row | Get-Member -MemberType NoteProperty).Name

                foreach ($property in $properties) {
                    $value = $row.$property
                    if ($value -is [System.Boolean]) {
                        $value = $value ? "abap_true" : "abap_false"
                    }
                    elseif ($value -is [DateTime]) {
                        $value = $value.ToString("yyyyMMdd")
                    }
                    elseif ($value -is [System.String]) {
                        if ($value -eq "abap_true" -or $value -eq "abap_false") {
                            $value = $value.ToLower()
                        }
                        elseif ($value -eq "true") {
                            $value = "abap_true"
                        }
                        elseif ($value -eq "false") {
                            $value = "abap_false"
                        }
                        else {
                            if ($isCSV) {
                                $number = 0
                                if ([int]::TryParse($value, [ref]$number)) {
                                    $value = $number
                                }
                                else {
                                    $value = "'$value'"
                                }
                            }
                            else {
                                $value = "'$value'"
                            }
                        }
                    }
                    else {
                        $value = $value.ToString()
                    }

                    if ($value -eq "'`$uuid16'") {
                        $value = "cl_system_uuid=>create_uuid_x16_static( )"
                    }
                    elseif ($value -eq "'`$uuid36'") {
                        $value = "cl_system_uuid=>create_uuid_x36_static( )"
                    }
                    elseif ($value -eq "'`$uuid32'") {
                        $value = "cl_system_uuid=>create_uuid_x32_static( )"
                    }
                    elseif ($value -eq "'`$uuid26'") {
                        $value = "cl_system_uuid=>create_uuid_x26_static( )"
                    }
                    elseif ($value -eq "'`$uuid22'") {
                        $value = "cl_system_uuid=>create_uuid_x22_static( )"
                    }
                    elseif ($value -eq "'`$uuid16b'") {
                        $value = "cl_system_uuid=>create_uuid_x16_static( )->get_bytes( )"
                    }
                    elseif ($value -eq "'`$uuid36b'") {
                        $value = "cl_system_uuid=>create_uuid_x36_static( )->get_bytes( )"
                    }
                    elseif ($value -eq "'`$uuid32b'") {
                        $value = "cl_system_uuid=>create_uuid_x32_static( )->get_bytes( )"
                    }
                    elseif ($value -eq "'`$uuid26b'") {
                        $value = "cl_system_uuid=>create_uuid_x26_static( )->get_bytes( )"
                    }
                    elseif ($value -eq "'`$uuid22b'") {
                        $value = "cl_system_uuid=>create_uuid_x22_static( )->get_bytes( )"
                    }

                    $code += "      $($property.ToLower()) = $value`n"
                }
                $code += " )`n"
            }

            $codeSuf += "  ).`n"
            $codeSuf += "`n"
            if ($deleteContent) {
                $codeSuf += "  DELETE FROM $($tableName.ToLower()).`n"
            }
            if ($existDraftTable -and $deleteDraftContent) {
                $codeSuf += "  DELETE FROM $($draftTableName.ToLower()).`n"
            }
            $codeSuf += "`n"
            $codeSuf += "  INSERT $($tableName.ToLower()) FROM TABLE itab.`n"
            $codeSuf += "`n"
            if ($writeLog) {
                $codeSuf += "  out->write( | { sy-dbcnt } entries inserted successfully | ).`n"
            }
            $codeSuf += "`n"
            $codeSuf += "  ENDMETHOD.`n"
            $codeSuf += "ENDCLASS.`n"

            $finalCode = $codePre + $code + $codeSuf
            Set-Clipboard $finalCode
            Write-Host "Code in Zwischenablage kopiert" -ForegroundColor Green

        }
        else {
            Write-Host "Abbruch" -ForegroundColor Red
        }
    }
}

function ReadString {
    param(
        [string]$Prompt,
        [string]$Default = ""
    )

    Write-Host $Prompt -ForegroundColor Yellow -NoNewline

    if ($Default -ne "") {
        Write-Host " (Enter=$Default)" -ForegroundColor DarkGray -NoNewline
    }
    Write-Host ": " -NoNewline
    $response = Read-Host
    if ($response -eq "") {
        return $Default
    } else {
        return $response
    }
}
function ReadYesNo {
    param(
        [string]$Prompt,
        [Switch]$NoDefault
    )
    Write-Host $Prompt -ForegroundColor Yellow -NoNewline
    if ($NoDefault) {
        Write-Host " (j/N): " -NoNewline
    } else {
        Write-Host " (J/n): " -NoNewline
    }
    $response = Read-Host
    if ($NoDefault) {
        return $response -eq "j"
    } else {
        return $response -ne "n"
    }
}