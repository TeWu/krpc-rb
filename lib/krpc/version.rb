module KRPC
  module Version
    # Dear krpc-rb developer: Before bumping version below, please ensure that protobuf schema is up to date.
    MAJOR = 0
    MINOR = 4
    PATCH = 1
    LABEL = nil
    IS_STABLE = true
  end

  VERSION = ([Version::MAJOR, Version::MINOR, Version::PATCH, Version::LABEL, Version::IS_STABLE ? nil : "next"].compact * '.').freeze
end
