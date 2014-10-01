require 'puppet/parameter/name'
require 'puppet/property/connection_limit'
require 'puppet/property/connection_rate_limit'
require 'puppet/property/description'
require 'puppet/property/state'
require 'puppet/property/truthy'
require 'puppet/property/profile'

Puppet::Type.newtype(:f5_virtualserver) do
  @doc = 'Manage node objects'

  # Parameter reference per provider:
  # https://support.f5.com/kb/en-us/solutions/public/14000/100/sol14163.html

  apply_to_device
  ensurable

  newparam(:name, :parent => Puppet::Parameter::F5Name, :namevar => true)
  newproperty(:connection_limit, :parent => Puppet::Property::F5ConnectionLimit)
  newproperty(:connection_rate_limit, :parent => Puppet::Property::F5ConnectionRateLimit)
  newproperty(:description, :parent => Puppet::Property::F5Description)
  newproperty(:state, :parent => Puppet::Property::F5State)

  newproperty(:source) do
    # TODO: Should we validate this to an IP?
    # yes; cidr
  end

  newproperty(:destination_address) do
    #options = "{ 'host': '<address>' } or { 'network': '<address> <mask>' }"

    #validate do |value|
    #  unless value.is_a?(Hash) and (value['host'] or value['network'])
    #    fail ArgumentError, "Destination: Valid options: #{options}"
    #  end
    #end
  end

  newproperty(:destination_mask) do
  end

  newproperty(:service_port) do
    #used by destination
    options = "<*|Integer>"

    validate do |value|
      fail ArgumentError, "Service_port: Valid options: #{options}" unless value =~ /^(\*|\d+)$/
      # Only check in the case of a number.
      if value =~ /\d+$/
        fail ArgumentError, "Service_port:  Must be between 1-65535" unless value.to_i.between?(1,65535)
      end
    end
    munge do |value|
      if value == "*"
        0
      else
        value
      end
    end
  end

  newproperty(:protocol) do
    newvalues(:all, :tcp, :udp, :sctp)
  end

  newproperty(:address_status, :parent => Puppet::Property::F5truthy) do
    truthy_property("Notify Status to Virtual Address in the gui", :yes, :no)
  end

  newproperty(:protocol_profile_client, :parent => Puppet::Property::F5Profile) do
  end

  newproperty(:protocol_profile_server, :parent => Puppet::Property::F5Profile) do
  end

  # Only one of the next five properties can be set.
  newproperty(:http_profile, :parent => Puppet::Property::F5Profile) do
  end

  newproperty(:ftp_profile, :parent => Puppet::Property::F5Profile) do
  end

  newproperty(:rtsp_profile, :parent => Puppet::Property::F5Profile) do
  end

  newproperty(:socks_profile, :parent => Puppet::Property::F5Profile) do
  end

  newproperty(:xml_profile, :parent => Puppet::Property::F5Profile) do
  end


  newproperty(:stream_profile, :parent => Puppet::Property::F5Profile) do
  end

  newproperty(:ssl_profile_client, :array_matching => :all, :parent => Puppet::Property::F5Profile) do
  end

  newproperty(:ssl_profile_server, :array_matching => :all, :parent => Puppet::Property::F5Profile) do
  end

  newproperty(:authentication_profiles, :array_matching => :all, :parent => Puppet::Property::F5Profile) do
  end

  newproperty(:dns_profile, :parent => Puppet::Property::F5Profile) do
  end

  newproperty(:diameter_profile, :parent => Puppet::Property::F5Profile) do
  end

  newproperty(:fix_profile, :parent => Puppet::Property::F5Profile) do
  end

  newproperty(:request_adapt_profile, :parent => Puppet::Property::F5Profile) do
  end

  newproperty(:response_adapt_profile, :parent => Puppet::Property::F5Profile) do
  end

  newproperty(:sip_profile, :parent => Puppet::Property::F5Profile) do
  end

  newproperty(:statistics_profile, :parent => Puppet::Property::F5Profile) do
  end

  newproperty(:vlan_and_tunnel_traffic) do
    options = "<all|{ <'enabled'|'disabled'> => [ '/Partition/object' ]}>"
    validate do |value|
      # Make sure we either have all or a hash.
      fail ArgumentError, "Vlan_and_tunnel_traffic: Valid options: #{options}" unless value =~ /^all$/ || value.is_a?(Hash)
      if value.is_a?(Hash)
        # Make sure the hash contains either enabled or disabled.
        fail ArgumentError, "Vlan_and_tunnel_traffic: Valid options: #{options}" unless value['enabled'] || value['disabled']
        # Count after validation matches the count before so all validated OK.
        if value['enabled']
          fail ArgumentError, "Vlan_and_tunnel_traffic: Valid options: #{options}" unless value['enabled'].select { |obj| obj.match(%r{^/\w+/[\w\.-]+$}) }.count == value['enabled'].count
        elsif value['disabled']
          fail ArgumentError, "Vlan_and_tunnel_traffic: Valid options: #{options}" unless value['disabled'].select { |obj| obj.match(%r{^/\w+/[\w\.-]+$}) }.count == value['disabled'].count
        end
      end
    end
  end

  newproperty(:source_address_translation) do
    #XXX need other options like LSN and none
    options = "<automap|{ 'snat' => '/Partition/pool_name'}|{ 'lsn' => '/Partition/pool_name'}>"
    validate do |value|
      # Make sure we either have automap or a hash.
      fail ArgumentError, "Source_address_translation: Valid options: #{options}; got #{value.inspect}" unless value == "automap" || value.is_a?(Hash)
      if value.is_a?(Hash)
        # Make sure the hash contains 'snat' or 'lsn' as the key.
        if (! value['snat'] and ! value['lsn']) or (value['lsn'] and value['snat'])
          fail ArgumentError, "Source_address_translation: Missing 'snat' or 'lsn' key. Valid options: #{options}; got #{value.inspect}"
        end
        # Make sure the hash value is an object.
        if ! [value['snat'],value['lsn']].select { |x| x.match(%r{^/\w+/[\w\.-]+$}) if x }
          fail ArgumentError, "Source_address_translation: 'snat' or 'lsn' value is not in the correct form. Valid options: #{options}; got #{value.inspect}"
        end
      end
    end
  end

  newproperty(:bandwidth_controller, :parent => Puppet::Property::F5Profile) do
  end

  newproperty(:traffic_class, :array_matching => :all) do
    validate do |value|
      fail ArgumentError, "Traffic_class: Values must take the form /Partition/name; #{value} does not" unless value.match(%r{^/\w+/[\w\.-]+$})
    end
  end

  newproperty(:connection_rate_limit_mode) do
    newvalues(
      :per_virtual_server,
      :per_virtual_server_and_source_address,
      :per_virtual_server_and_destination_address,
      :per_virtual_server_destination_and_source_address,
      :per_source_address,
      :per_destination_address,
      :per_source_and_destination_address,
    )
  end

  # Only required for per_virtual_server and per_destination_address
  newproperty(:connection_rate_limit_source_mask) do
    options = "<0-32>"
    validate do |value|
      fail ArgumentError, "Connection_rate_limit_source_mask: Valid options: #{options}" unless value.to_i.between?(0,32)
    end
    munge do |value|
      Integer(value)
    end
  end

  # Any property with a destination.
  newproperty(:connection_rate_limit_destination_mask) do
    options = "<0-32>"
    validate do |value|
      fail ArgumentError, "Connection_rate_limit_destination_mask: Valid options: #{options}" unless value.to_i.between?(0,32)
    end
    munge do |value|
      Integer(value)
    end
  end

  newproperty(:address_translation, :parent => Puppet::Property::F5truthy) do
    truthy_property(nil)
  end

  newproperty(:port_translation, :parent => Puppet::Property::F5truthy) do
    truthy_property(nil)
  end

  newproperty(:source_port) do
    newvalues(:preserve, :preserve_strict, :change)
  end

  newproperty(:clone_pool_client, :parent => Puppet::Property::F5Profile) do
  end

  newproperty(:clone_pool_server, :parent => Puppet::Property::F5Profile) do
  end

  newproperty(:auto_last_hop) do
    newvalues(:default, :enabled, :disabled)
  end

  newproperty(:last_hop_pool, :parent => Puppet::Property::F5Profile) do
  end

  newproperty(:analytics_profile, :parent => Puppet::Property::F5Profile) do
  end

  newproperty(:nat64, :parent => Puppet::Property::F5truthy) do
    truthy_property(nil)
  end

  newproperty(:request_logging_profile) do
    options = "<Integer>"
    validate do |value|
      fail ArgumentError, "Request_logging_profile: Valid options: #{options}" unless value.match(%r{^/\w+/[\w\.-]+$})
    end
  end

  newproperty(:vs_score) do
    options = "<0-100> - Percentage"
    validate do |value|
      fail ArgumentError, "Vs_score: Valid options: #{options}" unless value.to_i.between?(0,100)
    end
    munge do |value|
      Integer(value)
    end
  end

  newproperty(:rewrite_profile, :parent => Puppet::Property::F5Profile) do
  end

  newproperty(:html_profile, :parent => Puppet::Property::F5Profile) do
  end

  newproperty(:rate_class, :parent => Puppet::Property::F5Profile) do
  end

  newproperty(:oneconnect_profile, :parent => Puppet::Property::F5Profile) do
  end

  newproperty(:ntlm_conn_pool, :parent => Puppet::Property::F5Profile) do
  end

  newproperty(:http_compression_profile, :parent => Puppet::Property::F5Profile) do
  end

  newproperty(:web_acceleration_profile, :parent => Puppet::Property::F5Profile) do
  end

  newproperty(:spdy_profile, :parent => Puppet::Property::F5Profile) do
  end

  newproperty(:irules, :array_matching => :all) do
    options = "</Partition/Object>"
    validate do |value|
      fail ArgumentError, "Irules: Valid options: #{options}" unless value.match(%r{^/\w+/[\w\.-]+$})
    end
  end

  newproperty(:policies, :array_matching => :all) do
    options = "</Partition/Object>"
    validate do |value|
      fail ArgumentError, "Policies: Valid options: #{options}" unless value.match(%r{^/\w+/[\w\.-]+$})
    end
  end

  newproperty(:default_pool, :parent => Puppet::Property::F5Profile) do
  end

  newproperty(:default_persistence_profile, :parent => Puppet::Property::F5Profile) do
  end

  newproperty(:fallback_persistence_profile, :parent => Puppet::Property::F5Profile) do
  end

  validate do
    if self[:provider] == :standard and self[:ensure] == :present and [self[:http_profile], self[:ftp_profile], self[:rtsp_profile], self[:socks_profile], self[:xml_profile]].select{|x| x}.length < 1
      fail ArgumentError, 'ERROR:  One of the `http_profile`, `ftp_profile`, `rtsp_profile`, `socks_profile`, or `xml_profile` attributes must be set for standard virtualservers'
    end

    if [:per_virtual_server_and_source_address, :per_virtual_server_destination_and_source_address, :per_source_address, :per_source_and_destination_address].include?(self[:connection_rate_limit_mode]) and ! self[:connection_rate_limit_source_mask]
      fail ArgumentError, 'ERROR:  Connection_rate_limit_source_mask required.'
    end
    if ! [:per_virtual_server_and_source_address, :per_virtual_server_destination_and_source_address, :per_source_address, :per_source_and_destination_address].include?(self[:connection_rate_limit_mode]) and self[:connection_rate_limit_source_mask]
      fail ArgumentError, 'ERROR:  Connection_rate_limit_source_mask may only be set if connection_rate_limit_mode is set to one of `per_virtual_server_and_source_address`, `per_virtual_server_destination_and_source_address`, `per_source_address`, or `per_source_and_destination_address`'
    end

    if [:per_virtual_server_and_destination_address, :per_virtual_server_destination_and_source_address, :per_destination_address, :per_source_and_destination_address].include?(self[:connection_rate_limit_mode]) and ! self[:connection_rate_limit_destination_mask]
      fail ArgumentError, 'ERROR:  Connection_rate_limit_destination_mask required.'
    end
    if ! [:per_virtual_server_and_destination_address, :per_virtual_server_destination_and_source_address, :per_destination_address, :per_source_and_destination_address].include?(self[:connection_rate_limit_mode]) and self[:connection_rate_limit_destination_mask]
      fail ArgumentError, 'ERROR:  Connection_rate_limit_destination_mask may only be set if connection_rate_limit_mode is set to one of `per_virtual_server_and_destination_address`, `per_virtual_server_destination_and_source_address`, `per_destination_address`, or `per_source_and_destination_address`'
    end
  end
end
