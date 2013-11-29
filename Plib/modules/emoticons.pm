#!/usr/bin/perl
# no doc!?1?!?!?
# >Robertof
# >documentation
# author: alfateam123
# module: emoticon
# purpose: 'cause writing emoticons can be difficult

package Plib::modules::emoticon;

my %emoticons=();

sub readEmoticons{
	my $emoticon_archive;
	{ 
	    local $/ = undef;
		local *FILE;
		open FILE, "<", './databases/emoticons/emoticon_archive.tsv';
		$emoticon_archive = <FILE>;
		close FILE;
	}
	foreach my $line (split "\n", $emoticon_archive)
	{
		my ($name, $emoji) = split "\t", $line;
		$emoticons{$name} = $emoji;
	}
}

sub saveNewEmoticon {
	my ($name, $emoji) = @_;
	$emoticons{$name} = $emoji;
	&writeEmoticons;
}

sub removeEmoticon {
	my $emoticon_name = shift;

	delete $emoticons{$emoticon_name};
	&writeEmoticons;
}

sub writeEmoticons {
	local $/ = undef;
	local *FILE; open FILE, ">", './databases/emoticons/emoticon_archive.tsv';
	foreach (keys %emoticons)
	{
		print FILE "$_\t$emoticons{$_}\n";
	}
	close FILE;
}

sub new { return $_[0]; }
sub atInit{}
sub atWhile {
	my ($self, $isTest, $botClass, $sent, $nick, $ident, $host) = @_;
	return 1 if $isTest;
	if ($nick and $ident and $host and $info = $botClass->matchMsg ($sent)) {
		if ($info->{"message"} =~ /:(\w+):{0,1}/i) {
			my $omgstr='>asks for an emoticon >writes it wrong => (╯ᐧ _ ᐧ ) ╯┻━┻ ';

			if(exists $emoticon_archive{$1})
			{
				$omgstr=$emoticon_archive{$1};
			}
			$botClass->sendMsg ($info->{"chan"}, $omgstr);
		}
		elsif ($info->{"message"} =~ /^!emoticon add :(\w+):{0,1} (.*)$/){
			saveNewEmoticon($1, $2);
			$botClass->sendMsg($info->{"chan"}, "added relation between $1 and $2 into emoticons. Thank you \\(^u^)/");
		}
		elsif ($info->{"message"} =~ /^!emoticon remove :(\w+):{0,1}$/){
			removeEmoticon($1);
			$botClass->sendMsg($info->{"chan"}, "removed emoticon $1.");
		}
	}
}
1;
