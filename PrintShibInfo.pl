#! /usr/bin/perl

print "Content-type: text/html; charset=ISO-8859-1\n\n";
print <<"-30-";
<title>DMP Tool Shibboleth Attribute Test</title>
<h1>DMP Tool Shibboleth Attribute Test</h1>
<p>
This CGI checks to see if this DMP Tool server is receiving the
attributes from your Identity Provider that it requires to
successfully authenticate you as a user of the the DMP Tool.
</p>
-30-

$eppn = $mail = '';

for $k(sort(keys(%ENV))) { 
   next unless ($headervalue = $ENV{$k});
   next unless ($k =~ /^(HTTP_EPPN|HTTP_MAIL|Shib|[a-z])/);
   $label = "<b>$k:</b> ";

   # Probably not necessary, but just in case.....
   $headervalue =~ tr/\000-\037\177-\377//d;
   $headervalue =~ s/</&lt;/g;
   $headervalue =~ s/>/&gt;/g;

   if (($k eq 'HTTP_EPPN') && ($headervalue =~ /.+\@.+\..+/)) {
		$eppn = $headervalue;
   } elsif (($k eq 'HTTP_MAIL') && ($headervalue =~ /.+\@.+\..+/)) {
		$mail = $headervalue;
   } else {
	 $printInfo .= $label . $headervalue . "\n";
   }
}

if ($eppn ne '' && $mail ne '') {
	print <<"-30-";
	<h2>Success!</h2>
	The attributes required (eppn and mail) are being successfully received by this SP.
	<ul>
	<li> eppn: $eppn
	<li> mail: $mail
	</ul>
-30-
} else {
	print <<"-30-";
	<h2>Failure!</h2>
	All the attributes required (eppn and mail) are NOT being successfully received by this SP.
	<ul>
	<li> eppn: $eppn
	<li> mail: $mail
	</ul>
	Please review your Identity Provider logs and attribute release rules
	to determine what might be preventing releasing all the necessary 
	attributes to this SP.
-30-
}

print <<"-30-";
<h3>All the Shibboleth-related information being received by this SP</h3>		
<pre>
$printInfo
</pre>
-30-

exit;
