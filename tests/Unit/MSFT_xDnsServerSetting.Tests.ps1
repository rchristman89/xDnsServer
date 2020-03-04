$script:dscModuleName = 'xDnsServer'
$script:dscResourceName = 'MSFT_xDnsServerSetting'

function Invoke-TestSetup
{
    try
    {
        Import-Module -Name DscResource.Test -Force -ErrorAction 'Stop'
    }
    catch [System.IO.FileNotFoundException]
    {
        throw 'DscResource.Test module dependency not found. Please run ".\build.ps1 -Tasks build" first.'
    }

    $script:testEnvironment = Initialize-TestEnvironment `
        -DSCModuleName $script:dscModuleName `
        -DSCResourceName $script:dscResourceName `
        -ResourceType 'Mof' `
        -TestType 'Unit'

    Import-Module (Join-Path -Path $PSScriptRoot -ChildPath 'Stubs\DnsServer.psm1') -Force
}

function Invoke-TestCleanup
{
    Restore-TestEnvironment -TestEnvironment $script:testEnvironment
}

Invoke-TestSetup

try
{
    InModuleScope $script:dscResourceName {
        #region Pester Test Initialization
        $testParameters = @{
            Name                      = 'Dc1DnsServerSetting'
            AddressAnswerLimit        = 5
            AllowUpdate               = 2
            AutoCacheUpdate           = $true
            AutoConfigFileZones       = 4
            BindSecondaries           = $true
            BootMethod                = 1
            DefaultAgingState         = $true
            DefaultNoRefreshInterval  = 10
            DefaultRefreshInterval    = 10
            DisableAutoReverseZones   = $true
            DisjointNets              = $true
            DsPollingInterval         = 10
            DsTombstoneInterval       = 10
            EDnsCacheTimeout          = 100
            EnableDirectoryPartitions = $false
            EnableDnsSec              = 0
            EnableEDnsProbes          = $false
            EventLogLevel             = 3
            ForwardDelegations        = 1
            Forwarders                = '8.8.8.8'
            ForwardingTimeout         = 4
            IsSlave                   = $true
            ListenAddresses           = '192.168.0.10', '192.168.0.11'
            LocalNetPriority          = $false
            LogFileMaxSize            = 400000000
            LogFilePath               = 'C:\Windows\System32\DNS_log\DNS.log'
            LogIPFilterList           = '192.168.0.10', '192.168.0.11'
            LogLevel                  = 256
            LooseWildcarding          = $true
            MaxCacheTTL               = 86200
            MaxNegativeCacheTTL       = 901
            NameCheckFlag             = 1
            NoRecursion               = $false
            RecursionRetry            = $false
            RecursionTimeout          = 16
            RoundRobin                = $false
            RpcProtocol               = 1
            ScavengingInterval        = 100
            SecureResponses           = $false
            SendPort                  = 100
            StrictFileParsing         = $true
            UpdateOptions             = 700
            WriteAuthorityNS          = $true
            XfrConnectTimeout         = 15
        }

        $mockGetCimInstance = @{
            Name                      = 'DnsServerSetting'
            Caption                   = $null
            Description               = $null
            InstallDate               = $null
            Status                    = 'OK'
            CreationClassName         = $null
            Started                   = $true
            StartMode                 = 'Automatic'
            SystemCreationClassName   = $null
            SystemName                = $null
            AddressAnswerLimit        = 0
            AllowUpdate               = 1
            AutoCacheUpdate           = $false
            AutoConfigFileZones       = 1
            BindSecondaries           = $false
            BootMethod                = 3
            DefaultAgingState         = $false
            DefaultNoRefreshInterval  = 168
            DefaultRefreshInterval    = 168
            DisableAutoReverseZones   = $false
            DisjointNets              = $false
            DsAvailable               = $true
            DsPollingInterval         = 180
            DsTombstoneInterval       = 1209600
            EDnsCacheTimeout          = 900
            EnableDirectoryPartitions = $true
            EnableDnsSec              = 1
            EnableEDnsProbes          = $true
            EventLogLevel             = 4
            ForwardDelegations        = 0
            Forwarders                = { 168.63.129.16 }
            ForwardingTimeout         = 3
            IsSlave                   = $false
            ListenAddresses           = $null
            LocalNetPriority          = $true
            LogFileMaxSize            = 500000000
            LogFilePath               = 'C:\Windows\System32\DNS\DNS.log'
            LogIPFilterList           = '10.1.1.1', '10.0.0.1'
            LogLevel                  = 0
            LooseWildcarding          = $false
            MaxCacheTTL               = 86400
            MaxNegativeCacheTTL       = 900
            NameCheckFlag             = 2
            NoRecursion               = $true
            RecursionRetry            = 3
            RecursionTimeout          = 8
            RoundRobin                = $true
            RpcProtocol               = 5
            ScavengingInterval        = 168
            SecureResponses           = $true
            SendPort                  = 0
            ServerAddresses           = 'fe80::7da3:a014:6581:2cdc', '10.0.0.4'
            StrictFileParsing         = $false
            UpdateOptions             = 783
            Version                   = 629146374
            WriteAuthorityNS          = $false
            XfrConnectTimeout         = 30
            PSComputerName            = $null
        }

        $array1 = 1, 2, 3
        $array2 = 3, 2, 1
        $array3 = 1, 2, 3, 4

        $mockGetDnsDiag = @{
            FilterIPAddressList = '10.1.1.1', '10.0.0.1'
        }

        $mockReadOnlyProperties = @{
            DsAvailable = $true
        }
        #endregion Pester Test Initialization

        #region Example state 1
        Describe 'MSFT_xDnsServerSetting\Get-TargetResource' {
            Mock -CommandName Assert-Module

            Context 'The system is not in the desired state' {
                It "Get method returns 'something'" {
                    Mock Get-CimInstance -MockWith { $mockGetCimInstance }
                    Mock Get-PsDnsServerDiagnosticsClass -MockWith { $mockGetDnsDiag }
                    $getResult = Get-TargetResource -Name 'DnsServerSetting' -Verbose

                    foreach ($key in $getResult.Keys)
                    {
                        if ($null -ne $getResult[$key] -and $key -ne 'Name')
                        {
                            $getResult[$key] | Should be $mockGetCimInstance[$key]
                        }
                        elseif ($key -eq 'LogIPFilterList')
                        {
                            $getResult[$key] | Should be $mockGetDnsDiag[$key]
                        }
                        if ($key -eq 'DsAvailable')
                        {
                            $getResult[$key] | Should Be $mockReadOnlyProperties[$key]
                        }
                    }
                }

                It 'Get throws when CimClass is not found' {
                    $mockThrow = @{
                        Exception = @{
                            Message = 'Invalid Namespace'
                        }
                    }

                    Mock Get-CimInstance -MockWith { throw $mockThrow }
                    Mock Get-PsDnsServerDiagnosticsClass

                    { Get-TargetResource -Name 'DnsServerSettings' -Verbose } | should throw
                }
            }

            Context 'Error handling' {
                It 'Test throws when CimClass is not found' {
                    $mockThrow = @{
                        Exception = @{
                            Message = 'Invalid Namespace'
                        }
                    }

                    Mock Get-CimInstance -MockWith { throw $mockThrow }

                    { Get-TargetResource -Name 'DnsServerSettings' -Verbose } | should throw
                }
            }
        }

        Describe 'MSFT_xDnsServerSetting\Test-TargetResource' {
            Mock -CommandName Assert-Module

            Context 'The system is not in the desired state' {
                $falseParameters = @{
                    Name = 'DnsServerSetting'
                }

                foreach ($key in $testParameters.Keys)
                {
                    if ($key -ne 'Name')
                    {
                        $falseTestParameters = $falseParameters.Clone()
                        $falseTestParameters.Add($key, $testParameters[$key])

                        It "Test method returns false when testing $key" {
                            Mock Get-TargetResource -MockWith { $mockGetCimInstance }
                            Test-TargetResource @falseTestParameters -Verbose | Should be $false
                        }
                    }
                }
            }

            Context 'The system is in the desired state' {
                Mock Get-TargetResource -MockWith { $mockGetCimInstance }

                $trueParameters = @{
                    Name = 'DnsServerSetting'
                }

                foreach ($key in $testParameters.Keys)
                {
                    if ($key -ne 'Name')
                    {
                        $trueTestParameters = $trueParameters.Clone()
                        $trueTestParameters.Add($key, $mockGetCimInstance[$key])

                        It "Test method returns true when testing $key" {
                            Test-TargetResource @trueTestParameters -Verbose | Should be $true
                        }
                    }
                }
            }
        }

        Describe 'MSFT_xDnsServerSetting\Test-TargetResource' {
            Mock -CommandName Assert-Module

            It 'Set method calls Set-CimInstance' {
                $mockCimClass = Import-Clixml -Path $PSScriptRoot\MockObjects\DnsServerClass.xml

                Mock Get-CimInstance -MockWith { $mockCimClass }
                Mock Set-CimInstance

                Set-TargetResource @testParameters -Verbose

                Assert-MockCalled Set-CimInstance -Exactly 1
            }
        }
    }
}
finally
{
    Invoke-TestCleanup
}
