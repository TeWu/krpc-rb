module KRPC
  module Version
    MAJOR = 0
    MINOR = 3
    PATCH = 1
    LABEL = nil
  end

  VERSION = ([Version::MAJOR, Version::MINOR, Version::PATCH, Version::LABEL].compact * '.').freeze
end
