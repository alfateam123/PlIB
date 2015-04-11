#!/usr/bin/perl
# no doc!?1?!?!?
# >Robertof
# >documentation
# author: alfateam123
# module: emoticon
# purpose: 'cause writing emoticons can be difficult

package Plib::modules::emoticons;

use feature 'say';
use Encode qw(decode encode);

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
		if ($info->{"message"} =~ /^!(emoticon|emoticons|emoji|emojis) add :(\w+):{0,1} (.+)$/){
			saveNewEmoticon($2, $3);
			$botClass->sendMsg($info->{"chan"}, "added relation between $2 and $3 into emoticons. Thank you \\(^u^)/");
		}
		elsif ($info->{"message"} =~ /^!(emoticon|emoticons|emoji|emojis) remove :(\w+):{0,1}$/){
			removeEmoticon($2);
			$botClass->sendMsg($info->{"chan"}, "removed emoticon $2.");
		}
		elsif($info->{"message"} =~ /^!(emoticon|emoticons|emoji|emojis) (show|list)$/)
		{
			my $emoji_list="";
			foreach (keys %emoticons)
			{
				$emoji_list.=" $_ => ".decode('UTF-8', $emoticons{$_}, ENCODE::FB_CROAK)." ~";
			}
			$emoji_list =~ s/~$//;
			while(length($emoji_list) > 200){
                          #$emoji_list = substr($emoji_list, 0, 199);
                          $botClass->sendMsg($info->{"chan"}, substr($emoji_list, 0, 199) );
                          $emoji_list = substr($emoji_list, 199)
                        };
                        $botClass->sendMsg($info->{"chan"}, $emoji_list);
		}
		elsif ($info->{"message"} =~ /:(\w+):?/ig) {
			#my $omgstr='';
			#printEmoticons();
			#say ">>>$1<<<";
			#if(exists $emoticons{$1})
			#{
			#	#say 'esiste!';
			#	#say "__>$emoticons{$1}<__";
			#	$omgstr=$emoticons{$1};
			#        $botClass->sendMsg ($info->{"chan"}, $omgstr);
                        #}
                        my $woot = $info->{"message"};
                        while($woot =~ /:(\w+):?/ig){
                             my $related_emoji  = $1;
                             $related_emoji = $emoticons{$1} if exists $emoticons{$1};
                             $woot =~ s/:$1:?/$related_emoji/ if $related_emoji ne $1;
                          }
                        $botClass->sendMsg($info->{"chan"}, $woot) if $woot ne $info->{"message"};
	}}
}
1;
