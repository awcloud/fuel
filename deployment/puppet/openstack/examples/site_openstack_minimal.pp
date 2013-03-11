#
# Parameter values in this file should be changed, taking into consideration your
# networking setup and desired OpenStack settings.
# 
# Please consult with the latest Fuel User Guide before making edits.
#

# This is a name of public interface. Public network provides address space for Floating IPs, as well as public IP accessibility to the API endpoints.
$public_interface    = 'eth1'

# This is a name of internal interface. It will be hooked to the management network, where data exchange between components of the OpenStack cluster will happen.
$internal_interface  = 'eth0'

# This is a name of private interface. All traffic within OpenStack tenants' networks will go through this interface.
$private_interface   = 'eth2'

# Public and Internal VIPs. These virtual addresses are required by HA topology and will be managed by keepalived.
$internal_virtual_ip = '10.0.125.253'
$public_virtual_ip   = '10.0.74.253'

$nodes_harr = [
  {
    'name' => 'fuel-cobbler',
    'role' => 'cobbler',
    'internal_address' => '10.0.0.102',
    'public_address'   => '10.0.204.102',
  },
  {
    'name' => 'fuel-controller-01',
    'role' => 'controller',
    'internal_address' => '10.0.0.103',
    'public_address'   => '10.0.204.103',
  },
  {
    'name' => 'fuel-controller-02',
    'role' => 'controller',
    'internal_address' => '10.0.0.104',
    'public_address'   => '10.0.204.104',
  },
  {
    'name' => 'fuel-controller-03',
    'role' => 'controller',
    'internal_address' => '10.0.0.105',
    'public_address'   => '10.0.204.105',
  },
  {
    'name' => 'fuel-compute-01',
    'role' => 'compute',
    'internal_address' => '10.0.0.106',
    'public_address'   => '10.0.204.106',
  },
  {
    'name' => 'fuel-compute-02',
    'role' => 'compute',
    'internal_address' => '10.0.0.107',
    'public_address'   => '10.0.204.107',
  },
]
$nodes = $nodes_harr
$default_gateway = '10.0.204.1'
$dns_nameservers = ['10.0.204.1','8.8.8.8']
$node = filter_nodes($nodes,'name',$::hostname)
$internal_address = $node[0]['internal_address']
$public_address = $node[0]['public_address']
$internal_netmask = '255.255.255.0'
$public_netmask = '255.255.255.0'
$controller_internal_addresses = nodes_to_hash(filter_nodes($nodes,'role','controller'),'name','internal_address')
$controller_public_addresses = nodes_to_hash(filter_nodes($nodes,'role','controller'),'name','public_address')
$controller_hostnames = keys($controller_internal_addresses)

if $::hostname == 'fuel-controller-01' {
  $primary_controller = true
} else {
  $primary_controller = false
}

# Specify pools for Floating IP and Fixed IP.
# Floating IP addresses are used for communication of VM instances with the outside world (e.g. Internet).
# Fixed IP addresses are typically used for communication between VM instances.
$create_networks = true
$floating_range  = '10.0.74.128/28'
$fixed_range     = '10.0.161.128/28'
$num_networks    = 1
$network_size    = 15
$vlan_start      = 300

# If $external_ipinfo option is not defined the addresses will be calculated automatically from $floating_range:
# the first address will be defined as an external default router
# second address will be set to an uplink bridge interface (br-ex)
# remaining addresses are utilized for ip floating pool
$external_ipinfo = {}
## $external_ipinfo = {
##   'public_net_router' => '10.0.74.129',
##   'ext_bridge'        => '10.0.74.130',
##   'pool_start'        => '10.0.74.131',
##   'pool_end'          => '10.0.74.142',
## }

# For VLAN networks: valid VLAN VIDs are 1 through 4094.
# For GRE networks: Valid tunnel IDs are any 32 bit unsigned integer.
$segment_range   = '900:999'

# it should be set to an integer value (valid range is 0..254)
$deployment_id = '89'

# Here you can enable or disable different services, based on the chosen deployment topology.
$multi_host              = true
$cinder                  = true
$cinder_on_computes      = false
$manage_volumes          = true
$quantum                 = true
$auto_assign_floating_ip = false
$glance_backend          = 'file'



# Set nagios master fqdn
$nagios_master        = 'nagios-server.your-domain-name.com'
## proj_name  name of environment nagios configuration
$proj_name = 'test'

# Set up OpenStack network manager
$network_manager      = 'nova.network.manager.FlatDHCPManager'

# Setup network interface, which Cinder used for export iSCSI targets.
$cinder_iscsi_bind_iface = $internal_interface

# Here you can add physical volumes to cinder. Please replace values with the actual names of devices.
$nv_physical_volume      = ['/dev/sdz', '/dev/sdy', '/dev/sdx']

# Specify credentials for different services
$mysql_root_password     = 'nova'
$admin_email             = 'openstack@openstack.org'
$admin_password          = 'nova'

$keystone_db_password    = 'nova'
$keystone_admin_token    = 'nova'

$glance_db_password      = 'nova'
$glance_user_password    = 'nova'

$nova_db_password        = 'nova'
$nova_user_password      = 'nova'

$rabbit_password         = 'nova'
$rabbit_user             = 'nova'

$quantum_user_password   = 'quantum_pass'
$quantum_db_password     = 'quantum_pass'
$quantum_db_user         = 'quantum'
$quantum_db_dbname       = 'quantum'
$tenant_network_type     = 'gre'

$quantum_host            = $internal_virtual_ip
stage {'netconfig':
      before  => Stage['main'],
}
class {'l23network': stage=> 'netconfig'}
$quantum_gre_bind_addr = $internal_address

$use_syslog = false

if $use_syslog {
class { "::rsyslog::client":
    log_local => true,
    log_auth_local => true,
    server => '127.0.0.1',
    port => '514'
 }
}

  case $::osfamily {
    "Debian":  {
       $rabbitmq_version_string = '2.8.7-1'
    }
    "RedHat": {
       $rabbitmq_version_string = '2.8.7-2.el6'
    }
  }
# OpenStack packages to be installed
$openstack_version = {
  'keystone'         => 'latest',
  'glance'           => 'latest',
  'horizon'          => 'latest',
  'nova'             => 'latest',
  'novncproxy'       => 'latest',
  'cinder'           => 'latest',
  'rabbitmq_version' => $rabbitmq_version_string,
}

$mirror_type = 'default'
$enable_test_repo = false

$quantum_sql_connection  = "mysql://${quantum_db_user}:${quantum_db_password}@${quantum_host}/${quantum_db_dbname}"

$verbose = true
Exec { logoutput => true }

# Globally apply an environment-based tag to all resources on each node.
tag("${::deployment_id}::${::environment}")

stage { 'openstack-custom-repo': before => Stage['netconfig'] }
class { 'openstack::mirantis_repos':
  stage => 'openstack-custom-repo',
  type=>$mirror_type,
  enable_test_repo=>$enable_test_repo,
}
if $::operatingsystem == 'Ubuntu'
{
  class { 'openstack::apparmor::disable': stage => 'openstack-custom-repo' }
}


#Rate Limits for cinder and Nova
#Cinder and Nova can rate-limit your requests to API services
#These limits can be small for your installation or usage scenario
#Change the following variables if you want. The unit is requests per minute.

$nova_rate_limits = { 'POST' => 1000,
 'POST_SERVERS' => 1000,
 'PUT' => 1000, 'GET' => 1000,
 'DELETE' => 1000 }
 

$cinder_rate_limits = { 'POST' => 1000,
 'POST_SERVERS' => 1000,
 'PUT' => 1000, 'GET' => 1000,
 'DELETE' => 1000 }

sysctl::value { 'net.ipv4.conf.all.rp_filter': value => '0' }

# Dashboard(horizon) https/ssl mode
#     false: normal mode with no encryption
# 'default': uses keys supplied with the ssl module package
#   'exist': assumes that the keys (domain name based certificate) are provisioned in advance
#  'custom': require fileserver static mount point [ssl_certs] and hostname based certificate existence
$horizon_use_ssl = false


# Definition of OpenStack controller nodes.
node /fuel-controller-[\d+]/ {

  class {'nagios':
    proj_name       => $proj_name,
    services        => [
      'host-alive','nova-novncproxy','keystone', 'nova-scheduler',
      'nova-consoleauth', 'nova-cert', 'haproxy', 'nova-api', 'glance-api',
      'glance-registry','horizon', 'rabbitmq', 'mysql'
    ],
    whitelist       => ['127.0.0.1', $nagios_master],
    hostgroup       => 'controller',
  }
    class { 'openstack::controller_ha':
      controller_public_addresses => $controller_public_addresses,
      public_interface        => $public_interface,
      internal_interface      => $internal_interface,
      private_interface       => $private_interface,
      internal_virtual_ip     => $internal_virtual_ip,
      public_virtual_ip       => $public_virtual_ip,
      controller_internal_addresses => $controller_internal_addresses,
      internal_address        => $internal_address,
      primary_controller      => $primary_controller,
      floating_range          => $floating_range,
      fixed_range             => $fixed_range,
      multi_host              => $multi_host,
      network_manager         => $network_manager,
      num_networks            => $num_networks,
      network_size            => $network_size,
      network_config          => { 'vlan_start' => $vlan_start },
      verbose                 => $verbose,
      auto_assign_floating_ip => $auto_assign_floating_ip,
      mysql_root_password     => $mysql_root_password,
      admin_email             => $admin_email,
      admin_password          => $admin_password,
      keystone_db_password    => $keystone_db_password,
      keystone_admin_token    => $keystone_admin_token,
      glance_db_password      => $glance_db_password,
      glance_user_password    => $glance_user_password,
      nova_db_password        => $nova_db_password,
      nova_user_password      => $nova_user_password,
      rabbit_password         => $rabbit_password,
      rabbit_user             => $rabbit_user,
      rabbit_nodes            => $controller_hostnames,
      memcached_servers       => $controller_hostnames,
      export_resources        => false,
      glance_backend          => $glance_backend,
      quantum                 => $quantum,
      quantum_user_password   => $quantum_user_password,
      quantum_db_password     => $quantum_db_password,
      quantum_db_user         => $quantum_db_user,
      quantum_db_dbname       => $quantum_db_dbname,
      tenant_network_type     => $tenant_network_type,
      segment_range           => $segment_range,
      cinder                  => $cinder,
      cinder_iscsi_bind_iface => $cinder_iscsi_bind_iface,
      galera_nodes            => $controller_hostnames,
      manage_volumes          => $manage_volumes,
      nv_physical_volume      => $nv_physical_volume,
      use_syslog              => $use_syslog,
      horizon_use_ssl         => $horizon_use_ssl,
      nova_rate_limits => $nova_rate_limits,
      cinder_rate_limits => $cinder_rate_limits
    }
}

# Definition of OpenStack compute nodes.
node /fuel-compute-[\d+]/ {

  class {'nagios':
    proj_name       => $proj_name,
    services        => [
      'host-alive', 'nova-compute','nova-network','libvirt'
    ],
    whitelist       => ['127.0.0.1', $nagios_master],
    hostgroup       => 'compute',
  }

    class { 'openstack::compute':
      public_interface   => $public_interface,
      private_interface  => $private_interface,
      internal_address   => $internal_address,
      libvirt_type       => 'qemu',
      fixed_range        => $fixed_range,
      network_manager    => $network_manager,
      network_config     => { 'vlan_start' => $vlan_start },
      multi_host         => $multi_host,
      sql_connection     => "mysql://nova:${nova_db_password}@${internal_virtual_ip}/nova",
      rabbit_nodes       => $controller_hostnames,
      rabbit_password    => $rabbit_password,
      rabbit_user        => $rabbit_user,
      rabbit_ha_virtual_ip   => $internal_virtual_ip,
      glance_api_servers => "${internal_virtual_ip}:9292",
      vncproxy_host      => $public_virtual_ip,
      verbose            => $verbose,
      vnc_enabled        => true,
      manage_volumes     => $manage_volumes,
      nv_physical_volume => $nv_physical_volume,
      nova_user_password => $nova_user_password,
      cache_server_ip    => $controller_hostnames,
      service_endpoint   => $internal_virtual_ip,
      quantum            => $quantum,
      quantum_host       => $quantum_host,
      quantum_sql_connection => $quantum_sql_connection,
      quantum_user_password  => $quantum_user_password,
      tenant_network_type    => $tenant_network_type,
      segment_range      => $segment_range,
      cinder             => $cinder_on_computes,
      cinder_iscsi_bind_iface => $cinder_iscsi_bind_iface,
      db_host            => $internal_virtual_ip,
      ssh_private_key    => 'puppet:///ssh_keys/openstack',
      ssh_public_key     => 'puppet:///ssh_keys/openstack.pub',
      use_syslog         => $use_syslog,
      nova_rate_limits   => $nova_rate_limits,
      cinder_rate_limits => $cinder_rate_limits

    }
}

# Definition of OpenStack Quantum node. 
node /fuel-quantum/ {
    class { 'openstack::quantum_router': 
      db_host               => $internal_virtual_ip,
      service_endpoint      => $internal_virtual_ip,
      auth_host             => $internal_virtual_ip,
      internal_address      => $internal_address,
      public_interface      => $public_interface,
      private_interface     => $private_interface,
      floating_range        => $floating_range,
      fixed_range           => $fixed_range,
      create_networks       => $create_networks,
      verbose               => $verbose,
      rabbit_password       => $rabbit_password,
      rabbit_user           => $rabbit_user,
      rabbit_nodes          => $controller_hostnames,
      rabbit_ha_virtual_ip   => $internal_virtual_ip,
      quantum               => $quantum,
      quantum_user_password => $quantum_user_password,
      quantum_db_password   => $quantum_db_password,
      quantum_db_user       => $quantum_db_user,
      quantum_db_dbname     => $quantum_db_dbname,
      tenant_network_type   => $tenant_network_type,
      external_ipinfo       => $external_ipinfo,
      segment_range         => $segment_range,
      api_bind_address      => $internal_address,
      use_syslog              => $use_syslog,
    }

    class { 'openstack::auth_file':
      admin_password       => $admin_password,
      keystone_admin_token => $keystone_admin_token,
      controller_node      => $internal_virtual_ip,
      before               => Class['openstack::quantum_router'],
    }
}

