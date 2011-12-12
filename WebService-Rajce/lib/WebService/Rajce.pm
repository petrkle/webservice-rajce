package WebService::Rajce;

use 5.006;
use strict;
use warnings;

use WWW::Mechanize;
use XML::Simple;
use Digest::MD5 qw(md5_hex);
use Encode;
use Image::Magick;

use vars qw($VERSION @ISA @EXPORT @EXPORT_OK);

require Exporter;


our @ISA = qw(Exporter AutoLoader);
our @EXPORT = qw();
our $VERSION = '0.01';


=head1 NAME

Rajce - Perl module for rajce.net web API.

=head1 SYNOPSIS

	use WebService::Rajce;
	my $rajce = new WebService::Rajce;
	$rajce->login($mail,$password);
	my $album = $rajce->create_album('Title','Description');
	$rajce->add_photo('/path/to/file.jpg',$album)
						  

=head1 DESCRIPTION

This module is interface to rajce.net web API.  

=head2 Methods

=over
=cut


=item * my $rajce = new WebService::Rajce;
Create new object instance.
=cut
sub new {
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

=item * $rajce->login($mail,$password);
Login to API.
=cut
sub login {
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
	my $response = $self->{BOT}->post($self->{API},
		{'data' => XMLout($login, KeepRoot => 1, XMLDecl => $self->{XML})});
	my $login_resp = XMLin($response->content());
	$self->{sessionToken}=$login_resp->{sessionToken};
	$self->{maxWidth}=$login_resp->{maxWidth};
	$self->{maxHeight}=$login_resp->{maxHeight};
	$self->{nick}=$login_resp->{nick};
	return $login_resp;
}

=item * $rajce->list($userid);
Get list of albums.
=cut
sub list {
	my ($self,$userid) = @_;

	my $listalbums = {'request'=>{
			'command'=>['getAlbumList'],
			'parameters'=>{
				'token'=>[$self->{sessionToken}],
				'userID'=>[$userid],
			},
		}
	};

	my $albums = $self->{BOT}->post($self->{API},
	 {'data' => XMLout($listalbums, KeepRoot => 1, XMLDecl => $self->{XML})});

return XMLin($albums->content());
}

=item * $rajce->photo_list($albumid);
Get list of images in album.
=cut
sub photo_list {
	my ($self,$albumid) = @_;

	my $photolist = {'request'=>{
			'command'=>['getPhotoList'],
			'parameters'=>{
				'token'=>[$self->{sessionToken}],
				'albumID'=>[$albumid],
				'columns'=>{
					'column'=>[
						'date',
						'name',
						'description',
						'url',
						'thumbUrl',
						'thumbUrlBest',
						'urlBase']
				}
			}
		}
	};

	my $photos = $self->{BOT}->post($self->{API},
		{'data' => XMLout($photolist, KeepRoot => 1, XMLDecl => $self->{XML})});

return XMLin($photos->content());
}

=item * $rajce->search_users($query,$skip,$limit);
Get list of users.
FIXME - not working
=cut
sub search_users {
	my ($self,$query,$skip,$limit) = @_;

	my $users = {'request'=>{
			'command'=>['searchUsers'],
			'parameters'=>{
				'token'=>[$self->{sessionToken}],
				'query'=>[$query],
				'skip'=>[$skip],
				'limit'=>[$limit],
				'columns'=>{
					'column'=>[
					'fullName',
					'albumCount',
					'viewCount']
				}
			}
		}
	};

	my $result = $self->{BOT}->post($self->{API},
		{'data' => XMLout($users, KeepRoot => 1, XMLDecl => $self->{XML})});

return XMLin($result->content());
}

=item * $rajce->get_url($target);
Get some URL from rajce.net
$target = 'user-profile' | 'email-notifications' | 'service-notifications' ;
=cut
sub get_url {
	my ($self,$target) = @_;

	my $geturl = {'request'=>{
			'command'=>['getUrl'],
			'parameters'=>{
				'token'=>[$self->{sessionToken}],
				'target'=>[$target],
			}
		}
	};

	my $result = $self->{BOT}->post($self->{API},
		{'data' => XMLout($geturl, KeepRoot => 1, XMLDecl => $self->{XML})});
	my $response = XMLin($result->content());

return $response->{url};
}


=item * $rajce->search_albums($query,$skip,$limit);
Get list of users.
FIXME - not working
=cut
sub search_albums {
	my ($self,$query,$skip,$limit) = @_;

	my $albums = {'request'=>{
			'command'=>['searchAlbums'],
			'parameters'=>{
				'token'=>[$self->{sessionToken}],
				'query'=>[$query],
				'skip'=>[$skip],
				'limit'=>[$limit],
				'columns'=>{
					'column'=>[
						'description',
						'shortenedDescription',
						'viewCount',
						'mediaCount',
						'createDate']
				}
			},
		}
	};

	print Dumper(XMLout($albums, KeepRoot => 1, XMLDecl => $self->{XML}));
	my $result = $self->{BOT}->post($self->{API},
		{'data' => XMLout($albums, KeepRoot => 1, XMLDecl => $self->{XML})});

return XMLin($result->content());
}


=item * $rajce->reg_url();
Get URL where is form for creating new account on rajce.net.
=cut
sub reg_url {
	my ($self) = @_;

	my $reg = {'request'=>{
			'command'=>['getRegisterUrl']
		}
	};

	my $regurl = $self->{BOT}->post($self->{API},
		{'data' => XMLout($reg, KeepRoot => 1, XMLDecl => $self->{XML})});
	my $reg_form = XMLin($regurl->content());

return $reg_form->{url};
}

=item * $rajce->recover_url();
Get URL where is form for recover forget password.
=cut
sub recover_url {
	my ($self) = @_;

	my $pass = {'request'=>{
			'command'=>['getRecoverPasswordUrl']
		}
	};

	my $url = $self->{BOT}->post($self->{API},
		{'data' => XMLout($pass, KeepRoot => 1, XMLDecl => $self->{XML})});
	my $pass_form = XMLin($url->content());

return $pass_form->{url};
}

=item * $rajce->create_album($title,$desc);
Create new album.
=cut
sub create_album {
	my ($self,$title,$desc) = @_;

	my $create = {'request'=>{
			'command'=>['createAlbum'],
			'parameters'=>{
				'token'=>[$self->{sessionToken}],
				'albumName'=>[decode("utf8",$title)],
				'albumDescription'=>[decode("utf8",$desc)],
				'albumVisible'=>[1],
			},
		}
	};

	my $album = $self->{BOT}->post($self->{API},
		{'data' => XMLout($create, KeepRoot => 1, XMLDecl => $self->{XML})});

return XMLin($album->content());
}

=item * $rajce->_open_album($album);
Open album for adding pictures.
=cut
sub _open_album {
	my ($self,$album) = @_;

	my $create = {'request'=>{
			'command'=>['openAlbum'],
			'parameters'=>{
				'token'=>[$self->{sessionToken}],
				'albumID'=>[$album->{albumID}],
			},
		}
	};

	my $open = $self->{BOT}->post($self->{API},
		{'data' => XMLout($create, KeepRoot => 1, XMLDecl => $self->{XML})});

return XMLin($open->content());
}

=item * $rajce->_close_album($album);
Close album after adding pictures.
=cut
sub _close_album {
	my ($self,$album) = @_;

	my $create = {'request'=>{
			'command'=>['closeAlbum'],
			'parameters'=>{
				'token'=>[$self->{sessionToken}],
				'albumToken'=>[$album->{albumToken}],
			},
		}
	};

	my $open = $self->{BOT}->post($self->{API},
		{'data' => XMLout($create, KeepRoot => 1, XMLDecl => $self->{XML})});

return XMLin($open->content());
}

=item * $rajce->add_photo($filename,$album);
Add photo into gallery.
=cut
sub add_photo {
	my ($self,$filename,$album) = @_;

	my $thumbsize = "100x100";

	my $thumb = new Image::Magick;
	$thumb->Read($filename);
	$thumb->AutoOrient();
	$thumb->Resize(geometry=>"$thumbsize^");
	$thumb->Crop(gravity=>"Center",geometry=>"$thumbsize");
	$thumb->Strip();

	my $pic = new Image::Magick;
	$pic->Read($filename);
	$pic->AutoOrient();
	$pic->Resize(geometry=>"$self->{maxWidth}x$self->{maxHeight}>");
	$pic->Strip();

	my ($width, $height) = $pic->Get('width','height');
	
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

	$self->_open_album($album);
	my $obrazek = $self->{BOT}->post($self->{API},
		{'data' => XMLout($newpicture, KeepRoot => 1,	XMLDecl => $self->{XML}),
			'thumb' => [undef,$filename,Content => $thumb->ImageToBlob()],
			'photo' => [undef,$filename,Content => $pic->ImageToBlob()]},
		Content_Type => 'form-data');
	$self->_close_album($album);

return XMLin($obrazek->content());
}

=item * $rajce->get_albumurl($album);
Get URL of album.
=cut
sub get_albumurl {
	my ($self,$album) = @_;

	my $url = {'request'=>{
			'command'=>['getAlbumUrl'],
			'parameters'=>{
				'token'=>[$self->{sessionToken}],
				'albumToken'=>[$album->{albumToken}],
			}
		}
	};

	my $alb = $self->{BOT}->post($self->{API},
		{'data' => XMLout($url, KeepRoot => 1, XMLDecl => $self->{XML})});
	my $response = XMLin($alb->content());

return $response->{url};
}

1;
__END__
=back

=head1 AUTHOR

Petr Kletecka, C<< <pek at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<pek at cpan.org>

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc WebService::Rajce


You can also look for information at:

https://github.com/petrkle/rajce

=head1 LICENSE AND COPYRIGHT

Copyright 2011 Petr Kletecka.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

=head1 SEE ALSO

www.rajce.net
http://goo.gl/34P9B - API doc

=cut
1;
