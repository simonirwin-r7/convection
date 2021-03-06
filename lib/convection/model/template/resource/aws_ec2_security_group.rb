require_relative '../resource'

module Convection
  module DSL
    ## Add DSL method to template namespace
    module Template
      def ec2_security_group(name, &block)
        r = Model::Template::Resource::EC2SecurityGroup.new(name, self)

        r.instance_exec(&block) if block
        resources[name] = r
      end

      module Resource
        ##
        # DSL For EC2SecurityGroup rules
        ##
        module EC2SecurityGroup
          def ingress_rule(protocol = nil, port = nil, source = nil, &block)
            rule = Model::Template::Resource::EC2SecurityGroup::Rule.new("#{ name }IngressGroupRule", @template)
            rule.protocol = protocol unless protocol.nil?
            rule.from = port unless port.nil?
            rule.to = port unless port.nil?
            rule.source = source unless source.nil?

            rule.instance_exec(&block) if block
            security_group_ingress << rule
          end

          def egress_rule(protocol = nil, port = nil, &block)
            rule = Model::Template::Resource::EC2SecurityGroup::Rule.new("#{ name }EgressGroupRule", @template)
            rule.protocol = protocol unless protocol.nil?
            rule.from = port unless port.nil?
            rule.to = port unless port.nil?

            rule.instance_exec(&block) if block
            security_group_egress << rule
          end
        end
      end
    end
  end

  module Model
    class Template
      class Resource
        ##
        # AWS::EC2::SecurityGroup
        ##
        class EC2SecurityGroup < Resource
          include DSL::Template::Resource::EC2SecurityGroup
          include Model::Mixin::Taggable

          attr_reader :security_group_ingress
          attr_reader :security_group_egress

          ##
          # Ingress/Egress Rule
          #
          class Rule < Resource
            extend Model::Mixin::Protocol

            attribute :from
            attribute :to
            protocol_property

            attribute :source
            attribute :destination_group
            attribute :source_group
            attribute :source_group_owner

            def render
              {
                'IpProtocol' => protocol, # From protocol_property
                'FromPort' => from,
                'ToPort' => to
              }.tap do |rule|
                rule['CidrIp'] = source unless source.nil?
                rule['DestinationSecurityGroupId'] = destination_group unless destination_group.nil?
                rule['SourceSecurityGroupId'] = source_group unless source_group.nil?
                rule['SourceSecurityGroupOwnerId'] = source_group_owner unless source_group_owner.nil?
              end
            end
          end

          property :description, 'GroupDescription'
          property :vpc, 'VpcId'

          def initialize(*args)
            super

            type 'AWS::EC2::SecurityGroup'
            @security_group_ingress = []
            @security_group_egress = []
          end

          def render(*args)
            super.tap do |resource|
              resource['Properties']['SecurityGroupIngress'] = security_group_ingress.map(&:render)
              resource['Properties']['SecurityGroupEgress'] = security_group_egress.map(&:render)
              render_tags(resource)
            end
          end
        end
      end
    end
  end
end
