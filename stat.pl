#!/usr/bin/perl --
#Author: Joe Yearsley
#Date: 23/2/14
#The below imports CGI modules as well as XML and WWW tools.
#save in hash, save sorted keys in an array,
#create new hash of top and bottom from sorted array
#look at bookmark for tables, comma array, new arrays for top + bottom 
#Set output to utf8
use CGI qw (:all);
use XML::Simple;
use LWP::Simple;
use utf8;
binmode STDOUT, ":utf8";

#Print out the HTML header
print header(-charset => 'UTF-8');
#Get the style sheet below
my $style = get_style();
#Print out the starting HTML tags
print start_html({-title=>'stat.pl',-author=>'sgjyears@liv.ac.uk',-style =>{-code => $style}},
                  -head=>meta({-http_equiv => 'Content-Type',
                               -content    => 'text/xml'}));
#Start the form and enter labels and text fields with their attributes.
print start_form({-method=>"GET", -action=>"http://cgi.csc.liv.ac.uk/".
"cgi-bin/cgiwrap/~u2jey/stat.pl"});
   print "<label>Input Related Keywords Here: </label>";
   print textfield({-name=>'query', -size=>100});
   print "<br /><label>Input The No. Of Results To Return: </label>";
   print textfield({-name=>'maxHits', -size=>100});
#Print a gap in HTML
   print br();
   print submit({-name=>'submit',-align=>'center'});
#End the form
print end_form;

#Get the parameters from the URL
$query = param('query');
$maxHits = param('maxHits');

#check to see if defined first
if ((defined $query) && (defined $maxHits)){
#Check if either or both are empty and deal with it
if (($query eq "") && ($maxHits eq "")){
   print p({-align=>center},"Enter data into both fields!");
} elsif ($query eq ""){
   print p({-align=>center},"Ensure there's keywords entered!");
} else {
   if ($maxHits =~ /^\d+$/){
 #Print out query string enviroment variable      
   	   print p({-align=>center},"The Query Used: $ENV{QUERY_STRING}");
       &InXMLSortData();
   } else {
   	  print p({-align=>center},"Enter the number of results to return!");
   }
}
}
#End the HTML
print end_html;

#Sub routine to get the XML file using LWP and XML simple
sub InXMLSortData {
   
   $parser = new XML::Simple;
#set the url with the parameters
   $url = "http://www.dblp.org/search/api/?q=$query&h=$maxHits&c=4&f=0&format=xml";
#get the file or deal with no file
   $content = get $url or print "ERROR\n";
#Enter the XML into a hash
   my $data = XMLin($content, ForceArray => 1, KeyAttr => [ ]);
#Call subroutine to hash the authors correctly
   &hashAuthors($data);
}


#Hash the authors
sub hashAuthors(){

#use for loop go through hits adding authors to global list, if already on list
# then add 1 else add to list
   my ($data) = @_;
   %authors =();
#Get size of sub array in the hash
   $count = scalar( @{$data->{'hits'}[0]->{'hit'}});
#Print out number of results returned
   print p({-align=>center},"Amount of Publications Returned: $count");
#Go through sub array and get the authors, increasing their hash value every time they
#  are found.
   for ($i = 0;$i <= $count; $i++){
      foreach my $hit ( @{$data->{'hits'}[0]->{'hit'}[$i]->{'info'}[0]->{'authors'}}) {
# But 'author' is an ArrayRef:
         foreach my $author ( @{ $hit->{'author'} } ) {
            if (exists($authors{$author})){
              $authors{$author} = $authors{$author} + 1;
            } else {
              $authors{$author} = 1;
            }
         }
      }
   }
   
#If exists then carry on, else print the error
  if (%authors){
  #Count for array to use to store sorted keys;
      $arrayCount = 0;
      foreach $key (sort {$authors{$b} <=> $authors{$a}} keys %authors) { 
    #For each key, sort and save key into an array
      @sortedAuthors[$arrayCount] = $key; 
    #Increase counter
      $arrayCount++;
      }
     &SortHashTop(@sortedAuthors);
     &SortHashBottom(@sortedAuthors);
     &printXML();
   } else {
     print p({-align=>center},"No Results Returned");
   }
}

#Way to sort the hash into a new hash of 10 and print it out in a table.
#For most published.
sub SortHashTop {
#Store the passed hash
   my (@authors) = @_;
#Cut the array down to the top 10
   my @sortedAuthors = &cutArray(@authors);
   
#print the table
  print table({-border=>1},
     caption('10 Authors with most publications'),
     Tr([
       th(['Author','No of Publications']),
#map the key and value to new td's , used instead of foreach
       map{
         td([
             $_, $authors{$_} 
        ])
#Should go through array, get names top to bottom, then look up in hash to get value!
       } @sortedAuthors
     ])
   );
}

#Way to sort the hash into a new hash of 10 and print it out in a table.
#For least published
sub SortHashBottom {
#Store the passed hash
   my (@authors) = @_;
#Reverse the array to keep in order, but get first 10 with same sub routine
   my @authorsR = reverse(@authors);
#Cut the array down to the top 10
   my @sortedAuthors = &cutArray(@authorsR);
   
#print the table
  print table({-border=>1},
     caption('10 Authors with least publications'),
     Tr([
       th(['Author','No of Publications']),
#map the key and value to new td's , used instead of foreach
       map{
         td([
             $_, $authors{$_} 
        ])
#Should go through array, get names top to bottom, then look up in hash to get value!
       } @sortedAuthors
     ])
   );
}

sub cutArray(){
#Get array, cut it to the first 10, return.
my (@array) = @_;
@cutArray = splice @array,0,10;
return @cutArray;
}
#Style sheet to get tables side by side and sort out the columns to look nicer
#EOT to allow the sheet to be printed as seen.
sub get_style {
        my $style = <<"EOT";
        body {
            font-family: ariel;
            bgcolor: white;
	    padding-left: 5%;
        }
        table {
            border: black 1pt solid;
            display: inline-block; 
            width : 40%;
            border-collapse: collapse;
            margin-top:40px;
            
        }
        th,td {
            border: black 1pt solid;
            width : 25%;
        }
        
EOT
        return $style;
    }

sub printXML() {
     #Get the XML
     $text = get("http://www.dblp.org/search/api/?q=$query&h=$maxHits&c=4&f=0&format=xml");
     print br();
     #Output text
     print "XML Returned: ";
     print "<pre>\n";
     print XMLout($text);
     print "\n</pre>";
     #Generate a XML file output aswell, put in root so can be seen in browser + downloaded
     my $temp = XMLin($text);
     my $xml = XMLout($temp,  OutputFile => '../out.xml');
     print '<a href="http://cgi.csc.liv.ac.uk/~u2jey/out.xml" download>XML FILE</a>';
}
