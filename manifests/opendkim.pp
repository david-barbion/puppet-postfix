class postfix::opendkim(
  $opendkim_package                 = $::postfix::server::opendkim_package,
  $opendkim_config_file             = $::postfix::server::opendkim_config_file,
  $opendkim_config_dir              = $::postfix::server::opendkim_config_dir,
  $opendkim_config_template         = $::postfix::server::opendkim_config_template,
  $opendkim_config_canonicalization = $::postfix::server::opendkim_config_canonicalization,
  $opendkim_host                    = $::postfix::server::opendkim_host,
  $opendkim_port                    = $::postfix::server::opendkim_port,
  $opendkim_service                 = $::postfix::server::opendkim_service,
  $opendkim_trusted_hosts           = $::postfix::server::opendkim_trusted_hosts,
  $mydomain                         = $::postfix::server::mydomain,
) {

  include '::postfix::params'

  package { $opendkim_package:
    ensure => present,
  }->

  file { [$opendkim_config_dir,
          "${opendkim_config_dir}/keys/",
          "${opendkim_config_dir}/keys/${mydomain}"]:
    ensure => directory,
    owner  => 'opendkim',
    group  => 'opendkim',
    mode   => '0750',
    before => Service[$opendkim_service],
  }->
  file { "${opendkim_config_dir}/TrustedHosts":
    content => template('postfix/opendkim-trusted.erb'),
    owner   => 'opendkim',
    group   => 'opendkim',
    mode    => '0640',
  }->
  file { "${opendkim_config_dir}/KeyTable":
    content => template('postfix/opendkim-keytable.erb'),
    owner   => 'opendkim',
    group   => 'opendkim',
    mode    => '0640',
  }->
  file { "${opendkim_config_dir}/SigningTable":
    content => template('postfix/opendkim-signingtable.erb'),
    owner   => 'opendkim',
    group   => 'opendkim',
    mode    => '0640',
  }->
  exec { "opendkim-genkey -s mail -d ${mydomain}":
    creates => "${opendkim_config_dir}/keys/${mydomain}/mail.private",
    cwd     => "${opendkim_config_dir}/keys/${mydomain}",
  }->
  file { "${opendkim_config_dir}/keys/${mydomain}/mail.private":
    owner => 'opendkim',
    group => 'opendkim',
    mode  => '0640',
  }->
  file { "${opendkim_config_dir}/keys/${mydomain}/mail.txt":
    owner => 'opendkim',
    group => 'opendkim',
    mode  => '0644',
  }->
  file { $opendkim_config_file:
    content => template($opendkim_config_template),
    owner   => 'opendkim',
    group   => 'opendkim',
    mode    => '0640',
  }

  service { $opendkim_service:
    ensure    => running,
    enable    => true,
    subscribe => [File[$opendkim_config_file],
                  File["${opendkim_config_dir}/TrustedHosts"],
                  File["${opendkim_config_dir}/KeyTable"],
                  File["${opendkim_config_dir}/keys/${mydomain}/mail.private"],
                  File["${opendkim_config_dir}/keys/${mydomain}/mail.txt"]],
  }

}
