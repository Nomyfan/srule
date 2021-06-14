function Get-GfwList {
  param (
      [Parameter(Mandatory)]
      [string]
      $Url
  )

  $response = Invoke-WebRequest -Uri $Url -RetryIntervalSec 1 -MaximumRetryCount 5
  $content = $response.Content

  return [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($content))
}

function StartsWithAny {
  param (
    [Parameter(Mandatory)]
    [string[]]
    $Starts,
    [Parameter(Mandatory)]
    [string]
    $Text
  )

  foreach($s in $Starts) {
    if($Text.StartsWith($s)) {
      return $true
    }
  }
  

  return $false
}

function ClearFormat {
  param (
    [Parameter(Mandatory, ValueFromPipeline)]
    [string]
    $Rule
  )

  $rules = New-Object 'System.Collections.Generic.List[string]'
  $rows = $Rule -split "`n"
  foreach($row in $rows) {
    $normalized_rule = $row.Trim((" {0}" -f [System.Environment]::NewLine))

    if ($normalized_rule -ne "" -and !(StartsWithAny -Text $normalized_rule -Starts "!","@@","[AutoProxy")) {
      # 清除前缀
      $normalized_rule = $normalized_rule -replace "^\|?https?://",""
      $normalized_rule = $normalized_rule -replace "^\|\|",""
      $normalized_rule = $normalized_rule -replace ""

      # 清除后缀
      $normalized_rule = $normalized_rule.TrimStart("/^*")

      $rules.Add($normalized_rule)
    }
  }

  return $rules.ToArray()
}

function FilterRules {
  param (
    [Parameter(Mandatory, ValueFromPipeline)]
    [string[]]
    $Rules
  )

  $handled_rules = New-Object 'System.Collections.Generic.HashSet[string]'
  $unhandle_rules = New-Object 'System.Collections.Generic.HashSet[string]'

  $Rules | ForEach-Object {
      $rule = $_
  
      if ($rule.Contains("/")) {
        $rule = $rule.Split("/")[0]
      }
  
      if(($rule -match '^[\w.-]+$')) {
        $handled_rules.Add($rule) | Out-Null
      } else {
        $unhandle_rules.Add($_) | Out-Null
      }
  }

  $ret = [System.Collections.Generic.List[string]]$handled_rules
  $ret.Sort()

  if($unhandle_rules.Count -ne 0) {
    Write-Warning "Unhandled rules"
    Write-Warning ([string[]]$unhandle_rules -join "`n")
  }

  
  return $ret.ToArray()
}

# Run the script
$gfw = Get-GfwList -Url "https://raw.githubusercontent.com/gfwlist/gfwlist/master/gfwlist.txt"
(FilterRules -Rules (ClearFormat -Rule $gfw)) -join "`n" | Out-File -Encoding 'utf8' -FilePath './dist/gfw.list'