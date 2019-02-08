#!/bin/bash
#
# This file is part of the espena/mkres distribution
# (https://github.com/espena/mkres).
# Copyright (c) 2017 Espen Andersen.
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, version 3.
#
# This program is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
# General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program. If not, see <http://www.gnu.org/licenses/>.

load_config() {
  FILETITLE="$1"
  TARGET="$PWD/$FILETITLE.sql"
  CONFIGFILE="$PWD/$FILETITLE.conf"
  DEFAULT_CONFIGFILE="$PWD/default.conf"
  OUTPUT="$PWD/$FILETITLE.pdf"
  CURDIR="$PWD"
  TMPDIR="$(mktemp -d)"
  LATEX_MAIN="$TMPDIR/main.tex"
  LATEX_BODY="$TMPDIR/body.tex"
  if [ ! -f "$CONFIGFILE" ] && [ ! -f "$DEFAULT_CONFIGFILE" ]; then
    cat <<EOF > "$CONFIGFILE"
DOCUMENT_LANGUAGE="english"
DOCUMENT_TITLE="My research report"
DOCUMENT_AUTHOR="Espen Andersen"
MYSQL_HOST="mysql"
MYSQL_PORT="3306"
MYSQL_USER="root"
MYSQL_PASS="secret"
EOF
  fi
	if [ ! -f "$CONFIGFILE" ]; then
		source "$DEFAULT_CONFIGFILE"
	else
		source "$CONFIGFILE"
	fi
}

write_latex_main() {
  cat <<EOF > "$LATEX_MAIN"
  \documentclass[10pt,a4paper]{article}
  \usepackage[T1]{fontenc}
  \usepackage[utf8]{inputenc}
  \usepackage{amsmath}
  \usepackage{amsfonts}
  \usepackage{amssymb}
  \usepackage{makeidx}
  \usepackage{graphicx}
  \usepackage{lmodern}
  \usepackage{parskip}
  \usepackage{kpfonts}
  \usepackage[left=2.5cm,right=2.5cm,top=2.5cm,bottom=3cm]{geometry}
  \usepackage{pgfplotstable}
  \usepackage{booktabs}
  \usepackage{tabularx}
  \usepackage{array}
  \usepackage{colortbl}
  \usepackage{placeins}
  \usepackage[$DOCUMENT_LANGUAGE]{babel}
  \renewcommand{\arraystretch}{1.2}
  \pgfplotstableset {
  	column type=,
  	end table={\end{tabularx}},
  	col sep=comma,
  	string type,
  	every head row/.style={after row=\hline\rule{0pt}{4.5mm}},
  	every head row/.append style={
          typeset cell/.code={
  			\ifnum\pgfplotstablecol=\pgfplotstablecols
          			\pgfkeyssetvalue{/pgfplots/table/@cell content}{\textbf{##1}\\\\}
          		\else
          			\pgfkeyssetvalue{/pgfplots/table/@cell content}{\textbf{##1}&}
          		\fi
          	}
      },
  	every last row/.style={after row=\hline\rule{0pt}{4.5mm}}
  }
  \title{$DOCUMENT_TITLE}
  \author{$DOCUMENT_AUTHOR}
  \begin{document}
  	\maketitle
  	\newpage
  	\tableofcontents
  	\newpage
  	\begin{flushleft}
  	\input{body.tex}
  	\end{flushleft}
  \end{document}
EOF
}

prepare_queries() {
  csplit --digits=2 --elide-empty-files --quiet --prefix="$TMPDIR/$FILETITLE." "$TARGET" "/\/\*\*/" "{*}"
}

build() {
  echo "" > "$LATEX_BODY"
  for file in $(find "$TMPDIR" -name "$FILETITLE.*" -not -name "$FILETITLE.*.csv" | sort);
  	do
      #iconv -f UTF-8 -t ISO-8859-1 -o "$file.new" "$file" && mv -f "$file.new" "$file"
      MD5=($(md5sum "$file"))
      CACHEDIR="/tmp/mkres_cache/$MD5"
      CACHEFILE_LATEX="$CACHEDIR/$(basename $file)"
      CACHEFILE_CSV="$CACHEFILE_LATEX.csv"
      LATEX_BODY_TMP=$(mktemp)
      CSVFILE="$(basename $file).csv"
      title="$(pcregrep -Mo 'subsection\{\K((?s).)*?(?=\})' $file)"
      alignment="$(pcregrep -Mo '<COLS>\K((?s).)*?(?=</COLS>)' $file)"
      if [ ! -f "$CACHEFILE_CSV" ]; then
    		latex="$(pcregrep -Mo '<LATEX>\K((?s).)*?(?=</LATEX>)' $file)"
        latexBelow="$(pcregrep -Mo '<LATEX_BELOW>\K((?s).)*?(?=</LATEX_BELOW>)' $file)"
        if [[ ! $alignment =~ ^[Xlrc]+$ ]]; then
          echo "Missing, bad or empty <COLS> tag for table \"$title\": \"$alignment\""
          exit
        fi
        if [ -f "$TMPDIR/$CSVFILE" ]; then
          # Do queries on second run
          printf   " ---> \"$title\" ($alignment):: SQL"
          iconv -f UTF-8 -t ISO-8859-1 -o "$file.8859-1" "$file"
          MYSQL_PWD=$MYSQL_PASS mysql -h$MYSQL_HOST -u$MYSQL_USER < "$file.8859-1" | sed 's/,/\\char44\{\}/g' | sed 's/_/\\char95\{\}/g' | sed 's/|/\\char124\{\}/g'| sed 's/%/\\char37\{\}/g'| sed 's/ /\\:/g' | sed 's/\t/,/g' | iconv -f ISO-8859-1 -t UTF-8 >> "$TMPDIR/$CSVFILE"

          echo "CSVFILE: $TMPDIR/$CSVFILE"

          rm -f "$file.8859-1"
          printf "\r ---> \"$title\" ($alignment):: OK!\n"
        else
          # Dry-run queries first
          cat "$file" | tr "\n" "\f" | sed -e 's/\fSELECT/ EXPLAIN SELECT/g' | sed -e 's/UNION/;/g' | MYSQL_PWD=$MYSQL_PASS mysql -h$MYSQL_HOST -u$MYSQL_USER > /dev/null
          if [ ${PIPESTATUS[4]} -eq 1 ]; then
            exit
          fi
        fi
    		echo "\\begin{minipage}{\\textwidth}" >> "$LATEX_BODY_TMP"
        echo "\\setlength{\\parskip}{\\baselineskip}" >> "$LATEX_BODY_TMP"
    		echo "$latex" >> "$LATEX_BODY_TMP"
    		echo "\\medskip\\FloatBarrier" >> "$LATEX_BODY_TMP"
    		printf "\\pgfplotstabletypeset[begin table={\\\\begin{tabularx}{\\\\textwidth}{%s}}]{%s}\n" \
    					 "$alignment" \
    					 "$CSVFILE" \
    					 >> "$LATEX_BODY_TMP"
    		echo "\\FloatBarrier" >> "$LATEX_BODY_TMP"
        echo "$latexBelow" >> "$LATEX_BODY_TMP"
        echo "\\bigskip" >> "$LATEX_BODY_TMP"
    		echo "\\end{minipage}" >> "$LATEX_BODY_TMP"
    		echo "\\bigskip" >> "$LATEX_BODY_TMP"
        cat "$LATEX_BODY_TMP" >> "$LATEX_BODY"
        if [ -f "$TMPDIR/$CSVFILE" ]; then
          mkdir -p "$CACHEDIR"
          mv "$LATEX_BODY_TMP" "$CACHEFILE_LATEX"
          cp "$TMPDIR/$CSVFILE" "$CACHEFILE_CSV"
        else
          touch "$TMPDIR/$CSVFILE"
        fi
      else
        cat "$CACHEFILE_LATEX" >> "$LATEX_BODY"
        if [ ! -f "$TMPDIR/$CSVFILE" ]; then
          cp "$CACHEFILE_CSV" "$TMPDIR/$CSVFILE"
          echo " ---> \"$title\" ($alignment):: OK! (Cached)"
        fi
      fi
  done
  cd "$TMPDIR"
  pdflatex --halt-on-error "$LATEX_MAIN" > "$TMPDIR/pdflatex.log"
  RES=$?
  cd "$CURDIR"
  if [ $RES -ne 0 ]; then
    tail "$TMPDIR/pdflatex.log"
    cp "$TMPDIR/pdflatex.log" "$PWD/pdflatex.log"
    echo "See $PWD/pdflatex.log for details"
    exit
  fi
}

load_config "$1"
i=0
# Run build process twice to generate TOC, and to catch LaTEX errors before
# starting potentially time consuming SQL queries.
while [ "$i" -lt 2 ]
do
  write_latex_main
  prepare_queries
  build
  i=`expr $i + 1`
done
mv "$TMPDIR/main.pdf" "$OUTPUT"
#rm -rf "$TMPDIR"
