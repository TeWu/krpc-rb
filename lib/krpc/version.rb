module KRPC
  module Version
    # Dear krpc-rb developer: Before bumping version below, please ensure that protobuf schema is up to date.
    MAJOR = 0
    MINOR = 4
    PATCH = 0
    LABEL = 'beta3'
  end

  VERSION = ([Version::MAJOR, Version::MINOR, Version::PATCH, Version::LABEL].compact * '.').freeze
end
