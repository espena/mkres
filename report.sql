/*******************************************************************************************************
  <LATEX>

    \section{MySQL database schema}

    This is a small example on how to mix LaTEX formatted text and MySQL queries to build
    a PDF research report.

    We use the default MySQL database as an example. Remember that the COLS tag (below)
    is mandatory, the number of letters corresponds to the number of columns in the output
    table. Each letter governs how the corresponding column shold be aligned:

    \begin{itemize}
    \item{\emph{l} = left align column text}
    \item{\emph{c} = center column text}
    \item{\emph{r} = right align column text}
    \item{\emph{X} = expand column to make table fit textwidth}
    \end{itemize}

    Hence, the COLS tag for the below table will be \emph{Xllccc}.

    \subsection{Table \emph{db}}

    The below table describes the contants of MySQL's \emph{db} table.

  </LATEX>
*******************************************************************************************************/

USE mysql; /* Always include the USE statement since each query runs in separate sessions */

DESCRIBE db; /* This outputs six columns, specify alignment with <COLS>Xllccc</COLS> */

/*******************************************************************************************************
  <LATEX>

    \section{MySQL users}

    You may define both main sections, subsections and subsubsetcions in commen blocks. The only
    rule is that there must be one and only one LaTEX block per query.

    \subsection{Table \emph{users}}

    The below table lists the users on current mysql instance. Please note that column names
    cannot contain special LaTEX characters, spaces or punctuation. Use naming aliases.

  </LATEX>
*******************************************************************************************************/
USE mysql;
SELECT
  User,
  Host,
  password_last_changed AS PasswordChange
FROM
  user; /* <COLS>Xlr</COLS> is the required column alignment tag for this query */
