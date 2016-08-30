platform :ios, '9.0'

source 'https://github.com/CocoaPods/Specs.git'
source 'https://git.nerderylabs.com/BRAVO.iOS.NerderyPods'

use_frameworks!

target 'NetflixPOC' do

# HTTP Mocking
# DEVELOPMENT && TESTING ONLY !!!
pod "Nocilla", :git => 'https://github.com/mark-randall/Nocilla'

# APIClient using AlamoFire
pod "APIClient", :git => 'https://git.nerderylabs.com/SIERRA.iOS.AlamofireAPIClient', :branch => 'develop'

# Statusbar ActivityIndicator for AlamoFire
pod 'AlamofireNetworkActivityIndicator', '~> 1.0'

# UITableViewDataSource abstraction
pod "DataSources", :git => 'https://git.nerderylabs.com/SIERRA.iOS.DataSources', :branch => 'develop'

# JSON to NSManagedObject model deserialization
pod "CoreDataExtensions", :git => 'https://git.nerderylabs.com/SIERRA.iOS.CoreDataExtensions', :branch => 'develop'

# MVVM Data Binding
pod 'RxSwift',    '~> 2.0'

# JWT for API Authentication
pod 'JSONWebToken', '~>1.4'

# Image Downloading and Caching
pod 'PINRemoteImage'

pod 'google-cast-sdk'

end

#Uncomment to update Acknowledgements.plist
#
#post_install do | installer |
#    require 'fileutils'
#    FileUtils.cp_r('Pods/Target Support Files/Pods/Pods-Acknowledgements.plist', 'SmartClean/Resources/Settings.bundle/Acknowledgements.plist', :remove_destination => true)
#end