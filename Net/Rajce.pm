#!/usr/bin/perl

package Rajce;

use strict;
use warnings;

use WWW::Mechanize;
use XML::Simple;
use Digest::MD5 qw(md5_hex);

use vars qw($VERSION @ISA @EXPORT @EXPORT_OK);

require Exporter;


@ISA = qw(Exporter AutoLoader);
@EXPORT = qw();
$VERSION = '0.01';

=head1 NAME

Rajce - Perl module for rajce.net api

=head1 SYNOPSIS

	use Net::Rajce;
	my $rajce = Rajce->new;
	$rajce->login($mail,$password);
						  

=head1 DESCRIPTION

This module is interface to rajce.net web api.  

=head2 Methods

=over
=cut


sub new {
=item * $rajce->new();
Create new object instance.
=cut
	my $class = shift;
	my $self  = {};
	$self->{API} = 'http://www.rajce.idnes.cz/liveAPI/index.php';
	$self->{XML} = '<?xml version="1.0" encoding="utf-8"?>';
	$self->{BOT} = WWW::Mechanize->new(autocheck => 1, agent => 'github.com/petrkle/rajce');
	$self->{BOT}->add_header('Accept-Encoding'=>'text/html');
	$self->{BOT}->add_header('Accept-Charset'=>'utf-8');
	$self->{BOT}->add_header('Accept-Language'=>'cs');
	$self->{BOT}->cookie_jar(HTTP::Cookies->new());
	bless($self, $class);
	return $self;
}

sub login {
=item * $rajce->login($mail,$password);
Login to api.
=cut
	my ($self,$mail,$password) = @_;

	my $login = {'request'=>{
			'command'=>['login'],
			'parameters'=>{
				'clientID'=>['Rajce.pm'],
				'currentVersion'=>[$VERSION],
				'lang'=>['cs_CZ'],
				'login'=>[$mail],
				'password'=>[md5_hex($password)]
			},
		}
	};
	my $response = $self->{BOT}->post($self->{API}, {'data' => XMLout($login, KeepRoot => 1, XMLDecl => $self->{XML})});
	my $login_resp = XMLin($response->content());
	$self->{sessionToken}=$login_resp->{sessionToken};
	return $login_resp;
}

sub list {
=item * $rajce->list();
Get list of albums;
=cut
	my ($self,$mail,$password) = @_;

	my $listalbums = {'request'=>{
			'command'=>['getAlbumList'],
			'parameters'=>{
				'token'=>[$self->{sessionToken}]
			},
		}
	};

	my $albums = $self->{BOT}->post($self->{API}, {'data' => XMLout($listalbums, KeepRoot => 1, XMLDecl => $self->{XML})});

return XMLin($albums->content());
}

1;
__END__

=back

=head1 AUTHOR

Petr Kletecka (petr@kle.cz)

=head1 COPYRIGHT

Copyright 2011 Petr Kletecka.  All rights reserved.

This library is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=head1 SEE ALSO

www.rajce.net

=cut
