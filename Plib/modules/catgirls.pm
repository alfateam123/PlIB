#!/usr/bin/perl
# PlIB most awesome plugin.
# Author: alfateam123
# Licence: WTFPL (hey, it's an 'hello world' plugin!)

package Plib::modules::catgirls;
use strict;
use warnings;

use JSON;
use XML::FeedPP;
use List::Util qw(shuffle); 
my $hasLoaded=0;
my @posts;
my @shownPosts;
#now they are read from file.
my $sources=();
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

    unless ($hasLoaded)
    {
        &loadCatgirls;
        $hasLoaded=1;
    }

    my $info;
    if ($nick and $ident and $host and $info = $botClass->matchMsg ($sent)){
        if ($info->{"message"} =~ /I want a catgirl( from (.*)){0,1}!$/i 
            or $info->{"message"} =~ /nyaa( from (.*)){0,1}\?/i
            or $info->{"message"} =~ /A catgirl is fine too( from (.*)){0,1}!/i
            ) {
              $botClass->sendMsg($info->{"chan"}, randomCatgirl($1, $2));
        }
        elsif ($info->{"message"} =~ /Check a catgirl! (.*)/i){
            my $lostCatgirl = $1;
            $botClass->sendMsg($info->{"chan"}, ">> ".$lostCatgirl." <<".checkACatgirl($lostCatgirl));
        }
        elsif($info->{"message"} =~ /Reload the catgirls!/i){
            $botClass->sendMsg($info->{"chan"}, "*activates Catgirl Finder* it may take a while...");
            &loadCatgirls;
            $botClass->sendMsg($info->{"chan"}, "ok, I got 'em all!");
        #bugfix  #5 start
            unless(scalar @unloaded_sources == 0)
            {
                my $unloaded_msg="These catgirl sources are closed or unreachable: ";
                foreach my $bad_source (@unloaded_sources)
                {
                    #$bad_source = isolateSource($bad_source);
                    $unloaded_msg .=" $bad_source ~";
                }
                $unloaded_msg =~ s/ ~$/. /;
                $unloaded_msg.= "We are sad, you can\'t see all the catgirls you requested. Try to fix the sources using \"remove a source!\" and \"add a source!\"";
                $botClass->sendMsg($info->{"chan"}, $unloaded_msg);
            }
        #end bugfix #5
        }
        elsif($info->{"message"} =~ /Get older catgirls!/i){
            $botClass->sendMsg($info->{"chan"}, "this functionality is not available at the time.")
        }
        elsif($info->{"message"} =~ /Gimme the sources!/i)
        {
            $botClass->sendMsg($info->{"chan"}, "The sources are: ".printSources());
        }
        elsif($info->{"message"} =~ /Add a source! (.*)( nsfw){0,1}/i){
            $botClass->sendMsg($info->{"chan"}, addSource($1, $2));
        }
        elsif($info->{"message"} =~ /Remove a source! (.*)/i){
            $botClass->sendMsg($info->{"chan"}, removeSource($1));
        }
        elsif ($info->{"message"} =~ /^CATGIRLS!$/i)
        {
            #the help
            $botClass->sendMsg($info->{"chan"}, "moar sources branch");
            $botClass->sendMsg($info->{"chan"}, "Commands you can issue:");
            $botClass->sendMsg($info->{"chan"}, "*) nyaa? | I want a catgirl! | A catgirl is fine too [from [Tumblr name]] : get a random catgirl. if specified, only catgirls from the given source will be selected.");
            $botClass->sendMsg($info->{"chan"}, "*) Reload the catgirls! : reload the archive. useful for long-running bots");
            $botClass->sendMsg($info->{"chan"}, "*) Get older catgirls! : finds moar catgirls");
            $botClass->sendMsg($info->{"chan"}, "*) Gimme the sources! : lists the sources ");
            $botClass->sendMsg($info->{"chan"}, "*) Add a source! [RSS Tumblr Feed] : adds a source to the sources");
            $botClass->sendMsg($info->{"chan"}, "*) Remove a source! [Tumblr name] : removes a source from the sources. example for \"Tumblr name\": http://fredrin.tumblr.com --> fredrin");
            $botClass->sendMsg($info->{"chan"}, "*) Check a catgirl! [url] : for debugging purposes. if in doubt, try launching 'Reload the catgirls!' command");
        }
    }
}

sub checkACatgirl{
    my $lostCatgirl=shift;

    foreach my $catgirl (@posts)
    {
        return "gotcha!" if $catgirl eq $lostCatgirl;
    }
    return "we lost a catgirl ç_ç";
}

#sub getLinkOnly{
#    my $description=shift;

#    $description =~ m/http:\/\/([^>"]*)/i;
#    return "http://".$1;
#}

sub loadCatgirls{
    @posts = (); #I forgot it. >_>
    @shownPosts = ();
    #@sources=loadSources();
    $sources=loadSources();
    @unloaded_sources=();
    foreach my $source (keys $sources) #(@sources)
    {
        #bugfix #5 start
        #old: my $feed = XML::FeedPP->new($source);
        my $feed;
        eval{
        	my $source_url=buildUrl($source);
            $feed = XML::FeedPP->new($source_url);
        };
        if ($@)
        {
            print "hey, failed! ".buildUrl($source);
            push(@unloaded_sources, $source);
            next; 
        }
        #end bugfix #5
        foreach my $post ($feed->get_item())
        {
            my $source_type = lc $sources->{$source}->{'source_type'};
            my $cat_image_link='no es fake, senor!';
            my $isgoodpost = 0;

            ($cat_image_link, $isgoodpost) = extractFromReddit($post) if $source_type eq 'reddit';
            ($cat_image_link, $isgoodpost) = extractFromTumblr($post) if $source_type eq 'tumblr';
        
            push (@posts, ($cat_image_link, $post->guid)) if $isgoodpost; #@cat);
        }
    }


    my %unique_image_links=();
    my $lposts= scalar @posts;
    my $i=0;
    while($i<$lposts)
    {
        my $image_link=$posts[$i];
        my $tumblr_link=$posts[$i+1];
        $unique_image_links{$image_link}=$tumblr_link;
        $i+=2;
    }

    my @links=keys %unique_image_links;
    $i=scalar @links;
    @posts=();
    while($i>=0)
    {
        push(@posts, ($links[$i], $unique_image_links{$links[$i]}));
        $i--;
    }
    #end bugfix #1

}

sub randomCatgirl{
    my $got_request=shift;
    my $requested_source=shift;
    $requested_source = lc $requested_source if $requested_source; #avoiding warnings

    my $posts_length=scalar @posts;
    return "WTF" if $posts_length<1;

    #now we accept requests.
    #if ($got_request ne ''){
    if (defined $got_request){
    #return "$requested_source is not even a source!" unless findSource("http://$requested_source.tumblr.com/rss")>-1;
    return "$requested_source is not even a source!" unless exists $sources->{$requested_source};
    }

    #I needed a way to not rewrite the same code twice.
    #just get the first rand() result if the user did not
    #requested a source, and search more if user requested
    #a source and the retrieved one is not ok.
    #also, the condition on $index_counter is necessary
    #to avoid endless iteration in case we extracted
    #all the posts of a given source.
    my $index=-1;
    my $index_counter=0;
    do{
        $index=int(rand($posts_length));
        #we want link_to_original (link to tumblr), and
        #we know that link_to_original is in even positions.
        $index-- if $index&1;
        $index_counter++;
    }while (
        #if user didn't ask, this will cut at first iteration
        $got_request ne '' and $requested_source ne ''
        #user asked and it's from the requested source [index+1 is the human-readable url]
        and not $posts[$index+1] =~ /$requested_source/
        #user asked and we're not searching unicorns
        and $index_counter<$posts_length
    );

    my $message="";
    if (defined $got_request){
        unless ($posts[$index+1] =~ /$requested_source/)
        {
            $message="We are very sorry, we didn\'t find anything at $requested_source. please, have this: ";
       }
    }
    $message.=$posts[$index] . ' (' . $posts[$index+1] . ')';

    #done in order to avoid "reposts"
    push(@shownPosts, $posts[$index]);
    push(@shownPosts, $posts[$index+1]);
    splice @posts, $index, 2; #we have to remove the tumblr link too.

    #doing some checks
    #maybe I need a better heuristic. this reloads
    #the archive when half of posts are shown.
    &loadCatgirls if (scalar @posts < scalar @shownPosts);

    return $message;
}

sub printSources{
    my $sourceList="";
    foreach my $source_name (keys $sources)
    {
        chomp $source_name;
        my $source_type = $sources->{$source_name}{'source_type'}; #nope.
        #$source =~ m/http:\/\/(.*)\.tumblr\.com\/rss/;
        $sourceList.="$source_name on $source_type ~ "; #"$1 ($source) ~ ";
    }
    $sourceList =~ s/ ~ $//; #removing last ~
    return $sourceList;
}

sub loadSources{
    #in this new branch, this file is now formatted as JSON
    
    open (SOURCES, '<', './Plib/modules/databases/catgirls/sources.txt') or return ('can\'t read the sources!', ">_>");
    my @faglines = <SOURCES>;
    close SOURCES;
    my $sources_content=join('', @faglines);
    my $read_sources = decode_json $sources_content;
    return $read_sources;
}

sub addSource{
	#TODO: this method needs a bit of work
    print "ok, called addSource!";
    my $newSource=shift;
    my $newsourcensfw=shift;

    $newSource = lc $newSource; #<Robertof>: "dat case sensitiveness!" 
    $newSource =~ s/^\s+|\s+$//g; #trimming ftw
    $newsourcensfw = 'NOT_AT_ALL' unless not defined $newsourcensfw; #$newsourcensfw ne '';

    my $newsourcetype = 'tumblr'; #leaving the default behaviour
    if ($newSource =~ /http\:\/\/reddit\.com\/r\/([a-z_\-0-9]*)/i)
    {
        $newsourcetype = 'reddit';
        $newSource = $1;
    }
    if ($newSource =~ /http:\/\/(.*)\.tumblr\.com/i)
    {
        $newsourcetype = 'tumblr';
        $newSource = $1;
    }
    #return "JUST THE TUMBLR NAME, YOU SMART ASS!" if $newSource =~ /^http/;
    return "$newSource is already a source!" if exists $sources->{$newSource}; #findSource("http://$newSource.tumblr.com/rss")>-1;

    #push @sources, "http://$newSource.tumblr.com/rss";
    $sources->{$newSource} = {#(
    	                'source_type' => $newsourcetype,
    	                'nsfw' => $newsourcensfw}; #); 
    
    open SOURCES, ">", "./Plib/modules/databases/catgirls/sources.txt" or
        return "can\'t open the source database!";
    print SOURCES encode_json $sources; #$newSource."\n";
    close SOURCES;
    #bugfix #6 start
    return "We\'ll look for catgirls there. Thanks for your suggestion!";
    #end bugfix #6
}

sub removeSource{
    my $oldSource = shift;
    #"dat case sensitiveness!"  
    $oldSource = lc $oldSource;
    #end 
    $oldSource=~ s/^\s+|\s+$//g;
    #my $oldSourceUrl="http://$oldSource.tumblr.com/rss";
    #return "$oldSource is not even a source!" unless findSource($oldSourceUrl)>-1;
    return "$oldSource is not even a source!" unless exists $sources->{$oldSource};

    delete $sources->{$oldSource};
    open SOURCES, ">", "./Plib/modules/databases/catgirls/sources.txt" or return "can\'t open the source database!";
    #foreach my $source (@sources)
    #{
    #    $source =~ m/http:\/\/(.*)\.tumblr\.com\/rss/;
    #    print SOURCES $1."\n";
    #}
    print SOURCES encode_json $sources; 
    close SOURCES;
    #bugfix #6 start
    return "We'll no longer look for catgirls there anymore. Thanks for your suggestion!";
    #end bugfix #6
}

sub findSource{
    my $sourceLookingFor=shift;
    #my $index=0;
    #foreach my $source (@sources)
    #{
    #    return $index if $source eq $sourceLookingFor;
    #    $index++;
    #}
    return 1 if exists $sources->{$sourceLookingFor};
    return -1;
}

#bugfix #5 start
#not directly related with the bugfix
#used only for show the source name
sub isolateSource{
    my $url = shift;
    $url =~ m/http\:\/\/(.*)\.tumblr.com/;
    return $1;
}
#end bugfix #5


########################################################################################
####################### extractions from sources #######################################
sub buildUrl{
	my $source_name=shift;
	my $mah_source_type = lc $sources->{$source_name}->{'source_type'};
	return "http://reddit.com/r/$source_name.rss" if $mah_source_type eq 'reddit';
	return "http://$source_name.tumblr.com/rss"   if $mah_source_type eq 'tumblr';
	return "wtf"; #our default
}

sub extractFromReddit{
	my $post = shift;
	my $title = $post->title;

	return ($title, 1);
	#return ('fake', 0);
}

sub extractFromTumblr{
	my $post = shift;
    
    #not everyone leaves the default "Photo" title.
    #my $title = $post->title;
    if (
        $post->description =~ /<img src="http:\/\/([^>"]*)"/
        ) 
    {
    	$post->description =~ m/http:\/\/([^>"]*)/i;
        #return (getLinkOnly($post->description), 1);
        return ("http://".$1, 1)
    }
    return ('fake', 0);
}
###################### end extractions from sources ####################################
########################################################################################

1;
