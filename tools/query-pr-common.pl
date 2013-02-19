#!/usr/bin/perl
# refactored from www/en/cgi/query-pr-summary.cgi

$project       = 'FreeBSD';
$mail_prefix   = 'freebsd-';
$mail_unass    = 'freebsd-bugs';
$ports_unass   = 'ports-bugs';

# put these in each of your .cgi files
#require '/c/gnats/tools/cgi-lib.pl';
#require '/c/gnats/tools/cgi-style.pl';
#require '/c/gnats/tools/query-pr-common.pl';
#require 'getopts.pl';

%mons = ('Jan', '01',  'Feb', '02',  'Mar', '03',
	 'Apr', '04',  'May', '05',  'Jun', '06',
	 'Jul', '07',  'Aug', '08',  'Sep', '09',
	 'Oct', '10',  'Nov', '11',  'Dec', '12');

$table   = "<table width='100%' border='0' cellspacing='1' cellpadding='0'>";
$table_e = '</table>';

# Customizations for the look and feel of the summary tables.
$t_style = "<style type='text/css'><!--\n" .
    "table { background-color: #ccc; color: #000; }\n" .
    "tr { padding: 0; }\n" .
    "th { background-color: #cbd2ec; color: #000; padding: 2px;\n" .
    "     text-align: left; font-weight: normal; font-style: italic; }\n" .
    "td { color: #000; padding: 2px; }\n" .
    "td a { text-decoration: none; }\n" .
    ".o { background-color: #fff; }\n" .
    ".a { background-color: #cffafd; }\n" .
    ".f { background-color: #ffc; }\n" .
    ".p { background-color: #d1fbd6; }\n" .
    ".r { background-color: #d6cfc4; }\n" .
    ".s { background-color: #fcccd9; }\n" .
    ".c { background-color: #c1d5db; }\n" .
    "--></style>";

sub escape($) { $_ = $_[0]; s/&/&amp;/g; s/</&lt;/g; s/>/&gt;/g; $_; }

sub cgiparam {
    local ($result) = @_;

    $result =~ s/[^A-Za-z0-9+.@-]/"%".sprintf("%02X", unpack("C", $&))/ge;
    $result;
}

# XXX not yet tested
# XXX added input as param
# XXX added html_mode as param
sub header_info {
    local($input) = @_[0];
    local($html_mode) = @_[1];

    if ($html_mode) {
	print &html_header("Current $project problem reports");
    }
    else {
	if (!$input{'very_quiet'}) {
	    print "Current $project problem reports\n";
	}
    }
# XXX MCL 20081013
#    if (!$input{'quiet'}) {
#       print "The following is a listing of current problems submitted by $project users. " .
#	  'These represent problem reports covering all versions including ' .
#	  'experimental development code and obsolete releases. ';
#
#       &header_info_states($html_mode);
#    }
#    print "</p>\n";
}

sub header_info_states {
    local($html_mode) = @_[0];

    if ($html_mode) {
	print <<EOM;

<p>
Bugs can be in one of several states:
</p>
<dl>
<dt class='o'><strong>o - open</strong></dt>
<dd>A problem report has been submitted, no sanity checking
performed.</dd>

<dt class='a'><strong>a - analyzed</strong></dt>
<dd>The problem is understood and a solution is being sought.</dd>

<dt class='f'><strong>f - feedback</strong></dt>
<dd>Further work requires additional information from the originator
or the community - possibly confirmation of the effectiveness of a
proposed solution.</dd>

<dt class='p'><strong>p - patched</strong></dt>
<dd>A patch has been committed, but some issues (MFC and / or
confirmation from originator) are still open.</dd>

<dt class='r'><strong>r - repocopy</strong></dt>
<dd>The resolution of the problem report is dependent on a repocopy
operation within the CVS repository which is awaiting completion.</dd>

<dt class='s'><strong>s - suspended</strong></dt>
<dd>The problem is not being worked on, due to lack of information or
resources.  This is a prime candidate for somebody who is looking for a
project to do. If the problem cannot be solved at all, it will be
closed, rather than suspended.</dd>

<dt class='c'><strong>c - closed</strong></dt>
<dd>A problem report is closed when any changes have been integrated,
documented, and tested -- or when fixing the problem is abandoned.</dd>
</dl>
EOM

# 20080915 test: declare this boilerplate obsolete
#    } else {
#
#print <<EOM;
#
#Bugs can be in one of several states:
#
#o - open
#A problem report has been submitted, no sanity checking performed.
#
#a - analyzed
#The problem is understood and a solution is being sought.
#
#f - feedback
#Further work requires additional information from the
#     originator or the community - possibly confirmation of
#     the effectiveness of a proposed solution.
#
#p - patched
#A patch has been committed, but some issues (MFC and / or
#     confirmation from originator) are still open.
#
#r - repocopy
#The resolution of the problem report is dependent on
#     a repocopy operation within the CVS repository which
#     is awaiting completion.
#
#s - suspended
#The problem is not being worked on, due to lack of information
#     or resources.  This is a prime candidate
#     for somebody who is looking for a project to do.
#     If the problem cannot be solved at all,
#     it will be closed, rather than suspended.
#
#c - closed
#A problem report is closed when any changes have been integrated,
#     documented, and tested -- or when fixing the problem is abandoned.
#EOM
    }
}

sub getline {
    local($_) = @_;
    ($tag,$remainder) = split(/[ \t]+/, $_, 2);
    return $remainder;
}

sub html_fixline {
    local($line) = @_[0];

    $line =~ s/&/&amp;/g;
    $line =~ s/</&lt;/g;
    $line =~ s/>/&gt;/g;

    $line;
}

sub printcnt {
    local($cnt) = $_[0];

    if ($cnt) {
	printf("%d problem%s total.\n", $cnt, $cnt == 1 ? '' : 's');
    } else {
	print("(none)\n");
    }
}

# XXX not yet used
# XXX add htmlmode as param
# XXX add catdesc as param
# XXX add cat as param
# XXX add prs as param
# XXX add query_pr_ref as param
sub cat_summary {
    &get_categories;
    foreach (keys %status) {
	s|/\d+||;
	$cat{$_}++;
    }
    foreach (@categories) {
	next unless $cat{$_};	# skip categories with no bugs.
	if ($htmlmode) {
	    print "<h3>Problems in category: $_ ($catdesc{$_})</h3>\n";
	} else {
	    print "Problems in category: $_ ($catdesc{$_})\n";
	}
	if (/^(\w+)/) {
	    &printcnt(&gnats_summary("\$cat eq \"$1\"", $html_mode, \@prs, $query_pr_ref));
	} else {
	    print "\n??? weird category $_\n";
	}
    }
}

# XXX not yet used
# XXX add html_mode as param
# XXX add who as param
# XXX add resp as param
# XXX add prs as param
# XXX add query_pr_ref as param
sub resp_summary {
    local($who, %who);

    foreach (keys %resp) {
	$who{$resp{$_}}++;
    }
    foreach $who (sort keys %who) {
	$cnt = &gnats_summary("\$resp eq \"$who\"", $html_mode, \@prs, $query_pr_ref);
    }
}

# XXX not yet used
# XXX add html_mode as param
# XXX add input as param
# XXX add state as param
# XXX add prs as param
# XXX add query_pr_ref as param
sub state_summary {
    &get_states;
    foreach (@states) {
	next if ($_ eq "closed" && !$input{"closedtoo"});
	if ($htmlmode) {
	    print "<h3>Problems in state: $_</h3>\n";
	} else {
	    print "Problems in state: $_$\n";
	}
	if (/^(\w)/) {
	    &printcnt(&gnats_summary("\$state eq \"$1\" ", $html_mode, \@prs, $query_pr_ref));
	} else {
	    print "\n??? bad state $state\n";
	}
    }
}

# XXX not yet used
# XXX add html_mode as param
# XXX add prs as param
# XXX add query_pr_ref as param
sub severity_summary {
    if ($htmlmode) {
	print "<h3>Critical problems</h3>\n";
    } else {
	print "Critical problems\n";
    }
    &printcnt(&gnats_summary('$severity eq "critical"', $html_mode, \@prs, $query_pr_ref));

    if ($htmlmode) {
	print "<h3>Serious problems</h3>\n";
    } else {
	print "Serious problems\n";
    }
    &printcnt(&gnats_summary('$severity eq "serious"', $html_mode, \@prs, $query_pr_ref));

    if ($htmlmode) {
	print "<h3>Non-critical problems</h3>\n";
    } else {
	print "Non-critical problems\n";
    }
    &printcnt(&gnats_summary('$severity eq "non-critical"', $html_mode, \@prs, $query_pr_ref));
}

sub get_categories {
    @categories = ();

    open(Q, 'query-pr --list-categories 2>/dev/null |') ||
	die "Cannot get categories\n";

    while(<Q>) {
	chop;
	local ($cat, $desc, $responsible, $notify) = split(/:/);
	push(@categories, $cat);
	$catdesc{$cat} = $desc;
    }
}

# XXX not yet used
# XXX statedesc?
sub get_states {
    @states = ();

    open(Q, 'query-pr --list-states 2>/dev/null |') ||
	die "Cannot get states\n";

    while(<Q>) {
	chop;
	local ($state, $type, $desc) = split(/:/);
	push(@states, $state);
	$statedesc{$state} = $desc;
    }
}

# XXX not yet used
# XXX classdesc?
sub get_classes {
    @classes = ();

    open(Q, 'query-pr --list-classes 2>/dev/null |') ||
	die "Cannot get classes\n";

    while(<Q>) {
	chop;
	local ($class, $type, $desc) = split(/:/);
	push(@classes, $class);
	$classdesc{$class} = $desc;
    }
}

# XXX now returns @prs
sub read_gnats {
# XXX MCL these next two changes STILL do not do what I want!!!
#   local($report)   = @_[0];
    local($report)   = @_;
    $report=~s/"//g;

#print "query-pr $report 2>/dev/null |";

    open(Q, "query-pr $report 2>/dev/null |") || die "Cannot query the PR's\n";

    while(<Q>) {
	chop;
	if(/^>Number:/) {
	    $number = &getline($_);
#print $number;

	} elsif (/Arrival-Date:/) {
	    $date = &getline($_);
	    # strip timezone if any (between HH:MM:SS and YYYY at end of line):
	    $date =~ s/(\d\d:\d\d:\d\d)\D+(\d{4})$/\1 \2/;
	    ($dow,$mon,$day,$time,$year,$xtra) = split(/[ \t]+/, $date);
	    $day = "0$day" if $day =~ /^[0-9]$/;
	    $date = "$year/$mons{$mon}/$day";

	} elsif (/>Last-Modified:/) {
	    $lastmod = &getline($_);
	    if ($lastmod =~ /^[ 	]*$/) {	
		$lastmod = $date;
	    } else {
	        # strip timezone if any (between HH:MM:SS and YYYY at end of line):
		$lastmod =~ s/(\d\d:\d\d:\d\d)\D+(\d{4})$/\1 \2/;
		($dow,$mon,$day,$time,$year,$xtra) = split(/[ \t]+/, $lastmod);
		$day = "0$day" if $day =~ /^[0-9]$/;
	        $lastmod = "$year/$mons{$mon}/$day";
	    }

	} elsif (/>Category:/) {
	    $cat = &getline($_);

	} elsif (/>Severity:/) {
	    $sev = &getline($_);

	} elsif (/>Responsible:/) {
	    $resp = &getline($_);
	    $resp =~ s/@.*//;
	    $resp =~ tr/A-Z/a-z/;
	    $resp = "" if (($resp =~ /$mail_unass/o) or ($resp =~ /$ports_unass/o));
	    $resp =~ s/^$mail_prefix//;

	} elsif (/>State:/) {
	    $status = &getline($_);
	    $status =~ s/(.).*/\1/;

	} elsif (/>Synopsis:/) {
	    $syn = &getline($_);
	    $syn =~ s/[\t]+/ /g;

	} elsif (/^$/) {
	    $_ = sprintf("%s/%s", $cat, $number);

	    $status{$_} = $status;
	    $date{$_} = $date;
	    $resp{$_} = $resp;
	    $syn{$_} = $syn;
	    $sev{$_} = $sev;
	    $lastmod{$_} = $lastmod;
	    push(@prs,$_);
	}
    }
    close(Q);

    @prs;
}

# XXX changed to use address of prs as param 2
# XXX add query_pr_ref as param
sub gnats_summary {
    local($report)   = @_[0];
    local($htmlmode) = @_[1];
    local($prs)      = @_[2];
    local($counter)  = 0;

    foreach (@{$prs}) {
	$state = $status{$_};
	$date = $date{$_};
	$resp = $resp{$_};
	$syn = $syn{$_};
	$severity = $sev{$_};
	($cat, $number) = m|^([^/]+)/(\d+)$|;

	next if (($report ne '') && (eval($report) == 0));

	if ($htmlmode) {
	    $title = "<a href='$query_pr_ref?pr=$cat/$number'>$_</a>";
	    $syn = &html_fixline($syn);
	    gnats_summary_line_html($counter, $state, $date, $title, $resp, $syn);
	} else {
	    $title = substr($cat,0,5) . '/' . $number;
	    gnats_summary_line_text($counter, $state, $date, $title, $resp, $syn);
	}

	$counter++;
    }

    if ($htmlmode) {
	print "${table_e}\n" if $counter;
    } else {
	print "\n" if $counter;
    }

    $counter;
}

sub gnats_summary_line_html {
    local($counter)  = shift;
    local($state)    = shift;
    local($date)     = shift;
    local($title)    = shift;
    local($resp)     = shift;
    local($syn)      = shift;

    if ($counter == 0) {
       print "$table<tr><th>S</th><th>Submitted</th><th>Tracker</th><th>Resp.</th><th>Description</th></tr>\n"
    }

    print "<tr class='$state'><td>$state</td><td>$date</td><td>$title</td><td>$resp</td><td>$syn</td></tr>\n";
}

sub gnats_summary_line_text {
    local($counter)  = shift;
    local($state)    = shift;
    local($date)     = shift;
    local($title)    = shift;
    local($resp)     = shift;
    local($syn)      = shift;

    # Print the banner line if this is the first iteration.
    print "S Tracker      Resp.      Description\n" .
          "----------------------------------------" .
          "----------------------------------------\n"
	if ($counter == 0);
    print "$state " .
	$title . (' ' x (13 - length($title))) .
	$resp . (' ' x (11 - length($resp))) .
	substr($syn,0,54) . "\n";
}

# XXX not yet used
# XXX add self_ref as param
sub displayform {
print qq`
<p>
Please select the items you wish to search for.  Multiple items are AND'ed
together.
</p>
<form method='get' action='$self_ref'>

<table>
<tr>
<td><b>Category</b>:</td>
<td><select name='category'>
<option selected='selected' value=''>Any</option>`;

&get_categories;
foreach (sort @categories) {
    print "<option>$_</option>\n";
}

print qq`
</select></td>
<td><b>Severity</b>:</td>
<td><select name='severity'>
<option selected='selected' value=''>Any</option>
<option>non-critical</option>
<option>serious</option>
<option>critical</option>
</select></td>
</tr><tr>
<td><b>Priority</b>:</td>
<td><select name='priority'>
<option selected='selected' value=''>Any</option>
<option>low</option>
<option>medium</option>
<option>high</option>
</select></td>
<td><b>Class</b>:</td>
<td><select name='class'>
<option selected='selected' value=''>Any</option>
`;

&get_classes;
foreach (@classes) {
	print "<option>$_</option>\n";
}

print qq`</select></td>
</tr><tr>
<td><b>State</b>:</td>
<td><select name='state'>
<option selected='selected' value=''>Any</option>
`;

&get_states;
foreach (@states) {
	($us = $_) =~ s/^./\U$&/;
	print "<option value='$_'>";
	print "$us</option>\n";
}

print qq`</select></td>
<td><b>Sort by</b>:</td>
<td><select name='sort'>
<option value='none'>No Sort</option>
<option value='lastmod'>Last-Modified</option>
<option value='category'>Category</option>
<option value='responsible'>Responsible Party</option>
</select></td>
</tr><tr>
<!-- We don't use submitter Submitter: -->
<td><b>Text in single-line fields</b>:</td>
<td><input type='text' name='text' /></td>
<td><b>Responsible</b>:</td>
<td><input type='text' name='responsible' /></td>
</tr><tr>
<td><b>Text in multi-line fields</b>:</td>
<td><input type='text' name='multitext' /></td>
<td><b>Originator</b>:</td>
<td><input type='text' name='originator' /></td>
</tr><tr>
<td><b>Closed reports too</b>:</td>
<td><input name='closedtoo' value='on' type='checkbox' /></td>
<td><b>Release</b>:</td>
<td><select name='release'>
<option selected='selected' value=''>Any</option>
<option value='^FreeBSD [2345]'>Pre-6.x</option>
<option value='^FreeBSD 6'>6.x only</option>
<option value='^FreeBSD 5'>5.x only</option>
<option value='^FreeBSD 4'>4.x only</option>
<option value='^FreeBSD 3'>3.x only</option>
<option value='^FreeBSD 2'>2.x only</option>
</select></td>
</tr>
</table>
<input type='submit' value='Query PRs' />
<input type='reset' value='Reset Form' />
</form>
`;
}