# -*- encoding: utf-8 -*-
# stub: fastlane 2.214.0 ruby cert/lib credentials_manager/lib deliver/lib fastlane/lib fastlane_core/lib frameit/lib gym/lib match/lib pem/lib pilot/lib precheck/lib produce/lib scan/lib screengrab/lib sigh/lib snapshot/lib spaceship/lib supply/lib trainer/lib

Gem::Specification.new do |s|
  s.name = "fastlane".freeze
  s.version = "2.214.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.metadata = { "bug_tracker_uri" => "https://github.com/fastlane/fastlane/issues", "changelog_uri" => "https://github.com/fastlane/fastlane/releases", "documentation_uri" => "https://docs.fastlane.tools/", "homepage_uri" => "https://fastlane.tools", "source_code_uri" => "https://github.com/fastlane/fastlane" } if s.respond_to? :metadata=
  s.require_paths = ["cert/lib".freeze, "credentials_manager/lib".freeze, "deliver/lib".freeze, "fastlane/lib".freeze, "fastlane_core/lib".freeze, "frameit/lib".freeze, "gym/lib".freeze, "match/lib".freeze, "pem/lib".freeze, "pilot/lib".freeze, "precheck/lib".freeze, "produce/lib".freeze, "scan/lib".freeze, "screengrab/lib".freeze, "sigh/lib".freeze, "snapshot/lib".freeze, "spaceship/lib".freeze, "supply/lib".freeze, "trainer/lib".freeze]
  s.authors = ["Iulian Onofrei".freeze, "Josh Holtz".freeze, "Fumiya Nakamura".freeze, "Olivier Halligon".freeze, "Maksym Grebenets".freeze, "Kohki Miki".freeze, "Jimmy Dee".freeze, "Jan Piotrowski".freeze, "Andrew McBurney".freeze, "Aaron Brager".freeze, "Helmut Januschka".freeze, "Matthew Ellis".freeze, "Luka Mirosevic".freeze, "Max Ott".freeze, "Stefan Natchev".freeze, "J\u00E9r\u00F4me Lacoste".freeze, "Felix Krause".freeze, "Jorge Revuelta H".freeze, "Joshua Liebowitz".freeze, "\u0141ukasz Grabowski".freeze, "Satoshi Namai".freeze, "Daniel Jankowski".freeze, "Manu Wallner".freeze, "Danielle Tomlinson".freeze, "Roger Oba".freeze, "Manish Rathi".freeze]
  s.date = "2023-07-14"
  s.description = "The easiest way to automate beta deployments and releases for your iOS and Android apps".freeze
  s.email = ["fastlane@krausefx.com".freeze]
  s.executables = ["bin-proxy".freeze, "fastlane".freeze]
  s.files = ["bin/bin-proxy".freeze, "bin/fastlane".freeze]
  s.homepage = "https://fastlane.tools".freeze
  s.licenses = ["MIT".freeze]
  s.required_ruby_version = Gem::Requirement.new(">= 2.6".freeze)
  s.rubygems_version = "3.2.33".freeze
  s.summary = "The easiest way to automate beta deployments and releases for your iOS and Android apps".freeze

  s.installed_by_version = "3.2.33" if s.respond_to? :installed_by_version

  if s.respond_to? :specification_version then
    s.specification_version = 4
  end

  if s.respond_to? :add_runtime_dependency then
    s.add_runtime_dependency(%q<xcodeproj>.freeze, [">= 1.13.0", "< 2.0.0"])
    s.add_runtime_dependency(%q<xcpretty>.freeze, ["~> 0.3.0"])
    s.add_runtime_dependency(%q<terminal-notifier>.freeze, [">= 2.0.0", "< 3.0.0"])
    s.add_runtime_dependency(%q<terminal-table>.freeze, [">= 1.4.5", "< 2.0.0"])
    s.add_runtime_dependency(%q<plist>.freeze, [">= 3.1.0", "< 4.0.0"])
    s.add_runtime_dependency(%q<CFPropertyList>.freeze, [">= 2.3", "< 4.0.0"])
    s.add_runtime_dependency(%q<addressable>.freeze, [">= 2.8", "< 3.0.0"])
    s.add_runtime_dependency(%q<multipart-post>.freeze, [">= 2.0.0", "< 3.0.0"])
    s.add_runtime_dependency(%q<word_wrap>.freeze, ["~> 1.0.0"])
    s.add_runtime_dependency(%q<optparse>.freeze, ["~> 0.1.1"])
    s.add_runtime_dependency(%q<tty-screen>.freeze, [">= 0.6.3", "< 1.0.0"])
    s.add_runtime_dependency(%q<tty-spinner>.freeze, [">= 0.8.0", "< 1.0.0"])
    s.add_runtime_dependency(%q<artifactory>.freeze, ["~> 3.0"])
    s.add_runtime_dependency(%q<babosa>.freeze, [">= 1.0.3", "< 2.0.0"])
    s.add_runtime_dependency(%q<colored>.freeze, [">= 0"])
    s.add_runtime_dependency(%q<commander>.freeze, ["~> 4.6"])
    s.add_runtime_dependency(%q<excon>.freeze, [">= 0.71.0", "< 1.0.0"])
    s.add_runtime_dependency(%q<faraday-cookie_jar>.freeze, ["~> 0.0.6"])
    s.add_runtime_dependency(%q<faraday>.freeze, ["~> 1.0"])
    s.add_runtime_dependency(%q<faraday_middleware>.freeze, ["~> 1.0"])
    s.add_runtime_dependency(%q<fastimage>.freeze, [">= 2.1.0", "< 3.0.0"])
    s.add_runtime_dependency(%q<gh_inspector>.freeze, [">= 1.1.2", "< 2.0.0"])
    s.add_runtime_dependency(%q<highline>.freeze, ["~> 2.0"])
    s.add_runtime_dependency(%q<json>.freeze, ["< 3.0.0"])
    s.add_runtime_dependency(%q<mini_magick>.freeze, [">= 4.9.4", "< 5.0.0"])
    s.add_runtime_dependency(%q<naturally>.freeze, ["~> 2.2"])
    s.add_runtime_dependency(%q<rubyzip>.freeze, [">= 2.0.0", "< 3.0.0"])
    s.add_runtime_dependency(%q<security>.freeze, ["= 0.1.3"])
    s.add_runtime_dependency(%q<xcpretty-travis-formatter>.freeze, [">= 0.0.3"])
    s.add_runtime_dependency(%q<dotenv>.freeze, [">= 2.1.1", "< 3.0.0"])
    s.add_runtime_dependency(%q<bundler>.freeze, [">= 1.12.0", "< 3.0.0"])
    s.add_runtime_dependency(%q<simctl>.freeze, ["~> 1.6.3"])
    s.add_runtime_dependency(%q<jwt>.freeze, [">= 2.1.0", "< 3"])
    s.add_runtime_dependency(%q<google-apis-playcustomapp_v1>.freeze, ["~> 0.1"])
    s.add_runtime_dependency(%q<google-apis-androidpublisher_v3>.freeze, ["~> 0.3"])
    s.add_runtime_dependency(%q<google-cloud-storage>.freeze, ["~> 1.31"])
    s.add_runtime_dependency(%q<emoji_regex>.freeze, [">= 0.1", "< 4.0"])
    s.add_runtime_dependency(%q<aws-sdk-s3>.freeze, ["~> 1.0"])
    s.add_development_dependency(%q<rake>.freeze, [">= 0"])
    s.add_development_dependency(%q<rspec>.freeze, ["~> 3.10"])
    s.add_development_dependency(%q<rspec_junit_formatter>.freeze, ["~> 0.4.1"])
    s.add_development_dependency(%q<pry>.freeze, [">= 0"])
    s.add_development_dependency(%q<pry-byebug>.freeze, [">= 0"])
    s.add_development_dependency(%q<pry-rescue>.freeze, [">= 0"])
    s.add_development_dependency(%q<pry-stack_explorer>.freeze, [">= 0"])
    s.add_development_dependency(%q<yard>.freeze, ["~> 0.9.11"])
    s.add_development_dependency(%q<webmock>.freeze, ["~> 3.8"])
    s.add_development_dependency(%q<coveralls>.freeze, ["~> 0.8.13"])
    s.add_development_dependency(%q<rubocop>.freeze, ["= 1.12.1"])
    s.add_development_dependency(%q<rubocop-performance>.freeze, [">= 0"])
    s.add_development_dependency(%q<rubocop-require_tools>.freeze, [">= 0"])
    s.add_development_dependency(%q<rb-readline>.freeze, [">= 0"])
    s.add_development_dependency(%q<rest-client>.freeze, [">= 1.8.0"])
    s.add_development_dependency(%q<fakefs>.freeze, ["~> 1.2"])
    s.add_development_dependency(%q<sinatra>.freeze, ["~> 2.0.8"])
    s.add_development_dependency(%q<xcov>.freeze, ["~> 1.4.1"])
    s.add_development_dependency(%q<climate_control>.freeze, ["~> 0.2.0"])
  else
    s.add_dependency(%q<xcodeproj>.freeze, [">= 1.13.0", "< 2.0.0"])
    s.add_dependency(%q<xcpretty>.freeze, ["~> 0.3.0"])
    s.add_dependency(%q<terminal-notifier>.freeze, [">= 2.0.0", "< 3.0.0"])
    s.add_dependency(%q<terminal-table>.freeze, [">= 1.4.5", "< 2.0.0"])
    s.add_dependency(%q<plist>.freeze, [">= 3.1.0", "< 4.0.0"])
    s.add_dependency(%q<CFPropertyList>.freeze, [">= 2.3", "< 4.0.0"])
    s.add_dependency(%q<addressable>.freeze, [">= 2.8", "< 3.0.0"])
    s.add_dependency(%q<multipart-post>.freeze, [">= 2.0.0", "< 3.0.0"])
    s.add_dependency(%q<word_wrap>.freeze, ["~> 1.0.0"])
    s.add_dependency(%q<optparse>.freeze, ["~> 0.1.1"])
    s.add_dependency(%q<tty-screen>.freeze, [">= 0.6.3", "< 1.0.0"])
    s.add_dependency(%q<tty-spinner>.freeze, [">= 0.8.0", "< 1.0.0"])
    s.add_dependency(%q<artifactory>.freeze, ["~> 3.0"])
    s.add_dependency(%q<babosa>.freeze, [">= 1.0.3", "< 2.0.0"])
    s.add_dependency(%q<colored>.freeze, [">= 0"])
    s.add_dependency(%q<commander>.freeze, ["~> 4.6"])
    s.add_dependency(%q<excon>.freeze, [">= 0.71.0", "< 1.0.0"])
    s.add_dependency(%q<faraday-cookie_jar>.freeze, ["~> 0.0.6"])
    s.add_dependency(%q<faraday>.freeze, ["~> 1.0"])
    s.add_dependency(%q<faraday_middleware>.freeze, ["~> 1.0"])
    s.add_dependency(%q<fastimage>.freeze, [">= 2.1.0", "< 3.0.0"])
    s.add_dependency(%q<gh_inspector>.freeze, [">= 1.1.2", "< 2.0.0"])
    s.add_dependency(%q<highline>.freeze, ["~> 2.0"])
    s.add_dependency(%q<json>.freeze, ["< 3.0.0"])
    s.add_dependency(%q<mini_magick>.freeze, [">= 4.9.4", "< 5.0.0"])
    s.add_dependency(%q<naturally>.freeze, ["~> 2.2"])
    s.add_dependency(%q<rubyzip>.freeze, [">= 2.0.0", "< 3.0.0"])
    s.add_dependency(%q<security>.freeze, ["= 0.1.3"])
    s.add_dependency(%q<xcpretty-travis-formatter>.freeze, [">= 0.0.3"])
    s.add_dependency(%q<dotenv>.freeze, [">= 2.1.1", "< 3.0.0"])
    s.add_dependency(%q<bundler>.freeze, [">= 1.12.0", "< 3.0.0"])
    s.add_dependency(%q<simctl>.freeze, ["~> 1.6.3"])
    s.add_dependency(%q<jwt>.freeze, [">= 2.1.0", "< 3"])
    s.add_dependency(%q<google-apis-playcustomapp_v1>.freeze, ["~> 0.1"])
    s.add_dependency(%q<google-apis-androidpublisher_v3>.freeze, ["~> 0.3"])
    s.add_dependency(%q<google-cloud-storage>.freeze, ["~> 1.31"])
    s.add_dependency(%q<emoji_regex>.freeze, [">= 0.1", "< 4.0"])
    s.add_dependency(%q<aws-sdk-s3>.freeze, ["~> 1.0"])
    s.add_dependency(%q<rake>.freeze, [">= 0"])
    s.add_dependency(%q<rspec>.freeze, ["~> 3.10"])
    s.add_dependency(%q<rspec_junit_formatter>.freeze, ["~> 0.4.1"])
    s.add_dependency(%q<pry>.freeze, [">= 0"])
    s.add_dependency(%q<pry-byebug>.freeze, [">= 0"])
    s.add_dependency(%q<pry-rescue>.freeze, [">= 0"])
    s.add_dependency(%q<pry-stack_explorer>.freeze, [">= 0"])
    s.add_dependency(%q<yard>.freeze, ["~> 0.9.11"])
    s.add_dependency(%q<webmock>.freeze, ["~> 3.8"])
    s.add_dependency(%q<coveralls>.freeze, ["~> 0.8.13"])
    s.add_dependency(%q<rubocop>.freeze, ["= 1.12.1"])
    s.add_dependency(%q<rubocop-performance>.freeze, [">= 0"])
    s.add_dependency(%q<rubocop-require_tools>.freeze, [">= 0"])
    s.add_dependency(%q<rb-readline>.freeze, [">= 0"])
    s.add_dependency(%q<rest-client>.freeze, [">= 1.8.0"])
    s.add_dependency(%q<fakefs>.freeze, ["~> 1.2"])
    s.add_dependency(%q<sinatra>.freeze, ["~> 2.0.8"])
    s.add_dependency(%q<xcov>.freeze, ["~> 1.4.1"])
    s.add_dependency(%q<climate_control>.freeze, ["~> 0.2.0"])
  end
end
