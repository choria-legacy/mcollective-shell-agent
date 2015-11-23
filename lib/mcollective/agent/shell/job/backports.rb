require 'rubygems'
require 'posix-spawn'
require 'uuid'

module Process
  def self.spawn(*arguments)
    ::POSIX::Spawn.spawn(*arguments)
  end
end

module SecureRandom
  def self.uuid
    ::UUID.generate
  end
end
