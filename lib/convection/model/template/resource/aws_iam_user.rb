require_relative '../resource'

module Convection
  module DSL
    ## Add DSL method to template namespace
    module Template
      def iam_user(name, &block)
        r = Model::Template::Resource::IAMUser.new(name, self)

        r.instance_exec(&block) if block
        resources[name] = r
      end

      module Resource
        ## Role DSL
        module IAMUser
          def policy(policy_name, &block)
            add_policy = Model::Mixin::Policy.new(:name => policy_name, :template => @template)
            add_policy.instance_exec(&block) if block

            @policies << add_policy
          end

          def with_key(serial = 0, &block)
            key = Model::Template::Resource::IAMAccessKey.new("#{ name }Key", @template)
            key.user_name = self
            key.serial = serial

            key.depends_on(self)

            key.with_output("#{ name }Id", key.reference)
            key.with_output("#{ name }Secret", get_att(key.name, 'SecretAccessKey'))

            key.instance_exec(&block) if block

            @template.resources[key.name] = key
          end
        end
      end
    end
  end

  module Model
    class Template
      class Resource
        ##
        # AWS::IAM::User
        ##
        class IAMUser < Resource
          include DSL::Template::Resource::IAMUser

          property :path, 'Path'
          property :login_profile, 'LoginProfile'
          property :group, 'Groups', :array
          attr_reader :policies

          def initialize(*args)
            super

            type 'AWS::IAM::User'
            @policies = []
          end

          def render
            @properties['Policies'] = @policies.map(&:render) unless @policies.empty?
            super
          end
        end
      end
    end
  end
end
