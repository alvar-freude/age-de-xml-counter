#!/usr/bin/env perl

use strict;
use warnings;

#
# KONFIGURATION!
# Hier bei Bedarf Regex anpassen.
# Der sollte einen Match haben: die IP-Adresse
# 

my $IP_REGEX = qr{ ^(.*?) \s }x;


=head1 NAME

 count_age-de.pl - Wie viele Nutzer haben ein anerkanntes "Jugendschutzprogramm" installiert?

=head1 VERSION

Version 1.1

=head1 SYNOPSIS

=encoding utf8

Dieses Skript nimmt einen oder mehrere Dateinamen von Logfiles entgegen; 
alternativ liest es die Eingaben aus STDIN.

Beispiele:

  perl count_age-de.pl access_log
  perl count_age-de.pl 2015-05-*.log
  
  grep my-site 2015-05-2*.log | perl count_age-de.pl 


=head1 BESCHREIBUNG

Dieses kleine Sktipt zählt, wie viele Zugriffe auf die Datei age-de.xml in 
einem Webserver-Access-Log stehen.

Diese Zugriffe kommen von einem von der "Kommission für Jugendmedienschutz" 
offiziell anerkannten "Jugendschutzprogramm", also Internet-Filter. Der 
Nutzer mit diesem Browser hat also ein solches Programm installiert.

Üblicherweise sind das sehr wenige Zugriffe.

Zusätzlich zählt dieses Skript die unterschiedlichen IP-Adressen, von denen 
insgesamt zugegriffen wurde und berechnet so einen Prozentwert an 
Installationen eines solchen Filters. Alternativ kann auch ein anderes 
Merkmal gezählt werden, hauptsache es entspricht ungefähr einem Wert pro 
Nutzer.

Suchmaschinen-Bots und so weiter werden mitgezählt, bei einigermaßen 
frequentierten Webseiten ist die Anzahl der IP-Adressen im Verhältnis zu den 
echten Nutzern aber gering. 

Das Skript kommt auch mit anonymisierten IP-Adressen (Hash o.ä.) zurecht; 
wenn das letzte Oktett gekürzt wurde -- dann werden u.U. weniger Nutzer 
gezählt, aber das hat erst bei sehr stark frequentiertern Webseiten eine 
große Auswirkung.

Alle 100000 (hunderttausend) Zeilen gibt das Skript ein # als Statusmeldung 
aus.


=head2 Ungenauigkeit

Dieses Skript ist sehr simpel und stupide. Es zählt alles, was im Server-Log 
steht -- und nicht alles sind menschliche Zugriffe. Vor allem selten 
frequentierte Webseiten haben einen hohen Anteil an automatisierten Zugriffen 
(von Suchmaschinen und anderen Bots).

Wenn Logfiles mehrerer Tage analysiert werden, ist es oft so, dass der 
gleiche Nutzer mit verschiedenen IP-Adressen aufschlägt, also mehrfach 
gezählt wird -- dies gilt aber auch für Nutzer mit installiertem Filter. 

Wenn mehrere Nutzer eine öffentliche IP-Adresse haben (beispielsweise eine 
Firma oder ein Haushalt), dann werden alle als einer gezählt.

Die Exakte Anzahl an Nutzern ist de fakto nicht bestimmbar. Es gibt 
aber einige Verfahren von den verschiedenen Logfile-Analyse- und 
Statistik-Programmen sowie von der IVW, um auf Näherungswerte zu 
kommen. Diese sind selbstverständlich viel realistischer als eine 
Auswertung mit diesem Skript. Zu beachten ist aber, dass diese Verfahren 
meist nur Nutzer zählen, die JavaScript angeschaltet haben und/oder 
Werbeanzeigen sehen. Nutzer, die diese ausblenden, werden mit solchen 
Verfahren also oft nicht mitgezählt. 

Die Ungenauigkeiten sind also relativ hoch. Üblicherweise haben aber nur 
sehr wenige Nutzer einen Filter installiert, so dass es zwar mathematisch 
aber nicht in der Bewertung einen relevanten Unterschied macht, ob nun 
0,005% oder 0,05% der Nutzer einen Filter installiert haben.


=head2 Update Version 1.1

Bei einigen Webseiten gibt es eine relevante Anzahl an Zugriffen, bei 
denen von einer IP-Adresse (o.ä.) nur ein einziger Zugriff gemacht wird. 
Oft auf die Startseite und ohne Bilder, CSS oder JS zu laden. Häufig von 
chinesischen IP-Adressen.

Daher gibt das Skript nun auch noch Zähler für die Anzahl der IP-Adressen 
(oder anderen halbwegs eindeutigen Merkmalen aus Spalte 1), die mind. 3, 
5, 10 oder 20 mal im Logfile auftauchen.

Da Webseiten in der Regel aus mehreren Elementen bestehen, erzeugt ein 
Besucher in der Regel auch mehrere Zugriffe. Damit können automatisierte 
Zugriffe von seltenen Bots weggefiltert werden. Und je nach Anzahl der 
Elemente auf einer Seite solche Nutzer, die nur eine Seite aufgerufen 
haben (wenn die Anzahl der Elemente pro Seite unter 20 ist) oder das Laden 
der Seite vorzeitig abgebrochen haben.

Außerdem wird ausgegeben, wie viele IPs/Nutzer für mehr als 1, 2 und 5 % 
der Gesamtzugriffe verantwortlich sind. 


=head2 Logfile-Format

Das Skript versteht alle Standard Apache Logfile-Formate. Streng genommen 
ist es sehr stupide und simpel und nimmt pro Zeile einfach das erste "Wort" 
(alle Zeichen bis zum ersten leerzeichen) als IP-Adresse; das kann auch etwas 
beliebig anderes sein, sollte aber ungefähr für jeden Nutzer habwegs eindeutig 
sein.

Der Regex zum Finden der IP-Adresse steht ganz am Anfang als Konstante; das 
ließe sich natürlich auch als CLI-Parameter definieren, für die drei Zeilen 
Code habe ich aber gerade keine Lust ... :-)


Wer nur zählen möchte, kann dies auch ganz einfach mit grep ohne dieses 
Programm machen:

  grep -c age-de.xml logfile.log


=head2 Geschwindigkeit

Die Geschwindigkeit der Verarbeitung ist i.d.R. von der Geschwindigkeit des 
Massenspeichers (Festplatte) abhängig; der Code ist meist schneller als die 
Festplatte oder SSD. Selbstkomprimierende Filesysteme wie ZFS helfen. 
Auf einem Haswell XEON E3-1230 v3 komme ich auf rund 500 MB Logfile/Sekunde, 
aus dem Cache.

Die Geschwindigkeit ist auch sehr stark davon abhängig, wie Perl compiliert 
wurde. Aber auch das dürfte meist immer noch schneller als die Festplatte 
sein.

  print "#" unless [...]


=head1 AUTHOR

  Alvar C.H. Freude
  http://alvar.a-blast.org/
  http://blog.alvar-freude.de/
  alvar@a-blast.org
  
  http://ak-zensur.de/

=cut

use English qw( -no_match_vars );

$OUTPUT_AUTOFLUSH = 1;

my %ips;
my $count_age_de = 0;
my $count_lines  = 0;

print "Zaehle die Zugriffe auf age-de.xml und IP-Adressen, alle 100000 Zeilen gibt es ein #\n\n";

while ( my $line = <ARGV> )
   {
   my ($ip) = $line =~ $IP_REGEX;
   $ips{$ip}++;
   $count_age_de++ if $line =~ m{ /age-de\.xml }x;
   print "#" unless $count_lines++ % 100000;       # Statusbalken; CPU 10% schneller ohne
   }

print "\n";

my $count_ips = scalar keys %ips;
print "versch. IPs:    $count_ips\n";
print "Age-DE:         $count_age_de\n";
printf "Das sind:       %7.5f%% der IPs\n", ( $count_age_de / $count_ips ) * 100;
print "Alle Zugriffe:  $count_lines\n\n";


my ( $eins, $drei, $fuenf, $zehn, $zwanzig, $top5p, $top2p, $top1p );
$eins = $drei = $fuenf = $zehn = $zwanzig = $top5p = $top2p = $top1p = 0;

my $top5p_limit = int( $count_lines * 0.05 );
my $top2p_limit = int( $count_lines * 0.02 );
my $top1p_limit = int( $count_lines * 0.01 );

# Das hier ließe sich deutlich optimieren, wenn nur die möglichen Abfragen
# bleiben (nur was über 10 ist, kann über 20 sein)
# So ist es aber übersichtlicher (als mehrfach verschachtelte if-Blöcke) und
# in der Regel sowieso schnell genug
foreach my $ip ( keys %ips )
   {
   $eins++    if $ips{$ip} == 1;
   $drei++    if $ips{$ip} >= 3;
   $fuenf++   if $ips{$ip} >= 5;
   $zehn++    if $ips{$ip} >= 10;
   $zwanzig++ if $ips{$ip} >= 20;
   $top5p++   if $ips{$ip} >= $top5p_limit;
   $top2p++   if $ips{$ip} >= $top2p_limit;
   $top1p++   if $ips{$ip} >= $top1p_limit;
   }

print "IPs mit 1 Hit:  $eins\n";
print "IPs ab 3 Hits:  $drei\n";
print "IPs ab 5 Hits:  $fuenf\n";
print "IPs ab 10 Hits: $zehn\n";
print "IPs ab 20 Hits: $zwanzig\n";
print "IPs in Top 5%:  $top5p (ab $top5p_limit Hits)\n";
print "IPs in Top 2%:  $top5p (ab $top2p_limit Hits)\n";
print "IPs in Top 1%:  $top1p (ab $top1p_limit Hits)\n";


print "\nHinweis: Je nach Randbedingung kann eine IP-Adresse mehr oder weniger einen Nutzer darstellen\n\n";

