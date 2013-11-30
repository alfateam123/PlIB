#!/usr/bin/perl
# no doc!?1?!?!?
# >Robertof
# >documentation
# author: alfateam123
# module: emoticon
# purpose: 'cause writing emoticons can be difficult

package Plib::modules::emoticons;

use feature 'say';

my %emoticons=();

sub readEmoticons{
	my $emoticon_archive;
	{ 
	    local $/ = undef;
		local *FILE;
		open FILE, "<", './Plib/modules/databases/emoticons/emoticon_archive.tsv' or die "wtf $!";
		$emoticon_archive = <FILE>;
		close FILE;
	}
	foreach my $line (split "\n", $emoticon_archive)
	{
		my ($name, $emoji) = split "\t", $line;
		$emoticons{$name} = $emoji;
	}
}

sub printEmoticons{
	#for debug purposes
	foreach my $name (keys %emoticons)
	{
		say "$name => $emoticons{$name}";
	}
}

sub saveNewEmoticon {
	my ($name, $emoji) = @_;
	#say "name:$name, emoji:$emoji";
	$emoticons{$name} = $emoji;
	&writeEmoticons;
}

sub removeEmoticon {
	my $emoticon_name = shift;

	delete $emoticons{$emoticon_name};
	&writeEmoticons;
}

sub writeEmoticons {
	#local $/ = undef;
	local *FILE; open FILE, ">", './Plib/modules/databases/emoticons/emoticon_archive.tsv' or die "diocane $!";
	foreach (keys %emoticons)
	{
		print FILE $_, "\t", $emoticons{$_}, "\n";
	}
	close FILE;
}

sub new { return $_[0]; }
sub atInit{}
sub atWhile {
	my ($self, $isTest, $botClass, $sent, $nick, $ident, $host) = @_;
	return 1 if $isTest;

	readEmoticons() unless (scalar (keys %emoticons));

	if ($nick and $ident and $host and $info = $botClass->matchMsg ($sent)) {
		if ($info->{"message"} =~ /^!emoticon add :(\w+):{0,1} (.+)$/){
			saveNewEmoticon($1, $2);
			$botClass->sendMsg($info->{"chan"}, "added relation between $1 and $2 into emoticons. Thank you \\(^u^)/");
		}
		elsif ($info->{"message"} =~ /^!emoticon remove :(\w+):{0,1}$/){
			removeEmoticon($1);
			$botClass->sendMsg($info->{"chan"}, "removed emoticon $1.");
		}
		elsif($info->{"message"} =~ /^!emoticon show$/)
		{
			my $emoji_list="";
			foreach (keys %emoticons)
			{
				$emoji_list.=" $_ => $emoticons{$_} ~";
			}
			$emoji_list =~ s/~$//;
			$botClass->sendMsg($info->{"chan"}, "list of emoticons: ".$emoji_list);
		}
		elsif ($info->{"message"} =~ /:(\w+):{0,1}/i) {
			my $omgstr='>asks for an emoticon >writes it wrong =>  ┻━┻ ︵ヽ(`Д´)ﾉ ';
			#printEmoticons();
			#say ">>>$1<<<";
			if(exists $emoticons{$1})
			{
				#say 'esiste!';
				#say "__>$emoticons{$1}<__";
				$omgstr=$emoticons{$1};
			}
			$botClass->sendMsg ($info->{"chan"}, $omgstr);
		}
	}
}
1;
