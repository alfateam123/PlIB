#!/usr/bin/perl
# Author: alfateam123
# Licence: WTFPL 

package Plib::modules::nyaafansub;
use strict;
use warnings;

use JSON;
use XML::FeedPP;
use List::Util qw(shuffle); 
my $hasLoaded=0;
my @posts;
my @shownPosts;
#now they are read from file.
my @sources=();
my @unloaded_sources=();


sub new {
	return $_[0];
}

sub atInit {
	#BEWARE: this function is not called if 
	#the plugin is loaded after PlIB startup
	#(aka !dml load catgirls)

	my ($self, $isTest, $botClass) = @_;
	return 1 if $isTest;
	#$botClass->sendMsg ($botClass->getAllChannels (",", 0), "Hello world!");
}

sub atWhile {
	my ($self, $isTest, $botClass, $sent, $nick, $ident, $host) = @_;
	return 1 if $isTest;

	my $info;
	if ($nick and $ident and $host and $info = $botClass->matchMsg ($sent)){
    if ($info->{"message"} =~ /released\? help/i
        ) {
        $botClass->sendMsg($info->{"chan"}, "released? <show>");
    }
    elsif ($info->{"message"} =~ /released\? ([a-z\s0-9]+)$/i
        ) {
        $botClass->sendMsg($info->{"chan"}, izReleazed($1));
    }
  }
}

sub getGroup{
  my $releaseName=shift;
  $releaseName =~ /^\[([a-z\-\s0-9]+)\]/i;
  $1;
};

sub epNum{
  my $releaseName=shift;
  $releaseName =~ /([0-9]{2})/;
  $1;
}

sub izReleazed{
  my $show=shift;

  my $feed;
  #eval{
    my $source="http://www.nyaa.se/?page=rss&cats=1_0&filter=2&term=${show}";
    print "$source\n";
    $feed = XML::FeedPP->new($source);
  #};

  for my $err ($@)
  {print '>>>'.$err."<<<\n";}
  return "y0u br0k3n nyaa. c00l" if ($@);

  my $message='';
  my $last_upper_group='';
  my $limit=5;
  my $release_counter=0;
  foreach my $post ($feed->get_item())
  {
    my $title = $post->title;
    my $link = $post->link;
    $link =~ s/download/view/;
    my $poster = getGroup($title);
    my $ep_num = epNum($title);

    #business rules
    #don't show if the previous line was from the same group
    next if $poster eq $last_upper_group;
    #don't show if raw/raws
    next if $poster =~ /raw(s){0,1}/i;
    
    $last_upper_group=$poster;
    $release_counter++;
    $message.="[$poster] - $ep_num ==> $link ~ ";
    #baby don't hurt me / don't hurt me / no more!
    last if $release_counter >= $limit;
  }
  $message =~ s/ ~ $//;
  return "I-It\'s not like I can\'t find anyone who subs ${show} on nyaa, b-baka!" if $message eq '';

  return $message;
}

1;
