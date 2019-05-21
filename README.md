# age-de.xml counting script 
Simple script for counting web requests from users with installed child protection software, which is approoved in Germany.

More in German.

# NAME

```
count-age-de-xml.pl - Wie viele Nutzer haben ein anerkanntes "Jugendschutzprogramm" installiert?
```

# VERSION

Version 1.2

# SYNOPSIS

Dieses Skript nimmt einen oder mehrere Dateinamen von Logfiles entgegen; 
alternativ liest es die Eingaben Unix-typisch aus STDIN.

Beispiele:

```perl
perl count-age-de-xml.pl access_log
perl count-age-de-xml.pl 2015-05-*.log

grep my-site 2015-05-2*.log | perl count-age-de-xml.pl 
```

# BESCHREIBUNG

**Für Hintergrundinfos siehe den Artikel:** 
[Wie viele Nutzer haben „anerkannte Jugendschutzprogramme“?](https://blog.alvar-freude.de/2015/06/filter-nutzung.html)

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
auf STDERR aus (so dass die normalen Ausgaben z.B. in ein File umgeleitet 
werden können). 

## Ungenauigkeit

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

## Update Version 1.1

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

## Update Version 1.2 (Mai 2019)

Veröffentlichung auf GitHub (Pull-Requests nehme ich natürlich gerne an!), 
kleine Änderungen.

## Logfile-Format

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

```
grep -c age-de.xml logfile.log
```

## Geschwindigkeit

Die Geschwindigkeit der Verarbeitung ist i.d.R. von der Geschwindigkeit des 
Massenspeichers (Festplatte) abhängig; der Code ist meist schneller als die 
Festplatte (bei schnellen SSDs heutzutage nicht mehr). Selbstkomprimierende 
Filesysteme wie ZFS helfen. Auf einem Haswell XEON E3-1230 v3 komme ich auf 
rund 500 MB Logfile/Sekunde, aus dem Cache.

Die Geschwindigkeit ist auch sehr stark davon abhängig, wie Perl compiliert 
wurde. 

Wem die Geschwindigkeit für goße Logfiles nicht ausreicht, kann mehrere 
Logfiles in mehreren Prozessen parallel starten; oder den Code auf 
Multithreading umschreiben ;-)

Wer ein bisschen mehr Performance oder keine Statusmeldunggen haben will, 
entfernt die Zeile mit 

```
print "#" unless [...]
```

Dann gibt es nicht mehr alle 100000 Zeilen ein #.

# AUTHOR

```
Alvar C.H. Freude
http://alvar.a-blast.org/
http://blog.alvar-freude.de/
alvar@a-blast.org

http://ak-zensur.de/
```
