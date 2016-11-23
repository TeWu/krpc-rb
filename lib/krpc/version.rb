module KRPC
  module Version
    MAJOR = 0
    MINOR = 4
    PATCH = 0
    LABEL = 'beta1'
  end

  VERSION = ([Version::MAJOR, Version::MINOR, Version::PATCH, Version::LABEL].compact * '.').freeze
end
