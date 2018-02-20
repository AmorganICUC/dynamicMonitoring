use strict;
use warnings;
use Net::OpenSSH;
use DBI;
#use Term::Menu;

my ($ssh,$dbh,$keypath,$key,$ipaddr);
my @apiaddress;
my @webaddress;
my @serviceaddress;
my @mladdress;
my $API="API";
my $WEB="WEB";
my $ML="ML";
my $SERVICE="SERVICE";
my $user="ubuntu";
$keypath="/ubuntu.pem";

##connect to the production database

my $from_host="icuc-prod-primary.czrsywfk6vbk.us-west-2.rds.amazonaws.com";
my $from_db="social_patrol_primary";
my $from_dsn = "DBI:mysql:database=$from_db;host=$from_host";
my $from_user="sproot";
my $from_pass="SocialPatrol2*16";
$dbh = DBI->connect( $from_dsn, $from_user, $from_pass, {RaiseError => 1, PrintError => 1 }) or die ( "Couldn't connect to database: " . DBI->errstr );


##get ip addresses for api servers
my $APInodes = $dbh->prepare('SELECT node_addr FROM system_nodes WHERE node_type = ?');
$APInodes->execute($API);


	##get ip addresses for web servers
	my $WEBnodes = $dbh->prepare('SELECT node_addr FROM system_nodes WHERE node_type = ?');
	$WEBnodes->execute($WEB);


		##get ip addresses for service servers
		my $SERVICEnodes = $dbh->prepare('SELECT node_addr FROM system_nodes WHERE node_type = ?');
		$SERVICEnodes->execute($SERVICE);

				##get ip addresses for machine learning servers
				my $MLnodes = $dbh->prepare('SELECT node_addr FROM system_nodes WHERE node_type = ?');
				$MLnodes->execute($ML);

##gett ip addresses for api nodes
while(my @api = $APInodes->fetchrow_array())

{
		if ($api[0] =~ /^ip/mi)
                {
                push @apiaddress, $api[0];
                }
		else
		{
		print "BAD ADDRESS!!";
			}

}


##gett ip addresses for web nodes
while(my @web = $WEBnodes->fetchrow_array())

{
		if ($web[0] =~ /^ip/mi)
                {
                push @webaddress, $web[0];
		}
		else 
                { 
                print "BAD ADDRESS!!";
                       	}

}


##gett ip addresses for service nodes
while(my @service = $SERVICEnodes->fetchrow_array())

{
		if ($service[0] =~ /^ip/mi)
                {
                push @serviceaddress, $service[0];
		}
}


##get ip addresses for ML nodes
while(my @ml = $MLnodes->fetchrow_array())

{
		if ($ml[0] =~ /^ip/mi)
		{ 
               push @mladdress, $ml[0];
		}
}
	system qq{mv /root/.ssh/known_hosts /root/.ssh/known };
	foreach(@apiaddress)
	{
	system qq{ ssh-keygen -R $_ };
	system qq{ ssh-keyscan -H $_ >> ~/.ssh/known_hosts };
    	$ssh = Net::OpenSSH->new($_, user => $user, key_path =>$keypath );
	ubuntu();
	}

			foreach my $line (@mladdress)
			{
			system qq{ ssh-keygen -R "$line" };
			system qq{ ssh-keyscan -H "$line" >> ~/.ssh/known_hosts 2>/dev/null};
			$ssh = Net::OpenSSH->new("$line", user => $user, key_path =>$keypath );
			ubuntu();
			}


		foreach(@webaddress)
		{
		system qq{ ssh-keygen -R $_ };
		system qq{ ssh-keyscan -H $_ >> ~/.ssh/known_hosts };
    		$ssh = Net::OpenSSH->new($_, user => $user, key_path =>$keypath );
		ubuntu();
		}

			
			foreach(@serviceaddress)
			{
			system qq{ ssh-keygen -R $_ };
			system qq{ ssh-keyscan -H $_ >> ~/.ssh/known_hosts };
		    	$ssh = Net::OpenSSH->new($_, user => $user, key_path =>$keypath );
			ubuntuservice();
			}

sub ubuntu
{
 $ssh->system({tty => 1}, qq{ if [ ! -e "/etc/zabbix/zabbix_agentd.conf" ]; then  wget http://repo.zabbix.com/zabbix/3.0/ubuntu/pool/main/z/zabbix-release/zabbix-release_3.0-1+trusty_all.deb; else echo "Nothing to do! "; exit;fi});
 $ssh->system({tty => 1}, qq{ if [ ! -e "/etc/zabbix/zabbix_agentd.conf" ]; then sudo dpkg -i zabbix-release_3.0-1+trusty_all.deb;  else echo "Nothing to do! "; exit;fi});
 $ssh->system({tty => 1}, qq{ if [ ! -e "/etc/zabbix/zabbix_agentd.conf" ]; then sudo apt-get install -y  zabbix-agent ; else echo "Nothing to do! "; exit;fi});
 $ssh->system({tty => 1}, qq{ sudo  perl -p -i -e "s/Server=127.0.0.1/Server=10.1.80.15/g" /etc/zabbix/zabbix_agentd.conf});
 $ssh->system({tty => 1}, qq{ sudo  perl -p -i -e "s/ServerActive=127.0.0.1/ServerActive=10.1.80.15/g" /etc/zabbix/zabbix_agentd.conf}); 
 $ssh->system({tty => 1}, qq{ sudo  perl -p -i -e "s/Hostname=Zabbix server/#Hostname=Zabbix server/g" /etc/zabbix/zabbix_agentd.conf});
 $ssh->system({tty => 1}, qq{ sudo  perl -p -i -e "s/# HostnameItem=system.hostname/HostnameItem=system.hostname/g" /etc/zabbix/zabbix_agentd.conf});
 $ssh->system({tty => 1}, qq{ sudo  perl -p -i -e "s/# HostMetadata=/HostMetadata=social/g" /etc/zabbix/zabbix_agentd.conf && sudo systemctl restart zabbix-agent.service});
}

sub ubuntuservice
{
 $ssh->system({tty => 1}, qq{ if [ ! -e "/etc/zabbix/zabbix_agentd.conf" ]; then  wget http://repo.zabbix.com/zabbix/3.0/ubuntu/pool/main/z/zabbix-release/zabbix-release_3.0-1+trusty_all.deb; else echo "Nothing to do! "; exit;fi});
 $ssh->system({tty => 1}, qq{ if [ ! -e "/etc/zabbix/zabbix_agentd.conf" ]; then sudo dpkg -i zabbix-release_3.0-1+trusty_all.deb;  else echo "Nothing to do! "; exit;fi});
 $ssh->system({tty => 1}, qq{ if [ ! -e "/etc/zabbix/zabbix_agentd.conf" ]; then sudo apt-get install -y  zabbix-agent ; else echo "Nothing to do! "; exit;fi});
 $ssh->system({tty => 1}, qq{ sudo  perl -p -i -e "s/Server=127.0.0.1/Server=10.1.80.15/g" /etc/zabbix/zabbix_agentd.conf});
 $ssh->system({tty => 1}, qq{ sudo  perl -p -i -e "s/ServerActive=127.0.0.1/ServerActive=10.1.80.15/g" /etc/zabbix/zabbix_agentd.conf}); 
 $ssh->system({tty => 1}, qq{ sudo  perl -p -i -e "s/Hostname=Zabbix server/#Hostname=Zabbix server/g" /etc/zabbix/zabbix_agentd.conf});
 $ssh->system({tty => 1}, qq{ sudo  perl -p -i -e "s/# HostnameItem=system.hostname/HostnameItem=system.hostname/g" /etc/zabbix/zabbix_agentd.conf});
 $ssh->system({tty => 1}, qq{ sudo  perl -p -i -e "s/# HostMetadata=/HostMetadata=service/g" /etc/zabbix/zabbix_agentd.conf && sudo systemctl restart zabbix-agent.service});
}

