# ----- ----- ----- ----- ----- ----- ----- ----- ----- ----- ----- ----- ----- ----- ----- ----- -----
#
# Create SNMP sensors in PRTG
#
# ----- ----- ----- ----- ----- ----- ----- ----- ----- ----- ----- ----- ----- ----- ----- ----- -----

# ----- ----- ----- ----- ----- ----- ----- ----- ----- ----- ----- ----- ----- ----- ----- ----- ----- ----- ----- ----- ----- ----- ----- ----- ----- #
# Connect to PRTG
# ----- ----- ----- ----- ----- ----- ----- ----- ----- ----- ----- ----- ----- ----- ----- ----- ----- ----- ----- ----- ----- ----- ----- ----- ----- #

Connect-PrtgServer prtg.domain.local

# ----- ----- ----- ----- ----- ----- ----- ----- ----- ----- ----- ----- ----- ----- ----- ----- ----- ----- ----- ----- ----- ----- ----- ----- ----- #
# Variables
# ----- ----- ----- ----- ----- ----- ----- ----- ----- ----- ----- ----- ----- ----- ----- ----- ----- ----- ----- ----- ----- ----- ----- ----- ----- #

$Probe = Get-Probe -Name 'TEST'
$Services = Import-Csv -Path .\Services.csv -Delimiter ';' -Encoding UTF8

# ----- ----- ----- ----- ----- ----- ----- ----- ----- ----- ----- ----- ----- ----- ----- ----- ----- ----- ----- ----- ----- ----- ----- ----- ----- #
# Functions
# ----- ----- ----- ----- ----- ----- ----- ----- ----- ----- ----- ----- ----- ----- ----- ----- ----- ----- ----- ----- ----- ----- ----- ----- ----- #

function UptimeSensor ($Device) {
    Write-Host " Creating sensor: SNMP System Uptime"
    $UptimeParameters = $Device | New-SensorParameters -RawType snmpuptime
    $UptimeSensor = $Device | Add-Sensor -Parameters $UptimeParameters
    $UptimeSensor | Set-ObjectProperty -Name "SNMP Availability"
}
function DiskSensors ($Device) {
    Write-Host " Creating sensors: SNMP Disk Free"
    $DiskTargets = $Device | Get-SensorTarget -RawType snmpdiskfree
    $DiskParameters = $Device | New-SensorParameters -RawType snmpdiskfree

    foreach ($DiskTarget in $DiskTargets) {
        $DiskParameters.disk__check = $DiskParameters.Targets.disk__check | Where-Object { $_.Name -eq $DiskTarget.Name }
        $DiskSensor = $Device | Add-Sensor -Parameters $DiskParameters
        $DiskSensorName = $DiskSensor.Name
        $DiskSensorName = $DiskSensorName.Replace("Disk Free:", "SNMP Disk")
        $DiskSensorName = $DiskSensorName.Split("L")[0]
        $DiskSensor | Set-ObjectProperty -Name $DiskSensorName
    }
}
function ServiceSensors ($Device) {
    Write-Host " Creating sensors: SNMP Service"
    foreach ($Service in $Services) {
        $ServiceTarget = $Device | Get-SensorTarget -RawType snmpservice | Where-Object { $_.Properties -eq $Service.Name }
    
        if ($ServiceTarget) {
            $ServiceParameters = $Device | New-SensorParameters -RawType snmpservice
            $ServiceParameters.service__check = $ServiceParameters.Targets.service__check | Where-Object { $_.Properties -eq $Service.Name }
            $ServiceSensor = $Device | Add-Sensor -Parameters $ServiceParameters
        } else {
            Write-Host "  Service doesn't exist: " -NoNewline
            Write-Host $Service.Name
        }
    }
}
function CPUSensor ($Device) {
    Write-Host " Creating sensor: SNMP CPU Load"
    $CPUParameters = $Device | New-SensorParameters -RawType snmpcpu
    $CPUSensor = $Device | Add-Sensor -Parameters $CPUParameters
}
function MemorySensors ($Device) {
    Write-Host " Creating sensors: SNMP Memory"
    $MemoryTargets = $Device | Get-SensorTarget -RawType snmpmemory
    $MemoryParameters = $Device | New-SensorParameters -RawType snmpmemory

    foreach ($MemoryTarget in $MemoryTargets) {
        $MemoryParameters.memory__check = $MemoryParameters.Targets.memory__check | Where-Object { $_.Name -eq $MemoryTarget.Name }
        $MemorySensor = $Device | Add-Sensor -Parameters $MemoryParameters
        $MemorySensorName = $MemorySensor.Name
        $MemorySensorName = $MemorySensorName.Replace("Memory:", "SNMP")
        $MemorySensor | Set-ObjectProperty -Name $MemorySensorName
    }
}
function TrafficSensors ($Device) {
    Write-Host " Creating sensor: SNMP Network"
    $TrafficTarget = $null
    $TrafficLANTarget = $Device | Get-SensorTarget -RawType snmptraffic | Where-Object { $_.Name -like "*Local Area Connection Traffic" }
    $TrafficETHTarget = $Device | Get-SensorTarget -RawType snmptraffic | Where-Object { $_.Name -like "*Ethernet Traffic" }
    $TrafficParameters = $Device | New-SensorParameters -RawType snmptraffic
    if ($TrafficLANTarget) {
        $TrafficTarget = $TrafficLANTarget
    } elseif ($TrafficETHTarget) {
        $TrafficTarget = $TrafficETHTarget
    } else {
        Write-Host " Unable to add SNMP traffic sensor"
        break
    }
    if ($TrafficTarget) {
        $TrafficParameters.interfacenumber__check = $TrafficParameters.Targets.interfacenumber__check | Where-Object { $_.Name -eq $TrafficTarget.Name }
        $TrafficSensor = $Device | Add-Sensor -Parameters $TrafficParameters
        $TrafficSensor | Set-ObjectProperty -Name "SNMP Network"
    } else {
        Write-Host " Unable to add SNMP traffic sensor"
    }
}

# ----- ----- ----- ----- ----- ----- ----- ----- ----- ----- ----- ----- ----- ----- ----- ----- ----- ----- ----- ----- ----- ----- ----- ----- ----- #
# Start
# ----- ----- ----- ----- ----- ----- ----- ----- ----- ----- ----- ----- ----- ----- ----- ----- ----- ----- ----- ----- ----- ----- ----- ----- ----- #

$HostName = 'server'
$Device = Get-Device -Probe $Probe -Name $HostName

Write-Host " "
Write-Host "Processing: " -NoNewline
Write-Host $Device.Name

UptimeSensor $Device
CPUSensor $Device
MemorySensors $Device
TrafficSensors $Device
DiskSensors $Device
ServiceSensors $Device


