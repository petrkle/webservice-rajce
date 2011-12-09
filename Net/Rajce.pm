#!/usr/bin/perl

package Rajce;

use strict;
use warnings;

use WWW::Mechanize;
use XML::Simple;
use Digest::MD5 qw(md5_hex);
use File::Basename;
use File::Temp qw(tempdir);
use File::Copy;
use Image::Size;

use vars qw($VERSION @ISA @EXPORT @EXPORT_OK);

require Exporter;


@ISA = qw(Exporter AutoLoader);
@EXPORT = qw();
$VERSION = '0.01';

=head1 NAME

Rajce - Perl module for rajce.net web API.

=head1 SYNOPSIS

	use Net::Rajce;
	my $rajce = new Rajce;
	$rajce->login($mail,$password);
						  

=head1 DESCRIPTION

This module is interface to rajce.net web API.  

=head2 Methods

=over
=cut


sub new {
=item * my $rajce = new Rajce;
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
Login to API.
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
=item * $rajce->list($userid);
Get list of albums.
=cut
	my ($self,$userid) = @_;

	my $listalbums = {'request'=>{
			'command'=>['getAlbumList'],
			'parameters'=>{
				'token'=>[$self->{sessionToken}],
				'userID'=>[$userid],
			},
		}
	};

	my $albums = $self->{BOT}->post($self->{API}, {'data' => XMLout($listalbums, KeepRoot => 1, XMLDecl => $self->{XML})});

return XMLin($albums->content());
}

sub search_users {
=item * $rajce->search_users($query,$skip,$limit);
Get list of users.
FIXME - not working
=cut
	my ($self,$query,$skip,$limit) = @_;

	my $users = {'request'=>{
			'command'=>['searchUsers'],
			'parameters'=>{
				'token'=>[$self->{sessionToken}],
				'query'=>[$query],
				'skip'=>[$skip],
				'limit'=>[$limit],
				'columns'=>{
					'column'=>['fullName', 'albumCount', 'viewCount']
				}
			},
		}
	};

	my $result = $self->{BOT}->post($self->{API}, {'data' => XMLout($users, KeepRoot => 1, XMLDecl => $self->{XML})});

return XMLin($result->content());
}

sub search_albums {
=item * $rajce->search_albums($query,$skip,$limit);
Get list of users.
FIXME - not working
=cut
	my ($self,$query,$skip,$limit) = @_;

	my $albums = {'request'=>{
			'command'=>['searchAlbums'],
			'parameters'=>{
				'token'=>[$self->{sessionToken}],
				'query'=>[$query],
				'skip'=>[$skip],
				'limit'=>[$limit],
				'columns'=>{
					'column'=>['description','shortenedDescription','viewCount','mediaCount','createDate']
				}
			},
		}
	};

	print Dumper(XMLout($albums, KeepRoot => 1, XMLDecl => $self->{XML}));
	my $result = $self->{BOT}->post($self->{API}, {'data' => XMLout($albums, KeepRoot => 1, XMLDecl => $self->{XML})});

return XMLin($result->content());
}


sub reg_url {
=item * $rajce->reg_url();
Get URL where is form for creating new account on rajce.net.
=cut
	my ($self) = @_;

	my $reg = {'request'=>{
			'command'=>['getRegisterUrl']
		}
	};

	my $regurl = $self->{BOT}->post($self->{API}, {'data' => XMLout($reg, KeepRoot => 1, XMLDecl => $self->{XML})});
	my $reg_form = XMLin($regurl->content());

return $reg_form->{url};
}

sub create_album {
=item * $rajce->create_album($title,$desc);
Create new album.
=cut
	my ($self,$title,$desc) = @_;

	my $create = {'request'=>{
			'command'=>['createAlbum'],
			'parameters'=>{
				'token'=>[$self->{sessionToken}],
				'albumName'=>[$title],
				'albumDescription'=>[$desc],
				'albumVisible'=>[1],
			},
		}
	};

	my $album = $self->{BOT}->post($self->{API}, {'data' => XMLout($create, KeepRoot => 1, XMLDecl => $self->{XML})});

return XMLin($album->content());
}

sub open_album {
=item * $rajce->open_album($album);
Open album for adding pictures.
=cut
	my ($self,$album) = @_;

	my $create = {'request'=>{
			'command'=>['openAlbum'],
			'parameters'=>{
				'token'=>[$self->{sessionToken}],
				'albumID'=>[$album->{albumID}],
			},
		}
	};

	my $open = $self->{BOT}->post($self->{API}, {'data' => XMLout($create, KeepRoot => 1, XMLDecl => $self->{XML})});

return XMLin($open->content());
}

sub close_album {
=item * $rajce->close_album($album);
Close album after adding pictures.
=cut
	my ($self,$album) = @_;

	my $create = {'request'=>{
			'command'=>['closeAlbum'],
			'parameters'=>{
				'token'=>[$self->{sessionToken}],
				'albumToken'=>[$album->{albumToken}],
			},
		}
	};

	my $open = $self->{BOT}->post($self->{API}, {'data' => XMLout($create, KeepRoot => 1, XMLDecl => $self->{XML})});

return XMLin($open->content());
}

sub add_photo {
=item * $rajce->add_photo($filename,$album);
Add photo into gallery.
=cut
	my ($self,$filename,$album) = @_;
	my $tempdir = tempdir('rajce.tempXXXXX', CLEANUP => 1);

	my $file = basename($filename);
	copy("$filename","$tempdir/$file");
	system("convert -auto-orient -strip -resize 800x600\\> \"$tempdir/$file\" \"$tempdir/$file\"\n");
	my ($width, $height) = imgsize("$tempdir/$file");
	system("convert -auto-orient -strip -resize 100x100^ -gravity center -extent 100x100 \"$tempdir/$file\" \"$tempdir/thumb.$file\"\n");

	my $newpicture = {'request'=>{
			'command'=>['addPhoto'],
			'parameters'=>{
				'token'=>[$self->{sessionToken}],
				'albumToken'=>[$album->{albumToken}],
				'width'=>[$width],
				'height'=>[$height],
			},
		}
	};

	my $obrazek = $self->{BOT}->post($self->{API}, {'data' => XMLout($newpicture, KeepRoot => 1, XMLDecl => $self->{XML}),'thumb' => ["$tempdir/thumb.$file"], 'photo' => ["$tempdir/$file"]}, Content_Type => 'form-data');

return XMLin($obrazek->content());
}

sub get_albumurl {
=item * $rajce->get_albumurl($album);
Get URL of album.
=cut
	my ($self,$album) = @_;

	my $url = {'request'=>{
			'command'=>['getAlbumUrl'],
			'parameters'=>{
				'token'=>[$self->{sessionToken}],
				'albumToken'=>[$album->{albumToken}],
			}
		}
	};

	my $alb = $self->{BOT}->post($self->{API}, {'data' => XMLout($url, KeepRoot => 1, XMLDecl => $self->{XML})});
	my $response = XMLin($alb->content());

return $response->{url};
}

1;
__END__

=back

=head1 AUTHOR

Petr Kletecka (petr@kle.cz)

=head1 COPYRIGHT

Copyright 2011 Petr Kletecka. All rights reserved.

This library is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=head1 SEE ALSO

www.rajce.net
http://goo.gl/34P9B - API doc

=cut
