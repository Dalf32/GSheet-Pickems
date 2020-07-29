lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "gsheet-pickems/version"

Gem::Specification.new do |spec|
  spec.name          = "gsheet-pickems"
  spec.version       = GSheetPickems::VERSION
  spec.authors       = ["Dalf32"]
  spec.email         = ["kylepmullins@gmail.com"]

  spec.summary       = 'Google Sheets Pickems'
  spec.description   = ''
  spec.homepage      = "https://github.com/Dalf32/GSheet-Pickems"
  spec.license       = "MIT"

  if spec.respond_to?(:metadata)
    spec.metadata["homepage_uri"] = spec.homepage
    spec.metadata["source_code_uri"] = "https://github.com/Dalf32/GSheet-Pickems"
    spec.metadata["changelog_uri"] = spec.metadata["source_code_uri"]
  else
    raise "RubyGems 2.0 or newer is required to protect against " \
      "public gem pushes."
  end

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  # spec.files         = Dir.chdir(File.expand_path('..', __FILE__)) do
  #   `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  # end
  spec.files         = Dir.chdir(File.expand_path('..', __FILE__)) do |dir|
    Dir.glob(File.join('**', '*.rb'))
  end
  spec.bindir        = "bin"
  spec.executables   = []
  spec.require_paths = ["lib"]

  spec.add_development_dependency 'bundler', '~> 1.17'
  spec.add_development_dependency 'rake', '~> 10.0'
  spec.add_dependency 'googleauth', '~>0.10'
  spec.add_dependency 'google-api-client', '~>0.37'
  spec.add_dependency 'json', '>=2.3'
end
