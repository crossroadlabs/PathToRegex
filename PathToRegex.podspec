Pod::Spec.new do |s|
  s.name         = "PathToRegex"
  s.version      = "0.4.0"
  s.summary      = "A Swift library translating paths with wildcards into regular expressions"
  s.homepage     = "https://github.com/crossroadlabs/PathToRegex"
  s.license      = { :type => 'LGPL v3', :file => 'LICENSE' }
  s.author       = { "Crossroad Labs" => "daniel@crossroadlabs.xyz" }
  s.source       = { :git => "https://github.com/crossroadlabs/PathToRegex.git", :tag => "#{s.version}" }
  s.source_files = 'PathToRegex/*.swift'

  s.ios.deployment_target = '8.0'
  s.osx.deployment_target = '10.9'
  s.tvos.deployment_target = '9.0'
  s.watchos.deployment_target = '2.0'

  s.dependency 'CrossroadRegex', '~> 0.8.0'
end
