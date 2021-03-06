require_relative '../../dsl/intrinsic_functions'
require_relative '../mixin/cidr_block'
require_relative '../mixin/conditional'
require_relative '../mixin/policy'
require_relative '../mixin/protocol'
require_relative '../mixin/taggable'
require_relative './output'

module Convection
  module Model
    class Template
      ##
      # Resource
      ##
      class Resource

        ##
        # Helpers for defining Resource DSLs
        ##
        module Helpers
          def property(accesor, property_name, type = :string)
            case type.to_sym
            when :string
              define_method(accesor) do |value = nil|
                ## Call Instance#property
                return property(property_name) if value.nil?
                property(property_name, value)
              end

              define_method("#{ accesor }=") do |value|
                ## Call Instance#property
                property(property_name, value)
              end
            when :array
              define_method(accesor) do |*value|
                @properties[property_name] = [] unless @properties[property_name].is_a?(Array)
                @properties[property_name].push(*value.flatten.map do |entity|
                  entity.is_a?(Resource) ? entity.reference : entity
                end)

                @properties[property_name]
              end
            else
              fail TypeError, "Property must be defined with type `string` or `array`, not #{ type }"
            end
          end
        end

        include DSL::Helpers
        include Model::Mixin::Conditional
        extend Resource::Helpers

        attribute :type
        attr_reader :name
        attr_reader :properties

        def initialize(name, template)
          @name = name
          @template = template

          @type = ''
          @properties = {}
          @depends_on = []
        end

        def property(key, value = nil)
          return properties[key] if value.nil?
          properties[key] = value.is_a?(Resource) ? value.reference : value
        end

        def depends_on(resource)
          @depends_on << (resource.is_a?(Resource) ? resource.name : resource)
        end

        def reference
          {
            'Ref' => name
          }
        end

        def with_output(output_name = name, value = reference, &block)
          o = Model::Template::Output.new(output_name, @template)
          o.value = value
          o.description = "Resource #{ type }/#{ name }"

          o.instance_exec(&block) if block
          @template.outputs[output_name] = o
        end

        def as_attribute(attr_name, attr_type = :string)
          @template.attribute_mappings[name] = {
            :name => attr_name,
            :type => attr_type
          }
        end

        def render
          {
            'Type' => type,
            'Properties' => properties
          }.tap do |resource|
            resource['DependsOn'] = @depends_on unless @depends_on.empty?
            render_condition(resource)
          end
        end
      end
    end
  end
end

require_relative 'resource/aws_auto_scaling_auto_scaling_group.rb'
require_relative 'resource/aws_auto_scaling_launch_configuration.rb'
require_relative 'resource/aws_auto_scaling_scaling_policy.rb'
require_relative 'resource/aws_cloud_watch_alarm'
require_relative 'resource/aws_ec2_instance'
require_relative 'resource/aws_ec2_internet_gateway'
require_relative 'resource/aws_ec2_network_acl'
require_relative 'resource/aws_ec2_network_acl_entry'
require_relative 'resource/aws_ec2_route'
require_relative 'resource/aws_ec2_route_table'
require_relative 'resource/aws_ec2_security_group'
require_relative 'resource/aws_ec2_subnet'
require_relative 'resource/aws_ec2_subnet_network_acl_association'
require_relative 'resource/aws_ec2_subnet_route_table_association'
require_relative 'resource/aws_ec2_vpc'
require_relative 'resource/aws_ec2_vpc_gateway_attachment'
require_relative 'resource/aws_elb.rb'
require_relative 'resource/aws_s3_bucket'
require_relative 'resource/aws_s3_bucket_policy'
require_relative 'resource/aws_iam_group'
require_relative 'resource/aws_iam_access_key'
require_relative 'resource/aws_iam_role'
require_relative 'resource/aws_iam_policy'
require_relative 'resource/aws_iam_user'
require_relative 'resource/aws_iam_instance_profile'
require_relative 'resource/aws_rds_db_instance'
require_relative 'resource/aws_rds_db_parameter_group'
require_relative 'resource/aws_rds_db_subnet_group.rb'
require_relative 'resource/aws_rds_db_security_group.rb'
require_relative 'resource/aws_route53_recordset.rb'
require_relative 'resource/aws_route53_health_check.rb'
require_relative 'resource/aws_sns_topic'
require_relative 'resource/aws_sqs_queue'
require_relative 'resource/aws_sqs_queue_policy'
