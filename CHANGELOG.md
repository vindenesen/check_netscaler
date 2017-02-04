## 1.0.0 (2017-02-01)
 - huge rewrite of the Plugin, changed nearly every parameters 
 - upgrading from versions prior to 1.0.0 require to change your monitoring configuration
 - added own nitro implementation and dropped the dependency to Nitro.pm by Citrix
 - added check for unsaved configuration changes (changes in nsconfig not written to disk)
 - improved check for ssl certificates to only check for a specific certificate
 - fixed a bug in check_state to support services and servicegroups again

## 0.2.0
 - patch for Nitro.pm to support ssl connections
 - added check to test the validity and expiry of installed certificates 

## 0.1.2
 - added performance data feature 
 - updated sub add_arg and added default values for parameters
 - Bugfix in vserver checks loop by @macampo 

## 0.1.1 
 - documentation fixes by @Velociraptor85

## 0.1.0 (2015-12-17)
 - First release based on Nitro.pm