require 'aws-sdk'
require 'tty-prompt'
require 'optparse'
require 'parseconfig'
require 'ncupdater'

library_files = Dir[File.join(File.dirname(__FILE__), '/ncaws/**/*.rb')].sort
library_files.each do |file|
    require file
end

class NCAws
    def options
        @options = {}
        @role = ''
        @environment = ''
        @name = ''
        # Use OptionParser gem to get the options we need
        opt_parser = OptionParser.new do |opts|
          opts.banner = 'Usage: ncaws [options]'

          opts.on('-r', '--role ROLE', 'Filter by tag role') do |role|
            @options[:roel] = role
            @role = role
          end

          opts.on('-e', '--environment ENVIRONMENT', 'Filter by tag environment') do |environment|
            @options[:environment] = environment
            @environment = environment
          end

          opts.on('-n', '--name NAME', 'Filter by name') do |name|
            @options[:name] = name
            @name = name
          end
        end
        opt_parser.parse!
    end

    def run
        commands = {
            :'Adding gem server' => 'sudo gem sources -a http://gems.nodesmanager.io',
            :'Gem update' => 'sudo gem update ncaws'
        }

        ncupdater = NCUpdater::new(File.dirname(__FILE__) + '/../.semver', 'http://nodesmanager.io/versions/ncaws', commands)

        if ncupdater::new_version?
            ncupdater::update
        end

        options
        connect
    end

    def connect

        servers = {}
        bastion = {}
        role = {}
        environment = {}

        if @role != ''
            role = {
                name: 'tag:role',
                values: ["#{@role}"]
            }
        end

        if @environment != ''
            environment = {
                name: 'tag:environment',
                values: ["#{@environment}"]
            }
        end

        if @name != ''
            environment = {
                name: 'tag:Name',
                values: ["#{@name}"]
            }
        end

        ec2 = Aws::EC2::Client.new(
            access_key_id: config['AWS']['KEY'],
            secret_access_key: config['AWS']['SECRET'],
            region: 'eu-west-1'
        )

       filters = {
          filters: [
              {
                  name: 'instance-state-name',
                  values: ['running']
              },
              role,
              environment
          ]
      }

       ec2_instances = ec2.describe_instances(filters)

        instance_name = 'undefined'
        instance_env = 'undefined'

        ec2_instances.reservations.each do |instance|
            instance.instances[0].tags.each do |value|
                if value.key == 'Name'
                    instance_name = value.value
                end

                if value.key == 'environment'
                    instance_env = value.value
                end
            end
            servers["#{instance_env} #{instance_name.colorize(:light_blue)} (#{instance.instances[0].private_ip_address})"] = "#{instance.instances[0].private_ip_address}"
            if instance.instances[0].vpc_id == config['VPC1']['ID']
                bastion["#{instance.instances[0].private_ip_address}"] = config['VPC1']['BASTION']
            elsif instance.instances[0].vpc_id == config['VPC2']['ID']
                bastion["#{instance.instances[0].private_ip_address}"] = config['VPC2']['BASTION']
            else
                bastion["#{instance.instances[0].private_ip_address}"] = config['DEFAULT']['BASTION']
            end
        end

        begin
            prompt = TTY::Prompt.new
            server = prompt.select("Choose server to connect to", servers)
        rescue SystemExit, Interrupt
            exit
        end

        exec "ssh -o ProxyCommand=\"ssh -W %h:%p ubuntu@#{bastion[server]}\" ubuntu@#{server}"

    end

    def config
        config = ParseConfig.new('/etc/nodes/ncaws.conf')
        config

      end
end
