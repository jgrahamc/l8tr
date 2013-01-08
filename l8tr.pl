#!/usr/bin/perl -w

use strict;
use warnings;

use DB_File;
use CGI qw(:standard);
use Crypt::Blowfish;
use GD;
use GD::Image;

my $key  = pack( 'H16',
                 'TODO' );
my $cipher = Crypt::Blowfish->new( $key );

my $new_captcha = '';
$new_captcha .= chr(int(32+rand(127-32)));
$new_captcha .= chr(int(32+rand(127-32)));
for (1..5) { $new_captcha .= ('A'..'Z')[rand 26] }
$new_captcha .= chr(int(32+rand(127-32)));

my $ciphertext = unpack( 'H16', $cipher->encrypt( $new_captcha ) );

my $action = lc(param( 'action' ));

if ( !defined( $action ) ) {
    $action = '';
}

if ( $action eq 'monitor' ) {
    print header();

    my $url     = param( 'url'     );
    my $email   = param( 'email'   );
    my $bml     = param( 'bml'   );
    # my $captcha = param( 'captcha' );
    # my $secret  = param( 'secret'  );

    my $error = '';
    my $ok = '';

    # Check that the URL and email address are valid.  If either are
    # invalid then $url or $email will be undefined.

    ( $url )=$url =~ /^((http:\/\/)?\w{1}[\w\-\._\/%&:;=~\@\?#\*\+!'\(\),\$]*)$/;
    ( $email ) = $email =~ /^(\w{1}[\w\-\._]*\@[\w\-\._]+)$/;
    ( $bml ) = $bml =~ /^(1)$/;
    if ( !defined( $bml ) ) {
        $bml = 0;
    }

    if ( defined( $url) && ( $url !~ /\./ ) ) {
        $url = undef;
    }

    if ( $url =~ /^ftp:\/\// ) {
        $url = undef;
        $error .= 'ftp:// style URLs are not currently supported<br>';
    }

    if ( $url =~ /^file:\/\// ) {
        $url = undef;
        $error .= 'file:// style URLs are not currently supported<br>';
    }
    if ( $url =~ /^(http:\/\/)?(\w+\.)?l8tr\.org/ ) {
        $url = undef;
        $error .= 'Monitoring of l8tr.org itself is not permitted<br>';
    }
    if ( $url =~ /^(http:\/\/)?212\.69\.38\.60/ ) {
        $url = undef;
        $error .= 'Monitoring of l8tr.org itself is not permitted<br>';
    }

    if ( defined( $url ) && defined( $email ) ) {

        # Verify that the capture looks correct.  If it is not then
        # $captcha will be undefined

        # ( $captcha ) = $captcha =~ /^([A-Z]{5})$/i;
        # ( $secret  ) = $secret  =~ /^([a-f0-9]+)$/;

        my $secret = 'disabled';
        my $captcha = $secret;

        if ( defined( $captcha ) && defined( $secret ) ) {

            # Verify that the captcha value is correct

            # my $plain = $cipher->decrypt( pack( 'H16', $secret ) );
            # ( $plain ) = $plain =~ /^..(.{5}).$/;

            my $plain = $captcha;

            if ( lc($plain) eq lc($captcha) ) {

                # At this point we have a valid $url and $email
                # address so add this address to be monitored

                if ( open ADD, '>>/tmp/l8tr.add' ) {
                    print ADD "$url $email $ENV{REMOTE_ADDR}\n";
                    close ADD;
                    $ok = "OK, we'll monitor $url and send email to $email when that page becomes available";
                    if ( !$bml ) {
                        $ok .= "<hr>Get the bookmarklet!  Just drag the following link to your toolbar: <a href=\"javascript:location.href='http://l8tr.org/cgi-bin/l8tr.pl?url='+encodeURIComponent(location.href)+'&email=$email&action=monitor&bml=1'\">l8tr</a>.  When you navigate to a page that is too slow, or that you need to be reminded of later, just click the l8tr button and you're done.";
                    }
                    $url = $email = '';
                }
            } else {
                $error .= 'The letters typed in the verification test were incorrect, please retry<br>';
          }
        } else {
            $error .= 'The letters typed in the verification test were incorrect, please retry<br>';
        }
    }

    if ( !defined( $url ) ) {
      $error .= 'The URL you typed is incorrect, please make sure that it is a valid URL<br>';
    }
    if ( !defined( $email ) ) {
      $error .= 'The email address you typed is incorrect, please make sure that it is a valid email address<br>';
    }

    page( ($error ne ''), $ciphertext, $url, $email, $error, $ok );
} elsif ( $action eq 'cache' ) {
    my $hash = param( 'cache' );
    my $file = param( 'file' );
    my $email = param( 'email' );
    ( $hash ) = $hash =~ /^([a-f0-9]+)$/;
    ( $file ) = $file =~ /^(cached\.[a-z]+)$/;
    ( $email ) = $email =~ /^(\w{1}[\w\-\._]*\@[\w\-\._]+)$/;

    if ( defined( $hash ) && defined( $file ) && defined( $email ) &&
         ( -e "/var/www/cache/$hash/$file" ) ) {
      print header();
  print <<EOF;
<!DOCTYPE html PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN">
<html>
<head>

  <meta content="text/html; charset=ISO-8859-1" http-equiv="content-type">
  <title>l8tr.org (beta)</title>

</head>
<body style="color: rgb(0, 0, 0); background-color: rgb(255, 255, 204);" alink="#000099" link="#000099" vlink="#990099">

<big style="font-family: Helvetica,Arial,sans-serif;"><big><big><big><big><a style="text-decoration: none;" href="/">l<span style="color: rgb(255, 102, 102);">8</span>tr.org</a><small><small><small>(beta)
<br>
<br>
The cached page you are looking for can be found here: <a href="http://l8tr.org/cache/$hash/$file">cached version</a><br></small></small></small></big></big></big></big>
<hr style="width: 100%; height: 2px;">Get the bookmarklet!  Just drag the following link to your toolbar: <a href=\"javascript:location.href='http://l8tr.org/cgi-bin/l8tr.pl?url='+encodeURIComponent(location.href)+'&email=$email&action=monitor&bml=1'\">l8tr</a>.  When you navigate to a page that is too slow, or that you need to be reminded of later, just click the l8tr button and you're done.
<hr style="width: 100%; height: 2px;"><small style="font-family: Helvetica,Arial,sans-serif;">(Yes,
this service is totally free; no, you will not receive spam from
us)<br><small style="font-family: Helvetica,Arial,sans-serif;">Brought
to you by <a href="http://www.jgc.org/">John
Graham-Cumming</a>. &nbsp;All rights reserved.</small></small>
<p align=center>
<script type="text/javascript"><!--
google_ad_client = "pub-1648014530831369";
google_alternate_color = "FFFFCC";
google_ad_width = 728;
google_ad_height = 90;
google_ad_format = "728x90_as";
google_ad_type = "text_image";
//2006-10-05: l8tr
google_ad_channel ="9239155794";
//--></script>
<script type="text/javascript"
  src="http://pagead2.googlesyndication.com/pagead/show_ads.js">
</script>
<p>
</body>
</html>
EOF
    } else {
      print header( 'text/html', '404 Not found' );
    }
} elsif ( $action eq 'image' ) {
    my $image = param( 'image' );
    ( $image ) = $image =~ /^([a-f0-9]+)$/;

    if ( defined( $image ) ) {
        my $plain = $cipher->decrypt( pack( 'H16', $image ) );
        ( $plain ) = $plain =~ /^..(.{5}).$/;

        my $img = new GD::Image(100,20);

        my $bg = $img->colorAllocate(168, 168, 168);
        my $fg = $img->colorAllocate(20, 20, 20);
        my $lc = $img->colorAllocate(168,20,168);

        # TODO Random spacing

        my $letters = '';
        foreach my $l (split(//, $plain)) {
            $letters .= $l;
            $letters .= ' ' x int(rand(2));
        }

        for (1..50) {
            my ( $sx, $sy ) = ( rand( $img->width ), rand( $img->height ) );
	    my $c = (rand(1)>0.5)?((rand(1)>0.5)?$lc:$fg):$lc;
            $img->setPixel( $sx, $sy, $c);
        }

        for (1..5) {
            my ( $sx, $sy ) = ( rand( $img->width ), rand( $img->height ) );
            my ( $ex, $ey ) = ( rand( $img->width ), rand( $img->height ) );
	    my $c = (rand(1)>0.5)?((rand(1)>0.5)?$lc:$fg):$lc;
            $img->line( $sx, $sy, $ex, $ey, $c);
        }

        $img->string(gdGiantFont, 8, 3, $letters, $fg);

        for (1..2) {
repeat:
            my ( $sx, $sy ) = ( rand( $img->width ), rand( $img->height ) );
            my ( $ex, $ey ) = ( rand( $img->width ), rand( $img->height ) );
            if ( $sx == $ex ) {
                goto repeat;
            }
            if ( $sy == $ey ) {
                goto repeat;
            }
            my $c = (rand(1)>0.5)?((rand(1)>0.5)?$bg:$fg):$lc;
            $img->line( $sx, $sy, $ex, $ey, $c);
        }

        print header( -type=>'image/png' );
        print $img->png;
    }
} else {
    print header();
    page( 1, $ciphertext, '', '', '', '' );
}

sub page
{
  my ( $source, $key, $url, $email, $error, $ok ) = @_;

  $url   = '' if ( !defined( $url   ) );
  $email = '' if ( !defined( $email ) );

  if ( $error ne '' ) {
    $error .= '<br>';
  }
  if ( $ok ne '' ) {
    $ok = '<hr>' . $ok . '<br>';
  }

  print <<EOF;
<!DOCTYPE html PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN">
<html>
<head>

  <meta content="text/html; charset=ISO-8859-1" http-equiv="content-type">
  <title>l8tr.org (beta)</title>


</head>
<body style="color: rgb(0, 0, 0); background-color: rgb(255, 255, 204);" alink="#000099" link="#000099" vlink="#990099">

<big style="font-family: Helvetica,Arial,sans-serif;"><big><big><big><big><a style="text-decoration: none;" href="/">l<span style="color: rgb(255, 102, 102);">8</span>tr.org</a><small><small><small>(beta)
<br>

<span style="font-style: italic;">Tell me when that
overloaded web page is available</span><br>

</small></small></small></big></big></big></big></big>
<ul>

  <li><big style="font-family: Helvetica,Arial,sans-serif;"><big><big><big><big><small><small><small>That
blog entry you want to read is currently overloaded?</small></small></small></big></big></big></big></big></li>

  <li><big style="font-family: Helvetica,Arial,sans-serif;"><big><big><big><big><small><small><small>The
web page everyone's talking about is Slashdotted?</small></small></small></big></big></big></big></big></li>

  <li><big style="font-family: Helvetica,Arial,sans-serif;"><big><big><big><big><small><small><small>Affected
by the Digg effect?</small></small></small></big></big></big></big></big></li>

  <li><big style="font-family: Helvetica,Arial,sans-serif;"><big><big><big><big><small><small><small>Just
don't have time to read that page?</small></small></small></big></big></big></big></big></li>

</ul>

<big><big style="font-family: Helvetica,Arial,sans-serif;"><font color=blue>$ok</font></big></big>
EOF
    if ( $ok eq '' ) {
        print <<EOF;
<hr style="width: 100%; height: 2px;"><big style="font-family: Helvetica,Arial,sans-serif;"><big><big><big><big><small><small><small>Just
fill out this form and we'll email you l<span style="color: rgb(255, 102, 102);">8</span>tr when the
page is available<br> (and we'll cache it so if it goes down again you'll still have access):<br>

<br>

</small></small></small></big></big></big></big></big>
<big><big style="font-family: Helvetica,Arial,sans-serif;"><font color=red>$error</font></big></big>
<form style="font-family: Helvetica,Arial,sans-serif;" method="post" action="/monitor" name="start">
  <table style="width: 100%;" border="0" cellpadding="2" cellspacing="2">

    <tbody>

      <tr>

        <td><big><big>URL of web page to monitor:</big></big></td>

        <td><input size="100" name="url" value="$url"></td>

      </tr>

      <tr>

        <td><big><big>Your email address:</big></big></td>

        <td><input size="50" name="email" value="$email"></td>

      </tr>

    </tbody>
  </table>

  <br>

  <input value="$key" name="secret" type="hidden">
  <input value="Monitor" name="action" style="font-family: Helvetica,Arial,sans-serif; font-size: 16pt;" type="submit">
</form>
EOF
        }
print <<EOF;
<hr style="width: 100%; height: 2px;"><big style="font-family: Helvetica,Arial,sans-serif;"><big><big><small><small>Get the l8tr.org Firefox extension: right-click any link, click on <em>Monitor with l8tr</em> and you're done.  Click <a href="/l8tr-1.0.xpi">here</a> to install.
<br>
</small></small></big></big></big>
<hr style="width: 100%; height: 2px;"><big style="font-family: Helvetica,Arial,sans-serif;"><big><big><small><small><small>(Yes,
this service is totally free; no, you will not receive spam from
us)<br>

</small></small></small></big></big></big><small style="font-family: Helvetica,Arial,sans-serif;">Brought
to you by <a href="http://www.jgc.org/">John
Graham-Cumming</a>. &nbsp;All rights reserved.</small>
<p align=center>
</body>
</html>
EOF
}
