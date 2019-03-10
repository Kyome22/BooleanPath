Pod::Spec.new do |spec|
  spec.name         = "BooleanPath"
  spec.version      = "1.0"
  spec.summary      = "Add boolean operations to NSBezierPath like the pathfinder of Adobe Illustrator."
  spec.description  = <<-DESC
    This is a rewrite of VectorBoolean written by Leslie Titze's.
    BooleanPath is written by Swift for macOS.
  DESC
  spec.homepage     = "https://github.com/Kyome22/BooleanPath"
  spec.license      = { :type => "MIT", :file => "LICENSE" }
  spec.author       = { "Takuto Nakamura" => "kyomesuke@icloud.com" }
  spec.social_media_url      = "https://twitter.com/Kyomesuke3"
  spec.osx.deployment_target = '10.10'
  spec.source       = { :git => "https://github.com/Kyome22/BooleanPath.git", :tag => "#{spec.version}" }
  spec.frameworks   = 'Foundation', 'Cocoa', 'QuartzCore'
  spec.source_files  = "BooleanPath/**/*.swift"
  spec.swift_version = "4.2"
  spec.requires_arc  = true
end
