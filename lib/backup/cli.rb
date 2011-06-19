# encoding: utf-8

module Backup
  module CLI

    ##
    # Wrapper method for %x[] to run CL commands
    # through a ruby method. This helps with test coverage and
    # improves readability.
    #
    # It'll first remove all prefixing and postfix spaces by using .strip!
    # This allows for the EOS blocks to be indented without actually using any
    # prefixing spaces. This cleans up the implementation code.
    #
    # Every time the Backup::CLI#run method is invoked, it'll invoke
    # the Backup::CLI#raise_if_command_not_found method after running the
    # requested command on the OS.
    #
    # Backup::CLI#raise_if_command_not_found takes a single argument, the utility name.
    # the command.slice(0, command.index(/\s/) || command.size).split('/')[-1] line will extract only the utility
    # name (e.g. mongodump, pgdump, etc) from a command like "/usr/local/bin/mongodump <options>"
    # and pass that in to the Backup::CLI#raise_if_command_not_found
    def run(command)
      command.strip!
      @nice_utility ||= utility('nice')
      command_utility = command.slice(0, command.index(/\s/) || command.size).split('/')[-1]
      not_found = utility(command_utility) == command_utility
      return if not_found

      if @nice_utility != 'nice'
        #it exists on the system; lets use it!
        `nice -n 20 #{command}`
      else
        `#{command}`
      end
    ensure
      raise_if_command_not_found!(command_utility, not_found)
    end

    ##
    # Wrapper method for FileUtils.mkdir_p to create directories
    # through a ruby method. This helps with test coverage and
    # improves readability
    def mkdir(path)
      FileUtils.mkdir_p(path)
    end

    ##
    # Wrapper for the FileUtils.rm_rf to remove files and folders
    # through a ruby method. This helps with test coverage and
    # improves readability
    def rm(path)
      FileUtils.rm_rf(path)
    end

    ##
    # Tries to find the full path of the specified utility. If the full
    # path is found, it'll return that. Otherwise it'll just return the
    # name of the utility. If the 'utility_path' is defined, it'll check
    # to see if it isn't an empty string, and if it isn't, it'll go ahead and
    # always use that path rather than auto-detecting it
    def utility(name)
      if respond_to?(:utility_path)
        if utility_path.is_a?(String) and not utility_path.empty?
          return utility_path
        end
      end

      if path = %x[which #{name}].chomp and not path.empty?
        return path
      end
      name
    end

    ##
    # If the command that was previously run via this Ruby process returned
    # error code "32512", the invoked utility (e.g. mysqldump, pgdump, etc) could not be found.
    # If this is the case then this method will throw an exception, informing the user of this problem.
    #
    # Since this raises an exception, it'll stop the entire backup process, clean up the temp files
    # and notify the user via the built-in notifiers if these are set.
    def raise_if_command_not_found!(utility, not_found=false)
      if not_found || $?.to_i.eql?(32512)
        raise Exception::CommandNotFound , "Could not find the utility \"#{utility}\" on \"#{RUBY_PLATFORM}\".\n" +
                                           "If this is a database utility, try defining the 'utility_path' option in the configuration file.\n" +
                                           "See the Database Wiki for more information about the Utility Path option."
      end
    end

  end
end
