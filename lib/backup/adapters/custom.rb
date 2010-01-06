module Backup
  module Adapters
    class Custom < Backup::Adapters::Base
      
      attr_accessor :archived_file, :compressed_file, :encrypted_file, :commands
      
      private

        # Execute any given commands, then archive and compress every folder/file
        def perform
          execute_commands
          targz
        end
        
        # Executes the commands
        def execute_commands
          if commands.is_a?(Array)
            puts system_messages[:commands]
            commands.each do |command|
              %x{ #{command.gsub(':tmp_path', tmp_path)} }
            end
          elsif commands.is_a?(String)
            puts system_messages[:commands]
            %x{ #{commands.gsub(':tmp_path', tmp_path)} }
          end
        end
        
        # Archives and Compresses
        def targz
          puts system_messages[:archiving]; puts system_messages[:compressing]
          %x{ tar -czf #{File.join(tmp_path, compressed_file)} #{File.join(tmp_path, '*')} }
        end
        
        # Loads the initial settings
        def load_settings
          self.trigger  = procedure.trigger
          self.commands = procedure.get_adapter_configuration.attributes['commands']
          
          self.archived_file    = "#{timestamp}.#{trigger.gsub(' ', '-')}.tar"      
          self.compressed_file  = "#{archived_file}.gz"
          self.encrypted_file   = "#{compressed_file}.enc"
          self.final_file       = compressed_file
        end
                
    end
  end
end
