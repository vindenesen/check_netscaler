## 1.3.0 (2017-XX-XX)
- added command license to check the status of a local license file (#17)
- added perl-Time-Piece as new dependency (Time::Piece for license check)
- added switch for selecting a different version of the NITRO API (fixes #16)
- allow the usage of urlopts everywhere (fixes #13)

## 1.2.0 (2017-08-12)
- merged pull request from @bb-Ricardo
  - added command server to check status of Load Balancing Servers
  - added command hwinfo to just print information about the Netscaler itself
  - added command interfaces to check state of all interfaces and add performance data for each interface
  - added command to request performance data
  - added command to check the state of a servicegroup and its members (set warning and critical values for member quorum)
  - added Icinga2 config templates
- updated documentation and plugin_test.sh

## 1.1.1 (2017-06-10)
- bugfix for servicegroups in 12.0 (#12)
- new option to connect to an alternate port (for CPX instances)

## 1.1.0 (2017-05-13)
 - new check command for STA services
 - small documentation fixes

## 1.0.0 (2017-02-01)
 - huge rewrite of the Plugin, changed nearly every parameters 
 - upgrading from versions prior to 1.0.0 require to change your monitoring configuration
 - added own nitro implementation and dropped the dependency to Nitro.pm by Citrix
 - added check for unsaved configuration changes (changes in nsconfig not written to disk)
 - improved check for ssl certificates to only check for a specific certificate
 - fixed a bug in check_state to support services and servicegroups again

## 0.2.0 2017-01-04
 - patch for Nitro.pm to support ssl connections
 - added check to test the validity and expiry of installed certificates 

## 0.1.2 2016-12-02
 - added performance data feature 
 - updated sub add_arg and added default values for parameters
 - Bugfix in vserver checks loop by @macampo 

## 0.1.1 2016-11-10
 - documentation fixes by @Velociraptor85

## 0.1.0 (2015-12-17)
 - First release based on Nitro.pm
